{$APPTYPE CONSOLE}
program NOIwsl;

uses
  Windows, dynlibs, strutils, SysUtils, Process, Classes, zstream, LibLZMA, XZ;

{$R *.res}

type
  TWslIsDistributionRegistered = function(distributionName: PCWSTR): BOOL; cdecl;
  TWslLaunch = function (distributionName: PCWSTR; command:PCWSTR; useCurrentWorkingDirectory:BOOL; stdIn:HANDLE; stdOut:HANDLE; stdErr:HANDLE; var process:HANDLE):HRESULT;cdecl;
  TWslLaunchInteractive = function (distributionName: PCWSTR; command: PCWSTR; useCurrentWorkingDirectory: BOOL; var exitCode: DWORD): HRESULT; cdecl;
  TWslRegisterDistribution = function (distributionName: PCWSTR; tarGzFilename: PCWSTR):HRESULT;cdecl;
  TWslConfigureDistribution = function (distributionName: PCWSTR; defaultUID: ULONG; wslDistributionFlags: BYTE): HRESULT; cdecl;

const
  BufferSize=128*1024;

var
  WslIsDistributionRegistered: TWslIsDistributionRegistered;
  WslLaunch: TWslLaunch;
  WslLaunchInteractive: TWslLaunchInteractive;
  WslRegisterDistribution: TWslRegisterDistribution;
  WslConfigureDistribution: TWslConfigureDistribution;

  h: handle = 0;
  user: string;
  cmd: wideString;
  wslapi: TLibHandle;
  retry, i: integer;
  hr: hRESULT = 0;
  exitCode: DWORD = 0;
  aDISTRO, aDIR, aPATH: ansiString;
  wDISTRO: wideString;
  pDISTRO: PCWSTR;
  outputStr: ansiString;
  outputWide: wideString;
  outputList: tStringList;
  aTARXZ: ansiString = 'rootfs.tar.xz';
  aTARGZ: ansiString = 'install.tar.gz';

function RunWsl(const commands:array of string;out outputString:wideString):boolean;
var
  outputAnsi: ansiString;
  outputPCWSTR: PCWSTR;
begin
  result := RunCommand('wsl.exe', commands, outputAnsi);
  outputPCWSTR := @outputAnsi[1];
  outputString := StrPas(outputPCWSTR);
end;

function WslIsOptionalComponentInstalled(): boolean; begin
  try
    writeln();
    result := RunWsl(['--list', '--verbose'], outputWide);
    if result then writeln(outputWide);
    result := result and (Pos('VERSION', outputWide)>0);
    wslapi := LoadLibrary('wslapi.dll');
    WslIsDistributionRegistered := TWslIsDistributionRegistered(GetProcedureAddress(wslapi, 'WslIsDistributionRegistered'));
    WslLaunch := TWslLaunch(GetProcedureAddress(wslapi, 'WslLaunch'));
    WslLaunchInteractive := TWslLaunchInteractive(GetProcedureAddress(wslapi, 'WslLaunchInteractive'));
    WslRegisterDistribution := TWslRegisterDistribution(GetProcedureAddress(wslapi, 'WslRegisterDistribution'));
    WslConfigureDistribution := TWslConfigureDistribution(GetProcedureAddress(wslapi, 'WslConfigureDistribution'));
    result := result and (wslapi <> DynLibs.NilHandle);
  except
    result := false;
  end;
end;

function xz2gz(xzf:string; gzf:string): boolean;
var
gz: TGZFileStream;
InFile: TStream;
DeComp:TXZDecompressionStream;
BUffer:array[0..BufferSize-1] of Byte;
count:integer;
show:integer;
begin
  result := false;
  if LoadLZMADLL then
  begin
      gz := TGZFileStream.Create(gzf,gzOpenWrite);
      try
          InFile := TFileStream.Create(xzf, fmOpenRead + fmShareDenyWrite);
          Decomp := TXZDecompressionStream.Create(InFile);
          try
            show := 0;
            while True do
            begin
              Count:=Decomp.Read(Buffer,BufferSize);
              if Count<>0 then gz.WriteBuffer(Buffer,Count) else Break;
              show := show + Count;
              if show > 100*1024*1024 then begin
                write('.');
                show := 0;
              end;
            end;
            writeln('OK.');
          finally
            DeComp.Free;
            InFile.Free;
          end;
      finally
        gz.Free;
      end;
      result := true;
      UnloadLZMADLL;
   end;
end;

procedure checkFiles();
begin
    if ParamStr(1) <> '' then begin
      if lowerCase(ExtractFileExt(ParamStr(1))) = '.xz' then begin
        aTARXZ := ParamStr(1);
        aTARGZ := aPATH + ChangeFileExt(ExtractFileName(aTARXZ), '.gz');
      end else
      if lowerCase(ExtractFileExt(ParamStr(1))) = '.gz' then begin
        aTARXZ := '';
        aTARGZ := paramStr(1);
      end else begin
        writeln('Only tar.xz tar.gz supported.');
        write('Press Enter to exit...');
        readln();
        halt;
      end;
    end;
    if aTARXZ<>'' then begin
      if not fileExists(aTARXZ) then begin
        writeln(aTARXZ+' not found.');
        write('Press Enter to exit...');
        readln();
        halt;
      end;
    end else begin
      if not fileExists(aTARGZ) then begin
        writeln(aTARGZ+' not found.');
        write('Press Enter to exit...');
        readln();
        halt;
      end;
    end;
end;

procedure checkPorts();
begin
    writeln();
  writeln('-> Make sure 3389 port available, or modify /etc/xrdp/xrdp.ini');
  if RunCommand('netstat.exe', ['-ano'], outputStr) then
  try
    outputList := tStringList.Create();
    outputList.Text := outputStr;
    for i := 0 to outputList.Count-1 do begin
      outputStr := outputList.Strings[i];
      if (not outputStr.Contains('TCP')) and (not outputStr.Contains('UDP')) then
        writeln(outputStr)
      else begin
        if (not outputStr.Contains('TCP')) then continue;
        if (not outputStr.Contains(':3389')) then continue;
        writeln(outputStr);
      end;
    end;
  finally
    outputList.Free;
  end;
  writeln();
  writeln('-> Remote Destop: mstsc.exe /v:localhost[:3389]');
  writeln();
end;

begin
  writeln();
  writeln(' NOIwsl: NOILinux in Windows WSL2                                            ');
  writeln('=============================================================================');
  writeln(' Usage:                                                                      ');
  writeln(' NOIwsl.exe - Install [rootfs.tar.xz] to NOIwsl distro.                      ');
  writeln(' Blabla.exe - New folder, copy&rename exe, install to Blabla distro.         ');
  writeln(' NOIwsl.exe D:\install.tar.gz - Install D:\install.tar.gz to NOIwsl distro.  ');
  writeln('                                                                             ');
  writeln('                                  Github.com/wideyu/noiwsl  wideyu@qq.com    ');
  writeln('=============================================================================');

  aDISTRO := ExtractFileName(ParamStr(0));
  if ExtractFileExt(aDISTRO)<>'' then
    aDISTRO := copy(aDISTRO,1,rpos(ExtractFileExt(aDISTRO),aDISTRO)-1);
  wDISTRO := UnicodeString(aDISTRO);
  pDISTRO := @wDISTRO[1];
  aDIR := ExtractFileDir(ParamStr(0));
  aPATH := ExtractFilePath(ParamStr(0));

  if not WslIsOptionalComponentInstalled() then begin
    writeln('Install Windows WSL2 first.');
    write('Press Enter to exit...');
    readln();
    exit;
  end;

  if not WslIsDistributionRegistered(pDISTRO) then begin

    checkFiles();

    if (aTARXZ<>'') then begin
      try
        if not LoadLZMADLL() then begin
          writeln(LZMA_DLL+' not found.');
          write('Press Enter to exit...');
          readln();
          halt();
        end;
      except
      end;

      write(aTARXZ+' -> '+aTARGZ+', this may take a few minutes...');
      if not xz2gz(aTARXZ, aTARGZ) then begin
        write('Press Enter to exit...');
        readln();
        halt;
      end;
    end;

    write('Installing '+aDISTRO+', this may take a few minutes...');
    //if WslRegisterDistribution(pDISTRO, @wTARGZ[1])=0 then
    if RunWsl(['--import', aDISTRO, aDIR, aTARGZ, '--version', '2'], outputWide) then begin
      if WslIsDistributionRegistered(pDISTRO) then
        writeln('OK.')
      else
        writeln('ERROR!');
      writeln(outputWide);
    end;
    if not WslIsDistributionRegistered(pDISTRO) then begin
      write('Press Enter to exit...');
      readln();
    end;

    if WslIsDistributionRegistered(pDISTRO) then begin
      cmd := '/opt/distrod/bin/distrod enable';
      hr := WslLaunchInteractive(pDISTRO, @cmd[1], false, exitCode);

      for retry := 0 to 9 do begin
        writeln('Please create a default UNIX user account. The username dose not need to match your Windows username.');
        writeln('For more informaton visit: https://aka.ms/wslusers');
        write('Enter new UNIX username: ');
        readln(user);
        cmd := UnicodeString('adduser --quiet --gecos "' + user + '" "' + user + '"');
        //cmd := 'adduser -g "' + user + '" "' + user + '"';
        hr := WslLaunchInteractive(pDISTRO, @cmd[1], false, exitCode);
        if (hr<>0) or (exitCode<>0) then begin
          cmd := UnicodeString('deluser "' + user + '"');
          WslLaunchInteractive(pDISTRO, @cmd[1], false, exitCode);
          continue;
        end;
        if (hr=0) and (exitCode=0) then break;
      end;

      cmd := UnicodeString('usermod -aG adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev ' + user);
      hr := WslLaunchInteractive(pDISTRO, @cmd[1], false, exitCode);

      //cmd := 'echo -e "[user]\ndefault=' + user + '" >> /etc/wsl.conf';
      //hr := WslLaunchInteractive(DISTRO, @cmd[1], false, ec);
      hr := WslConfigureDistribution(pDISTRO, 1000, 15);
    end;

  end;

  checkPorts();

  if WslIsDistributionRegistered(pDISTRO) then begin
    RunWsl(['-d', aDISTRO, '-u', 'root', '--exec', '/opt/distrod/bin/distrod', 'enable'], outputWide) ;
    //writeln(outputWide);
    WslLaunch(pDISTRO, '', false, GetStdHandle(STD_INPUT_HANDLE), GetStdHandle(STD_OUTPUT_HANDLE), GetStdHandle(STD_ERROR_HANDLE), h);
  end;

  if wslapi <> DynLibs.NilHandle then if FreeLibrary(wslapi) then wslapi:= DynLibs.NilHandle;
end.

