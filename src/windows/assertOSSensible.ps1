function assertOSSensible($build = 16215) {
    if (![System.Environment]::Is64BitOperatingSystem) {
        throw (_ '64 BIT WINDOWS 10 SYSTEM REQUIRED.')
    }

    if ([System.Environment]::OSVersion.Version.Major -lt 10) {
        throw (_ 'WINDOWS 10 OR, A NEWER SYSTEM REQUIRED.')
    }

    if ([System.Environment]::OSVersion.Version.Build -lt $build) {
        throw (_ 'WINDOWS 10 BUILD {0} OR HIGHER REQUIRED.' $build)
    }
}
