#Requires -Version 5

# --- L10N

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Classroom files package not installed: {0} = Classroom dosya paketi kurulu değil: {0}
    Missing program: {0}                       = Program kurulu değil: {0}
    WSL not found                              = WSL aktif değil

    CLASSROOM INSTALLATION NOT FOUND.                                                   = CLASSROOM KURULUMU BULUNAMADI.
    PLEASE COMPLETE CLASSROOM BOOTSTRAPING BY FOLLOWING INSTRUCTIONS AT THE LINK BELOW. = LUTFEN ONCE ASAGIDAKI BAGLANTIYA GIREREK ONYUKLEME ISLEMINI TAMAMLAYIN.
    PLEASE INSTALL IT BY ISSUING THE FOLLOWING COMMAND.                                 = LUTFEN ONCE ASAGIDA KOMUTLA KURULUM YAPIN.
'@}) | importTranslations

# --- Support

# We prefer using WSL1 by default to be on the safe side.  But note
# that the required setup has been made for WSL2 at the bootstrap.
$WSL = @{
    Distribution  = 'Classroom'
    ScoopPackage  = 'classroom'
    RootDirectory = $null
    RootFSFile    = $null
    Version       = 1
}

function assertBootstrapped {
    if (testIsBootstrapped) { return }

    notice (_ 'CLASSROOM INSTALLATION NOT FOUND.')
    notice (_ 'PLEASE COMPLETE CLASSROOM BOOTSTRAPING BY FOLLOWING INSTRUCTIONS AT THE LINK BELOW.')
    notice ''
    notice "`thttps://classroom.omu.sh"

    exit 1
}

function assertInstalled {
    if (testHasClassroom) {
        return
    }

    notice (_ 'CLASSROOM INSTALLATION NOT FOUND.')
    notice (_ 'PLEASE INSTALL IT BY ISSUING THE FOLLOWING COMMAND.')
    notice ''
    notice "`tclassroom install"

    exit 1
}

function invokeClassroom {
    wsl --distribution $WSL.Distribution $args
}

function testHasClassroom {
    wsl --list --quiet | capture | Select-String $WSL.Distribution
}

function testIsBootstrapped {
    foreach ($command in 'scoop', 'git') {
        if (!(testHasCommand $command)) {
            Write-Verbose (_ 'Missing program: {0}' $command)
            return $false
        }
    }

    if (!(testHasCommand 'wsl')) {
        Write-Verbose (_ 'WSL not found')
        return $false
    }

    if (!(testHasPackage $WSL.ScoopPackage)) {
        Write-Verbose (_ 'Classroom files package not installed: {0}' $WSL.ScoopPackage)
        return $false
    }

    $true
}
