BeforeAll {
    . "$PSScriptRoot\..\..\..\lib\functions.ps1"

    $Script:trueCommand, $Script:falseCommand = if ($Env:OS -eq 'Windows_NT') {
        @('cmd', '/c', 'exit', '0'), @('cmd', '/c', 'exit', '42')
    } else {
        @('true'), @('false')
    }

    function justfail { throw 'error' }
}

Describe 'invokeNative' {
    Context 'exec' {
        It 'Given a failing command, it throws error' {
            { exec @Script:falseCommand } | Should -Throw
            { exec justfail 3>$null } | Should -Throw
        }

        It 'Given a succeeding command, it throws no error' {
            { exec @Script:trueCommand } | Should -Not -Throw
        }
    }

    Context 'safeexec' {
        It 'Given a failing command, it throws no error' {
            { safeexec @Script:falseCommand 3>$null } | Should -Not -Throw
            { safeexec justfail 3>$null } | Should -Not -Throw
        }
        It 'Given a succeeding command, it throws no error' {
            { safeexec @Script:trueCommand } | Should -Not -Throw
        }
    }

    Context 'cexec' -Skip:($Env:OS -ne 'Windows_NT') {
        It 'Given a failing command, it throws error' {
            { cexec @Script:falseCommand } | Should -Throw
        }

        It 'Given a succeeding command, it throws no error' {
            { cexec @Script:trueCommand } | Should -Not -Throw
        }
    }

    Context 'safecexec' -Skip:($Env:OS -ne 'Windows_NT') {
        It 'Given a failing command, it throws no error' {
            { safecexec @Script:falseCommand 3>$null } | Should -Not -Throw
        }
        It 'Given a succeeding command, it throws no error' {
            { safecexec @Script:trueCommand } | Should -Not -Throw
        }
    }

    Context 'trueexec' {
        It 'Given a failing command, it returns false' {
            trueexec @Script:falseCommand | Should -BeFalse
            trueexec throw 'error' | Should -BeFalse
        }

        It 'Given a succeeding command, it returns true' {
            trueexec @Script:trueCommand | Should -BeTrue
        }
    }
}
