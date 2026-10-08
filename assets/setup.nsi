!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!addplugindir .
!addplugindir x86-ansi

!define APPNAME "Sentinel"
!define PROGNAME "sentinel"
!define EXECUTABLE "${PROGNAME}.exe"
!define PROG_VERSION "pkg_version"
!define COMPANYNAME "Sentinel"
!define ESTIMATED_SIZE 190000
!define MUI_ICON "sentinel.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "banner.bmp"

Name "${APPNAME}"
OutFile "${PROGNAME}-${PROG_VERSION}.en-US.pkg_arch_suffix-setup.exe"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation"
InstallDir $PROGRAMFILES64\${APPNAME}
RequestExecutionLevel admin

# Pages
!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Welcome to Sentinel Setup"
!define MUI_WELCOMEPAGE_TEXT "Sentinel is a custom version of Firefox, focused on privacy, security and freedom.$\r$\n$\r$\n\
This setup will guide you through the installation.$\r$\n$\r$\n\
Click Next to continue."

!define MUI_COMPONENTSPAGE_SMALLDESC

!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Create desktop shortcut"
!define MUI_FINISHPAGE_RUN_FUNCTION "CreateDesktopShortcut"
!define MUI_FINISHPAGE_RUN_NOTCHECKED

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Sentinel Browser" main
  SectionIn RO

	# Make sure Sentinel is closed before the installation
	nsProcess::_FindProcess "${EXECUTABLE}"
	Pop $R0
	${If} $R0 = 0
		IfSilent 0 +4
		DetailPrint "${APPNAME} is still running, aborting because of silent install."
		SetErrorlevel 2
		Abort

		DetailPrint "${APPNAME} is still running"
		MessageBox MB_OKCANCEL "Sentinel is still running and has to be closed for the setup to continue." IDOK continue IDCANCEL break
break:
		SetErrorlevel 1
		Abort
continue:
		DetailPrint "Closing ${APPNAME} gracefully..."
		nsProcess::_CloseProcess "${EXECUTABLE}"
		Pop $R0
		Sleep 2000
		nsProcess::_FindProcess "${EXECUTABLE}"
		Pop $R0
		${If} $R0 = 0
			DetailPrint "Failed to close ${APPNAME}, killing it..."
			nsProcess::_KillProcess "${EXECUTABLE}"
			Sleep 2000
			nsProcess::_FindProcess "${EXECUTABLE}"
			Pop $R0
			${If} $R0 = 0
				DetailPrint "Failed to kill ${APPNAME}, aborting"
				MessageBox MB_ICONSTOP "Sentinel is still running and can't be closed by the installer. Please close it manually and try again."
				SetErrorlevel 2
				Abort
			${EndIf}
		${EndIf}
	${EndIf}

	# Copy files
	SetOutPath $INSTDIR
	File /r Sentinel\*.*

	# Start Menu
	RMDir /r "$SMPROGRAMS\${COMPANYNAME}" ; Previously those files were stored for the user, we don't want double entries
	SetShellVarContext all
	CreateDirectory "$SMPROGRAMS\${COMPANYNAME}"
	CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\${PROGNAME}.exe" "" "$INSTDIR\${MUI_ICON}"
	CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" ""

	# Uninstaller
	writeUninstaller "$INSTDIR\uninstall.exe"

	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${APPNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\${MUI_ICON}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "${COMPANYNAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "${PROG_VERSION}"
	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
	# Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${ESTIMATED_SIZE}

	# Registry information to let Windows pick us up in the list of available browsers
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel" "" "Sentinel"

	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities" "ApplicationDescription" "Sentinel"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities" "ApplicationIcon" "$INSTDIR\sentinel.exe,0"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities" "ApplicationName" "Sentinel"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities\FileAssociations" ".htm" "SentinelHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities\FileAssociations" ".html" "SentinelHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities\FileAssociations" ".pdf" "SentinelHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities\Startmenu" "StartMenuInternet" "Sentinel"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities\URLAssociations" "http" "SentinelHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\Capabilities\URLAssociations" "https" "SentinelHTM"

	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\DefaultIcon" "" "$INSTDIR\sentinel.exe,0"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\Sentinel\shell\open\command" "" "$INSTDIR\sentinel.exe"

	WriteRegStr HKLM "Software\RegisteredApplications" "Sentinel" "Software\Clients\StartMenuInternet\Sentinel\Capabilities"

	WriteRegStr HKLM "Software\Classes\SentinelHTM" "" "Sentinel Handler"
	WriteRegStr HKLM "Software\Classes\SentinelHTM" "AppUserModelId" "Sentinel"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\Application" "AppUserModelId" "Sentinel"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\Application" "ApplicationIcon" "$INSTDIR\sentinel.exe,0"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\Application" "ApplicationName" "Sentinel"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\Application" "ApplicationDescription" "Start the Sentinel Browser"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\Application" "ApplicationCompany" "Sentinel Community"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\DefaultIcon" "" "$INSTDIR\sentinel.exe,0"
	WriteRegStr HKLM "Software\Classes\SentinelHTM\shell\open\command" "" "$\"$INSTDIR\sentinel.exe$\" -osint -url $\"%1$\""
SectionEnd

Section /o "Sentinel WinUpdater" winupdater
	File Sentinel-WinUpdater.exe
	File ScheduledTask-Create.ps1
	File ScheduledTask-Remove.ps1
	CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\Sentinel WinUpdater.lnk" "$INSTDIR\Sentinel-WinUpdater.exe" "" "$INSTDIR\Sentinel-WinUpdater.exe"
SectionEnd

Section /o "Schedule Automatic Updates" autoupdate
	DetailPrint "Creating scheduled update task"
	Exec '"$INSTDIR\Sentinel-WinUpdater.exe" /CreateTask'
	Sleep 3000
SectionEnd

Section "-Remove WinUpdater" delwinupdater
	SectionGetFlags ${winupdater} $0
	IntCmp $0 ${SF_SELECTED} +1 +2
	Return
	Call RemoveWinUpdater
	Delete "$INSTDIR\Sentinel-WinUpdater.*"
	Delete "$INSTDIR\*.ps1"
SectionEnd

# Uninstaller
section "Uninstall"

	# Kill Sentinel if it is still running
	nsProcess::_FindProcess "${EXECUTABLE}"
	Pop $R0
	${If} $R0 = 0
		DetailPrint "${APPNAME} is still running, killing it..."
		nsProcess::_KillProcess "${EXECUTABLE}"
		Sleep 2000
	${EndIf}

	SetShellVarContext all

	# Remove the Start Menu folder
	RmDir /r "$SMPROGRAMS\Sentinel"

	# Remove files
	RmDir /r $INSTDIR

	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"

	# Windows default browser integration
	DeleteRegKey HKLM "Software\Clients\StartMenuInternet\Sentinel"
	DeleteRegKey HKLM "Software\RegisteredApplications"
	DeleteRegKey HKLM "Software\Classes\SentinelHTM"

	# Remove WinUpdater
	Call un.RemoveWinUpdater
sectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${main} "Install the browser for all users."
  !insertmacro MUI_DESCRIPTION_TEXT ${winupdater} "A companion tool to update Sentinel with a single click."
  !insertmacro MUI_DESCRIPTION_TEXT ${autoupdate} "Run Sentinel WinUpdater to create a scheduled task for automatic updates."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Shared function
!macro RemoveWinUpdater un
  Function ${un}RemoveWinUpdater
		DetailPrint "Removing WinUpdater"
		SetShellVarContext current
		FindFirst $0 $1 $PROFILE\..\*
		loop:
			StrCmp $1 "" done
			RmDir /r "$PROFILE\..\$1\AppData\Roaming\Sentinel\WinUpdater"
			FindNext $0 $1
			Goto loop
		done:
		FindClose $0
		SetShellVarContext all

		DetailPrint "Removing scheduled update task(s) if present"
		nsExec::ExecToLog `powershell -Command "Get-ScheduledTask 'Sentinel*' | Unregister-ScheduledTask -Confirm:$$false"`
  FunctionEnd
!macroend
; Function for installer and uninstaller
!insertmacro RemoveWinUpdater ""
!insertmacro RemoveWinUpdater "un."

Function .onInit
	Var /GLOBAL DEFAULT_INSTDIR
	Var /GLOBAL INSTALL_TYPE
	StrCpy $DEFAULT_INSTDIR $INSTDIR
	StrCpy $INSTALL_TYPE "normal"
	SetShellVarContext current
	IfFileExists "$SMPROGRAMS\${COMPANYNAME}\Sentinel WinUpdater.lnk" +3 +1
	SetShellVarContext all
	IfFileExists "$INSTDIR\Sentinel-WinUpdater.exe" +1 +2
	SectionSetFlags ${winupdater} ${SF_SELECTED}
	IfFileExists "$INSTDIR\sentinel.exe" +2 +1
	SectionSetFlags ${winupdater} ${SF_SELECTED}
	SetShellVarContext all
FunctionEnd

Function .onSelChange
	SectionGetFlags ${winupdater} $0
	IntCmp $0 ${SF_SELECTED} +2 +1
	SectionSetFlags ${autoupdate} 0
FunctionEnd

Function CreateDesktopShortcut
	SetShellVarContext all
	CreateShortCut "$DESKTOP\Sentinel.lnk" "$INSTDIR\sentinel.exe" "" "$INSTDIR\sentinel.exe" 0
FunctionEnd
