function assertHomeSensible {
    if ($HOME -cmatch '[^\x20-\x7F]') {
        notice (_ 'YOUR USER NAME, HENCE HOME FOLDER NAME, CONTAINS NON-ASCII CHARACTERS WHICH MAY CAUSE PROBLEMS.')
        notice (_ 'PLEASE CHANGE YOUR USER NAME, OR PERHAPS DO A FRESH INSTALLATION OF WINDOWS WITH A PROPER NAME.')
        notice ''
        throw (_ 'Invalid Home folder name')
    }
}
