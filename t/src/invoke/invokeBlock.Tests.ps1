BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\functions.ps1"

    function justfail { throw 'error' }
}

Describe 'invokeBlock' {
    Context 'call' {
        It 'Given a failing block, it throws error' {
            { call { Write-Error '' } 3>$null } | Should -Throw
            { call { justfail } 3>$null } | Should -Throw
        }

        It 'Given a succeeding block, it throws no error' {
            { call { $null } } | Should -Not -Throw
        }
    }

    Context 'safecall' {
        It 'Given a failing block, it throws no error' {
            { safecall { Write-Error '' } 3>$null } | Should -Not -Throw
            { safecall { throw 'error' } 3>$null } | Should -Not -Throw
        }

        It 'Given a succeeding block, it throws no error' {
            { safecall { $null } } | Should -Not -Throw
        }
    }
}
