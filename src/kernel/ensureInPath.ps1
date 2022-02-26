# Adapted from https://github.com/ScoopInstaller/Scoop
function ensureInPath {
    param (
        [string] $scope = 'User',

        [Parameter(Mandatory, ValueFromRemainingArguments, Position = 0)] [string[]] $remainings
    )

    $dir  = fullpath([IO.Path]::Combine([string[]]($remainings)))
    $path = [Environment]::GetEnvironmentVariable('PATH', $scope)

    if ($path -notmatch [Regex]::escape($dir)) {
        [Environment]::SetEnvironmentVariable('Path', "$dir;$path", $scope)
        $Env:Path = "$dir;$Env:PATH"
    }
}
