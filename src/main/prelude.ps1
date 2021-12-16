$ErrorActionPreference     = 'Stop'
$Global:ProgressPreference = 'SilentlyContinue'

$PSDefaultParameterValues                  = $PSDefaultParameterValues.Clone()
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
