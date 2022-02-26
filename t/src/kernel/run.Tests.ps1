BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\functions.ps1"
}

Describe 'run' {
    It 'Given a simple route, it runs successfully' {
        Set-Content "$TestDrive\\foo.ps1" -Value 'Write-Output ok'
        $(run $TestDrive 'foo' | capture) | Should -Be 'ok'
    }

    It 'Given a deep route, it runs successfully' {
        $dir = "$TestDrive\\a\\b\\c"
        mkdirp $dir
        Set-Content "$dir\\foo.ps1" -Value 'Write-Output ok'
        $(run $TestDrive 'a/b/c/foo' | capture) | Should -Be 'ok'
    }

    It 'Given arguments, it takes all arguments' {
        Set-Content "$TestDrive\\foo.ps1" -Value 'Write-Output "$args"'
        $(run $TestDrive 'foo' 'xxx' | capture) | Should -Be 'xxx'
    }

    It 'Given some arguments with spaces, it takes the argument correctly' {
        Set-Content "$TestDrive\\foo.ps1" -Value 'Write-Output $args[1]'
        $(run $TestDrive 'foo' '1' 'x x x' '2' | capture) | Should -Be 'x x x'
    }
}
