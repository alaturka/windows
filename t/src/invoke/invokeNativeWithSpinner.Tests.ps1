BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\functions.ps1"
}

Describe 'invokeNativeWithSpinner' {
    BeforeEach {
        Mock Write-Host {}
    }

    It 'Given a file, it runs successfully' {
        $file = "$TestDrive\\foo.ps1"
        Set-Content $file -Value 'Write-Output "$args"'

        $result = invokeNativeWithSpinner -MessageProgress 'Test' $file a b c
        $result.Output | Should -Be 'a b c'
    }

    It 'Given some arguments with spaces, it takes the argument correctly' {
        $file = "$TestDrive\\foo.ps1"
        Set-Content $file -Value 'Write-Output $args[1]'

        $result = invokeNativeWithSpinner -MessageProgress 'Test' $file a 'x x x' c
        $result.Output | Should -Be 'x x x'
    }
}
