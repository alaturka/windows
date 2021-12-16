#Requires -Version 5

Set-Location "$PSScriptRoot\..\.."

function main {
    Invoke-Pester t
}

main @args
