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

function Invoke-ExistsCmd()
{
    Param($cmdName)
    Get-Command -Name $cmdName > $null 2>&1
    $result = $?
    return $result
}

function Invoke-InstallCargoPackage
{
    Param([switch]$NoPueue)

    $tmp = Join-Path -Path $env:USERPROFILE -ChildPath ".mimikun-pkglists"
    $pkglist = Join-Path -Path $tmp -ChildPath "windows_cargo_packages.txt"

    #$taskId = pueue add -p -- "Write-Output start"
    Get-Content -Path $pkglist |
        ForEach-Object {
            $pkg = $_
            $cond = Invoke-ExistsCmd $pkg
            if (-not $cond)
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
                        Write-Output "$pkg is not found"
                        if ($NoPueue)
                        {
                            cargo install $pkg
                        } else
                        {
                            pueue add -- "cargo install $pkg"
                            #$taskId = pueue add --after $taskId -p -- "cargo install $pkg"
                        }
                    }
                }
            }
        }
    # Install from sources
    if ($NoPueue)
    {
        cargo install --git "https://github.com/Adarsh-Roy/gthr" --locked
    } else
    {
        pueue add -- "cargo install --git 'https://github.com/Adarsh-Roy/gthr' --locked"
        #$taskId = pueue add --after $taskId -p -- "cargo install $pkg"
    }
}

Set-Alias -Name install_cargo_package -Value Invoke-InstallCargoPackage
Set-Alias -Name instacapa -Value Invoke-InstallCargoPackage
