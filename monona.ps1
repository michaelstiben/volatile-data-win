# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms

function Show-Menu {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string[]]$Options
  )

  # Clear the console
  Clear-Host

  # Display the title
  Write-Host $Title -ForegroundColor Cyan

  # Initialize selected option
  $SelectedIndex = 0

  do {
    # Display the menu options
    for ($i = 0; $i -lt $Options.Count; $i++) {
      if ($i -eq $SelectedIndex) {
        Write-Host "* $($Options[$i])" -ForegroundColor Green
      } else {
        Write-Host "  $($Options[$i])"
      }
    }

    # Get user input (arrow keys and Enter)
    $keyInfo = $Host.UI.RawUI.ReadKey()

    switch ($keyInfo.VirtualKeyCode) {
      38 { # Up arrow
        $SelectedIndex = ($SelectedIndex - 1 + $Options.Count) % $Options.Count # Wrap around
        break
      }
      40 { # Down arrow
        $SelectedIndex = ($SelectedIndex + 1) % $Options.Count # Wrap around
        break
      }
      13 { # Enter key
        break # Exit the loop
      }
    }

    # Clear the menu for redraw
    Clear-Host
    Write-Host $Title -ForegroundColor Cyan

  } until ($keyInfo.VirtualKeyCode -eq 13)

  return $SelectedIndex
}

function Select-File-Dialog {
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.InitialDirectory = "C:\" # Set initial directory (optional)
  $OpenFileDialog.Filter = "RAW Files (*.raw)|*.raw|All Files (*.*)|*.*" # Filter for .raw files
  $OpenFileDialog.Multiselect = $false
  $OpenFileDialog.Title = "Select RAW Files" # Set the dialog title

  if ($OpenFileDialog.ShowDialog() -eq "OK") {
    return $OpenFileDialog.FileName # Return the selected file path
  } else {
    return $null # Return $null if no file is selected
  }
}

function Initialize-Directory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$DirectoryPath
  )

  if (!(Test-Path -Path $DirectoryPath -PathType Container)) {
    Write-Host "Directory '$DirectoryPath' does not exist. Creating..." -ForegroundColor Yellow
    try {
      New-Item -ItemType Directory -Path $DirectoryPath | Out-Null
      Write-Host "Directory '$DirectoryPath' created successfully." -ForegroundColor Green
    }
    catch {
      Write-Error "Failed to create directory '$DirectoryPath': $($_.Exception.Message)"

    }
  } else {
    Write-Host "Directory '$DirectoryPath' already exists." -ForegroundColor Green

  }
}

function Get-Volatil-Data {
  param(
    [Parameter(Mandatory = $true)]
    [string]$DirectoryPath
  )

  Write-Host "(1/12) Extrayendo la fecha del sistema"
  $datetimeOutput = & "Get-Date"
  $datetimeFilePath = $volatilDataPath + "\datetime.txt"
  $datetimeOutput | Out-File -FilePath $datetimeFilePath -Encoding UTF8

  Write-Host "(2/12) Extrayendo la lista de procesos"
  $pslistOutput = & "Get-Process"
  $pslistFilePath = $volatilDataPath + "\pslist.txt"
  $pslistOutput | Out-File -FilePath $pslistFilePath -Encoding UTF8

  Write-Host "(3/12) Extrayendo la lista de dlls"
  $listdllsOutput = & "./herramientas/Listdlls.exe"
  $listdllsFilePath = $volatilDataPath + "\listdlls.txt"
  $listdllsOutput | Out-File -FilePath $listdllsFilePath -Encoding UTF8

  Write-Host "(4/12) Extrayendo las conexiones en los puertos"
  $netstatFilePath = $volatilDataPath + "\netstat.txt"
  Netstat -an | Out-File -FilePath $netstatFilePath -Encoding UTF8

  Write-Host "(5/12) Extrayendo informacion del host"
  $psinfoOutput = & "./herramientas/psinfo.exe"
  $psinfoFilePath = $volatilDataPath + "\psinfo.txt"
  $psinfoOutput | Out-File -FilePath $psinfoFilePath -Encoding UTF8

  Write-Host "(6/12) Extrayendo los logs de procesos"
  $psloglistOutput = & "./herramientas/psloglist.exe"
  $psloglistFilePath = $volatilDataPath + "\psloglist.txt"
  $psloglistOutput | Out-File -FilePath $psloglistFilePath -Encoding UTF8

  Write-Host "(7/12) Extrayendo la lista de servicios ejecutandose"
  $psserviceOutput = & "./herramientas/psservice.exe"
  $psserviceFilePath = $volatilDataPath + "\psservice.txt"
  $psserviceOutput | Out-File -FilePath $psserviceFilePath -Encoding UTF8

  Write-Host "(8/12) Extrayendo la lista de servicios ejecutandose"
  $psloggedonOutput = & "./herramientas/psloggedon.exe"
  $psloggedonFilePath = $volatilDataPath + "\psloggedon.txt"
  $psloggedonOutput | Out-File -FilePath $psloggedonFilePath -Encoding UTF8

  Write-Host "(9/12) Extrayendo la lista direcciones MAC registradas en la maquina"
  $arpFilePath = $volatilDataPath + "\arp.txt"
  arp -a | Out-File -FilePath $arpFilePath -Encoding UTF8

  Write-Host "(10/12) Extrayendo la fecha de creacion de los archivos en la maquina"
  $creationDateFilePath = $volatilDataPath + "\creationDate.txt"
  cmd /r dir /t:c/a/s/o: c:\ | Out-File -FilePath $creationDateFilePath -Encoding UTF8 

  Write-Host "(11/12) Extrayendo la fecha de modificacion de los archivos en la maquina"
  $creationDateFilePath = $volatilDataPath + "\writeDate.txt"
  cmd /r dir /t:w/a/s/o: c:\ | Out-File -FilePath $creationDateFilePath -Encoding UTF8 

  Write-Host "(12/12) Extrayendo la fecha de acceso de los archivos en la maquina"
  $creationDateFilePath = $volatilDataPath + "\accessDate.txt"
  cmd /r dir /t:a/a/s/o: c:\ | Out-File -FilePath $creationDateFilePath -Encoding UTF8 
}

function Use-Volatility{
  param(
    [Parameter(Mandatory = $true)]
    [string]$DirectoryPath
  )

  $rawFilePath = Select-File-Dialog

  if ($rawFilePath) {
    Write-Host "Archivo Seleccionado: $rawFilePath"
  } else {
    Write-Host "No se ha seleccionado un archivo .raw terminando programa." -ForegroundColor Red
    return 0
  }

  $imageProfileRegex = "(VistaSP[0-2]x(64|86)|Win(10|2003SP[0-2]|2008(R2)?SP[0-2]|2012R2|2012|7SP[0-1]|81U1|8SP[0-1]|XP(SP[1-3])?)x(64|86))"
  $physicalOffsetRegex = "Offset \(V\)\s+:\s+(0x[0-9a-fA-F]+)"

  $imageInfoArguments = @("imageinfo", "-f", $rawFilePath)
  $imageInfoOutput = & $volatilityExePath @imageInfoArguments

  $profileMatches = $imageInfoOutput | Select-String -Pattern $imageProfileRegex -AllMatches | Select-Object -First 1
  $volatilityProfile = $profileMatches.Matches | Select-Object -First 1
  Write-Host "Perfil encontrado: $volatilityProfile"
  $imageInfoFilePath = $DirectoryPath + "\imageinfo.txt"
  $imageInfoOutput | Out-File -FilePath $imageInfoFilePath -Encoding UTF8

  $kdbgscanArguments = @("kdbgscan", "-f", $rawFilePath, "--profile", $volatilityProfile)
  $kdbgscanOutput = & $volatilityExePath @kdbgscanArguments
  $kdbgscanFilePath = $DirectoryPath + "\kdbgscan.txt"
  $kdbgscanOutput | Out-File -FilePath $kdbgscanFilePath -Encoding UTF8

  
  $physicalOffsetMatches = $kdbgscanOutput | Select-String -Pattern $physicalOffsetRegex 
  $physicalOffset = $physicalOffsetMatches.Matches.Groups[1].Value
  Write-Host "Offset fisico encontrado: $physicalOffset"

  $psListArguments = @("pslist", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $psListOutput = & $volatilityExePath @psListArguments
  $psListFilePath = $DirectoryPath + "\psList.txt"
  $psListOutput | Out-File -FilePath $psListFilePath -Encoding UTF8

  $dllListArguments = @("dlllist", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $dllListOutput = & $volatilityExePath @dllListArguments
  $dllListFilePath = $DirectoryPath + "\dllList.txt"
  $dllListOutput | Out-File -FilePath $dllListFilePath -Encoding UTF8

  $handlesArguments = @("handles", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $handlesOutput = & $volatilityExePath @handlesArguments
  $handlesFilePath = $DirectoryPath + "\handles.txt"
  $handlesOutput | Out-File -FilePath $handlesFilePath -Encoding UTF8

  $mftparserArguments = @("mftparser", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $mftparserOutput = & $volatilityExePath @mftparserArguments
  $mftparserFilePath = $DirectoryPath + "\mftparser.txt"
  $mftparserOutput | Out-File -FilePath $mftparserFilePath -Encoding UTF8

  $timelinerArguments = @("timeliner", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $timelinerOutput = & $volatilityExePath @timelinerArguments
  $timelinerFilePath = $DirectoryPath + "\timeliner.txt"
  $timelinerOutput | Out-File -FilePath $timelinerFilePath -Encoding UTF8

  $cmdscanArguments = @("cmdscan", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $cmdscanOutput = & $volatilityExePath @cmdscanArguments
  $cmdscanFilePath = $DirectoryPath + "\cmdscan.txt"
  $cmdscanOutput | Out-File -FilePath $cmdscanFilePath -Encoding UTF8

  $consolesArguments = @("consoles", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $consolesOutput = & $volatilityExePath @consolesArguments
  $consolesFilePath = $DirectoryPath + "\consoles.txt"
  $consolesOutput | Out-File -FilePath $consolesFilePath -Encoding UTF8

  $hivescanArguments = @("hivescan", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $hivescanOutput = & $volatilityExePath @hivescanArguments
  $hivescanFilePath = $DirectoryPath + "\hivescan.txt"
  $hivescanOutput | Out-File -FilePath $hivescanFilePath -Encoding UTF8

  $procexedumpFilePath = $DirectoryPath + "\procexedump"
  Initialize-Directory -DirectoryPath $procexedumpFilePath
  $procexedumpArguments = @("procexedump", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset, "--dump-dir", $procexedumpFilePath)
  & $volatilityExePath @procexedumpArguments
  
  $dlldumpFilePath = $DirectoryPath + "\dlldump"
  Initialize-Directory -DirectoryPath $dlldumpFilePath
  $dlldumpArguments = @("dlldump", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset, "--dump-dir", $dlldumpFilePath)
  & $volatilityExePath @dlldumpArguments

}

$volatilityExePath = ".\volatility.exe"

$asciiArt = @"
 __  __  _____  _  _  _____  _  _    __      ____  ____    __    __  __ 
(  \/  )(  _  )( \( )(  _  )( \( )  /__\    (_  _)( ___)  /__\  (  \/  )
 )    (  )(_)(  )  (  )(_)(  )  (  /(__)\     )(   )__)  /(__)\  )    ( 
(_/\/\_)(_____)(_)\_)(_____)(_)\_)(__)(__)   (__) (____)(__)(__)(_/\/\_)
"@

$welcomeMessage = @"
Esta es una herramienta construida por el equipo monona para la recoleccion de datos volatiles.

En la carpeta que seleccione a continuacion, se crearan los directorios con la informacion volatil.
"@

Write-Host $asciiArt
Write-Host $welcomeMessage

Read-Host -Prompt "Presione Enter para iniciar"

# Create a new instance of the FolderBrowserDialog
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

# Set the description of the dialog
$folderBrowser.Description = "Seleccione el folder donde desea almacenar la informacion volatil"

# Show the dialog and check if the user clicked OK
if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # Get the selected folder path
    $selectedPath = $folderBrowser.SelectedPath
    Write-Host "el directorio seleccionado fue: $selectedPath`n"
    
    $menuTitle = "Seleccione una opcion:"
    $menuOptions = @(
      "Opcion 1: Recopilar datos volatiles en este equipo",
      "Opcion 2: Recopilar datos volatiles de un volcado de memoria (.raw)"
    )

    $selection = Show-Menu -Title $menuTitle -Options $menuOptions

    Write-Host "Selecciono: $($menuOptions[$selection])" -ForegroundColor Yellow

    # Perform actions based on the selection
    switch ($selection) {
      0 {
        $volatilDataPath = $selectedPath + "\Datos_volatiles"
        Initialize-Directory -DirectoryPath $volatilDataPath
        Clear-Host
        Write-Host $asciiArt
        Get-Volatil-Data -DirectoryPath $volatilDataPath
        Write-Host "Option 1 completed."
      }
      1 {
        $concatenatedVolatilityPath = $selectedPath + "\volatility"
        Initialize-Directory -DirectoryPath $concatenatedVolatilityPath
        Clear-Host
        Write-Host $asciiArt
        Write-Host "Seleccione el archivo .raw ..."
        Start-Sleep -Seconds 2 # Example: pause for 2 seconds
        Use-Volatility -DirectoryPath $concatenatedVolatilityPath
        Write-Host "Option 2 completed."
      }
    }

    Write-Host "Script finished." -ForegroundColor Green

    # Wait for user input before closing
    Read-Host -Prompt "Presione Enter para terminar."
} else {
    Write-Host "No se selecciono ningun directorio"
    # Wait for user input before closing
    Read-Host -Prompt "Presione Enter para terminar."
}
