function testHasFont($name) {
    [void]([System.Reflection.Assembly]::LoadWithPartialName("System.Drawing"))

    @(
        (New-Object System.Drawing.Text.InstalledFontCollection).Families |
        Select-Object -ExpandProperty Name |
        Select-String -Pattern $name
    ).Count -ne 0
}
