#Requires -Version 5

Set-Location "$PSScriptRoot\..\.."

function main {
    Write-Host 'Syntax checking...' -f yellow
    & ".\.local\bin\syntax.ps1"
    Write-Host
    Write-Host 'Linting...' -f yellow
    & ".\.local\bin\lint.ps1"
}

main @args
