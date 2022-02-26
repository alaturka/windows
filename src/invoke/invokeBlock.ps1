function invokeBlock {
    param (
        [Parameter(Mandatory)] [scriptblock] $block,
                               [string]      $messageFailure = (_ 'Operation failed'),
                               [switch]      $safe
    )

    $ErrorActionPreference = 'Stop'

    $failed, $detail = $false, $null

    try {
        Set-Strictmode -Off
        $block.Invoke()
    }
    catch [System.Management.Automation.ActionPreferenceStopException] {
        $failed = $true

        if ($Error.Count -gt 1) { $detail = $($Error[1]) }
    }
    catch {
        $failed, $detail = $true, "$_"
    }

    if ($failed) {
        if (![String]::IsNullOrWhiteSpace($detail)) { Write-Warning $detail }
        if ($safe) { Write-Warning $messageFailure } else { throw $messageFailure }
    }
}

function call { invokeBlock @args }
function safecall { invokeBlock -Safe @args }
