BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\functions.ps1"

    function runFragile {
        if ($Script:turn -eq 0) {
            $Script:turn++
            throw 'broken'
        }

        return 42
    }

    function resetFragile {
        $Script:turn = 0
    }
}

Describe 'invokeBlockWithRetry' {
    Context 'insistentcall' {
        BeforeEach { resetFragile }

        It 'Given a succeeding block, it throws no error' {
            { insistentcall { $null } } | Should -Not -Throw
        }

        It 'Given a block which fails only at the first attempt, it throws no error by default' {
            { insistentcall { runFragile } 3>$null } | Should -Not -Throw
        }

        It 'Given a fragile block, it returns correct value on success' {
            insistentcall { runFragile } 3>$null | Should -Be 42
        }

        It 'Given a block which fails only at the first attempt, it throws error if no retry wanted' {
            { insistentcall { runFragile } -Try 1 3>$null } | Should -Throw
        }
    }
}
