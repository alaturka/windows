BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\functions.ps1"
}

Describe 'resolveLFHSourceFromURL' -Skip:($Env:OS -ne 'Windows_NT') {
    It 'Returns local src from a URL with https schema' {
        resolveLFHSourceFromURL -URL 'https://github.com/acme/roadrunner' -Root '/a/b/c' | `
        Should -Be ($($PWD.drive.name) + ':\a\b\c\local\src\github.com\acme\roadrunner')
    }

    It 'Returns local src from a URL with file schema' {
        resolveLFHSourceFromURL -URL 'file:///github.com/acme/roadrunner' -Root '/a/b/c' | `
        Should -Be ($($PWD.drive.name) + ':\a\b\c\local\src\github.com\acme\roadrunner')
    }

    It 'Returns local src from a URL without schema' {
        resolveLFHSourceFromURL -URL 'github.com/acme/roadrunner' -Root '/a/b/c' | `
        Should -Be ($($PWD.drive.name) + ':\a\b\c\local\src\github.com\acme\roadrunner')
    }

    It 'Returns dot local src from a URL with https schema' {
        resolveLFHSourceFromURL -URL 'https://github.com/acme/roadrunner' -Root '/a/b/c' -Dot | `
        Should -Be ($($PWD.drive.name) + ':\a\b\c\.local\src\github.com\acme\roadrunner')
    }

    It 'Returns local src with slug' {
        resolveLFHSourceFromURL -URL 'github.com/acme/roadrunner' -Root '/a/b/c' x y z | `
        Should -Be ($($PWD.drive.name) + ':\a\b\c\local\src\github.com\acme\roadrunner\x\y\z')
    }
}
