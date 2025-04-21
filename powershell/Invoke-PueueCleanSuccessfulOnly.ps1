function Invoke-PueueCleanSuccessfulOnly()
{
    pueue clean --successful-only
}

Set-Alias -Name puc -Value Invoke-PueueCleanSuccessfulOnly

