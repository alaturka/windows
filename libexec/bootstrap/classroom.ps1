#Requires -Version 5

# KEEP THIS IDEMPOTENT

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
    Checking network connectivity...                     = Ag baglantisi denetleniyor...
    Cloning repository failed: {0}                       = Depo klonlaması başarısız: {0}
    Command failed: ${0}                                 = Komut başarısız: {0}
    Command required: {0}                                = Program gerekiyor: {0}
    DONE                                                 = TAMAM
    Execution Policy violation                           = Yurutme ilkeleriyle uyumsuzluk
    Failed to determine privileges: {0}                  = Yönetici ayrıcalıkları belirlenemedi: {0}
    File not found: {0}                                  = Dosya bulunamadı: {0}
    Ignoring failed operation                            = Hatalı işlem göz ardı ediliyor
    Installing {0}                                       = {0} kuruluyor
    Invocation from remote failed: {0}                   = Uzaktan çalıştırma başarısız: {0}
    Operation failed                                     = İşlem başarısız
    Package installation failed: {0}                     = Paketin kurulumu başarısız: {0}
    Package uninstallation failed: {0}                   = Paketin kaldırılması başarısız: {0}
    Package update failed: {0}                           = Paket güncellemesi başarısız: {0}
    Please run this program in an administrator terminal = Lutfen bu programi bir yonetici terminalinde calistirin
    Repository exists: {0}                               = Depo zaten mevcut: {0}
    Repository not exists: {0}                           = Depo bulunamadı: {0}
    Retrying failed operation: {0}                       = Başarısız işlem tekrar deneniyor: {0}
    Route {0} not found at path {1}                      = {0} rotası {1} dosya yolunda bulunamadı
    Uninstalling package: {0}                            = {0} paketi kaldırılıyor
    Updating repository failed: {0}                      = Depo güncellemesi başarısız: {0}
    Updating {0}                                         = {0} güncelleniyor

    64 BIT WINDOWS 10 SYSTEM REQUIRED.       = 64 BITLIK BIR WINDOWS 10 ISLETIM SISTEMI GEREKIYOR.
    NETWORK CONNECTION REQUIRED              = AG BAGLANTISI GEREKIYOR
    WINDOWS 10 BUILD {0} OR HIGHER REQUIRED. = WINDOWS 10 BUILD {0} VEYA DAHA YENI BIR SURUM GEREKIYOR.
    WINDOWS 10 OR, A NEWER SYSTEM REQUIRED.  = WINDOWS 10 VEYA DAHA YENI BIR SURUM GEREKIYOR.

    FOR A BETTER WSL EXPERIENCE, UPGRADING TO A MORE LATEST VERSION OF WINDOWS IS RECOMMENDED. = WSL YENILIKLERI ICIN DAHA GUNCEL BIR WINDOWS SURUMUNE YUKSELTME YAPMANIZ ONERILIR.
    YOU DO NOT HAVE SUFFICIENT PERMISSIONS. PLEASE RUN THE FOLLOWING COMMAND AND RETRY:        = YETERLI IZINLERE SAHIP DEGILSINIZ.  LUTFEN SU KOMUTU CALISTIRARAK TEKRAR EDIN:
    YOUR SYSTEM MEETS THE MINIMUM REQUIREMENTS FOR WSL AND, THE INSTALLATION WILL CONTINUE.    = SISTEMINIZ WSL ICIN GEREKLI ASGARI SARTLARI SAGLIYOR VE KURULUM DEVAM EDECEK.
'@}) | importTranslations

function abort {
    foreach ($message in $args) { Write-Host $message -f red }
    exit 1
}

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

function notice {
    foreach ($message in $args) { Write-Host $message -f yellow }
}

function testHasCommand($name) {
    [boolean](Get-Command $name -ErrorAction Ignore)
}

# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function initializeGitRepository($source) {
    if (Test-Path -Path $source.Path) {
        throw (_ 'Repository exists: {0}' $source.Path)
    }

    git clone -q $source.URL --branch $source.Branch --single-branch "`"$($source.Path)`""

    if ($LastExitCode -ne 0) { rmrf $source.Path }

    if (!(Test-Path $source.Path)) {
        throw (_ 'Cloning repository failed: {0}' $source.URL)
    }
}

function testGitRepository($repository) {
    if (!(Test-Path -Path $repository)) {
        return $false
    }

    if (!(Test-Path -Path "$repository\.git")) {
        return $false
    }

    [void](git -C $repository rev-parse --verify HEAD *>$null); $LastExitCode -eq 0
}

function invokeBlock {
    param (
        [Parameter(Mandatory)] [scriptblock] $block,
                               [string]      $messageFailure = (_ 'Ignoring failed operation'),
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
        if (![String]::IsNullOrWhiteSpace($detail)) { Write-Verbose $detail }
        if ($safe) { Write-Verbose $messageFailure } else { throw $messageFailure }
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
            Write-Verbose (_ 'Retrying failed operation: {0}' $_.Exception.InnerException.Message)
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
        if (![String]::IsNullOrWhiteSpace($detail)) { Write-Verbose $detail }
        if ($safe) { Write-Verbose $message } else { throw $message }
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
        Write-Verbose "$_"
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

    Test-Path -Path $lfhBin
}

# Taken from: https://stackoverflow.com/a/58289397
function getInvokedPath {
    $callStack = Get-PSCallStack

    $firstCall = $callStack[$callStack.Count - 1];
    if ($null -ne $firstCall.ScriptName) {
        return $firstCall.ScriptName
    }

    $secondCall = $callStack[$callStack.Count - 2];
    if ($null -ne $secondCall.ScriptName -and $secondCall.FunctionName -eq "<ScriptBlock>") {
        return $secondCall.ScriptName
    }

    $null
}

function progname($path) {
    [IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name)
}

$Script:DoneCount = 0

function willdo($message) {
    $Script:DoneCount++
    Write-Host ">   $message" -f yellow
}

function wontdo($message) {
    Write-Host "X   $message" -f cyan
}

function installMissingPackage {
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
        return
    }

    if (testHasPackage $package) {
        if ($repair) {
            if (trueexec scoop prefix $package) {
                wontdo($step)
                return
            }

            Write-Verbose (_ 'Uninstalling package: {0}' $package)

            safeexec -MessageFailure (_ 'Package uninstallation failed: {0}' $package) scoop uninstall $package
        } else {
            wontdo($step)
            return
        }
    }

    willdo($step)

    exec -MessageFailure (_ 'Package installation failed: {0}' $package) scoop install $package
}

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

# --- Tasks

# KEEP THIS ASCII

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Activating UTF-8 support                             = UTF-8 aktive ediliyor
    Activating Windows Subsystem for Linux (WSL)         = Windows Linux Alt Sistemi (WSL) aktive ediliyor
    Classroom files                                      = Classroom dosyalari
    Classroom files package not installed                = Classroom dosya paketi kurulu degil
    Classroom initialization failed                      = Classroom ilklenmesi basarisiz
    Deploying Classroom                                  = Classroom konuslandiriliyor
    File downloader                                      = Dosya indirme araci
    Initializing Classroom                               = Classroom ilkleniyor
    Initializing LFH Tree                                = LFH dizin agaci ilkleniyor
    Initializing Local File Hierarchy                    = Lokal Dosya Sistemi ilkleniyor
    Initializing package manager                         = Paket yoneticisi ilkleniyor
    Initializing WSL version 2 support                   = Windows Linux Alt Sistemi Versiyon 2 ilkleniyor
    Installing package manager                           = Paket yoneticisi kuruluyor
    Kernel update file for WSL not found                 = WSL icin kernel guncelleme dosyasi bulunamadi
    Nothing done.                                        = Herhangi bir islem yapilmadi.
    Removing possible bogus repository: {0}              = Hasarli olmasi muhtemel depo siliniyor: {0}
    Skipping Windows Terminal installation on Windows 11 = Windows 11 uzerinde Windows Terminal kurulumu atlandi
    Updating package index                               = Paket indeksi yenileniyor

    BOOTSTRAP FAILED. PLEASE RETRY OR, REPORT IF THE ISSUE PERSISTS!   = ON YUKLEME BASARISIZ. ISLEMI TEKRAR EDIN VEYA SORUN DEVAM EDIYORSA RAPORLAYIN!
    COMPLETE THE INSTALLATION WITH THE FOLLOWING COMMAND AFTER REBOOT: = BILGISAYAR BASLADIGINDA KURULUMU ASAGIDAKI KOMUTLA TAMAMLAYIN:
    REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION!                     = BILGISAYAR YENIDEN BASLATILMALI, LUTFEN ISLEMI ONAYLAYIN!
'@}) | importTranslations

function deployClassroom {
    $step = _ 'Deploying Classroom'

    if ($Program.IsOffline) {
        wontdo($step)
        return
    }

    if (Test-Path -Path $Source.Path) {
        if (testGitRepository $Source.Path) {
            wontdo($step)
            return
        }

        Write-Verbose (_ 'Removing possible bogus repository: {0}' $Source.Path)
        rmrf $Source.Path
    }

    willdo($step)

    # Git clone only if we are online (i.e. the script wasn't invoked by means of "iwr | iex")
    initializeGitRepository $Source
}

function initializeClassroom {
    $step = _ 'Initializing Classroom'

    if (testHasCommand 'classroom') {
        wontdo($step)
        return
    }

    willdo($step)

    ensureInPath $Source.Path 'bin'

    if (!(testHasCommand 'classroom')) {
        throw (_ 'Classroom initialization failed')
    }
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
    safecall { initializeUTF8               } # allow terminal messages with UTF-8 characters
    safecall { initializeLocalFileHierarchy } # for future deployments inside a LFH tree
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

    $hasKernel = Test-Path -Path $WSL.KernelTarget -PathType leaf

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
        if (!(testHasPackage $WSL.ScoopPackage)) {
            throw (_ 'Classroom files package not installed')
        }

        $source = (joinPathPackage $WSL.ScoopPackage $WSL.KernelSource)
        if (!(Test-Path -Path $source -PathType leaf)) {
            throw (_ 'Kernel update file for WSL not found')
        }

        [void](mkdir $(dirname $WSL.KernelTarget))
        [void](Copy-Item $source $WSL.KernelTarget)
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
        installMissingPackage -Name (_ 'Classroom files') -Package $WSL.ScoopPackage -Repair
    }
}

function installGit {
    installMissingPackage -Name 'Git' -Command 'git' -Package 'git' -Repair
}

function installScoop {
    $step = _ 'Installing package manager'

    if (testHasCommand 'scoop') {
        wontdo($step)
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

function sanitize {
    assertExecutionPolicy
    assertOSSensible
    assertAdminTerminal
    assertWSLReady
    assertNetConnectivity
}

function initialize {
    # Detect whether the script piped to Invoke-Expression (offline) or invoked locally (online)
    $Program.IsOffline = (getInvokedPath -ne $null)

    $Source.Path       = if ($Program.IsOffline) {
        (fullpath("$PSScriptRoot/../.."))
    } else {
        (resolveLFHSourceFromURL -URL $Source.URL -Root $HOME)
    }
}

function shutdown {
    if ($Script:DoneCount -eq 0) {
        notice ''
        notice (_ 'Nothing done.')
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

function restore {
}

# --- Entry

$Program = @{
    Name           = (progname)
    RebootRequired = $null
    IsOffline      = $null
}

$Source = @{
    URL    = 'https://github.com/alaturka/windows'
    Branch = 'main'
    Path   = $null
}

$WSL = @{
    ScoopPackage = 'classroom'
    KernelSource = 'FID_LXSS_KERNEL'
    KernelTarget = 'C:\Windows\System32\lxss\tools\kernel'
}

function main() {
    try {
        sanitize
    }
    catch {
        Write-Host $PSItem.Exception.Message -f red # FIXME
        return
    }

    try {
        initialize

        installScoop
        installAria2
        installGit
        initializeScoop

        installWindowsTerminal
        installClassroomFiles
        deployClassroom
        initializeClassroom

        initializeWSL
        initializeOptionals

        shutdown
    }
    catch {
        Write-Host $PSItem.Exception.Message -f red # FIXME

        notice ''
        notice (_ 'BOOTSTRAP FAILED. PLEASE RETRY OR, REPORT IF THE ISSUE PERSISTS!')
        notice ''
        notice "`thttps://github.com/alaturka/windows/issues/new/choose"
    }
    finally {
        restore
    }
}

main @args

# vim: et ts=4 sw=4 sts=4 tw=120
