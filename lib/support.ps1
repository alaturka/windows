#Requires -Version 5

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

function backslashify($path) {
    $path -replace '/', "`\"
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

function extname($path) {
    [IO.Path]::GetExtension($path)
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

function relpath($path) {
    Join-Path $MyInvocation.PSScriptRoot -ChildPath $path
}

function rmrf($dir) {
    if (Test-Path -Path $dir) {
        Remove-Item $dir -Recurse -Force -Confirm:$false
    }
}

function testHasCommand($name) {
    [boolean](Get-Command $name -ErrorAction Ignore)
}

function testIsPathInside($root, $path = $PWD) {
 	(fullpath($path)).StartsWith((fullpath($root)), [StringComparison]::OrdinalIgnoreCase)
}

function getGitRelease($repository) {
    $version = git -C $repository describe --always --long 2>$null | capture

    if ([String]::IsNullOrWhiteSpace($version)) {
        return 'UNRELEASED'
    }

    $version
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

# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function updateGitRepository($source) {
    if (!(Test-Path -Path "$($source.Path)\.git")) {
        throw (_ 'Repository not exists: {0}' $source.Path)
    }

    Push-Location $source.Path

    $previousCommit  = git rev-parse HEAD | capture
    $currentURL      = git config remote.origin.url | capture
    $currentBranch   = git branch | capture

    $isURLChanged    = ![String]::IsNullOrWhiteSpace($source.URL) -and
                       !($currentURL -Match $source.URL)
    $isBranchChanged = ![String]::IsNullOrWhiteSpace($source.Branch) -and
                       !($currentBranch -Match "\*\s+$($source.Branch)")

    # Change remote URL if the source is changed
    if ($isURLChanged) {
        git config remote.origin.url $source.URL
    }

    # Fetch and reset local source if the source or the branch is changed
    if ($isURLChanged -or $isBranchChanged) {
        # Reset git fetch refs, so that it can fetch all branches (GH-3368)
        git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
        # Fetch remote branch
        git fetch --force origin "refs/heads/`"$($source.Branch)`":refs/remotes/origin/$($source.Branch)" -q
        # Checkout and track the branch
        git checkout -B $source.Branch -t origin/$source.Branch -q
        # Reset branch HEAD
        git reset --hard origin/$source.Branch -q
    } else {
        git pull --rebase=false -q
    }

    if ($LastExitCode -ne 0) { throw (_ 'Updating repository failed: {0}' $currentURL) }

    Pop-Location
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

$Spinners = @(
    '⣾⣿', '⣽⣿', '⣻⣿', '⢿⣿', '⡿⣿', '⣟⣿', '⣯⣿', '⣷⣿',
    '⣿⣾', '⣿⣽', '⣿⣻', '⣿⢿', '⣿⡿', '⣿⣟', '⣿⣯', '⣿⣷'
)

# Adapted from https://gist.github.com/yoav-lavi/1253321d968db7f52d1a77ac48e3ff96
function invokeNativeWithSpinner {
    param (
        [Parameter(Mandatory, Position = 0)] [string] $native,
        [Parameter(Mandatory              )] [string] $messageProgress,
                                             [string] $messageSuccess,
                                             [string] $messageFailure,

        [Parameter(ValueFromRemainingArguments, Position = 1)] [string[]] $remainings
    )

    $result = [PsCustomObject]@{
        Command   = $native
        Arguments = $remainings
        Output    = $null
        ExitCode  = $null
    }

    $job = [PowerShell]::Create().AddScript({
        param ($result)

        $arguments = $result.Arguments

        $result.Output   = & $result.Command @arguments 2>&1
        $result.ExitCode = $LastExitCode
    }).AddArgument($result)

    $async = $job.BeginInvoke()

    $i = 0
    while (!$async.IsCompleted) {
        $spinner =  $Spinners[$i]
        Write-Host -NoNewLine "`r$spinner  $messageProgress" -ForegroundColor cyan

        Start-Sleep -Milliseconds 100

        if (++$i -eq $Spinners.Count) { $i = 0 }
    }

    $job.EndInvoke($async)

    $lead = "`r$(' ' * $($Spinners[0].Length + $messageProgress.Length + 2))`r>$(' ' * $($Spinners[0].Length - 1))"

    if ($result.ExitCode -eq 0 -and ($PSBoundParameters.Keys -contains 'messageSuccess')) {
        Write-Host -NoNewLine "$lead  $messageSuccess" -ForegroundColor cyan
    } elseif ($result.ExitCode -ne 0 -and ($PSBoundParameters.Keys -contains 'messageFailure')) {
        Write-Host -NoNewLine "$lead  $messageFailure" -ForegroundColor red
        Write-Host
        Write-Host $result.Output
    }

    Write-Host

    $result
}

function longexec { invokeNativeWithSpinner @args }

function invokePath {
    param (
        [Parameter(Mandatory)] [string] $route,
        [Parameter(Mandatory)] [string] $path,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $executable = backslashify $route

    $executable = Join-Path $path -ChildPath "$executable.ps1"

    if (!(Test-Path -Path $executable -PathType leaf)) {
        throw (_ 'Route {0} not found at path {1}' $route, $path)
    }

    $executable = fullpath($executable)

    & $executable @remainings
}

function run { invokePath @args }

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

function done($message) {
    $line = ("{0,-40}`t{1}" -f $message, (_ 'DONE'))
    Write-Host "> $line" -f yellow
}

function notdone($message) {
    $line = ("{0,-40}`t{1}" -f $message, '-')
    Write-Host "> $line" -f cyan
}

function progname($path) {
    [IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name)
}

function testIsInvokedImplicit {
    $position = (Get-PSCallStack | Select-Object -Last 1).Position
    if ([String]::IsNullOrWhiteSpace($position)) {
        return $false
    }

    (
        ($position -split ' ')[0] -eq ([IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name))
    )
}

$Script:DoneCount = 0

function willdo($message) {
    $Script:DoneCount++
    Write-Host ">   $message" -f yellow
}

function wontdo($message) {
    Write-Host "X   $message" -f cyan
}

function installExistingPackage {
    param (
        [Parameter(Mandatory)] [string] $name,
        [Parameter(Mandatory)] [string] $package,
                               [string] $command
    )

    $step = (_ 'Installing {0}' $name)

    if (testHasPackage $package) {
        $step = (_ 'Updating {0}' $package)
        willdo($step)

        exec -MessageFailure (_ 'Package update failed: {0}' $package) scoop update $package
    } elseif (($PSBoundParameters.Keys -contains 'command') -and !(testHasCommand $command)) {
        willdo($step)

        exec -MessageFailure (_ 'Package installation failed: {0}' $package) scoop install $package
    } else {
        wontdo($step)
    }
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

# Credits: https://stackoverflow.com/a/37353046
function testHasWindowsOptionalFeature($feature) {
    [boolean]((Get-WindowsOptionalFeature -FeatureName $feature -Online).State -eq 'Enabled')
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

function invokeWSLFromStdin {
    param (
        [Parameter(ValueFromPipeline)] [string[]] $source,
                                       [string]   $file,
                                       [string]   $distribution,
                                       [string]   $exec,
                                       [string]   $user,

        [Parameter(ValueFromRemainingArguments, Position = 0)] [string[]] $remainings
    )

    begin {
        $command = @()

        # Windows side

        $command += 'wsl'

        if ($PSBoundParameters.Keys -contains 'distribution') {
            $command += '--distribution', $distribution
        }

        if (!($PSBoundParameters.Keys -contains 'root')) {
            $user = 'root'
        }

        $command += '--user', $user

        $command += '--exec'

        # Linux side

        $command += 'sh', '-c'

        if (!($PSBoundParameters.Keys -contains 'exec')) {
            $exec = 'bash -s'
        }

        $command += (
            "sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r//g'" +        # DOS to Unix conversion: remove UTF-8 BOM and CR
            " | exec $exec -- " +                               # Use exec (instead of fork) to avoid a redundant subshell
            ($remainings | ForEach-Object { "'$_'" }) -join ' ' # Single quote arguments for white space
        )
    }

    process {
        $source = if (!($PSBoundParameters.Keys -contains 'file')) {
            $_
        } else {
            if (!(Test-Path -Path $file -PathType leaf)) {
                throw (_ 'File not found: {0}' $file)
            }

            Get-Content $file
        }
    }

    end {
        $source | & "$Env:COMSPEC" /d /c $command
    }
}

function testCanWSL2 {
    # Build 18362 or higher required for WSL2.
    # Build 18980 or higher required to change username in WSL box.

    [System.Environment]::OSVersion.Version.Build -ge 18980
}

# vim: et ts=4 sw=4 sts=4 tw=120
