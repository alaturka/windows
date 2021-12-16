#Requires -Version 5

[CmdletBinding(DefaultParameterSetName = 'online')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
param (
    [Parameter(Position = 0)] [string] $Command,
                              [string] $Branch,

    [Parameter(ParameterSetName = 'online' )] [switch] $Online,
    [Parameter(ParameterSetName = 'offline')] [switch] $Offline,

    [Parameter(ValueFromRemainingArguments)]  [string[]] $Remainings
)

. "$PSScriptRoot\..\lib\support.ps1"

# --- Main

$(if ($PSCulture -eq 'tr-TR') { ConvertFrom-StringData -StringData @'
    Giving up renewing due to the stamp: {0}                = Önleyici damga dosyasından dolayı yenilemeden vazgeçiliyor: {0}
    Migrate installation                                    = Classroom kurulumunu revize et
    No such command: {0}                                    = Böyle bir komut yok: {0}
    Otherwise UTF-8 characters cannot be properly displayed = Aksi halde UTF-8 karakterler duzgun goruntulenmeyebilir
    Please run this program in Windows Terminal             = Lutfen programi Windows Terminal altinda calistirin
    (Re)install classroom                                   = Classroom (yeniden) kur
    Renew program itself                                    = Programın kendisini yenile
    Show version                                            = Sürüm numarasını göster
    Uninstall classroom                                     = Classroom kurulumunu kaldır
    Updating Classroom provisioner                          = Classroom hazırlayıcı yenileniyor
'@}) | importTranslations

function dispatch {
    if (!$Dispatch.ContainsKey($Command)) {
        throw (_ 'No such command: {0}' $Command)
    }

    if ($Command -eq 'renew') {
        renew
        return
    }

    if ($Dispatch[$Command].Renew -and $Program.IsOnline) { renew }

    if ($Command -eq 'version') {
        version
        return
    } elseif ($Command -eq 'help') {
        usage
        return
    }

    $path = Join-Path $PSScriptRoot '..' | Join-Path -ChildPath 'libexec' | Join-Path -ChildPath $Program.Name

    run $Dispatch[$Command].Command -Path $path @Remainings
}

function initialize {
    if (!$Command) {
        usage
        exit
    }

    $Program.IsOnline = testIsOnline

    if (![String]::IsNullOrWhiteSpace($Branch)) { $Source.Branch = $Branch }
}

function renew {
    $norenewFile = Join-Path $Source.Path '.git' | Join-Path -ChildPath 'NORENEW'
    if (Test-Path -Path $norenewFile) {
        Write-Verbose (_ 'Giving up renewing due to the stamp: {0}' $norenewFile)
        return
    }

    assertHasCommand 'git'
    assertNetConnectivity

    Write-Host ("... $(_ 'Updating Classroom provisioner')" -f 'cyan')
    updateGitRepository $Source
}

function restore {
}

function sanitize {
    assertOSSensible

    if (!$Env:WT_SESSION -and !$Env:SSH_CONNECTION) {
        Write-Warning (_ 'Please run this program in Windows Terminal')
        Write-Warning (_ 'Otherwise UTF-8 characters cannot be properly displayed')
        Write-Host ''
    }
}

function shutdown {
}

function usage() {
    $Dispatch.Values | Sort-Object -Property Command | Format-Table -HideTableHeaders -Property Command, Description
}

function testIsOnline {
	if ($Script:MyInvocation.BoundParameters.Keys -contains 'online') {
		$true
	} elseif ($Script:MyInvocation.BoundParameters.Keys -contains 'offline') {
		$false
	} else {
        # If nothing said explicitly, detect if the script was invoked via PATH (by entering its name).
        # We may fairly assume that if the script was deployed (i.e. no dev mode), it is in PATH and
        # we better update the working copy (online).
        testIsInvokedImplicit
    }
}

function version {
    Write-Host (getGitRelease $Source.Path)
}

# --- Entry

$Program = @{
    Name     = (progname)
    IsOnline = $null
}

$Source = @{
    URL    = $null
    Branch = 'main'
    Path   = (Join-Path $PSScriptRoot '..')
}

$Dispatch = @{
    'help'      = [PSCustomObject]@{ Command = 'help';      Description = (_ 'Display help');          Renew = $false }
    'install'   = [PSCustomObject]@{ Command = 'install';   Description = (_ '(Re)install classroom'); Renew = $true  }
    'migrate'   = [PSCustomObject]@{ Command = 'migrate';   Description = (_ 'Migrate installation');  Renew = $true  }
    'renew'     = [PSCustomObject]@{ Command = 'renew';     Description = (_ 'Renew program itself');  Renew = $false }
    'uninstall' = [PSCustomObject]@{ Command = 'uninstall'; Description = (_ 'Uninstall classroom');   Renew = $true  }
    'version'   = [PSCustomObject]@{ Command = 'version';   Description = (_ 'Display version');       Renew = $false }
}

function main {
    sanitize
    try     { initialize; dispatch; shutdown }
    catch   { abort $PSItem.Exception.Message }
    finally { restore }
}

main @args

# vim: et ts=4 sw=4 sts=4 tw=120
