BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\support.ps1"
}

Describe 'invokeBlock' {
    Context 'call' {
        It 'Given a failing block, it throws error' {
            { call { Write-Error '' } } | Should -Throw
            { call { throw 'error' } } | Should -Throw
        }

        It 'Given a succeeding block, it throws no error' {
            { call { $null } } | Should -Not -Throw
        }
    }

    Context 'safecall' {
        It 'Given a failing block, it throws no error' {
            { safecall { Write-Error '' } *>$null } | Should -Not -Throw
            { safecall { throw 'error' } *>$null } | Should -Not -Throw
        }

        It 'Given a succeeding block, it throws no error' {
            { safecall { $null } } | Should -Not -Throw
        }
    }
}
