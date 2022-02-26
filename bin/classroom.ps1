#Requires -Version 5
# vim: et ts=4 sw=4 sts=4 tw=120

. "$PSScriptRoot\..\lib\functions.ps1"
. "$PSScriptRoot\..\lib\classroom.ps1"

# --- L10N

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    arguments                                                = argümanlar
    command                                                  = komut
    Command required                                         = Komut gerekiyor
    Display help                                             = Yardım görüntüle
    No such command: {0}                                     = Böyle bir komut yok: {0}
    Otherwise UTF-8 characters cannot be properly displayed  = Aksi halde UTF-8 karakterler duzgun goruntulenmeyebilir
    Please run this program in Windows Terminal              = Lutfen programi Windows Terminal altinda calistirin
    Provision system                                         = Sistem hazırla
    (Re)install classroom                                    = Classroom (yeniden) kur
    Renew classroom provisioners                             = Classroom hazırlayıcılarını yenile
    Show version                                             = Sürüm numarasını göster
    Uninstall classroom                                      = Classroom kurulumunu kaldır
    Unrecognized flag: {0}                                   = Tanınmayan seçenek: {0}
    Usage                                                    = Kullanım

    CLASSROOM INSTALLATION NOT FOUND.                                                   = CLASSROOM KURULUMU BULUNAMADI.
    PLEASE COMPLETE CLASSROOM BOOTSTRAPING BY FOLLOWING INSTRUCTIONS AT THE LINK BELOW. = LUTFEN ONCE ASAGIDAKI BAGLANTIYA GIREREK ONYUKLEME ISLEMINI TAMAMLAYIN.
'@}) | importTranslations

# --- Functions

function assertClassroomBootstrapped {
    if (testIsClassroomBootstrapped) { return }

    notice (_ 'CLASSROOM INSTALLATION NOT FOUND.')
    notice (_ 'PLEASE COMPLETE CLASSROOM BOOTSTRAPING BY FOLLOWING INSTRUCTIONS AT THE LINK BELOW.')
    notice ''
    notice "`thttps://classroom.alaturka.dev"

    exit 1
}

# --- Main

function bootstrap {
    assertOSSensible

    if (!$Env:WT_SESSION -and !$Env:SSH_CONNECTION) {
        Write-Warning (_ 'Please run this program in Windows Terminal')
        Write-Warning (_ 'Otherwise UTF-8 characters cannot be properly displayed')
        Write-Host ''
    }

    assertClassroomBootstrapped
}

function route {
    if (!$Route.ContainsKey($Program.Command)) {
        throw (_ 'No such command: {0}' $Program.Command)
    }

    if ($Program.Command -eq 'help') {
        usage
        return
    }

    $command = $Route[$Program.Command]

    if ($command.Renew -and $Program.IsOnline) {
        renewSelf
    }

    $path = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'libexec' | Join-Path -ChildPath $Program.Name

    $arguments = $Program.Arguments
    run $path $command.Name @arguments
}

function initialize {
    if ($Program.IsVerbose) { $Script:VerbosePreference = 'Continue' }
}

function parse {
    # Custom CLI parsing for the main program, PS CLI handling but in subcommands.
    # After parsing a few flags, pass all arguments to subcommand.

    :parse for ($i = 0; $i -lt $args.Length; $i++) {
        switch ($args[$i]) {
            -verbose { $Program.IsVerbose = $true            }
            -offline { $Program.IsOnline  = $false           }
            -online  { $Program.IsOnline  = $true            }
            -help    { usage; exit 0                         }
            -*       { abort (_ 'Unrecognized flag: {0}' $_) }
            default  {
                $Program.Command = $args[$i++]
                if ($i -lt $args.Length) { $Program.Arguments = $args[$i..($args.Length - 1)] }

                break parse
            }
        }
    }

    if (!$Program.Command) {
        usage
        abort (_ 'Command required')
    }
}

function shutdown {
}

function usage {
    (
        "$(_ 'Usage'): $($Program.Name) [-Verbose|-Online|-Offline] $(_ 'command') [$(_ 'arguments')]",
        ($Route.Values | Sort-Object -Property Name | Format-Table -HideTableHeaders -Property Name, Description)
    )
}

# --- Entry

$Program = @{
    Name      = (progname)
    # If the script was invoked by PATH (i.e. invoked by entering its name), we may fairly assume that the script was
    # deployed (production) and, we should better update the working copy (online) by default.
    IsOnline  = (testIsInvokedByPath)
    IsVerbose = $false
    Command   = $null
    Arguments = @()
}

$Route = @{
    'help'      = [PSCustomObject]@{ Name = 'help';      Description = (_ 'Display help');                 Renew = $false }
    'install'   = [PSCustomObject]@{ Name = 'install';   Description = (_ '(Re)install classroom');        Renew = $true  }
    'provision' = [PSCustomObject]@{ Name = 'provision'; Description = (_ 'Provision system');             Renew = $true  }
    'renew'     = [PSCustomObject]@{ Name = 'renew';     Description = (_ 'Renew classroom provisioners'); Renew = $false }
    'uninstall' = [PSCustomObject]@{ Name = 'uninstall'; Description = (_ 'Uninstall classroom');          Renew = $true  }
    'version'   = [PSCustomObject]@{ Name = 'version';   Description = (_ 'Show version');                 Renew = $false }
}

function main {
    bootstrap

    parse @args

    try     { initialize; route; shutdown }
    catch   { abort $PSItem.Exception.Message }
    finally { shutdown }
}

main @args
