@{
    Severity = @('Error','Warning', 'Information')

    ExcludeRules = @(
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidUsingWriteHost',
        'PSPossibleIncorrectUsageOfRedirectionOperator'
        'PSUseApprovedVerbs',
        'PSUseBOMForUnicodeEncodedFile',
        'PSUseDeclaredVarsMoreThanAssignments'
    )
}
