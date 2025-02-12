# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms

function Show-Menu {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string[]]$Options
  )

  Clear-Host

  Write-Host $Title -ForegroundColor Cyan

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
        $SelectedIndex = ($SelectedIndex - 1 + $Options.Count) % $Options.Count
        break
      }
      40 { # Down arrow
        $SelectedIndex = ($SelectedIndex + 1) % $Options.Count
        break
      }
      13 { # Enter key
        break 
      }
    }
    
    Clear-Host
    Write-Host $Title -ForegroundColor Cyan

  } until ($keyInfo.VirtualKeyCode -eq 13)

  return $SelectedIndex
}

function Select-File-Dialog {
  $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
  $OpenFileDialog.InitialDirectory = "C:\" 
  $OpenFileDialog.Filter = "RAW Files (*.raw)|*.raw|All Files (*.*)|*.*"
  $OpenFileDialog.Multiselect = $false
  $OpenFileDialog.Title = "Select RAW Files" 

  if ($OpenFileDialog.ShowDialog() -eq "OK") {
    return $OpenFileDialog.FileName 
  } else {
    return $null
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

function New-Hashes-File {
  param (
    [Parameter(Mandatory = $true)]
    [System.Collections.Generic.List[string]] $filePaths,

    [Parameter(Mandatory = $true)]
    [string]$DirectoryPath
  )
  
  $hashesOutputFile = $DirectoryPath + "\archivos_hashes.txt"

  foreach($filePath in $filePaths){
    try {
      $hashMd5 = Get-FileHash -Algorithm MD5 -Path $filePath | Select-Object Hash
      $hashSHA256 = Get-FileHash -Algorithm SHA256 -Path $filePath | Select-Object Hash
      "Archivo = " + $filePath | Out-File -FilePath $hashesOutputFile -Append
      "MD5     = " + $hashMd5 | Out-File -FilePath $hashesOutputFile -Append
      "SHA256  = " + $hashSHA256 | Out-File -FilePath $hashesOutputFile -Append
    }
    catch {
      Write-Error "Sucedio un error procesando '$filePath': $_"
    }
  }
}

function Get-Volatil-Data {
  param(
    [Parameter(Mandatory = $true)]
    [string]$DirectoryPath
  )

  Write-Host "OBTENIENDO INFORMACION VOLATIL EN ESTE EQUIPO."
  Write-Host "Espere a que el proceso termine, puede tomar un tiempo."

  $listCreatedFiles = New-Object System.Collections.Generic.List[string]

  Write-Host "(1/12) Extrayendo la fecha del sistema"
  $datetimeOutput = & "Get-Date"
  $datetimeFilePath = $volatilDataPath + "\datetime.txt"
  $datetimeOutput | Out-File -FilePath $datetimeFilePath -Encoding UTF8
  $listCreatedFiles.Add($datetimeFilePath)

  Write-Host "(2/12) Extrayendo la lista de procesos"
  $pslistOutput = & "Get-Process"
  $pslistFilePath = $volatilDataPath + "\pslist.txt"
  $pslistOutput | Out-File -FilePath $pslistFilePath -Encoding UTF8
  $listCreatedFiles.Add($pslistFilePath)

  Write-Host "(3/12) Extrayendo la lista de dlls"
  $listdllsOutput = & "./herramientas/Listdlls.exe"
  $listdllsFilePath = $volatilDataPath + "\listdlls.txt"
  $listdllsOutput | Out-File -FilePath $listdllsFilePath -Encoding UTF8
  $listCreatedFiles.Add($listdllsFilePath)

  Write-Host "(4/12) Extrayendo las conexiones en los puertos"
  $netstatFilePath = $volatilDataPath + "\netstat.txt"
  Netstat -an | Out-File -FilePath $netstatFilePath -Encoding UTF8
  $listCreatedFiles.Add($netstatFilePath)

  Write-Host "(5/12) Extrayendo informacion del host"
  $psinfoOutput = & "./herramientas/psinfo.exe"
  $psinfoFilePath = $volatilDataPath + "\psinfo.txt"
  $psinfoOutput | Out-File -FilePath $psinfoFilePath -Encoding UTF8
  $listCreatedFiles.Add($psinfoFilePath)

  Write-Host "(6/12) Extrayendo los logs de procesos"
  $psloglistOutput = & "./herramientas/psloglist.exe"
  $psloglistFilePath = $volatilDataPath + "\psloglist.txt"
  $psloglistOutput | Out-File -FilePath $psloglistFilePath -Encoding UTF8
  $listCreatedFiles.Add($psloglistFilePath)

  Write-Host "(7/12) Extrayendo la lista de servicios ejecutandose"
  $psserviceOutput = & "./herramientas/psservice.exe"
  $psserviceFilePath = $volatilDataPath + "\psservice.txt"
  $psserviceOutput | Out-File -FilePath $psserviceFilePath -Encoding UTF8
  $listCreatedFiles.Add($psserviceFilePath)

  Write-Host "(8/12) Extrayendo la lista de servicios ejecutandose"
  $psloggedonOutput = & "./herramientas/psloggedon.exe"
  $psloggedonFilePath = $volatilDataPath + "\psloggedon.txt"
  $psloggedonOutput | Out-File -FilePath $psloggedonFilePath -Encoding UTF8
  $listCreatedFiles.Add($psloggedonFilePath)

  Write-Host "(9/12) Extrayendo la lista direcciones MAC registradas en la maquina"
  $arpFilePath = $volatilDataPath + "\arp.txt"
  arp -a | Out-File -FilePath $arpFilePath -Encoding UTF8
  $listCreatedFiles.Add($arpFilePath)

  Write-Host "(10/12) Extrayendo la fecha de creacion de los archivos en disco"
  $creationDateFilePath = $volatilDataPath + "\creationDate.txt"
  cmd /r dir /t:c/a/s/o: c:\ | Out-File -FilePath $creationDateFilePath -Encoding UTF8 
  $listCreatedFiles.Add($creationDateFilePath)

  Write-Host "(11/12) Extrayendo la fecha de modificacion de los archivos en disco"
  $writeDateFilePath = $volatilDataPath + "\writeDate.txt"
  cmd /r dir /t:w/a/s/o: c:\ | Out-File -FilePath $writeDateFilePath -Encoding UTF8 
  $listCreatedFiles.Add($writeDateFilePath)

  Write-Host "(12/12) Extrayendo la fecha de acceso de los archivos en disco"
  $accessDateFilePath = $volatilDataPath + "\accessDate.txt"
  cmd /r dir /t:a/a/s/o: c:\ | Out-File -FilePath $accessDateFilePath -Encoding UTF8 
  $listCreatedFiles.Add($accessDateFilePath)

  New-Hashes-File -filePaths $listCreatedFiles -DirectoryPath $DirectoryPath
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

  Write-Host "OBTENIENDO INFORMACION VOLATIL DE UN VOLCADO DE MEMORIA '$rawFilePath'."
  Write-Host "Espere a que el proceso termine, puede tomar un tiempo."

  $listCreatedFiles = New-Object System.Collections.Generic.List[string]

  $imageProfileRegex = "(VistaSP[0-2]x(64|86)|Win(10|2003SP[0-2]|2008(R2)?SP[0-2]|2012R2|2012|7SP[0-1]|81U1|8SP[0-1]|XP(SP[1-3])?)x(64|86))"
  $physicalOffsetRegex = "Offset \(V\)\s+:\s+(0x[0-9a-fA-F]+)"

  Write-Host "(1/12) Extrayendo la informacionde la imagen ..."
  $imageInfoArguments = @("imageinfo", "-f", $rawFilePath)
  $imageInfoOutput = & $volatilityExePath @imageInfoArguments

  $profileMatches = $imageInfoOutput | Select-String -Pattern $imageProfileRegex -AllMatches | Select-Object -First 1
  $volatilityProfile = $profileMatches.Matches | Select-Object -First 1
  Write-Host "Perfil encontrado: $volatilityProfile"
  $imageInfoFilePath = $DirectoryPath + "\imageinfo.txt"
  $imageInfoOutput | Out-File -FilePath $imageInfoFilePath -Encoding UTF8
  $listCreatedFiles.Add($imageInfoFilePath)

  Write-Host "(2/12) Escaneando la imagen identificando cabeceras de KDBG..."
  $kdbgscanArguments = @("kdbgscan", "-f", $rawFilePath, "--profile", $volatilityProfile)
  $kdbgscanOutput = & $volatilityExePath @kdbgscanArguments
  $kdbgscanFilePath = $DirectoryPath + "\kdbgscan.txt"
  $kdbgscanOutput | Out-File -FilePath $kdbgscanFilePath -Encoding UTF8
  $listCreatedFiles.Add($kdbgscanFilePath)
  
  $physicalOffsetMatches = $kdbgscanOutput | Select-String -Pattern $physicalOffsetRegex 
  $physicalOffset = $physicalOffsetMatches.Matches.Groups[1].Value
  Write-Host "Offset fisico encontrado: $physicalOffset"

  Write-Host "(3/12) Extrayendo lista de procesos en ejecucion"
  $psListArguments = @("pslist", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $psListOutput = & $volatilityExePath @psListArguments
  $psListFilePath = $DirectoryPath + "\psList.txt"
  $psListOutput | Out-File -FilePath $psListFilePath -Encoding UTF8
  $listCreatedFiles.Add($psListFilePath)

  Write-Host "(4/12) Extrayendo lista de librerias dll en ejecucion"
  $dllListArguments = @("dlllist", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $dllListOutput = & $volatilityExePath @dllListArguments
  $dllListFilePath = $DirectoryPath + "\dllList.txt"
  $dllListOutput | Out-File -FilePath $dllListFilePath -Encoding UTF8
  $listCreatedFiles.Add($dllListFilePath)

  Write-Host "(5/12) Extrayendo lista de procesos relacionado con su handle"
  $handlesArguments = @("handles", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $handlesOutput = & $volatilityExePath @handlesArguments
  $handlesFilePath = $DirectoryPath + "\handles.txt"
  $handlesOutput | Out-File -FilePath $handlesFilePath -Encoding UTF8
  $listCreatedFiles.Add($handlesFilePath)

  Write-Host "(6/12) Escaneando y extrayendo la tabla maestra de archivos (MFT)"
  $mftparserArguments = @("mftparser", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $mftparserOutput = & $volatilityExePath @mftparserArguments
  $mftparserFilePath = $DirectoryPath + "\mftparser.txt"
  $mftparserOutput | Out-File -FilePath $mftparserFilePath -Encoding UTF8
  $listCreatedFiles.Add($mftparserFilePath)

  Write-Host "(7/12) Extrayendo linea de tiempo de los artefactos en memoria"
  $timelinerArguments = @("timeliner", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $timelinerOutput = & $volatilityExePath @timelinerArguments
  $timelinerFilePath = $DirectoryPath + "\timeliner.txt"
  $timelinerOutput | Out-File -FilePath $timelinerFilePath -Encoding UTF8
  $listCreatedFiles.Add($timelinerFilePath)

  Write-Host "(8/12) Extrayendo lista de comandos ejecutados en cmd.exe"
  $cmdscanArguments = @("cmdscan", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $cmdscanOutput = & $volatilityExePath @cmdscanArguments
  $cmdscanFilePath = $DirectoryPath + "\cmdscan.txt"
  $cmdscanOutput | Out-File -FilePath $cmdscanFilePath -Encoding UTF8
  $listCreatedFiles.Add($cmdscanFilePath)

  Write-Host "(9/12) Extrayendo lista de comandos ejecutados en cmd.exe con su respectivo buffer y salida (CONSOLE_INFORMATION)"
  $consolesArguments = @("consoles", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $consolesOutput = & $volatilityExePath @consolesArguments
  $consolesFilePath = $DirectoryPath + "\consoles.txt"
  $consolesOutput | Out-File -FilePath $consolesFilePath -Encoding UTF8
  $listCreatedFiles.Add($consolesFilePath)

  Write-Host "(10/12) Extrayendo las direcciones fisicas de los registros HIVES en memoria"
  $hivescanArguments = @("hivescan", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset)
  $hivescanOutput = & $volatilityExePath @hivescanArguments
  $hivescanFilePath = $DirectoryPath + "\hivescan.txt"
  $hivescanOutput | Out-File -FilePath $hivescanFilePath -Encoding UTF8
  $listCreatedFiles.Add($hivescanFilePath)

  Write-Host "(11/12) Creando los archivos ejecutables encontrados en memoria."
  $procexedumpFilePath = $DirectoryPath + "\procexedump"
  Write-Host "(11/12) Los ejecutables se crearán en la ruta" + $procexedumpFilePath
  Initialize-Directory -DirectoryPath $procexedumpFilePath
  $procexedumpArguments = @("procexedump", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset, "--dump-dir", $procexedumpFilePath)
  & $volatilityExePath @procexedumpArguments
  
  Write-Host "(12/12) Creando las librerias de ejecutables encontrados en la memoria"
  $dlldumpFilePath = $DirectoryPath + "\dlldump"
  Write-Host "(12/12) Las librerias se crearán en la ruta" + $dlldumpFilePath
  Initialize-Directory -DirectoryPath $dlldumpFilePath
  $dlldumpArguments = @("dlldump", "-f", $rawFilePath, "--profile", $volatilityProfile, "--kdbg", $physicalOffset, "--dump-dir", $dlldumpFilePath)
  & $volatilityExePath @dlldumpArguments

  New-Hashes-File -filePaths $listCreatedFiles -DirectoryPath $DirectoryPath
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

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog

$folderBrowser.Description = "Seleccione el folder donde desea almacenar la informacion volatil"

if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedPath = $folderBrowser.SelectedPath
    Write-Host "el directorio seleccionado fue: $selectedPath`n"
    
    $menuTitle = "Seleccione una opcion:"
    $menuOptions = @(
      "Opcion 1: Recopilar datos volatiles en este equipo",
      "Opcion 2: Recopilar datos volatiles de un volcado de memoria (.raw)"
    )

    $selection = Show-Menu -Title $menuTitle -Options $menuOptions

    Write-Host "Selecciono: $($menuOptions[$selection])" -ForegroundColor Yellow

    switch ($selection) {
      0 {
        $volatilDataPath = $selectedPath + "\Datos_volatiles"
        Initialize-Directory -DirectoryPath $volatilDataPath
        Clear-Host
        Write-Host $asciiArt
        Get-Volatil-Data -DirectoryPath $volatilDataPath
      }
      1 {
        $concatenatedVolatilityPath = $selectedPath + "\volatility"
        Initialize-Directory -DirectoryPath $concatenatedVolatilityPath
        Clear-Host
        Write-Host $asciiArt
        Write-Host "Seleccione el archivo .raw ..."
        Start-Sleep -Seconds 2 
        Use-Volatility -DirectoryPath $concatenatedVolatilityPath

      }
    }

    Write-Host "Script finished." -ForegroundColor Green
    Read-Host -Prompt "Presione Enter para terminar."
} else {
    Write-Host "No se selecciono ningun directorio"
    Read-Host -Prompt "Presione Enter para terminar."
}
