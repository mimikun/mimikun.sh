function Invoke-GenerateEditorConfig()
{
    Get-Item -Path .\.editorconfig -ErrorAction Ignore
    $res = $?
    if (!$res)
    {
        Write-Output ".editorconfig not exist."
        Write-Output "Creating .editorconfig."
        Copy-Item -Path $env:USERPROFILE\.editorconfig-template -Destination .\.editorconfig
    }
}

Set-Alias -Name editorconfig Invoke-GenerateEditorConfig
