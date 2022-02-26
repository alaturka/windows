$Classroom = @{
    Distribution = 'Classroom'
    Package      = 'classroom'
    Version      = 1 # Use WSL1 by default, but also prepare WSL2 albeit not enabled
    Root         = 'C:\Classroom'
    Kernel       = @{ Source = 'FID_LXSS_KERNEL'; Target = 'C:\Windows\System32\lxss\tools\kernel' }
}

$Linux = @{
    Remote    = 'https://github.com/alaturka/linux'
    Local     = '/opt/alaturka/linux'
    Branch    = $null
    Bootstrap = 'https://get.linux.alaturka.dev'
}

$Windows = @{
    Remote    = 'https://github.com/alaturka/windows'
    Local     = if (![String]::IsNullOrWhiteSpace($PSScriptRoot)) { (Join-Path $PSScriptRoot '..') } else { $null }
    Branch    = $null
    Bootstrap = 'https://get.windows.alaturka.dev'
}
