function Enter-GhqRepository
{
    [CmdletBinding()]
    param()

    $selectedRepo = ghq list -p | fzf
    if ($selectedRepo)
    {
        Set-Location $selectedRepo
    }
}

Set-Alias -Name gcd -Value Enter-GhqRepository
