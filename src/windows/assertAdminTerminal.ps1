function assertAdminTerminal {
    if (!(testIsAdmin)) {
        throw (_ 'Please run this program in an administrator terminal')
    }
}
