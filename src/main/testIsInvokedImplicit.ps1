function testIsInvokedImplicit {
    $position = (Get-PSCallStack | Select-Object -Last 1).Position
    if ([String]::IsNullOrWhiteSpace($position)) {
        return $false
    }

    (
        ($position -split ' ')[0] -eq ([IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name))
    )
}
