$Script:DoneCount = 0

function willdo($message) {
    $Script:DoneCount++
    Write-Host ">   $message" -f yellow
}

function wontdo($message) {
    Write-Host "X   $message" -f cyan
}
