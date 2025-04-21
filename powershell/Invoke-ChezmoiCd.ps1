function Invoke-ChezmoiCd
{
    if ($IsLinux)
    {
        Set-Location $env:CHEZMOI_DIR
    } else
    {
        chezmoi cd
    }
}

Set-Alias -Name chec -Value Invoke-ChezmoiCd
