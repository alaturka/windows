#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [string] $Side = 'both'
)

. "$PSScriptRoot\..\..\lib\functions.ps1"
. "$PSScriptRoot\..\..\lib\classroom.ps1"

# --- L10N

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Not renewing Linux side due to the missing installation = Kurulum yapılmadığından Linux hazırlayıcı yenilenmeyecek
    Renewing Linux provisioner                              = Linux hazırlayıcı yenileniyor
'@}) | importTranslations

# --- Functions

function renewLinux {
    if (!(testIsClassroomLinuxBootstrapped)) {
        Write-Verbose (_ 'Not renewing Linux side due to the missing installation')
        return
    }

    Write-Host ("... $(_ 'Renewing Linux provisioner')" -f 'cyan')
    invokeLinuxClassroom -Sudo renew
}

# --- Main

function bootstrap {
    assertNetConnectivity
}

# --- Entry

function main {
    bootstrap
    invokeClassroomSide -Side $Side -ActionWindows renewSelf -ActionLinux renewLinux
}

main @args
