@powershell -noprofile -ex unrestricted "& '%~dp0%~n0.ps1' %*;exit $lastexitcode"
