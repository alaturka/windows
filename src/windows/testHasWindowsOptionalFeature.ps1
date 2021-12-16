# Credits: https://stackoverflow.com/a/37353046
function testHasWindowsOptionalFeature($feature) {
    [boolean]((Get-WindowsOptionalFeature -FeatureName $feature -Online).State -eq 'Enabled')
}
