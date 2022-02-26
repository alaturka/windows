#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

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

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Classroom files package not installed: {0} = Classroom dosya paketi kurulu değil: {0}
    Classroom image not found: {0}             = Classroom imajı bulunamadı: {0}
    Missing program: {0}                       = Program kurulu değil: {0}
    Renewing self                              = Program kendini yeniliyor
    Unrecognized side: {0}                     = Tanınmayan bileşen: {0}
    WSL not found                              = WSL aktif değil
'@}) | importTranslations

function invokeClassroomSide {
    param (
                                [string] $side,
         [Parameter(Mandatory)] [string] $actionWindows,
         [Parameter(Mandatory)] [string] $actionLinux,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )


    if ([String]::IsNullOrWhiteSpace($side)) { $side = 'both' }

    switch ($side) {
        'windows' { Invoke-Command -ScriptBlock (Get-Command $actionWindows).ScriptBlock -ArgumentList $remainings  }
        'linux'   { Invoke-Command -ScriptBlock (Get-Command $actionLinux).ScriptBlock   -ArgumentList $remainings  }
        'both'    { Invoke-Command -ScriptBlock (Get-Command $actionWindows).ScriptBlock -ArgumentList $remainings;
                    Invoke-Command -ScriptBlock (Get-Command $actionLinux).ScriptBlock   -ArgumentList $remainings  }
        default   { throw (_ 'Unrecognized side: {0}' $side)                                                        }
    }
}

function invokeLinux {
    wsl --distribution $Classroom.Distribution -- @args
}

function invokeLinuxClassroom {
    param (
                                                 [switch] $offline,
                                                 [switch] $online,
                                                 [switch] $sudo,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $argv = @()

    if ($sudo) { $argv += 'sudo' }; $argv += 'classroom'

    if ($VerbosePreference -eq 'Continue')           { $argv += '-verbose' }
    if ($PSBoundParameters.Keys -contains 'offline') { $argv += '-offline' }
    if ($PSBoundParameters.Keys -contains 'online')  { $argv += '-online'  }

    $argv += $remainings

    wsl --distribution $Classroom.Distribution -- @argv
}

function renewSelf {
    assertHasCommand 'git'

    Write-Host ("... $(_ 'Renewing self')" -f 'cyan')
    syncSelf
}

function restartLinux {
    wsl --distribution $Classroom.Distribution --shutdown
}

function testIsClassroomBootstrapped {
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

    if (!(testHasPackage $Classroom.Package)) {
        Write-Verbose (_ 'Classroom files package not installed: {0}' $Classroom.Package)
        return $false
    }

    $rootFile = joinPathPackage $Classroom.Package 'rootfs.tar.gz'

    if (!(Test-Path -Path $rootFile -PathType Leaf)) {
        Write-Verbose (_ 'Classroom image not found: {0}' $rootFile)
        return $false
    }

    $true
}

function testIsClassroomLinuxBootstrapped {
    if (!(testHasWSLDistribution $Classroom.Distribution)) {
        return $false
    }

    if (!(trueexec wsl --distribution $Classroom.Distribution -- classroom version)) {
        return $false
    }

    $true
}
