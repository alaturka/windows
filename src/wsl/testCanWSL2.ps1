function testCanWSL2 {
    # Build 18362 or higher required for WSL2.
    # Build 18980 or higher required to change username in WSL box.

    [System.Environment]::OSVersion.Version.Build -ge 18980
}
