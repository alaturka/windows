BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\support.ps1"
}

Describe 'invokePath' {
    It 'Given a simple route, it runs successfully' {
        Set-Content "$TestDrive\\foo.ps1" -Value 'Write-Output ok'
        $(invokePath -Path $TestDrive -Route 'foo' | capture) | Should -Be 'ok'
    }

    It 'Given a deep route, it runs successfully' {
        $dir = "$TestDrive\\a\\b\\c"
        mkdirp $dir
        Set-Content "$dir\\foo.ps1" -Value 'Write-Output ok'
        $(invokePath -Path $TestDrive -Route 'a/b/c/foo' | capture) | Should -Be 'ok'
    }

    It 'Given arguments, it takes all arguments' {
        Set-Content "$TestDrive\\foo.ps1" -Value 'Write-Output "$args"'
        $(invokePath -Path $TestDrive -Route 'foo' 'xxx' | capture) | Should -Be 'xxx'
    }

    It 'Given some arguments with spaces, it takes the argument correctly' {
        Set-Content "$TestDrive\\foo.ps1" -Value 'Write-Output $args[1]'
        $(invokePath -Path $TestDrive -Route 'foo' '1' 'x x x' '2' | capture) | Should -Be 'x x x'
    }
}
