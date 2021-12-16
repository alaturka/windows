#Requires -Version 5

# KEEP THIS IDEMPOTENT

. "$PSScriptRoot\..\..\lib\support.ps1"
. "$PSScriptRoot\..\..\lib\classroom.ps1"

# --- L10N

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Classroom image not found: {0}                  = Classroom imajı bulunamadı: {0}
    Configured Git email: {0}                       = Ayarlanan Git email: {0}
    Configured Git username: {0}                    = Ayarlanan Git username: {0}
    Creating shortcuts at Desktop                   = Masaüstünde kısayol oluşturuluyor
    Importing WSL image, please wait                = WSL imajı aktarılıyor, lütfen bekleyin
    Initializing Git installation                   = Git kurulumu ilkleniyor
    Initializing VSCode installation                = VSCode kurulumu ilkleniyor
    Installing Classroom                            = Classroom kuruluyor
    Please change it as follows:                    = Lütfen bunu daha sonra aşağıdaki komutla değiştirin:
    Provisioning Classroom                          = Classroom hazırlanıyor
    Shortcut not found: {0}                         = Kısayol bulunamadı: {0}
    Updating packages failed: {0}                   = Paket güncellemeleri başarısız: {0}
    Updating packages                               = Kurulu paketler yenileniyor
    Windows Terminal required for desktop shortcuts = Masaüstü kısayolları için Windows Terminal gerekiyor
    WSL image import failed                         = WSL imajının aktarımı başarısız
    WSL image successfully imported                 = WSL imajı başarıyla aktarıldı

    Operation completed. Make sure to read related documents. =  İşlem tamamlandı. Lütfen ilgili dokümanları okumayı unutmayın.
    REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION             = MAKİNENİN YENİDEN BAŞLATILMASI GEREKİYOR, LÜTFEN IŞLEMİ ONAYLAYIN!
'@}) | importTranslations

# --- Tasks

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

function importClassroom {
    $step = _ 'Provisioning Classroom'

    if (testHasClassroom) {
        wontdo($step)
        return
    }

    willdo($step)

    $param = @{
        MessageProgress = _ 'Importing WSL image, please wait'
        MessageSuccess  = _ 'WSL image successfully imported'
        MessageFailure  = _ 'WSL image import failed'
    }
    [void](
        longexec @param wsl --import $WSL.Distribution $WSL.RootDirectory $WSL.RootFSFile --version $WSL.Version
    )
}

$GitConfig = @{
    Username   = $Env:username
    Email      = "$($Env:username)@$($Env:userdomain)"
    CredHelper = 'manager-core'
}

function initializeGit {
    $step = _ 'Initializing Git installation'

    $user       = git config --global user.name         | capture
    $email      = git config --global user.email        | capture
    $credhelper = git config --global credential.helper | capture

    if (($user -ne '') -and ($email -ne '') -and ($credhelper -ne '')) {
        return
    }

    willdo($step)

    if ($user -eq '') {
        notice (_ 'Configured Git username: {0}' $GitConfig.Username)
        notice (_ 'Please change it as follows:')
        notice "    git config --global user.name <KULLANICIADI>"

        git config --global user.name $GitConfig.Username
    }

    if ($email -eq '') {
        notice (_ 'Configured Git email: {0}' $GitConfig.Email)
        notice (_ 'Please change it as follows:')
        notice "    git config --global user.email <EMAIL>"

        git config --global user.email $GitConfig.Email
    }

    if ($credhelper -eq '') {
        git config --global credential.helper $GitConfig.CredHelper
    }
}

$Extensions = @(
    'GitHub.classroom',
    'GitHub.github-vscode-theme',
    'GitHub.remotehub',
    'GitHub.vscode-pull-request-github',
    'ms-python.python',
    'ms-vscode-remote.remote-wsl',
    'ms-vscode.cpptools',
    'ms-vsliveshare.vsliveshare',
    'rebornix.Ruby',
    'stkb.rewrap',
    'yzhang.markdown-all-in-one'
)

function initializeVSCode {
    $step = _ 'Initializing VSCode installation'

    if (!(testHasCommand 'code')) {
        wontdo($step)
        return
    }

    $installed = code --list-extensions | capture

    $missings = foreach ($extension in $Extensions) {
        if (!($installed | Select-String -Pattern $extension -Quiet)) { $extension }
    }

    if (!$missings) {
        wontdo($step)
        return
    }

    willdo($step)

    $node_options     = $Env:NODE_OPTIONS
    $Env:NODE_OPTIONS = '--no-deprecation'

    foreach ($extension in $missings) {
        Write-Verbose $extension
        safeexec code --install-extension $extension --log error --force
    }

    $Env:NODE_OPTIONS = $node_options
}

function installClassroom {
    $step = _ 'Installing Classroom'

    willdo($step)

    invokeWSLFromStdin -Distribution Classroom -File "$PSScriptRoot\install.sh"
    invokeClassroom --shutdown
}

function installVSCode {
    installMissingPackage -Name 'VSCode' -Command 'code' -Package 'vscode'
}

function updateScoop {
    $step = _ 'Updating packages'

    willdo($step)

    # Using COMSPEC due to the scoop bugs
    safecexec scoop update -q
    safecexec scoop update * -q
    safecexec scoop cleanup * -k
}

# --- Main

function sanitize {
    assertExecutionPolicy
    assertOSSensible
    assertBootstrapped
}

function initialize {
    $WSL.RootDirectory = Join-Path 'C:' $WSL.Distribution
    $WSL.RootFSFile    = joinPathPackage $WSL.ScoopPackage 'rootfs.tar.gz'

    if (!(Test-Path -Path $WSL.RootFSFile -PathType leaf)) {
        throw (_ 'Classroom image not found: {0}' $WSL.RootFSFile)
    }
}

function shutdown {
    if ($Script:DoneCount -eq 0) {
        notice ''
        notice (_ 'Nothing done.')
    } else {
        notice ''
        notice (_ 'Operation completed. Make sure to read related documents.')
        notice ''
        notice "`thttps://classroom.omu.sh"
    }

    if ($Script:RebootRequired) {
        notice ''
        notice (_ 'REBOOT REQUIRED, PLEASE CONFIRM THE OPERATION')

        reboot
    }
}

function restore {
}

# --- Entry

$Script:RebootRequired = $false

function main {
    try {
        sanitize
    }
    catch {
        Write-Host $PSItem.Exception.Message -f red # FIXME
        return
    }

    try {
        initialize

        updateScoop

        importClassroom
        installClassroom

        initializeGit

        installVSCode
        initializeVSCode

        copyShortcuts

        shutdown
    }
    catch {
        abort $PSItem.Exception.Message
    }
    finally {
        restore
    }
}

main @args

# vim: et ts=4 sw=4 sts=4 tw=120
