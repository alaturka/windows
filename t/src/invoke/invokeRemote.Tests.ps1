BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\support.ps1"
}

Describe 'invokeRemote' {
    It 'Given a remote file, it runs successfully' {
        $file = "$TestDrive/foo.ps1"
        Set-Content $file -Value 'Write-Output ok'
        $(urlrun $file | capture) | Should -Be 'ok'
    }
}
