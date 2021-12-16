BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\support.ps1"
}

Describe 'resolveLFH' -Skip:($Env:OS -ne 'Windows_NT') {
    It 'Returns non dot local' {
        resolveLFH -Root '/a/b/c' | Should -Be ($($PWD.drive.name) + ':\a\b\c\local')
    }

    It 'Returns dot local' {
        resolveLFH -Root '/a/b/c' -Dot | Should -Be ($($PWD.drive.name) + ':\a\b\c\.local')
    }

    It 'Returns local with slug' {
        resolveLFH -Root '/a/b/c' x y z | Should -Be ($($PWD.drive.name) + ':\a\b\c\local\x\y\z')
    }
}
