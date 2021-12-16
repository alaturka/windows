function progname($path) {
    [IO.Path]::GetFileNameWithoutExtension($Script:MyInvocation.MyCommand.Name)
}
