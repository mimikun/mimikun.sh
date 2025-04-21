function Set-GhqLocation() {
    Set-Location (ghq list -p | fzf)
}

Set-Alias -Name gcd -Value Set-GhqLocation
