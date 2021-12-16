function done($message) {
    $line = ("{0,-40}`t{1}" -f $message, (_ 'DONE'))
    Write-Host "> $line" -f yellow
}

function notdone($message) {
    $line = ("{0,-40}`t{1}" -f $message, '-')
    Write-Host "> $line" -f cyan
}
