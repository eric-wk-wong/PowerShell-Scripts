:: RENAME FILE
IF %OS%==32BIT (
cd "%windir%\system32"
takeown.exe /f atmfd.dll
icacls.exe atmfd.dll /save atmfd.dll.acl
icacls.exe atmfd.dll /grant Administrators:(F) 
rename atmfd.dll x-atmfd.dll
)
IF %OS%==64BIT (
cd "%windir%\system32"
takeown.exe /f atmfd.dll
icacls.exe atmfd.dll /save atmfd.dll.acl
icacls.exe atmfd.dll /grant Administrators:(F) 
rename atmfd.dll x-atmfd.dll
cd "%windir%\syswow64"
takeown.exe /f atmfd.dll
icacls.exe atmfd.dll /save atmfd.dll.acl
icacls.exe atmfd.dll /grant Administrators:(F) 
rename atmfd.dll x-atmfd.dll
)

:: UPDATE REGISTRY
REG ADD "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Windows" /v "DisableATMFD" /t REG_DWORD /d 1 /f
