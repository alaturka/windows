function testIsWindowsName($name) {
    switch ($name) {
        '11'    { return ([System.Environment]::OSVersion.Version.Build -ge 22000) }
        '10'    { return ([System.Environment]::OSVersion.Version.Build -ge 10240) }
        '8.1'   { return ([System.Environment]::OSVersion.Version.Build -ge 9600)  }
        '8'     { return ([System.Environment]::OSVersion.Version.Build -ge 9200)  }
        '7'     { return ([System.Environment]::OSVersion.Version.Build -ge 7601)  }
        'Vista' { return ([System.Environment]::OSVersion.Version.Build -ge 6002)  }
        'XP'    { return ([System.Environment]::OSVersion.Version.Build -ge 2600)  }
        default { throw "BUG: Unrecognized Windows name $name"                     }
    }
}
