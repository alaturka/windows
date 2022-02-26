function mkdirp {
    param (
        [switch] $out,

        [Parameter(ValueFromRemainingArguments)] [string[]] $remainings
    )

    $dir = [IO.Path]::Combine([string[]]($remainings))
    if (!(Test-Path -Path $dir)) {
        [void](New-Item -Path $dir -ItemType Directory)
    }

    if ($out) { $dir }
}
