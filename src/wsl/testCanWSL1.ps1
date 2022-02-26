function testCanWSL1 {
    # Build 18215 or higher required for WSL1.

    [System.Environment]::OSVersion.Version.Build -ge 16215
}
