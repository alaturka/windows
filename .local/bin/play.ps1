#Requires -Version 5

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [Parameter(Mandatory)] [string] $Action,
                           [string] $Mode = 'default'
)

function playBoot {
    switch ($Mode) {
        { @('default', 'next', 'dev', 'development') -contains $_ } {
            & 'libexec\bootstrap\classroom.ps1' -Verbose -Remote . -Local .
        }
        { @('prod', 'production') -contains $_ } {
            $VerbosePreference = 'Continue'
            Invoke-WebRequest -UseBasicParsing -Uri 'https://get.classroom.alaturka.dev' | Invoke-Expression
        }
        default {
            Write-Host "Unrecognized mode: $Mode"-f red
            exit 1
        }
    }
}

function playInstall {
    switch ($Mode) {
        { @('default', 'dev', 'development', 'next') -contains $_ } {
            & 'bin\classroom.ps1' -Verbose install -LinuxBootstrap 'file:///linux/libexec/bootstrap/classroom'
        }
        { @('prod', 'production') -contains $_ } {
            & 'bin\classroom.ps1' -Verbose install
        }
        default {
            Write-Host "Unrecognized mode: $Mode"-f red
            exit 1
        }
    }
}

function main {
    Set-Location "$PSScriptRoot\..\.."

    switch ($Action) {
        'boot'    { playBoot                                   }
        'install' { playInstall                                }
        default   { Write-Host 'Action required'-f red; exit 1 }
    }
}

main @args
