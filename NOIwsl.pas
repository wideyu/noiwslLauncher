program NOIwsl;

uses
  Windows, dynlibs, strutils, SysUtils, Process, Classes;

{$R *.res}

type
  TWslIsDistributionRegistered = function(distributionName: PCWSTR): BOOL; cdecl;
  TWslLaunch = function (distributionName: PCWSTR; command:PCWSTR; useCurrentWorkingDirectory:BOOL; stdIn:HANDLE; stdOut:HANDLE; stdErr:HANDLE; var process:HANDLE):HRESULT;cdecl;
  TWslLaunchInteractive = function (distributionName: PCWSTR; command: PCWSTR; useCurrentWorkingDirectory: BOOL; var exitCode: DWORD): HRESULT; cdecl;
  TWslRegisterDistribution = function (distributionName: PCWSTR; tarGzFilename: PCWSTR):HRESULT;cdecl;
  TWslConfigureDistribution = function (distributionName: PCWSTR; defaultUID: ULONG; wslDistributionFlags: BYTE): HRESULT; cdecl;
var
  WslIsDistributionRegistered: TWslIsDistributionRegistered;
  WslLaunch: TWslLaunch;
  WslLaunchInteractive: TWslLaunchInteractive;
  WslRegisterDistribution: TWslRegisterDistribution;
  WslConfigureDistribution: TWslConfigureDistribution;

  h: handle;
  user: string;
  cmd: wideString;
  wslapi: TLibHandle;
  retry, i: integer;
  hr: hResult;
  ec: DWORD;
  sDISTRO, sDIR: wideString;
  DISTRO: PCWSTR;
  rs: ansiString;
  sl: tStringList;

const
  TARGZ: wideString = 'install.tar.gz';

function WslIsOptionalComponentInstalled(): boolean; begin
  wslapi := LoadLibrary('wslapi.dll');
  WslIsDistributionRegistered := TWslIsDistributionRegistered(GetProcedureAddress(wslapi, 'WslIsDistributionRegistered'));
  WslLaunch := TWslLaunch(GetProcedureAddress(wslapi, 'WslLaunch'));
  WslLaunchInteractive := TWslLaunchInteractive(GetProcedureAddress(wslapi, 'WslLaunchInteractive'));
  WslRegisterDistribution := TWslRegisterDistribution(GetProcedureAddress(wslapi, 'WslRegisterDistribution'));
  WslConfigureDistribution := TWslConfigureDistribution(GetProcedureAddress(wslapi, 'WslConfigureDistribution'));
  result := (wslapi <> DynLibs.NilHandle)
    and (WslIsDistributionRegistered <> nil)
    and (WslLaunch <> nil)
    and (WslRegisterDistribution <> nil)
    and (WslLaunchInteractive <> nil)
    and (WslConfigureDistribution <> nil);
end;


begin
  writeln('!---------------------------------------------------------------------------!');
  writeln('! NOIwsl: NOILinux in Windows WSL2                                          !');
  writeln('!                                                                           !');
  writeln('! Usage:                                                                    !');
  writeln('! NOIwsl.exe - Install intall.tar.gz to NOIwsl distro.                      !');
  writeln('! Blabla.exe - New folder, copy&rename exe, install to Blabla distro.       !');
  writeln('! NOIwsl.exe D:\rootfs.tar.gz - Install D:\rootfs.tar.gz to NOIwsl distro.  !');
  writeln('!                                                                           !');
  writeln('!                                  Github.com/wideyu/noiwsl  wideyu@qq.com  !');
  writeln('!---------------------------------------------------------------------------!');

  sDISTRO := ExtractFileName(ParamStr(0));
  sDIR := ExtractFileDir(ParamStr(0));
  if ExtractFileExt(sDISTRO)<>'' then
    sDISTRO := copy(sDISTRO,1,rpos(ExtractFileExt(sDISTRO),sDISTRO)-1);
  DISTRO := @sDISTRO[1];

try

  if not WslIsOptionalComponentInstalled() then begin
    writeln('Install Windows WSL2 first.');
    write('Press Enter to exit...');
    readln();
    exit;
  end;

  if not WslIsDistributionRegistered(DISTRO) then begin

    (*if not RunCommand('wsl.exe --set-default-version 2', rs) then begin
      writeln('Install Windows WSL2 first.');
      write('Press Enter to exit...');
      readln();
      exit;
    end;*)

    write('Installing '+DISTRO+', this may take a few minutes... ');
    if ParamStr(1) <> '' then TARGZ := ParamStr(1);
    //if WslRegisterDistribution(DISTRO, @TARGZ[1])=0 then
    if RunCommand('wsl.exe --import '+sDISTRO+' '+sDIR+' '+TARGZ+' --version 2', rs) then
      if WslIsDistributionRegistered(DISTRO) then
        writeln('OK.');
    if not WslIsDistributionRegistered(DISTRO) then begin
      writeln('ERROR!');
      if not fileExists(TARGZ) then writeln(TARGZ + ' not found!');
      write('Press Enter to exit...');
      readln();
    end;

    if WslIsDistributionRegistered(DISTRO) then begin
      cmd := '/opt/distrod/bin/distrod enable';
      hr := WslLaunchInteractive(DISTRO, @cmd[1], false, ec);

      for retry := 0 to 9 do begin
        writeln('Please create a default UNIX user account. The username dose not need to match your Windows username.');
        writeln('For more informaton visit: https://aka.ms/wslusers');
        write('Enter new UNIX username: ');
        readln(user);
        cmd := 'adduser --quiet --gecos "' + user + '" "' + user + '"';
        //cmd := 'adduser -g "' + user + '" "' + user + '"';
        hr := WslLaunchInteractive(DISTRO, @cmd[1], false, ec);
        if (hr<>0) or (ec<>0) then begin
          cmd := 'deluser "' + user + '"';
          WslLaunchInteractive(DISTRO, @cmd[1], false, ec);
          continue;
        end;
        if (hr=0) and (ec=0) then break;
      end;

      cmd := 'usermod -aG adm,dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev ' + user;
      hr := WslLaunchInteractive(DISTRO, @cmd[1], false, ec);

      //cmd := 'echo -e "[user]\ndefault=' + user + '" >> /etc/wsl.conf';
      //hr := WslLaunchInteractive(DISTRO, @cmd[1], false, ec);
      hr := WslConfigureDistribution(DISTRO, 1000, 15);
    end;

  end;

  writeln();
  writeln('-> Make sure 3389 port available, or modify /etc/xrdp/xrdp.ini');
  RunCommand('netstat.exe -ano', rs);
  try
    sl := tStringList.Create();
    sl.Text := rs;
    for i := 0 to sl.Count-1 do begin
      rs := sl.Strings[i];
      if (not rs.Contains('TCP')) and (not rs.Contains('UDP')) then
        writeln(rs)
      else begin
        if (not rs.Contains('TCP')) then continue;
        if (not rs.Contains(':3389')) then continue;
        writeln(rs);
      end;
    end;
  finally
    sl.Free;
  end;
  writeln();
  writeln('-> Remote Destop: mstsc.exe /v:localhost[:3389]');
  writeln();

  if WslIsDistributionRegistered(DISTRO) then begin
    RunCommand('wsl.exe -d '+sDISTRO+' -u root -- /opt/distrod/bin/distrod enable', rs);
    RunCommand('wsl.exe -d '+sDISTRO+' -u root -- /opt/distrod/bin/distrod start', rs);
    WslLaunch(DISTRO, '', false, GetStdHandle(STD_INPUT_HANDLE), GetStdHandle(STD_OUTPUT_HANDLE), GetStdHandle(STD_ERROR_HANDLE), h);
  end;

finally
  if wslapi <>  DynLibs.NilHandle then if FreeLibrary(wslapi) then wslapi:= DynLibs.NilHandle;
end;
end.

