#Requires -Version 5

Set-Location "$PSScriptRoot\..\.."

function main {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 'Tls12'
    Set-PSRepository PSGallery -InstallationPolicy Trusted

    Install-Module PSScriptAnalyzer -SkipPublisherCheck -Confirm:$False -Force -ErrorAction Stop
    Install-Module Pester -SkipPublisherCheck -Confirm:$False -Force -ErrorAction Stop
}

main @args
