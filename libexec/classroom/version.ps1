#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [string] $Side = 'both'
)

. "$PSScriptRoot\..\..\lib\functions.ps1"
. "$PSScriptRoot\..\..\lib\classroom.ps1"

# --- Functions

function versionLinux {
    $version = if (testHasWSLDistribution $Classroom.Distribution) {
        invokeLinuxClassroom version | capture
    } else {
        '-'
    }

    Write-Output ("Linux`t{0}" -f $version)
}

function versionWindows {
    Write-Output ("Windows`t{0}" -f (getGitDescription $Windows.Path))
}

# --- Entry

function main {
    invokeClassroomSide -Side $Side -ActionWindows versionWindows -ActionLinux versionLinux
}

main @args
