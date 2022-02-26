#Requires -Version 5

Set-Location "$PSScriptRoot\..\.."

function main {
	Get-ChildItem -Path . -Recurse -Directory -Depth 0 -Force -ErrorAction SilentlyContinue | Where-Object {
		$_.Fullname -notmatch '\.git' -and $_.Fullname -notmatch '\.\.\.'
	} | ForEach-Object {
		Get-ChildItem -Path $_.Fullname. -Recurse -Include *.ps1 -Force -ErrorAction SilentlyContinue | ForEach-Object {
			Get-Command -Syntax  $_.FullName >$null
		}
	}
}

main @args
