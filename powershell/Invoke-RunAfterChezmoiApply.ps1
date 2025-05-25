# Run after chezmoi apply
function Invoke-RunAfterChezmoiApply
{
    Write-Output "post-apply-hook"

    ############################
    # Copy PowerShell profiles #
    ############################
    # PowerShell profiles
    $Profiles = @{
        Base = Join-Path $env:USERPROFILE ".config\powershell\Microsoft.PowerShell_profile.ps1"
        Pwsh = @{
            Documents = Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
            OneDrive = Join-Path $env:USERPROFILE "OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
        }
        PowerShell = @{
            Documents = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
            OneDrive = Join-Path $env:USERPROFILE "OneDrive\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
        }
    }

    Write-Output "Copy PowerShell profiles"
    Copy-Item -Path $Profiles.Base -Destination $Profiles.Pwsh.Documents
    Copy-Item -Path $Profiles.Base -Destination $Profiles.PowerShell.Documents

    ####################################
    # Copy nvim (neovim) configuration #
    ####################################
    # Neovim configuration
    $NvimConfigs = @{
        Windows = Join-Path -Path $env:LOCALAPPDATA -ChildPath "nvim"
        Linux = @{
            Full = Join-Path -Path $env:CHEZMOI_DIR -ChildPath "dot_config\nvim"
            Mini = Join-Path -Path $env:CHEZMOI_DIR -ChildPath "dot_config\nvim-mini"
        }
    }

    Write-Output "Remove old nvim(neovim) configuration"
    Remove-Item -Path $NvimConfigs.Windows -Force -Recurse -ErrorAction SilentlyContinue

    Write-Output "Create nvim target directory"
    New-Item -Path $NvimConfigs.Windows -ItemType Directory -Force | Out-Null

    Write-Output "Copy nvim (neovim) configuration"
    Copy-Item -Path "$($NvimConfigs.Linux.Mini)\*" -Destination $NvimConfigs.Windows -Recurse -Force

    #####################################
    # Copy vim (paleovim) configuration #
    #####################################
    # Vim configuration
    $PvimConfigs = @{
        Home = Join-Path -Path $env:CHEZMOI_DIR -ChildPath "dot_config\vim"
        Work = Join-Path -Path $env:CHEZMOI_DIR -ChildPath "dot_vim"
        Windows = Join-Path -Path $env:USERPROFILE -ChildPath "vimfiles"
    }

    $HomeComputers = @("wakamo", "izuna")

    Write-Output "Remove old vim(paleovim) configuration"
    Remove-Item -Path $PvimConfigs.Windows -Force -Recurse -ErrorAction SilentlyContinue

    Write-Output "Create vim target directory"
    New-Item -Path $PvimConfigs.Windows -ItemType Directory -Force | Out-Null

    Write-Output "Copy vim (paleovim) configuration"
    if ($HomeComputers -contains $env:COMPUTERNAME.ToLower())
    {
        Copy-Item -Path "$($PvimConfigs.Home)\*" -Destination $PvimConfigs.Windows -Recurse -Force
    } else
    {
        Copy-Item -Path "$($PvimConfigs.Work)\*" -Destination $PvimConfigs.Windows -Recurse -Force
    }
}

Invoke-RunAfterChezmoiApply
