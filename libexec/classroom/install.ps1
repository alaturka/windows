#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

# KEEP THIS IDEMPOTENT

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [string] $Side = 'both',

    [string] $LinuxBootstrap,
    [string] $LinuxBranch,
    [string] $LinuxLocal,
    [string] $LinuxRemote
)

. "$PSScriptRoot\..\..\lib\functions.ps1"
. "$PSScriptRoot\..\..\lib\classroom.ps1"

# --- L10N

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Adding VS Code as a context menu option          = Bağlam menüsüne VS Code ekleniyor
    Cannot determine the Windows side directory      = Windows tarafının hangi dizinde bulunduğu belirlenemiyor
    Create VS Code file associations                 = VS Code dosya ilişkileri oluşturuluyor
    Creating shortcuts at Desktop                    = Masaüstünde kısayol oluşturuluyor
    Image import failed                              = İmajın aktarımı başarısız
    Image successfully imported                      = İmaj başarıyla aktarıldı
    Importing Linux image                            = Linux imajı aktarılıyor
    Initializing Git installation                    = Git kurulumu ilkleniyor
    Initializing Linux image                         = Linux imajı ilkleniyor
    Initializing VS Code settings                    = VS Code ayarları ilkleniyor
    Initializing VSCode installation                 = VSCode kurulumu ilkleniyor
    Linux Bootstrap URL seems to be not working: {0} = Linux önyükleme bağlantısı çalışmıyor: {0}
    Linux side has already been bootstrapped         = Linux tarafı zaten ön yüklenmiş
    Please wait                                      = Lütfen bekleyin
    Provisioning Classroom                           = Classroom hazırlanıyor
    Provisioning Linux                               = Linux hazırlanıyor
    Setting Linux options has no effect              = Linux seçeneklerinin herhangi bir etkisi yok
    Setting bootstrap branch has no effect           = Önyükleme dalının verilmesinin bir etkisi yok
    Shortcut not found: {0}                          = Kısayol bulunamadı: {0}
    Updating packages                                = Kurulu paketler yenileniyor
    Updating packages failed: {0}                    = Paket güncellemeleri başarısız: {0}
    Windows Terminal required for desktop shortcuts  = Masaüstü kısayolları için Windows Terminal gerekiyor

    Operation completed. Make sure to read related documents. =  İşlem tamamlandı. Lütfen ilgili dokümanları okumayı unutmayın.
    REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION             = MAKİNENİN YENİDEN BAŞLATILMASI GEREKİYOR, LÜTFEN IŞLEMİ ONAYLAYIN!
'@}) | importTranslations

# --- Functions

function copyShortcuts {
    $step = _ 'Creating shortcuts at Desktop'

    if (!(testHasCommand 'wt')) {
        Write-Verbose (_ 'Windows Terminal required for desktop shortcuts')
        wontdo($step)
        return
    }

    $source = [System.IO.Path]::Combine(
        [Environment]::GetFolderPath('startmenu'), 'Programs', 'Scoop Apps', 'Classroom Terminal.lnk'
    )

    $destination = [System.IO.Path]::Combine(
        [Environment]::GetFolderPath('desktop'), 'Classroom Terminal.lnk'
    )

    if (!(Test-Path -Path $source)) {
        Write-Verbose (_ 'Shortcut not found: {0}' $source)
        wontdo($step)
        return
    }

    if (Test-Path -Path $destination) {
        wontdo($step)
        return
    }

    willdo($step)

    [void](Copy-Item -Path $source -Destination $destination)
}

function importLinux {
    $step = _ 'Importing Linux image'

    if (testHasWSLDistribution $Classroom.Distribution) {
        wontdo($step)
        return
    }

    willdo($step)

    $rootFile = joinPathPackage $Classroom.Package 'rootfs.tar.gz'

    $param = @{
        MessageProgress = _ 'Please wait'
        MessageSuccess  = _ 'Image successfully imported'
        MessageFailure  = _ 'Image import failed'
    }

    [void](
        longexec @param wsl --import $Classroom.Distribution $Classroom.Root $rootFile --version $Classroom.Version
    )
}

$GitConfig = @{
    'core.autocrlf'      = 'false'
    'core.eol'           = 'lf'
    'credential.helper'  = 'manager-core'
    'init.defaultBranch' = 'main'
    'user.email'         = "$($Env:username)@$($Env:userdomain)"
    'user.name'          = $Env:username
}

function initializeGit {
    $step = _ 'Initializing Git installation'

    $settings = foreach ($setting in $GitConfig.Keys) {
        if ([String]::IsNullOrWhiteSpace($(git config --global $setting | capture))) { $setting }
    }

    if (!$settings) {
        wontdo($step)
        return
    }

    willdo($step)

    foreach ($setting in $settings) {
        Write-Host ("    Git $($setting): $($GitConfig[$setting])")
        safeexec -- git config --global $setting $GitConfig[$setting]
    }
}

function initializeLinux {
    $step = _ 'Initializing Linux image'

    if (testIsClassroomLinuxBootstrapped) {
        wontdo($step)
        return
    }

    willdo($step)

    $flags = @()

    if ($VerbosePreference -eq 'Continue')            { $flags += ('-verbose') }
    if (![String]::IsNullOrWhiteSpace($Linux.Remote)) { $flags += ('-remote', $Linux.Remote) }
    if (![String]::IsNullOrWhiteSpace($Linux.Branch)) { $flags += ('-branch', $Linux.Branch) }
    if (![String]::IsNullOrWhiteSpace($Linux.Local))  { $flags += ('-local',  $Linux.Local)  }

    geturl $Linux.Bootstrap | invokeWSLFromStdin -Distribution $Classroom.Distribution -- @flags
    restartLinux
}

$Extensions = @(
    'GitHub.classroom',
    'GitHub.github-vscode-theme',
    'GitHub.remotehub',
    'ms-python.python',
    'ms-vscode.cpptools-extension-pack',
    'ms-vscode-remote.remote-wsl',
    'rebornix.Ruby',
    'stkb.rewrap',
    'xaver.clang-format',
    'yzhang.markdown-all-in-one'
)

function initializeVSCode {
    $step = _ 'Initializing VSCode installation'

    if (!(testHasCommand 'code')) {
        wontdo($step)
        return
    }

    $installed = safeexec -- code --list-extensions | capture

    $missings = foreach ($extension in $Extensions) {
        if (!($installed | Select-String -Pattern $extension -Quiet)) { $extension }
    }

    if (!$missings) {
        wontdo($step)
        return
    }

    willdo($step)

    $nodeOptions      = $Env:NODE_OPTIONS
    $Env:NODE_OPTIONS = '--no-deprecation'

    foreach ($extension in $missings) {
        Write-Verbose $extension
        safeexec -- code --install-extension $extension --log error --force
    }

    $Env:NODE_OPTIONS = $nodeOptions
}

function installLinux {
    $step = _ 'Provisioning Linux'

    willdo($step)

    invokeLinuxClassroom -Sudo install
    restartLinux
}

$VSCodeInitialSettings = @'
{
  "update.mode": "none"
}
'@

function installVSCode {
    if (!(installMissingPackage- -Name 'VSCode' -Command 'code' -Package 'vscode')) {
        return
    }

    # Initialize VS Code settings on first install (this will disable update notifications as we will handle it with scoop)
    if (!(Test-Path -Path ($settings = (Join-Path $HOME 'scoop\persist\vscode\data\user-data\User\settings.json')))) {
        Write-Verbose (_ 'Initializing VS Code settings')
        mkdirp $(dirname $settings)
        $VSCodeInitialSettings | Set-Content -NoNewline $settings
    }

    # Registry setup only on first install
    if ((Test-Path ($vscode = scoop prefix vscode)) -and (testHasCommand 'reg')) {
        if (Test-Path ($reg = Join-Path $vscode 'install-context.reg')) {
            Write-Verbose (_ 'Adding VS Code as a context menu option')
            reg import $reg
        }
        if (Test-Path ($reg = Join-Path $vscode 'install-associations.reg')) {
            Write-Verbose (_ 'Create VS Code file associations')
            reg import $reg
        }
    }
}

function updateScoop {
    $step = _ 'Updating packages'

    willdo($step)

    # Using COMSPEC due to the scoop bugs
    scoop update -q # invoke without a wrapper since scoop always return error somehow
    safecexec -- scoop update * -q
    safecexec -- scoop cleanup * -k
}

# --- Main

function bootstrap {
    assertExecutionPolicy
}

function finalize {
    if ($Script:DoneCount -eq 0) {
        notice ''
        notice (_ 'Nothing done.')
    } else {
        notice ''
        notice (_ 'Operation completed. Make sure to read related documents.')
        notice ''
        notice "`thttps://classroom.alaturka.dev"
    }

    if ($Script:RebootRequired) {
        notice ''
        notice (_ 'REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION')

        reboot
    }
}

function initialize {
    if (testIsClassroomLinuxBootstrapped) {
        foreach ($option in $LinuxBootstrap, $LinuxRemote, $LinuxBranch, $LinuxLocal) {
            if (![String]::IsNullOrWhiteSpace($option)) {
                Write-Warning (_ 'Linux side has already been bootstrapped')
                Write-Warning (_ 'Setting Linux options has no effect')
            }
        }

        return
    }

    if (![String]::IsNullOrWhiteSpace($LinuxBootstrap)) { $Linux.Bootstrap = $LinuxBootstrap }
    if (![String]::IsNullOrWhiteSpace($LinuxRemote))    { $Linux.Remote    = $LinuxRemote    }
    if (![String]::IsNullOrWhiteSpace($LinuxLocal))     { $Linux.Local     = $LinuxLocal     }

    $Linux.Branch = if (![String]::IsNullOrWhiteSpace($LinuxBranch)) {
        $LinuxBranch
    } else {
        # If the Linux side has not been bootstrapped yet, let it follows the Windows side at the lack of a given
        # branch, i.e. if the Windows side was bootstrapped from a "next" branch, the Linux side should also be
        # bootstrapped from the "next" branch. Why?  We probably prefer to use the same "edge" branch for both sides.
        if (![String]::IsNullOrWhiteSpace($Windows.Local)) {
            getGitCurrentBranch($Windows.Local)
        } else {
            Write-Warning (_ 'Cannot determine the Windows side directory')
        }
    }

    if (!(testurl $Linux.Bootstrap)) {
        throw (_ 'Linux Bootstrap URL seems to be not working: {0}' $Linux.Bootstrap)
    }
}

function shutdown {
}

# --- Entry

$Script:RebootRequired = $false

function installLinuxSide {
        importLinux
        initializeLinux
        installLinux

        copyShortcuts
}

function installWindowsSide {
        updateScoop
        initializeGit
        installVSCode
        initializeVSCode
}

function main {
    try {
        bootstrap
    }
    catch {
        fail $PSItem.Exception.Message
        return
    }

    try {
        initialize

        invokeClassroomSide -Side $Side -ActionWindows installWindowsSide -ActionLinux installLinuxSide
        finalize
    }
    catch {
        abort $PSItem.Exception.Message
    }
    finally {
        shutdown
    }
}

main @args
