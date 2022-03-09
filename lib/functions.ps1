#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

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

function assertHasFile {
    param (
        [Parameter(Mandatory)] [string] $file,
                               [string] $message
    )

    if (!($PSBoundParameters.Keys -contains 'message')) {
        $message = (_ 'File not found: {0}' $file)
    }

    if (Test-Path -Path $file -PathType Leaf) {
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

function geturl($url) {
    getting "$url"

    $path = urlpath($url)
    if ($path) {
        if (Test-Path -Path $path -PathType Leaf) {
            return (Get-Content -Path $path -Raw)
        } elseif (Test-Path -Path $path) {
            throw (_ 'Not a file: {0}' $url)
        } else {
            throw (_ 'File not found: {0}' $url)
        }
    }

    try {
        (Invoke-WebRequest -UseBasicParsing -Uri $url).Content
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
        if ($status -eq '404') {
            throw (_ 'URL not found: {0}' $url)
        } else {
            Write-Warning "$_"
            throw (_ 'Getting from remote failed: {0}' $url)
        }
    }
}

function getvar($name, $default = $null) {
    if (Test-path "variable:$name") {
        (Get-Item "variable:$name").Value
    } else {
        $default
    }
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

function relpath($path) {
    Join-Path $MyInvocation.PSScriptRoot -ChildPath $path
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

function testIsPathInside($root, $path = $PWD) {
 	(fullpath($path)).StartsWith((fullpath($root)), [StringComparison]::OrdinalIgnoreCase)
}

function testurl {
    param (
        [Parameter(Mandatory)] [string] $url,
                               [int]    $timeout = 10,
                               [int[]]  $successCodes = @(200, 301, 302)
    )

    $path = urlpath($url)
    if ($path -and (Test-Path -Path $path)) {
        return $true
    }

    try {
         $param = @{
             DisableKeepAlive = $true
             ErrorAction      = 'Stop'
             Method           = 'Head'
             TimeoutSec       = $timeout
             Uri              = $url
             UseBasicParsing  = $true
             Verbose          = $false
        }

        $response = Invoke-WebRequest @param

        if ($successCodes.Contains([int]$response.StatusCode)) { return $true }
    } catch {
        $status = $_.Exception.Response.StatusCode.Value__

        if ($status -eq '404') {
            Write-Verbose (_ 'URL not found: {0}' $url)
        } else {
            Write-Verbose "$_"
        }
    }

    Write-Verbose (_ 'Getting from remote failed: {0}' $url)

    $false
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



function getGitCurrentBranch($dir) {
    if (!(Test-Path -Path $dir -PathType Container)) {
        throw (_ 'Directory not found: {0}' $dir)
    }

    Push-Location $dir
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null | capture
    }
    finally {
        Pop-Location
    }

    $branch
}

function getGitDescription($dir) {
    if (!(Test-Path -Path $dir -PathType Container)) {
        throw (_ 'Directory not found: {0}' $dir)
    }

    Push-Location $dir
    try {
        $version = git describe --always --long 2>$null | capture
    }
    finally {
        Pop-Location
    }

    if ([String]::IsNullOrWhiteSpace($version)) {
        return 'UNRELEASED'
    }

    $version
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

function resolveGitRepository($path) {
    if (!(testHasCommand 'git')) { return $null }

    $dir = if (Test-Path -Path $dir -PathType Leaf) { dirname($path) } else { $path }

    Push-Location $dir
    try {
        $result = git rev-parse --show-toplevel 2>$null | capture
    }
    finally {
        Pop-Location
    }

    $result
}

# Adapted from Scoop source: https://github.com/ScoopInstaller/Scoop
function syncGitRepository {
    param (
        [Parameter(Mandatory, Position = 0)] [string] $dir,
                                             [string] $url,
                                             [string] $branch
    )

    if (!(Test-Path -Path $dir)) {
        throw (_ 'Directory not found: {0}' $dir)
    }

    Push-Location $dir

    if (!(testGitRepository $dir)) {
        throw (_ 'Not inside a valid repository: {0}' $dir)
    }

    try {
        $type = exec -- git config --local --default='exact' --get 'sync.type' | capture
        if ($type -eq 'never') {
            Write-Verbose (_ 'Skip syncing due to the sync type: {0}' $type)
            return
        }

        $isUrlChanged = if ($PSBoundParameters.Keys -contains 'url') {
            $currentUrl = exec -- git config remote.origin.url | capture
            $url -ne $currentUrl
        } else {
            $false
        }

        $currentBranch = exec -- git rev-parse --abbrev-ref HEAD | capture

        $isBranchChanged = if (($PSBoundParameters.Keys -contains 'branch') -and ($branch -ne '.')) {
            $branch -ne $currentBranch
        } else {
            $branch = $currentBranch
            $false
        }

        $commitBeforeUpdate = exec -- git rev-parse HEAD | capture

        getting (_ 'Updating repository {0}' $dir)

        # Fetch and reset local source if the source or the branch is changed
        if ($isUrlChanged -or $isBranchChanged) {
            # Change remote URL if the source is changed
            if ($isUrlChanged) { exec -- git config remote.origin.url $url }

            # Reset git fetch refs, so that it can fetch all branches (GH-3368)
            exec -- git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
            # Fetch remote branch
            exec -- git fetch --force origin "refs/heads/`"$($branch)`":refs/remotes/origin/$($branch)" --quiet
            # Checkout and track the branch
            exec -- git checkout -B $branch -t origin/$branch --quiet
            # Reset branch HEAD
            exec -- git reset --hard origin/$branch --quiet
        } else {
            exec -- git fetch --force origin --quiet
            # Reset branch HEAD
            exec -- git reset --hard origin/$branch --quiet
        }

        if (!($type -eq 'exact')) { exec -- git clean -xdf --quiet }

        $commitAfterUpdate = exec -- git rev-parse HEAD | capture

        if ($commitBeforeUpdate -ne $commitAfterUpdate) {
            Write-Verbose (_ 'Changes found')
        } else {
            Write-Verbose (_ 'No changes found')
        }

        if ($VerbosePreference -eq 'Continue') {
            $format = 'tformat: * %C(yellow)%h%Creset %<|(72,trunc)%s %C(cyan)%cr%Creset'
            exec -- git --no-pager log --no-decorate --format=$format "$commitBeforeUpdate..HEAD"
        }
    }
    finally {
        Pop-Location
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

$Spinners = @(
    '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷',
    '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷'
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
        $spinner = $Spinners[$i]
        Write-Host -NoNewLine "`r$spinner   $messageProgress" -ForegroundColor cyan

        Start-Sleep -Milliseconds 100

        if (++$i -eq $Spinners.Count) { $i = 0 }
    }

    $job.EndInvoke($async)

    # Flush prompt line: put space as long as the progress message length + 1 for prompt + 3 for space
    Write-Host -NoNewLine "`r$(' ' * $(1 + 3 + $messageProgress.Length))`r"

    if ($result.ExitCode -eq 0 -and ($PSBoundParameters.Keys -contains 'messageSuccess')) {
        Write-Host ">   $messageSuccess" -ForegroundColor cyan
    } elseif ($result.ExitCode -ne 0 -and ($PSBoundParameters.Keys -contains 'messageFailure')) {
        Write-Host ">   $messageFailure" -ForegroundColor red
        Write-Host
        Write-Host $result.Output
    }

    $result
}

function longexec { invokeNativeWithSpinner @args }

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

function run($path, $route) {
    $executable = Join-Path $path -ChildPath "$(backslashify $route).ps1"

    if (!(Test-Path -Path $executable -PathType leaf)) {
        throw (_ 'Route {0} not found at path {1}' $route, $path)
    }

    $executable = fullpath($executable)
    & $executable @args
}

function syncSelf {
    if (!$PSScriptRoot -or !(testGitRepository $PSScriptRoot)) {
        Write-Warning (_ 'No repository found for self')
        return
    }

    safecall -MessageFailure (_ 'Self updating failed') { syncGitRepository $PSScriptRoot }
}

function testIsInvokedByPath {
    $position = (Get-PSCallStack | Select-Object -Last 1).Position
    if ([String]::IsNullOrWhiteSpace($position)) {
        return $false
    }

    (
        ($position -split ' ')[0] -eq ([IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name))
    )
}

function urlrun($url) {
    Write-Verbose $url

    try {
        Set-StrictMode -Off

        # Set TLS1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'
        & $([scriptblock]::Create((Invoke-RestMethod $url))) @args
    }
    catch {
        Write-Warning "$_"
        throw (_ 'Invocation from remote failed: {0}' $url)
    }
}

function getBrokenPackages {
    $installed = Get-ChildItem -Directory $(Join-Path $HOME 'scoop' | Join-Path -ChildPath 'apps') -Name

    foreach ($package in $installed) {
        if ($package -eq 'scoop') { continue }

        scoop info $package *>$null
        if (($LastExitCode -ne 0) -or @(scoop info $package 6>$null | Select-String -pattern 'Installed: No').Count -eq 1) {
            $package
        }
    }
}

function installExistingPackage- {
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
        return $false
    }

    $true
}

function installExistingPackage { [void](installExistingPackage- @args) }

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
    @(scoop bucket list | Where-Object { $_.Name -eq $name }).Count -eq 1
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

function testHasWSLDistribution($distribution) {
    wsl --list --quiet | capture | Select-String $distribution
}
