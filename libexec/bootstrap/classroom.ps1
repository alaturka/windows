#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

# Classroom Bootstrap script
#
# Invoke without arguments
#
#         Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; iwr -useb URL | iex
#
# Invoke with arguments
#
#         Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; iex "& { $(irm URL) } ARGS..."
#
# For help:
#
#         Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; iex "& { $(irm URL) } -help"
#
# For program identification:
#
#         Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; iex "& { $(irm URL) } -id"

# KEEP THIS IDEMPOTENT

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [string] $Remote,
    [string] $Branch,
    [string] $Local,
    [switch] $ID,
    [switch] $Help
)

$Program = [PSCustomObject]@{
    Name           = 'classroom'
    Description    = 'Classroom Bootstraper'
    ID             = '$Date: 08-03-2022 21:14:57$'
    IsOffline      = $false
    RebootRequired = $false
}

# --- Support

Set-StrictMode -Version Latest

$ErrorActionPreference     = 'Stop'
$Global:ProgressPreference = 'SilentlyContinue'

$PSDefaultParameterValues                  = $PSDefaultParameterValues.Clone()
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

$T = @{}

function _($message, $values = @()) {
    $(if ($T.ContainsKey($message)) { $T[$message] } else { $message }) -f $values
}

function importTranslations {
    process {
        foreach ($key in $_.keys) {
            if ($T.ContainsKey($key)) {
                throw "BUG: Duplicate key '$key' found in L10n Message Dictionary"
            }

            $T.$key = $_.$key
        }
    }
}

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Changes found                                        = Değişiklikler var
    Checking network connectivity...                     = Ag baglantisi denetleniyor...
    Clone target directory already exists: {0}           = Klonlama hedef dizini zaten mevcut: {0}
    Cloning repository failed: {0}                       = Depo getirilemedi: {0}
    Cloning repository: {0}                              = Depo getiriliyor: {0}
    Command failed: ${0}                                 = Komut başarısız: {0}
    Command required: {0}                                = Program gerekiyor: {0}
    DONE                                                 = TAMAM
    Directory not found: {0}                             = Dizin bulunamadı: {0}
    Execution Policy violation                           = Yurutme ilkeleriyle uyumsuzluk
    Failed to determine privileges: {0}                  = Yönetici ayrıcalıkları belirlenemedi: {0}
    File not found: {0}                                  = Dosya bulunamadı: {0}
    Getting from remote failed: {0}                      = URL erişiminde hata: {0}
    Installing {0}                                       = {0} kuruluyor
    Invocation from remote failed: {0}                   = Uzaktan çalıştırma başarısız: {0}
    Malformed URL: {0}                                   = Geçersiz URL: {0}
    No changes found                                     = Değişiklik yok
    No repository found for self                         = Programa ait bir depo belirlenemedi
    Not a file: {0}                                      = Dosya değil: {0}
    Not implemented yet                                  = Henüz gerçeklenmedi
    Not inside a valid repository: {0}                   = Geçerli bir depo içinde değil: {0}
    Operation failed                                     = İşlem başarısız
    Package installation failed: {0}                     = Paketin kurulumu başarısız: {0}
    Package uninstallation failed: {0}                   = Paketin kaldırılması başarısız: {0}
    Package update failed: {0}                           = Paket güncellemesi başarısız: {0}
    Please run this program in an administrator terminal = Lutfen bu programi bir yonetici terminalinde calistirin
    Retrying failed operation: {0}                       = Başarısız işlem tekrar deneniyor: {0}
    Route {0} not found at path {1}                      = {0} rotası {1} dosya yolunda bulunamadı
    Self updating failed                                 = Öz yenileme başarısız
    Skip cloning as the repository seems local: {0}      = Depo yerelde bulunduğundan klonlama yapılmıyor: {0}
    Skip syncing due to the sync type: {0}               = İşlem tipinden dolayı eşzamanlama yapılmıyor: {0}
    URL not found: {0}                                   = URL bulunamadı: {0}
    Uninstalling package: {0}                            = {0} paketi kaldırılıyor
    Updating repository failed                           = Depo yenilemesi başarısız
    Updating repository {0}                              = Depo yenileniyor {0}
    Updating {0}                                         = {0} güncelleniyor

    64 BIT WINDOWS 10 SYSTEM REQUIRED.       = 64 BITLIK BIR WINDOWS 10 ISLETIM SISTEMI GEREKIYOR.
    NETWORK CONNECTION REQUIRED              = AG BAGLANTISI GEREKIYOR
    WINDOWS 10 BUILD {0} OR HIGHER REQUIRED. = WINDOWS 10 BUILD {0} VEYA DAHA YENI BIR SURUM GEREKIYOR.
    WINDOWS 10 OR, A NEWER SYSTEM REQUIRED.  = WINDOWS 10 VEYA DAHA YENI BIR SURUM GEREKIYOR.

    FOR A BETTER WSL EXPERIENCE, UPGRADING TO A MORE LATEST VERSION OF WINDOWS IS RECOMMENDED. = WSL YENILIKLERI ICIN DAHA GUNCEL BIR WINDOWS SURUMUNE YUKSELTME YAPMANIZ ONERILIR.
    YOU DO NOT HAVE SUFFICIENT PERMISSIONS. PLEASE RUN THE FOLLOWING COMMAND AND RETRY:        = YETERLI IZINLERE SAHIP DEGILSINIZ.  LUTFEN SU KOMUTU CALISTIRARAK TEKRAR EDIN:
    YOUR SYSTEM MEETS THE MINIMUM REQUIREMENTS FOR WSL AND, THE INSTALLATION WILL CONTINUE.    = SISTEMINIZ WSL ICIN GEREKLI ASGARI SARTLARI SAGLIYOR VE KURULUM DEVAM EDECEK.
'@}) | importTranslations

function assertHasCommand {
    param (
        [Parameter(Mandatory)] [string] $name,
                               [string] $message
    )

    if (!($PSBoundParameters.Keys -contains 'message')) {
        $message = (_ 'Command required: {0}' $name)
    }

    if (testHasCommand($name)) {
        return
    }

    throw $message
}

function assertHasDir {
    param (
        [Parameter(Mandatory)] [string] $dir,
                               [string] $message
    )

    if (!($PSBoundParameters.Keys -contains 'message')) {
        $message = (_ 'Directory not found: {0}' $dir)
    }

    if (Test-Path -Path $dir -PathType Container) {
        return
    }

    throw $message
}

function basename($path) {
    [IO.Path]::GetFileName($path)
}

function basenameWithoutExtension($path) {
    [IO.Path]::GetFileNameWithoutExtension($path)
}

function capture {
    process { $_ -replace '\s*$' -replace "`0" }
}

function dirname($path) {
    Split-Path -Path $path
}

# Adapted from https://github.com/ScoopInstaller/Scoop
function ensureInPath {
    param (
        [string] $scope = 'User',

        [Parameter(Mandatory, ValueFromRemainingArguments, Position = 0)] [string[]] $remainings
    )

    $dir  = fullpath([IO.Path]::Combine([string[]]($remainings)))
    $path = [Environment]::GetEnvironmentVariable('PATH', $scope)

    if ($path -notmatch [Regex]::escape($dir)) {
        [Environment]::SetEnvironmentVariable('Path', "$dir;$path", $scope)
        $Env:Path = "$dir;$Env:PATH"
    }
}

# Stolen from Scoop source code
function fullpath($path) {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
}

function mkdirp {
    param (
        [switch] $out,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $dir = [IO.Path]::Combine([string[]]($remainings))
    if (!(Test-Path -Path $dir)) {
        [void](New-Item -Path $dir -ItemType Directory)
    }

    if ($out) { $dir }
}

function rmrf {
    foreach ($dir in $args) {
        if (Test-Path -Path $dir) {
            Remove-Item $dir -Recurse -Force -Confirm:$false
        }
    }
}

function testHasCommand($name) {
    [boolean](Get-Command $name -ErrorAction Ignore)
}

function abort   { foreach ($message in $args) { Write-Host $message -f red    }; exit 1 }
function fail    { foreach ($message in $args) { Write-Host $message -f red    }         }
function succeed { foreach ($message in $args) { Write-Host $message -f green  }         }
function notice  { foreach ($message in $args) { Write-Host $message -f yellow }         }

function getting($message) { Write-Host "... $message" -f cyan                           }

$Script:DoneCount = 0
function willdo($message) { $Script:DoneCount++; Write-Host ">   $message" -f yellow    }
function wontdo($message) { Write-Host "X   $message" -f cyan                           }

function urlpath($url) {
    # Dots are special
    if (@('.', '..').Contains($url)) { return [IO.Path]::GetFullPath($url) }

    try {
        $parsed = [System.Uri]$url
        if ($($parsed | Select-Object -ExpandProperty Scheme) -eq 'file') {
            return [IO.Path]::GetFullPath($($parsed | Select-Object -ExpandProperty LocalPath))
        }
    }
    catch {
        Write-Verbose (_ 'Malformed URL: {0}' $url)
    }

    $null
}



function testIsURLLocalAndPresent($url, $dir) {
    $path = urlpath($url)
    if ($path) {
        $local = [IO.Path]::GetFullPath($dir)
        if ($path -eq $local) {
            return $true
        }
    }

    $false
}

# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function initializeGitRepository {
    param (
        [Parameter(Mandatory, Position = 0)] [string] $url,
        [Parameter(Mandatory, Position = 1)] [string] $dir,
                                             [string] $branch
    )

    if (testIsURLLocalAndPresent $url $dir) {
        Write-Verbose (_ 'Skip cloning as the repository seems local: {0}' $url)
        return
    }

    if (Test-Path -Path $dir) {
        throw (_ 'Clone target directory already exists: {0}' $dir)
    }

    $flags = @(
        '--quiet', '--single-branch'
    )

    $cloneDesc = "$url"
    if (![String]::IsNullOrWhiteSpace($branch) -and ($branch -ne '.')) {
        $flags += (
            '--branch', $branch
        )
        $cloneDesc = "$url [$branch]"
    }

    getting (_ 'Cloning repository: {0}' $cloneDesc)
    exec -- git clone @flags $url "`"$($dir)`""

    if ($LastExitCode -ne 0) { rmrf $dir }

    if (!(Test-Path -Path $dir)) {
        throw (_ 'Cloning repository failed: {0}' $cloneDesc)
    }
}

function testGitRepository($dir) {
    if (!(Test-Path -Path $dir)) {
        return $false
    }

    Push-Location $dir
    try {
        [void](git rev-parse --verify HEAD *>$null); $exitCode = $LastExitCode
    }
    finally {
        Pop-Location
    }

    $exitCode -eq 0
}

function invokeBlock {
    param (
        [Parameter(Mandatory)] [scriptblock] $block,
                               [string]      $messageFailure = (_ 'Operation failed'),
                               [switch]      $safe
    )

    $ErrorActionPreference = 'Stop'

    $failed, $detail = $false, $null

    try {
        Set-Strictmode -Off
        $block.Invoke()
    }
    catch [System.Management.Automation.ActionPreferenceStopException] {
        $failed = $true

        if ($Error.Count -gt 1) { $detail = $($Error[1]) }
    }
    catch {
        $failed, $detail = $true, "$_"
    }

    if ($failed) {
        if (![String]::IsNullOrWhiteSpace($detail)) { Write-Warning $detail }
        if ($safe) { Write-Warning $messageFailure } else { throw $messageFailure }
    }
}

function call { invokeBlock @args }
function safecall { invokeBlock -Safe @args }

# Adapted from: https://stackoverflow.com/a/45472343
function invokeBlockWithRetry {
    param (
        [Parameter(Mandatory)] [scriptblock] $block,
                               [int]         $try            = 2,
                               [int]         $delay          = 1000,
                               [string]      $messageFailure = (_ 'Operation failed')
    )

    $ErrorActionPreference = 'Stop'

    $attempt = 0

    do {
        $attempt++

        try {
            Set-Strictmode -Off
            return ($block.Invoke())
        }
        catch {
            Write-Warning (_ 'Retrying failed operation: {0}' $_.Exception.InnerException.Message)
            Start-Sleep -Milliseconds $delay
        }
    } while ($attempt -lt $try)

    throw $messageFailure
}

function insistentcall { invokeBlockWithRetry @args }

function invokeNative {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '')]
    param (
        [Parameter(Mandatory, Position = 0)] [string] $native,
                                             [string] $messageFailure,
                                             [switch] $com,
                                             [switch] $safe,

        [Parameter(ValueFromRemainingArguments, Position = 1)] [string[]] $remainings
    )

    $ErrorActionPreference = 'Stop'

    $message = if ($PSBoundParameters.Keys -contains 'messageFailure') {
        $messageFailure
    } else {
        (_ 'Command failed: {0}' "$native $remainings")
    }

    $failed, $detail = $false, $null

    try {
        if ($com) { & "$Env:COMSPEC" /d /c $native @remainings } else { & $native @remainings }

        $failed = $LastExitCode -ne 0
    }
    catch {
        $failed, $detail = $true, "$_"
    }

    if ($failed) {
        if (![String]::IsNullOrWhiteSpace($detail)) { Write-Warning $detail }
        if ($safe) { Write-Warning $message } else { throw $message }
    }
}

function exec { invokeNative @args }
function safeexec { invokeNative -Safe @args }
function cexec { invokeNative -Com @args }
function safecexec { invokeNative -Com -Safe @args }
function trueexec { try { invokeNative @args *>$null; return $true } catch { return $false } }

function invokeRemote {
    param (
        [Parameter(Mandatory)] [string] $url,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    Write-Verbose $url

    try {
        Set-StrictMode -Off

        # Set TLS1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'
        & $([scriptblock]::Create((Invoke-RestMethod $url))) @remainings
    }
    catch {
        Write-Warning "$_"
        throw (_ 'Invocation from remote failed: {0}' $url)
    }
}

function urlrun { invokeRemote @args }

function initializeLFH {
    param (
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot,
                               [switch] $hidden,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $lfhRoot = resolveLFH -Root $root -Dot:$dot $remainings

    $lfhBin = mkdirp $lfhRoot 'bin' -Out

    foreach ($dir in 'etc', 'tmp', 'var') {
        mkdirp $lfhRoot $dir
    }

    ensureInPath $lfhBin

    if ($hidden) {
        (Get-Item $lfhRoot -Force).Attributes = 'Hidden'
    }

    if (testHasCommand 'sudo') {
        sudo Add-MpPreference -ExclusionPath $lfhRoot
    }
}

function resolveLFH {
    param (
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $root = fullpath($root)

    $lfhRoot = if ($dot) {
        [IO.Path]::Combine($root, '.local')
    } else {
        [IO.Path]::Combine($root, 'local')
    }

    [IO.Path]::Combine([string[]](@($lfhRoot) + $remainings))
}

function resolveLFHSourceFromURL {
    param (
        [Parameter(Mandatory)] [string] $url,
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $src = $url -replace '^[^/]+:/+' -replace '(/+|[.]git)$' -replace '/', "`\"

    $slug  = @('src', $src)
    $slug += $remainings

    resolveLFH -Root $root -Dot:$dot @slug
}

function testHasLFH {
    param (
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot
    )

    $lfhBin = resolveLFH -Root $root -Dot:$dot 'bin'

    Test-Path -Path $lfhBin -PathType Container
}

function progname($path) {
    [IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name)
}

function installMissingPackage- {
    param (
        [Parameter(Mandatory)] [string] $name,
        [Parameter(Mandatory)] [string] $package,
                               [string] $command,
                               [switch] $ignore,
                               [switch] $repair
    )

    $step = (_ 'Installing {0}' $name)

    if (($PSBoundParameters.Keys -contains 'command') -and (testHasCommand $command)) {
        wontdo($step)
        return $false
    }

    if (testHasPackage $package) {
        if ($repair) {
            if (trueexec scoop prefix $package) {
                wontdo($step)
                return $false
            }

            Write-Verbose (_ 'Uninstalling package: {0}' $package)

            safeexec -MessageFailure (_ 'Package uninstallation failed: {0}' $package) scoop uninstall $package
        } else {
            wontdo($step)
            return $false
        }
    }

    willdo($step)

    exec -MessageFailure (_ 'Package installation failed: {0}' $package) scoop install $package

    $true
}

function installMissingPackage { [void](installMissingPackage- @args) }

function joinPathPackage($name) {
    $prefix = exec scoop prefix $name | capture
    Join-Path $prefix @args
}

function testHasPackageBucket($name) {
    @(scoop bucket list | Where-Object { $_ -eq $name }).Count -eq 1
}

function testHasPackage($name) {
    @(scoop export | Where-Object { ($_ -split ' ')[0] -eq $name }).Count -eq 1
}

function assertAdminTerminal {
    if (!(testIsAdmin)) {
        throw (_ 'Please run this program in an administrator terminal')
    }
}

function assertExecutionPolicy {
    $allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')

    if ((Get-ExecutionPolicy).ToString() -In $allowedExecutionPolicy) {
        return
    }

    notice (_ 'YOU DO NOT HAVE SUFFICIENT PERMISSIONS. PLEASE RUN THE FOLLOWING COMMAND AND RETRY:')
    Write-Output "    'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"

    throw (_ 'Execution Policy violation')
}

function assertNetConnectivity {
    $ProgressPreferenceSave    = $Global:ProgressPreference
    $Global:ProgressPreference = 'SilentlyContinue'

    Write-Verbose (_ 'Checking network connectivity...')

    if (!(Test-NetConnection github.com -InformationLevel Quiet)) {
        throw (_ 'NETWORK CONNECTION REQUIRED')
    }

    $Global:ProgressPreference = $ProgressPreferenceSave
}

function assertOSSensible($build = 16215) {
    if (![System.Environment]::Is64BitOperatingSystem) {
        throw (_ '64 BIT WINDOWS 10 SYSTEM REQUIRED.')
    }

    if ([System.Environment]::OSVersion.Version.Major -lt 10) {
        throw (_ 'WINDOWS 10 OR, A NEWER SYSTEM REQUIRED.')
    }

    if ([System.Environment]::OSVersion.Version.Build -lt $build) {
        throw (_ 'WINDOWS 10 BUILD {0} OR HIGHER REQUIRED.' $build)
    }
}

function enableWindowsOptionalFeature($feature) {
    $param = @{
        Online        = $true
        FeatureName   = $feature
        All           = $true
        NoRestart     = $true
        WarningAction = 'SilentlyContinue'
    }
    (Enable-WindowsOptionalFeature @param).RestartNeeded
}

function getWindowsOptionalFeature($feature) {
    $result = Get-WindowsOptionalFeature -FeatureName $feature -Online

    $isEnabled    = $result.State -eq 'Enabled'
    $isActionable = $result.RestartNeeded -or !$isEnabled
    $isRestart    = $result.RestartNeeded

    @{
        Actionable = $isActionable
        Enabled    = $isEnabled
        Restart    = $isRestart
    }
}

function reboot($message) {
    Write-Host
    foreach ($message in $args) { Write-Host $message -f yellow }
    Restart-Computer -Confirm -Force
}

function testIsAdmin {
    try {
        $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity

        return $principal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
    }
    catch {
        Write-Verbose (_ 'Failed to determine privileges: {0}' "$_")

        return $false
    }
}

function testIsWindowsName($name) {
    switch ($name) {
        '11'    { return ([System.Environment]::OSVersion.Version.Build -ge 22000) }
        '10'    { return ([System.Environment]::OSVersion.Version.Build -ge 10240) }
        '8.1'   { return ([System.Environment]::OSVersion.Version.Build -ge 9600)  }
        '8'     { return ([System.Environment]::OSVersion.Version.Build -ge 9200)  }
        '7'     { return ([System.Environment]::OSVersion.Version.Build -ge 7601)  }
        'Vista' { return ([System.Environment]::OSVersion.Version.Build -ge 6002)  }
        'XP'    { return ([System.Environment]::OSVersion.Version.Build -ge 2600)  }
        default { throw "BUG: Unrecognized Windows name $name"                     }
    }
}

function assertWSLReady {
    # Build 18362 or higher required for WSL2.
    # Build 18980 or higher required to change username in WSL box.

    $build = 18980
    if ([System.Environment]::OSVersion.Version.Build -lt $build) {
        notice (_ 'YOUR SYSTEM MEETS THE MINIMUM REQUIREMENTS FOR WSL AND, THE INSTALLATION WILL CONTINUE.')
        notice (_ 'FOR A BETTER WSL EXPERIENCE, UPGRADING TO A MORE LATEST VERSION OF WINDOWS IS RECOMMENDED.')
        notice ''
    }
}

function testCanWSL2 {
    # Build 18362 or higher required for WSL2.
    # Build 18980 or higher required to change username in WSL box.

    [System.Environment]::OSVersion.Version.Build -ge 18980
}

$Classroom = @{
    Distribution = 'Classroom'
    Package      = 'classroom'
    Version      = 1 # Use WSL1 by default, but also prepare WSL2 albeit not enabled
    Root         = 'C:\Classroom'
    Kernel       = @{ Source = 'FID_LXSS_KERNEL'; Target = 'C:\Windows\System32\lxss\tools\kernel' }
}

$Linux = @{
    Remote    = 'https://github.com/alaturka/linux'
    Local     = '/opt/alaturka/linux'
    Branch    = $null
    Bootstrap = 'https://get.linux.alaturka.dev'
}

$Windows = @{
    Remote    = 'https://github.com/alaturka/windows'
    Local     = if (![String]::IsNullOrWhiteSpace($PSScriptRoot)) { (Join-Path $PSScriptRoot '..') } else { $null }
    Branch    = $null
    Bootstrap = 'https://get.windows.alaturka.dev'
}

# --- Functions

# KEEP THIS ASCII

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Activating UTF-8 support                             = UTF-8 aktive ediliyor
    Activating Windows Subsystem for Linux Version 1     = Windows Linux Alt Sistemi Versiyon 1 aktive ediliyor
    Branch                                               = Dal
    Build                                                = Uretim
    Classroom Bootstrap failed.                          = Classroom On Yukleme Basarisiz.
    Classroom Bootstraper                                = Classroom Onyukleyici
    Classroom files                                      = Classroom dosyalari
    Classroom files package not installed                = Classroom dosya paketi kurulu degil
    Classroom initialization failed                      = Classroom ilklenmesi basarisiz
    Deploying Classroom Windows side                     = Classroom Windows tarafi konuslandiriliyor
    File downloader                                      = Dosya indirme araci
    Initializing Classroom                               = Classroom ilkleniyor
    Initializing LFH Tree                                = LFH dizin agaci ilkleniyor
    Initializing Local File Hierarchy                    = Lokal Dosya Sistemi ilkleniyor
    Initializing Windows Subsystem for Linux Version 2   = Windows Linux Alt Sistemi Versiyon 2 ilkleniyor
    Initializing package manager                         = Paket yoneticisi ilkleniyor
    Installing package manager                           = Paket yoneticisi kuruluyor
    Kernel update file for WSL not found                 = WSL icin kernel guncelleme dosyasi bulunamadi
    Nothing done.                                        = Herhangi bir islem yapilmadi.
    Removing bucket: {0}                                 = Paket deposu kaldiriliyor: {0}
    Removing possible bogus repository: {0}              = Hasarli olmasi muhtemel depo siliniyor: {0}
    Resetting package manager                            = Paket yoneticisi sifirlaniyor
    Skipping Windows Terminal installation on Windows 11 = Windows 11 uzerinde Windows Terminal kurulumu atlandi
    Uninstalling broken package: {0}                     = Bozuk paket kaldiriliyor: {0}
    Updating package index                               = Paket indeksi yenileniyor

    COMPLETE THE INSTALLATION WITH THE FOLLOWING COMMAND AFTER REBOOT:                 = BILGISAYAR BASLADIGINDA KURULUMU ASAGIDAKI KOMUTLA TAMAMLAYIN:
    REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION!                                     = BILGISAYAR YENIDEN BASLATILMALI, LUTFEN ISLEMI ONAYLAYIN!
    THIS MIGHT BE A TEMPORARY FAILURE. PLEASE RETRY AND, REPORT IF THE ISSUE PERSISTS! = BU GECICI BIR SORUN OLABILIR. LUTFEN ISLEMI TEKRAR EDIN, SORUN HALA DEVAM EDIYORSA RAPORLAYIN!
'@}) | importTranslations

function deployClassroom {
    $step = _ 'Deploying Classroom Windows side'

    if ($Program.IsOffline) {
        wontdo($step)
        return
    }

    if (Test-Path -Path $Windows.Local) {
        if (testGitRepository $Windows.Local) {
            wontdo($step)
            return
        }

        Write-Verbose (_ 'Removing possible bogus repository: {0}' $Windows.Local)
        rmrf $Windows.Local
    }

    willdo($step)

    # Git clone only if we are online (i.e. the script wasn't invoked by means of "iwr | iex")
    initializeGitRepository -URL $Windows.Remote -Dir $Windows.Local -Branch $Windows.Branch
}

function initializeClassroom {
    $step = _ 'Initializing Classroom'

    if (testHasCommand 'classroom') {
        wontdo($step)
        return
    }

    willdo($step)

    ensureInPath $Windows.Local 'bin'

    if (!(testHasCommand 'classroom')) {
        throw (_ 'Classroom initialization failed')
    }
}

function initializeEnvironmentVariables {
    # Detect Windows SSH connections inside WSL (useful for Vagrant)
    [System.Environment]::SetEnvironmentVariable('WSLENV', 'SSH_CONNECTION/u', 'User')
}

function initializeLocalFileHierarchy {
    $step = _ 'Initializing Local File Hierarchy'

    if ($Program.IsOffline -or (testHasLFH -Root $HOME)) {
        wontdo($step)
        return
    }

    willdo($step)

    initializeLFH -Root $HOME -Hidden
}

function initializeOptionals {
    safecall { initializeUTF8                 } # allow terminal messages with UTF-8 characters
    safecall { initializeLocalFileHierarchy   } # for future deployments inside a LFH tree
    safecall { initializeEnvironmentVariables } # set some useful environment variables
}

$Buckets = @{
    'extras'     = ''
    'nerd-fonts' = ''
    'classroom'  = 'https://github.com/alaturka/scoop.git'
}

function initializeScoop {
    $step = _ 'Initializing package manager'

    $missings = foreach ($bucket in $Buckets.GetEnumerator()) {
        if (!(testHasPackageBucket $bucket.Name)) { $bucket }
    }

    if (!$missings) {
        wontdo($step)
        return
    }

    willdo($step)

    foreach ($bucket in $missings) {
        Write-Verbose $bucket.Name

        exec scoop bucket add $bucket.Name $bucket.Value
    }

    safecall { tweakScoop } # do some tunings as per scoop checkup
}

function initializeUTF8 {
    $step = _ 'Activating UTF-8 support'

    $path    = 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage'
    $desired = '65001'

    $keys = foreach ($key in 'ACP', 'MACCP', 'OEMCP') {
        if (Get-ItemProperty -Path $path -Name $key) {
            $value = Get-ItemPropertyValue -Path $path -Name $key
            if ($value -ne $desired) { $key }
        }
    }

    if (!$keys) {
        wontdo($step)
        return
    }

    willdo($step)

    foreach ($key in $keys) {
        Set-ItemProperty -Path $path -Name $key -Value $desired
    }

    $Program.RebootRequired = $true
}

function initializeWSL1 {
    $step = _ 'Activating Windows Subsystem for Linux (WSL)'

    $feature = 'Microsoft-Windows-Subsystem-Linux'

    [void]($result = insistentcall { getWindowsOptionalFeature $feature })

    if (!$result.Actionable) {
        wontdo($step)
        return
    }

    willdo($step)

    if (!$result.Enabled) {
        [void](insistentcall { enableWindowsOptionalFeature $feature })
        $Program.RebootRequired = $true
    } elseif ($result.Restart) {
        $Program.RebootRequired = $true
    }
}

function initializeWSL2 {
    $step = _ 'Initializing WSL version 2 support'

    if (!(testCanWSL2)) {
        wontdo($step)
        return
    }

    $feature = 'VirtualMachinePlatform'

    [void]($result = insistentcall { getWindowsOptionalFeature $feature })

    $hasKernel = Test-Path -Path $Classroom.Kernel.Target -PathType leaf

    if (!$result.Actionable -And $hasKernel) {
        wontdo($step)
        return
    }

    willdo($step)

    if (!$result.Enabled) {
        [void](insistentcall { enableWindowsOptionalFeature $feature })
        $Script:RebootRequired = $true
    } elseif ($result.Restart) {
        $Script:RebootRequired = $true
    }

    if (!$hasKernel) {
        if (!(testHasPackage $Classroom.Package)) {
            throw (_ 'Classroom files package not installed')
        }

        $source = (joinPathPackage $Classroom.Package $Classroom.Kernel.Source)
        if (!(Test-Path -Path $source -PathType leaf)) {
            throw (_ 'Kernel update file for WSL not found')
        }

        [void](mkdir $(dirname $Classroom.Kernel.Target))
        [void](Copy-Item $source $Classroom.Kernel.Target)
    }
}

function initializeWSL {
    initializeWSL1
    safecall {
        initializeWSL2
    }
}

function installAria2 {
    installMissingPackage -Name (_ 'File downloader') -Package 'aria2'
    [void](scoop config aria2-warning-enabled false *>$null)
}

function installClassroomFiles {
    insistentcall {
        installMissingPackage -Name (_ 'Classroom files') -Package $Classroom.Package -Repair
    }
}

function installGit {
    installMissingPackage -Name 'Git' -Command 'git' -Package 'git' -Repair
}

function installScoop {
    $step = _ 'Installing package manager'

    if (testHasCommand 'scoop') {
        if (testScoopHealth) { wontdo($step) } else { resetScoop }
        return
    }

    willdo($step)

    urlrun 'get.scoop.sh'
}

function installWindowsTerminal {
    if ((testIsWindowsName '11') -and (testHasCommand 'wt')) {
        Write-Verbose (_ 'Skipping Windows Terminal installation on Windows 11')
        return
    }

    installMissingPackage -Name 'Windows Terminal' -Command 'wt' -Package 'windows-terminal'
    installMissingPackage -Name 'Cascadia Code Font' -Package 'cascadia-code'
    installMissingPackage -Name 'Visual C++ Redistributable 2019' -Package 'vcredist2019'
}

function resetScoop {
    $scoop = Join-Path $HOME 'scoop'
    if (!(Test-Path -Path $scoop -PathType Container)) {
        return
    }

    Write-Verbose (_ 'Resetting package manager')

    $dirs = Get-ChildItem -Directory $scoop | Where-Object { $_.Name -ne 'cache' } | %{ $_.FullName }
    rmrf @dirs
}

function tweakScoop {
    # Have some packages ready for the future
    safeexec scoop install gsudo innounp dark
    safecall {
        exec scoop install lessmsi
        scoop config MSIEXTRACT_USE_LESSMSI true
    }
    # Ensure Defender excludes Scoop paths
    Add-MpPreference -ExclusionPath $(Join-Path $HOME 'scoop'),$(Join-Path $Env:ProgramData 'scoop')
    # Enable long path support
    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -Value 1 -ErrorAction SilentlyContinue
}

# --- Main

function bootstrap {
    assertExecutionPolicy
    assertOSSensible
    assertAdminTerminal
    assertWSLReady
    assertNetConnectivity
}

function failure {
    fail $PSItem.Exception.Message

    notice ''
    fail   (_ 'Classroom Bootstrap failed.')
    notice ''
    notice (_ 'THIS MIGHT BE A TEMPORARY FAILURE. PLEASE RETRY AND, REPORT IF THE ISSUE PERSISTS!')
    notice ''
    notice "`thttps://github.com/alaturka/windows/issues/new/choose"

    $global:LastExitCode = 1
}

function initialize {
    if (![String]::IsNullOrWhiteSpace($Remote)) { $Windows.Remote = $Remote }
    if (![String]::IsNullOrWhiteSpace($Branch)) { $Windows.Branch = $Branch }
    if (![String]::IsNullOrWhiteSpace($Local))  { $Windows.Local  = $Local  }

    if ([String]::IsNullOrWhiteSpace($Windows.Local)) {
        $Windows.Local = resolveLFHSourceFromURL -URL $Windows.Remote -Root $HOME
    }

    if (testIsURLLocalAndPresent $Windows.Remote $Windows.Local) {
        assertHasDir $Windows.Local

        $Program.IsOffline = $true
    }
}

function introduce {
    notice "$(_ $Program.Description) - $($Program.ID)"
}

function success {
    if ($Script:DoneCount -eq 0) {
        succeed ''
        succeed (_ 'Nothing done.')
    }

    if ($Program.RebootRequired) {
        notice ''
        notice (_ 'REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION!')
        notice (_ 'COMPLETE THE INSTALLATION WITH THE FOLLOWING COMMAND AFTER REBOOT:')
        notice ''
        notice "`tclassroom install"

        reboot
    }
}

# --- Entry

function main {
    if ($Help) {
        $usage = @'

Usage: iex "& { $(irm URL) } [Flags...]"

Flags:

	-branch BRANCH  Bootstrap from BRANCH
	-help           Display help and return
	-id             Display ident string for this script and return
	-local DIR      Clone URL into DIR
	-remote URL     Remote repository URL
	-verbose        Be verbose

Requires a premissive ExecutionPolicy:

    Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force

'@
        Write-Host $usage
        return
    }

    introduce; if ($ID) { return }

    try {
        bootstrap
    }
    catch {
        return fail $PSItem.Exception.Message
    }

    # Poor man's handling of CTRL-C
    $didScoopCompleted = $false

    try {
        initialize

        installScoop
        installAria2
        installGit
        initializeScoop
        installWindowsTerminal
        installClassroomFiles

        $didScoopCompleted = $true
    }
    catch {
        resetScoop
        return failure
    }
    finally {
        if (!$didScoopCompleted) { resetScoop }
    }

    if (!$didScoopCompleted) { return }

    try {
        deployClassroom
        initializeClassroom
        initializeWSL
        initializeOptionals
    }
    catch {
        return failure
    }

    success
}

main @args
