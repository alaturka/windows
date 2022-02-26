#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [string] $Side = 'both'
)

. "$PSScriptRoot\..\..\lib\functions.ps1"
. "$PSScriptRoot\..\..\lib\classroom.ps1"

# --- Entry

function main {
	Write-Output (_ 'Not implemented yet')
}

main
