@{
    Severity = @('Error','Warning', 'Information')

    ExcludeRules = @(
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingWriteHost',
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseDeclaredVarsMoreThanAssignments'
    )
}
