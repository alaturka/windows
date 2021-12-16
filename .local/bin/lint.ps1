#Requires -Version 5

Set-Location "$PSScriptRoot\..\.."

function main {
    $allIssues = @()

	Get-ChildItem -Path . -Recurse -Directory -Depth 0 -Force -ErrorAction SilentlyContinue | Where-Object {
		$_.Fullname -notmatch '\.git' -and $_.Fullname -notmatch '\.\.\.'
	} | ForEach-Object {
	    Invoke-ScriptAnalyzer $_.Fullname -Recurse -Settings .\.local\etc\PSScriptAnalyzerSettings.psd1 -OutVariable issues
        $allIssues += $issues
	}

    if ($allIssues) {
        Write-Error "There were $($allIssues.Count) issues found." -ErrorAction Stop
    } else {
        Write-Host 'No issues found.'
    }
}

main @args
