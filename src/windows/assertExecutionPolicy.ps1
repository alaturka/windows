function assertExecutionPolicy {
    $allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')

    if ((Get-ExecutionPolicy).ToString() -In $allowedExecutionPolicy) {
        return
    }

    notice (_ 'YOU DO NOT HAVE SUFFICIENT PERMISSIONS. PLEASE RUN THE FOLLOWING COMMAND AND RETRY:')
    Write-Output "    'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"

    throw (_ 'Execution Policy violation')
}
