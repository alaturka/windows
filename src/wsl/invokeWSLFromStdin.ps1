function invokeWSLFromStdin {
    param (
        [Parameter(ValueFromPipeline)] [string[]] $source,
                                       [string]   $file,
                                       [string]   $distribution,
                                       [string]   $exec,
                                       [string]   $user,

        [Parameter(ValueFromRemainingArguments, Position = 0)] [string[]] $remainings
    )

    begin {
        $command = @()

        # Windows side

        $command += 'wsl'

        if ($PSBoundParameters.Keys -contains 'distribution') {
            $command += '--distribution', $distribution
        }

        if (!($PSBoundParameters.Keys -contains 'root')) {
            $user = 'root'
        }

        $command += '--user', $user

        $command += '--exec'

        # Linux side

        $command += 'sh', '-c'

        if (!($PSBoundParameters.Keys -contains 'exec')) {
            $exec = 'bash -s'
        }

        $command += (
            "sed -e '1s/^\xEF\xBB\xBF//' -e 's/\r//g'" +        # DOS to Unix conversion: remove UTF-8 BOM and CR
            " | exec $exec -- " +                               # Use exec (instead of fork) to avoid a redundant subshell
            ($remainings | ForEach-Object { "'$_'" }) -join ' ' # Single quote arguments for white space
        )
    }

    process {
        $source = if (!($PSBoundParameters.Keys -contains 'file')) {
            $_
        } else {
            if (!(Test-Path -Path $file -PathType leaf)) {
                throw (_ 'File not found: {0}' $file)
            }

            Get-Content $file
        }
    }

    end {
        $source | & "$Env:COMSPEC" /d /c $command
    }
}
