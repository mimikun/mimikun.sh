# Get a list of packages that can be updated
function Get-NeedUpdateCargoPackage()
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

# HACK: tabiew can't build
function Invoke-UpdateTabiew()
{
    Write-Output "compiling ""tabiew"" takes a SO LONG time"
    Write-Output "can't install it from crates.io"
}

# HACK: rustowl can't build
function Invoke-UpdateRustowl()
{
    Write-Output "compiling ""rustowl"" takes a SO LONG time"
    Write-Output "can't install it from crates.io"
}

# Run update commands
function Invoke-UpdateCargoPackage()
{
    Param([switch]$NoPueue)
    #$taskId = pueue add -p -- "Write-Output start"
    Get-NeedUpdateCargoPackage | ForEach-Object {
        $pkg = $_.Package
        Write-Output "Update: $pkg"
        if ($NoPueue)
        {
            switch ($pkg)
            {
                tabiew
                {
                    Invoke-UpdateTabiew
                }
                rustowl
                {
                    Invoke-UpdateRustowl
                }
                default
                {
                    cargo install $pkg
                }
            }
        } else
        {
            switch ($pkg)
            {
                tabiew
                {
                    Invoke-UpdateTabiew
                }
                rustowl
                {
                    Invoke-UpdateRustowl
                }
                default
                {
                    pueue add -- "cargo install $pkg"
                    #$taskId = pueue add --after $taskId -p -- "cargo install $pkg"
                }
            }
        }
    }
}

Set-Alias -Name update_cargo_package -Value Invoke-UpdateCargoPackage
Set-Alias -Name upcapa -Value Invoke-UpdateCargoPackage
