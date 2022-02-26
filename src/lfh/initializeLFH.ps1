function initializeLFH {
    param (
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot,
                               [switch] $hidden,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $lfhRoot = resolveLFH -Root $root -Dot:$dot $remainings

    $lfhBin = mkdirp $lfhRoot 'bin' -Out

    foreach ($dir in 'etc', 'tmp', 'var') {
        mkdirp $lfhRoot $dir
    }

    ensureInPath $lfhBin

    if ($hidden) {
        (Get-Item $lfhRoot -Force).Attributes = 'Hidden'
    }

    if (testHasCommand 'sudo') {
        sudo Add-MpPreference -ExclusionPath $lfhRoot
    }
}
