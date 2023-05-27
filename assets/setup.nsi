!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "Sections.nsh"
!addplugindir .
!addplugindir x86-ansi

!define APPNAME "LibreWolf"
!define PROGNAME "librewolf"
!define EXECUTABLE "${PROGNAME}.exe"
!define PROG_VERSION "pkg_version"
!define COMPANYNAME "LibreWolf"
!define ESTIMATED_SIZE 190000
!define MUI_ICON "librewolf.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "banner.bmp"

Name "${APPNAME}"
OutFile "${PROGNAME}-${PROG_VERSION}.en-US.win64-setup.exe"
InstallDirRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation"
InstallDir $PROGRAMFILES64\${APPNAME}
RequestExecutionLevel admin

# Pages

!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Welcome to the LibreWolf Setup"
!define MUI_WELCOMEPAGE_TEXT "This setup will guide you through the installation of LibreWolf.$\r$\n$\r$\n\
If you don't have it installed already, this will also install the latest Visual C++ Redistributable.$\r$\n$\r$\n\
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

Section "LibreWolf Browser" main
  SectionIn RO

	# Make sure LibreWolf is closed before the installation
	nsProcess::_FindProcess "${EXECUTABLE}"
	Pop $R0
	${If} $R0 = 0
		IfSilent 0 +4
		DetailPrint "${APPNAME} is still running, aborting because of silent install."
		SetErrorlevel 2
		Abort

		DetailPrint "${APPNAME} is still running"
		MessageBox MB_OKCANCEL "LibreWolf is still running and has to be closed for the setup to continue." IDOK continue IDCANCEL break
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
				MessageBox MB_ICONSTOP "LibreWolf is still running and can't be closed by the installer. Please close it manually and try again."
				SetErrorlevel 2
				Abort
			${EndIf}
		${EndIf}
	${EndIf}

	# Install Visual C++ Redistributable (only if not silent)
	IfSilent +4 0
	InitPluginsDir
	File /oname=$PLUGINSDIR\vc_redist.x64.exe vc_redist.x64.exe
	ExecWait "$PLUGINSDIR\vc_redist.x64.exe /install /quiet /norestart"

	# Copy files
	SetOutPath $INSTDIR
	File /r LibreWolf\*.*

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


	#
	# Registry information to let Windows pick us up in the list of available browsers
	#
	
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf" "" "LibreWolf"	

	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities" "ApplicationDescription" "LibreWolf"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities" "ApplicationIcon" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities" "ApplicationName" "LibreWolf"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\FileAssociations" ".htm" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\FileAssociations" ".html" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\FileAssociations" ".pdf" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\Startmenu" "StartMenuInternet" "LibreWolf"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\URLAssociations" "http" "LibreWolfHTM"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\Capabilities\URLAssociations" "https" "LibreWolfHTM"

	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\DefaultIcon" "" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Clients\StartMenuInternet\LibreWolf\shell\open\command" "" "$INSTDIR\librewolf.exe"
	
	WriteRegStr HKLM "Software\RegisteredApplications" "LibreWolf" "Software\Clients\StartMenuInternet\LibreWolf\Capabilities"
	
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM" "" "LibreWolf Handler"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM" "AppUserModelId" "LibreWolf"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "AppUserModelId" "LibreWolf"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationIcon" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationName" "LibreWolf"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationDescription" "Start the LibreWolf Browser"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\Application" "ApplicationCompany" "LibreWolf Community"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\DefaultIcon" "" "$INSTDIR\librewolf.exe,0"
	WriteRegStr HKLM "Software\Classes\LibreWolfHTM\shell\open\command" "" "$\"$INSTDIR\librewolf.exe$\" -osint -url $\"%1$\""

SectionEnd

Section /o "LibreWolf Portable" portable
	SetOutPath $INSTDIR
	File /r LibreWolf
	File LibreWolf-Portable.exe
SectionEnd

SectionGroup /e "LibreWolf WinUpdater" winupdatergroup
	Section /o "WinUpdater" winupdater
		${If} ${SectionIsSelected} ${portable}
			File LibreWolf-WinUpdater.exe
		${Else}
			SetShellVarContext current
			SetOutPath "$APPDATA\LibreWolf"
			File LibreWolf-WinUpdater.exe
			CreateDirectory "$SMPROGRAMS\${COMPANYNAME}"
			CreateShortCut "$SMPROGRAMS\${COMPANYNAME}\LibreWolf WinUpdater.lnk" "$APPDATA\LibreWolf\LibreWolf-WinUpdater.exe" "" "$APPDATA\LibreWolf\LibreWolf-WinUpdater.exe"
			SetShellVarContext all
		${EndIf}
	SectionEnd
	Section /o "Scheduled Task" scheduledtask
		DetailPrint "Creating Scheduled Task"
		; https://ss64.com/nt/schtasks.html
		; There is no better way to create _this_ specific task with schtasks.exe other than with this ugly xml file
		File "/oname=$PLUGINSDIR\winupdater_task.xml" "winupdater_task.xml"
		FileOpen $0 "$PLUGINSDIR\winupdater_task.xml" a
		FileSeek $0 0 END
		FileWrite $0 "      <Command>$APPDATA\LibreWolf\LibreWolf-WinUpdater.exe</Command>$\r$\n"
		FileWrite $0 "      <Arguments>/Scheduled</Arguments>$\r$\n"
		FileWrite $0 "    </Exec>$\r$\n"
		FileWrite $0 "  </Actions>$\r$\n"
		FileWrite $0 "</Task>"
		FileClose $0
		nsExec::ExecToLog 'schtasks.exe /create /xml "$PLUGINSDIR\winupdater_task.xml" /tn "LibreWolf WinUpdater" /f'
	SectionEnd
SectionGroupEnd

# Uninstaller
section "Uninstall"

	# Kill LibreWolf if it is still running
	nsProcess::_FindProcess "${EXECUTABLE}"
	Pop $R0
	${If} $R0 = 0
		DetailPrint "${APPNAME} is still running, killing it..."
		nsProcess::_KillProcess "${EXECUTABLE}"
		Sleep 2000
	${EndIf}

	# Remove the Start Menu folder
	SetShellVarContext current
	RmDir /r "$SMPROGRAMS\${COMPANYNAME}"
	SetShellVarContext all
	RmDir /r "$SMPROGRAMS\${COMPANYNAME}"
 
	# Remove files
	RmDir /r $INSTDIR

	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
	
	#
	# Windows default browser integration
	#
	
	DeleteRegKey HKLM "Software\Clients\StartMenuInternet\LibreWolf"
	DeleteRegKey HKLM "Software\RegisteredApplications"
	DeleteRegKey HKLM "Software\Classes\LibreWolfHTM"


	DetailPrint "Removing Scheduled Task"
	nsExec::ExecToLog 'schtasks.exe /delete /tn "LibreWolf WinUpdater" /f'

sectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${main} "Install the browser for all users"
  !insertmacro MUI_DESCRIPTION_TEXT ${portable} "Extract the browser to a folder or removable storage device for portable use"
  !insertmacro MUI_DESCRIPTION_TEXT ${winupdatergroup} "A companion tool to update LibreWolf with a single click"
  !insertmacro MUI_DESCRIPTION_TEXT ${winupdater} "A companion tool to update LibreWolf with a single click"
  !insertmacro MUI_DESCRIPTION_TEXT ${scheduledtask} "Adds Windows scheduled task to automatically update LibreWolf at log on and every 4 hours"
!insertmacro MUI_FUNCTION_DESCRIPTION_END


Function .onInit
	Var /GLOBAL DEFAULT_INSTDIR
	Var /GLOBAL INSTALL_TYPE
	StrCpy $DEFAULT_INSTDIR $INSTDIR
	StrCpy $INSTALL_TYPE "normal"
FunctionEnd

Function .onSelChange
	${If} ${SectionIsSelected} ${main}
	${AndIf} $0 = ${main}
		StrCpy $INSTDIR $DEFAULT_INSTDIR
		StrCpy $INSTALL_TYPE "normal"
		SectionSetFlags ${portable} 0
		SectionSetFlags ${main} 17 ; SF_SELECTED & SF_RO
		SectionSetFlags ${winupdater} 0
		SectionSetFlags ${scheduledtask} 0
	${EndIf}
	${If} ${SectionIsSelected} ${portable}
	${AndIf} $0 = ${portable}
		StrCpy $INSTDIR "$DESKTOP\LibreWolf Portable"
		StrCpy $INSTALL_TYPE "portable"
		SectionSetFlags ${portable} 17 ; SF_SELECTED & SF_RO
		SectionSetFlags ${main} 0
		SectionSetFlags ${winupdater} ${SF_SELECTED}
		SectionSetFlags ${scheduledtask} ${SF_RO}
	${EndIf}
	${IfNot} ${SectionIsSelected} ${winupdater}
	${AndIfNot} ${SectionIsSelected} ${portable}
	${AndIf} $0 = ${winupdater}
		SectionSetFlags ${scheduledtask} 0
	${EndIf}
	${If} ${SectionIsSelected} ${scheduledtask}
	${AndIf} $0 = ${scheduledtask}
		SectionSetFlags ${winupdater} ${SF_SELECTED}
	${EndIf}
FunctionEnd


Function "CreateDesktopShortcut"
	SetShellVarContext all
	${If} ${SectionIsSelected} ${portable}
		CreateShortCut "$DESKTOP\LibreWolf.lnk" "$INSTDIR\LibreWolf-Portable.exe" "" "$INSTDIR\LibreWolf\librewolf.ico" 0
	${Else}
		CreateShortCut "$DESKTOP\LibreWolf.lnk" "$INSTDIR\librewolf.exe" "" "$INSTDIR\librewolf.exe" 0
	${EndIf}
FunctionEnd
