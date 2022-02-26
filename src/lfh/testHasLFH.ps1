function testHasLFH {
    param (
        [Parameter(Mandatory)] [string] $root,
                               [switch] $dot
    )

    $lfhBin = resolveLFH -Root $root -Dot:$dot 'bin'

    Test-Path -Path $lfhBin -PathType Container
}
