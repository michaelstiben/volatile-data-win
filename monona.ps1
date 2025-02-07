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

function Ensure-Directory {
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

function Volatility-Recopilation{
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
  
  $imageInfoCommand = "imageinfo"
  $imageInfoArguments = @($imageInfoCommand, "-f", $rawFilePath)

  $imageInfoOutput = & $volatilityExePath @imageInfoArguments

  $imageProfileRegex = "(VistaSP[0-2]x(64|86)|Win(10|2003SP[0-2]|2008(R2)?SP[0-2]|2012R2|2012|7SP[0-1]|81U1|8SP[0-1]|XP(SP[1-3])?)x(64|86))"

  $profileMatches = $imageInfoOutput | Select-String -Pattern $imageProfileRegex -AllMatches | Select-Object -First 1

  $volatilityProfile = $profileMatches.Matches | Select-Object -First 1

  Write-Host "Perfil encontrado: $volatilityProfile"
  $imageInfoFilePath = $DirectoryPath + "\imageinfo.txt"
  $imageInfoOutput | Out-File -FilePath $imageInfoFilePath -Encoding UTF8

  $kdbgscanArguments = @("kdbgscan", "-f", $rawFilePath, "--profile", $volatilityProfile)
  $kdbgscanOutput = & $volatilityExePath @kdbgscanArguments
  $kdbgscanFilePath = $DirectoryPath + "\kdbgscan.txt"
  $kdbgscanOutput | Out-File -FilePath $kdbgscanFilePath -Encoding UTF8
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

En la carpeta que seleccione a continuacion, se crearan tres directorios con la informacion volatil:
  - dumpIt
  - Mac
  - volatility
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

    $concatenatedDumpPath = $selectedPath + "\dumpIt"
    $concatenatedMacPath = $selectedPath + "\Mac"
    
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

        Start-Sleep -Seconds 2 # Example: pause for 2 seconds
        Write-Host "Option 1 completed."
      }
      1 {
        $concatenatedVolatilityPath = $selectedPath + "\volatility"
        Ensure-Directory -DirectoryPath $concatenatedVolatilityPath
        Clear-Host
        Write-Host $asciiArt
        Write-Host "Seleccione el archivo .raw ..."
        Start-Sleep -Seconds 2 # Example: pause for 2 seconds
        Volatility-Recopilation -DirectoryPath $concatenatedVolatilityPath
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




