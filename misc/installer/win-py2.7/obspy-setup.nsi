!include "LogicLib.nsh"
!include "x64.nsh"


Name ObsPy

RequestExecutionLevel admin


# Download URLs
!define PYTHON_WIN32 "http://www.obspy.org/www/files/python-2.7.2.msi"
!define PYTHON_WIN64 "http://www.obspy.org/www/files/python-2.7.2.amd64.msi"
!define PYWIN32_WIN32 "http://www.obspy.org/www/files/pywin32-216.win32-py2.7.exe"
!define PYWIN32_WIN64 "http://www.obspy.org/www/files/pywin32-216.win-amd64-py2.7.exe"
!define PYWIN32_FILE "pywin32-216-python2.7.exe"
!define DISTRIBUTE_URL "http://python-distribute.org/distribute_setup.py"
!define DISTRIBUTE_FILE "distribute_setup.py"
!define NUMPY_WIN32 "http://www.obspy.org/www/files/numpy-MKL-1.6.1.win32-py2.7.exe"
!define NUMPY_WIN64 "http://www.obspy.org/www/files/numpy-MKL-1.6.1.win-amd64-py2.7.exe"
!define NUMPY_FILE "numpy-1.6.1-python2.7.exe"
!define SCIPY_WIN32 "http://www.obspy.org/www/files/scipy-0.10.0.win32-py2.7.exe"
!define SCIPY_WIN64 "http://www.obspy.org/www/files/scipy-0.10.0.win-amd64-py2.7.exe"
!define SCIPY_FILE "scipy-0.10.0-python2.7.exe"
!define MATPLOTLIB_WIN32 "http://www.obspy.org/www/files/matplotlib-1.1.0.win32-py2.7.exe"
!define MATPLOTLIB_WIN64 "http://www.obspy.org/www/files/matplotlib-1.1.0.win-amd64-py2.7.exe"
!define MATPLOTLIB_FILE "matplotlib-1.1.0-python2.7.exe"
!define LXML_WIN32 "http://www.obspy.org/www/files/lxml-2.3.2.win32-py2.7.exe"
!define LXML_WIN64 "http://www.obspy.org/www/files/lxml-2.3.2.win-amd64-py2.7.exe"
!define LXML_FILE "lxml-2.3.2-python2.7.exe"
!define PYQT_WIN32 "http://www.obspy.org/www/files/PyQt-Py2.7-x32-gpl-4.8.6-1.exe"
!define PYQT_WIN64 "http://www.obspy.org/www/files/PyQt-Py2.7-x64-gpl-4.8.6-1.exe"
!define PYQT_FILE "pyqt-4.8.6-1-python2.7.exe"

# General Symbol Definitions
!define REGKEY "SOFTWARE\$(^Name)"
!define VERSION 2.7.2-5
!define COMPANY "ObsPy Developer Team"
!define URL http://www.obspy.org

# MUI Symbol Definitions
!define MUI_ICON "obspy.ico"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_STARTMENUPAGE_REGISTRY_ROOT HKLM
!define MUI_STARTMENUPAGE_REGISTRY_KEY ${REGKEY}
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME StartMenuGroup
!define MUI_STARTMENUPAGE_DEFAULTFOLDER ObsPy
!define MUI_UNICON "obspy.ico"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

# Included files
!include Sections.nsh
!include MUI2.nsh

# Variables
Var StartMenuGroup
Var PythonDirectory


# check version before everything else
Page custom CheckVersionPage CheckVersionValidation
 
Function CheckVersionPage
    NSISdl::download_quiet http://obspy.org/www/files/obspy-setup.txt $TEMP\obspy-setup.txt
    Pop $R0 ;Get the return value
        StrCmp $R0 "success" +2
            # download failed - abort and continue installation
            Abort
    # check version in downloaded version file
    FileOpen $4 "$TEMP\obspy-setup.txt" r
    FileRead $4 $1
    FileClose $4
    Delete "$TEMP\obspy-setup.txt"
    ${If} $1 != ${VERSION}
        MessageBox MB_YESNO "There is a newer version of obspy-setup.exe available. Do you still want to install this version?" IDNO quit
        Abort
quit:
        Quit
    ${EndIf}
FunctionEnd
 
Function CheckVersionValidation
  # Form validation here. Call Abort to go back to the page.
  # Use !insertmacro MUI_INSTALLOPTIONS_READ $Var "InstallOptionsFile.ini" ...
  # to get values.
FunctionEnd


# Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE LICENSE.txt
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuGroup
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Installer languages
!insertmacro MUI_LANGUAGE English

# Installer attributes
OutFile obspy-setup.exe
InstallDir $PROFILE\ObsPy
CRCCheck on
XPStyle on
ShowInstDetails show
VIProductVersion 2.7.2.3
VIAddVersionKey ProductName ObsPy
VIAddVersionKey ProductVersion "${VERSION}"
VIAddVersionKey CompanyName "${COMPANY}"
VIAddVersionKey CompanyWebsite "${URL}"
VIAddVersionKey FileVersion "${VERSION}"
VIAddVersionKey FileDescription ""
VIAddVersionKey LegalCopyright ""
InstallDirRegKey HKLM "${REGKEY}" Path
ShowUninstDetails show

!define LVM_GETITEMCOUNT 0x1004
!define LVM_GETITEMTEXT 0x102D


Function InstallPython
    # check for Python 2.7.x
    ReadRegStr $2 HKLM "SOFTWARE\Python\PythonCore\2.7\InstallPath\InstallGroup" ""
    ${If} $2 == 'Python 2.7'
        # get Python directory
        ReadRegStr $2 HKLM "SOFTWARE\Python\PythonCore\2.7\InstallPath\" ""
        strcpy $PythonDirectory $2
        DetailPrint "Python 2.7.x installation found at $PythonDirectory."
    ${Else}
        DetailPrint "No existing Python 2.7.x installation found!"
        MessageBox MB_OK "Python 2.7.2 will now be downloaded and installed."
        # fetch latest version
        StrCpy $2 "$TEMP\python-2.7.2.msi"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${PYTHON_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${PYTHON_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${PYTHON_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${PYTHON_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait '"msiexec" /i $2'
        # set Python directory
        ReadRegStr $2 HKLM "SOFTWARE\Python\PythonCore\2.7\InstallPath\" ""
        DetailPrint "Python has been installed at $2"
        strcpy $PythonDirectory $2
    ${EndIf}
FunctionEnd

Function InstallDependencies
    DetailPrint "Installing dependencies ($PythonDirectory)"
    #
    # distribute
    #
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import setuptools"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "Setuptools/distribute already installed."
    ${Else}
        strcpy $2 "$TEMP\${DISTRIBUTE_FILE}"
        DetailPrint "Downloading ${DISTRIBUTE_URL}"
        nsisdl::download /TIMEOUT=30000 ${DISTRIBUTE_URL} $2
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        DetailPrint "Running python ${DISTRIBUTE_FILE}"
        nsExec::Exec '"$PythonDirectory\python.exe" "$2"'
        Delete "$TEMP\distribute_setup.py"
    ${EndIf}
    #
    # PyWin32 (needed for long filenames by virtualenv)
    #
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import win32com"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "PyWin32 already installed."
    ${Else}
        strcpy $2 "$TEMP\${PYWIN32_FILE}"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${PYWIN32_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${PYWIN32_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${PYWIN32_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${PYWIN32_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait $2
        Delete $2
    ${EndIf}
    #
    # NumPy
    #
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import numpy"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "NumPy already installed."
    ${Else}
        strcpy $2 "$TEMP\${NUMPY_FILE}"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${NUMPY_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${NUMPY_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${NUMPY_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${NUMPY_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait $2
        Delete $2
    ${EndIf}
    # SciPy
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import scipy"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "SciPy already installed."
    ${Else}
        strcpy $2 "$TEMP\${SCIPY_FILE}"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${SCIPY_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${SCIPY_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${SCIPY_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${SCIPY_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait $2
        Delete $2
    ${EndIf}
    # matplotlib
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import matplotlib"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "matplotlib already installed."
    ${Else}
        strcpy $2 "$TEMP\${MATPLOTLIB_FILE}"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${MATPLOTLIB_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${MATPLOTLIB_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${MATPLOTLIB_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${MATPLOTLIB_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait $2
        Delete $2
    ${EndIf}
    # lxml
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import lxml"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "lxml already installed."
    ${Else}
        strcpy $2 "$TEMP\${LXML_FILE}"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${LXML_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${LXML_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${LXML_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${LXML_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait $2
        Delete $2
    ${EndIf}
    # PyQT
    nsExec::Exec '"$PythonDirectory\python.exe" -c "import PyQt4"'
    Pop $R0
    ${If} $R0 == 0
        DetailPrint "PyQT already installed."
    ${Else}
        strcpy $2 "$TEMP\${PYQT_FILE}"
        ${If} ${RunningX64}
            DetailPrint "Downloading ${PYQT_WIN64}"
            nsisdl::download /TIMEOUT=30000 ${PYQT_WIN64} $2
        ${Else}
            DetailPrint "Downloading ${PYQT_WIN32}"
            nsisdl::download /TIMEOUT=30000 ${PYQT_WIN32} $2
        ${EndIf}
        Pop $R0 ;Get the return value
            StrCmp $R0 "success" +3
            MessageBox MB_OK "Download failed: $R0"
            Quit
        ExecWait $2
        Delete $2
    ${EndIf}
    # virtualenv
    DetailPrint "Running easy_install.exe -U virtualenv"
    nsExec::Exec '"$PythonDirectory\Scripts\easy_install.exe" -U "virtualenv"'
    # create virtualenv
    DetailPrint "Creating virtual environment ($INSTDIR)"
    nsExec::Exec '"$PythonDirectory\Scripts\virtualenv.exe" --system-site-packages --distribute "$INSTDIR"'
    DetailPrint "Installing further dependencies ($INSTDIR)"
    # pyreadline
    DetailPrint "Running easy_install.exe pyreadline"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" "pyreadline"'
    # ipython
    DetailPrint "Running easy_install.exe -U ipython"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "ipython"'
    # ipdb
    DetailPrint "Running easy_install.exe ipdb"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" "ipdb"'
    # pygments
    DetailPrint "Running easy_install.exe pygments"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" "pygments"'
    # pyzmq
    DetailPrint "Running easy_install.exe -U pyzmq"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "pyzmq"'
    # copy tcl folder in virtualenv as this is not done automatically
    CopyFiles "$PythonDirectory\tcl" "$INSTDIR"
FunctionEnd

Function InstallObsPy
    DetailPrint "Installing ObsPy ($INSTDIR)"
    # installation of all ObsPy modules
    DetailPrint "Running easy_install.exe -U obspy.core"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.core"'
    DetailPrint "Running easy_install.exe -U obspy.mseed"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.mseed"'
    DetailPrint "Running easy_install.exe -U obspy.arclink"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.arclink"'
    DetailPrint "Running easy_install.exe -U obspy.earthworm"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.earthworm"'
    DetailPrint "Running easy_install.exe -U obspy.gse2"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.gse2"'
    DetailPrint "Running easy_install.exe -U obspy.imaging"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.imaging"'
    DetailPrint "Running easy_install.exe -U obspy.iris"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.iris"'
    DetailPrint "Running easy_install.exe -U obspy.neries"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.neries"'
    DetailPrint "Running easy_install.exe -U obspy.sac"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.sac"'
    DetailPrint "Running easy_install.exe -U obspy.seishub"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.seg2"'
    DetailPrint "Running easy_install.exe -U obspy.seg2"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.segy"'
    DetailPrint "Running easy_install.exe -U obspy.seisan"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.seisan"'
    DetailPrint "Running easy_install.exe -U obspy.segy"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.seishub"'
    DetailPrint "Running easy_install.exe -U obspy.signal"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.signal"'
    DetailPrint "Running easy_install.exe -U obspy.sh"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.sh"'
    DetailPrint "Running easy_install.exe -U obspy.taup"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.taup"'
    DetailPrint "Running easy_install.exe -U obspy.wav"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.wav"'
    DetailPrint "Running easy_install.exe -U obspy.xseed"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.xseed"'
    DetailPrint "Running easy_install.exe -U obspy.realtime"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.realtime"'
    DetailPrint "Running easy_install.exe -U obspy.datamark"
    nsExec::Exec '"$INSTDIR\Scripts\easy_install.exe" -U "obspy.datamark"'
FunctionEnd

# Installer sections
Section
    SetShellVarContext all
    ${If} ${RunningX64}
        SetRegView 64
    ${EndIf}
    Call InstallPython
    Call InstallDependencies
    Call InstallObsPy
    SetOutPath $SMPROGRAMS\$StartMenuGroup
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\ObsPy Homepage.lnk" http://www.obspy.org "" "$WINDIR\System32\SHELL32.dll" 13
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Tutorials.lnk" http://tutorial.obspy.org "" "$WINDIR\System32\SHELL32.dll" 13
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Gallery.lnk" http://gallery.obspy.org "" "$WINDIR\System32\SHELL32.dll" 13
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Waveform Examples.lnk" http://examples.obspy.org "" "$WINDIR\System32\SHELL32.dll" 13
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Buildbot Reports.lnk" http://tests.obspy.org "" "$WINDIR\System32\SHELL32.dll" 13
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\IPython Console.lnk" "cmd" '/K "$INSTDIR\Scripts\ipython"' "$INSTDIR\Scripts\python.exe" 0
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\IPython Console (QT).lnk" "cmd" '/K "$INSTDIR\Scripts\ipython" qtconsole --colors=linux --pylab=inline' "$INSTDIR\Scripts\python.exe" 0
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\ObsPy Shell.lnk" "cmd" '/K "$INSTDIR\Scripts\activate.bat"'
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Run Test Suite.lnk" "cmd" '/K "$INSTDIR\Scripts\obspy-runtests"' "$WINDIR\System32\SHELL32.dll" 152
    WriteRegStr HKLM "${REGKEY}\Components" Main 1
    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR
    SetOutPath $INSTDIR
    WriteUninstaller $INSTDIR\uninstall.exe
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    SetOutPath $SMPROGRAMS\$StartMenuGroup
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Uninstall $(^Name).lnk" $INSTDIR\uninstall.exe
    !insertmacro MUI_STARTMENU_WRITE_END
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayName "$(^Name)"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayVersion "${VERSION}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" Publisher "${COMPANY}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" URLInfoAbout "${URL}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayIcon $INSTDIR\uninstall.exe
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" UninstallString $INSTDIR\uninstall.exe
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoModify 1
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoRepair 1
SectionEnd


# Uninstaller sections
Section uninstall
    SetShellVarContext all
    Delete "$SMPROGRAMS\$StartMenuGroup\ObsPy Homepage.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\Tutorials.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\Gallery.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\Waveform Examples.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\Buildbot Reports.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\IPython Console.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\IPython Console (QT).lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\ObsPy Shell.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\Run Test Suite.lnk"
    Delete "$SMPROGRAMS\$StartMenuGroup\Uninstall $(^Name).lnk"
    DeleteRegValue HKLM "${REGKEY}\Components" Main
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)"
    DeleteRegValue HKLM "${REGKEY}" StartMenuGroup
    DeleteRegValue HKLM "${REGKEY}" Path
    DeleteRegKey /IfEmpty HKLM "${REGKEY}\Components"
    DeleteRegKey /IfEmpty HKLM "${REGKEY}"
    RMDir /r $SMPROGRAMS\$StartMenuGroup
    RMDir /r $INSTDIR
    Push $R0
    StrCpy $R0 $StartMenuGroup 1
    StrCmp $R0 ">" no_smgroup
no_smgroup:
    Pop $R0
SectionEnd
