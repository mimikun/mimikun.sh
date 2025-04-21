function Get-NeedUpdateCargoPackages()
{
    $tmp = cargo install-update --list |
        Select-Object -Skip 2
    $need_update_pkgs = $tmp -split "`n" |
        ForEach-Object {
            if ($_ -match "^\s*Package\s+Installed\s+Latest\s+Needs update\s*$")
            {
                return
            }
            if ($_ -match "^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$" -and $matches[4] -eq "Yes")
            {
                [PSCustomObject]@{
                    Package      = $matches[1]
                    Installed    = $matches[2]
                    Latest       = $matches[3]
                    NeedsUpdate  = $matches[4]
                }
            }
        }
    return $need_update_pkgs
}

function Invoke-UpdateCargoPackages()
{
    Param([switch]$NoPueue)
    Get-NeedUpdateCargoPackages | ForEach-Object {
        $pkgs = $_.Package
        Write-Output "Update: $pkgs"
        if ($NoPueue)
        {
            cargo install $pkgs
        } else
        {
            pueue add -- "cargo install $pkgs"
        }
    }
}

Set-Alias -Name update_cargo_packages -Value Invoke-UpdateCargoPackages
Set-Alias -Name upcapa -Value Invoke-UpdateCargoPackages
