$T = @{}

function _($message, $values = @()) {
    $(if ($T.ContainsKey($message)) { $T[$message] } else { $message }) -f $values
}

function importTranslations {
    process {
        foreach ($key in $_.keys) {
            if ($T.ContainsKey($key)) {
                throw "BUG: Duplicate key '$key' found in L10n Message Dictionary"
            }

            $T.$key = $_.$key
        }
    }
}
