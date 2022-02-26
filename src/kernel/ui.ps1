function abort   { foreach ($message in $args) { Write-Host $message -f red    }; exit 1 }
function fail    { foreach ($message in $args) { Write-Host $message -f red    }         }
function succeed { foreach ($message in $args) { Write-Host $message -f green  }         }
function notice  { foreach ($message in $args) { Write-Host $message -f yellow }         }

function getting($message) { Write-Host "... $message" -f cyan                           }

$Script:DoneCount = 0
function willdo($message) { $Script:DoneCount++; Write-Host ">   $message" -f yellow    }
function wontdo($message) { Write-Host "X   $message" -f cyan                           }
