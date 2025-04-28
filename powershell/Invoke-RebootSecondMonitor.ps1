<#
FIRST_MONITOR
ViewSonic XG2705
DISPLAY\VSC0E39\5&82E1834&0&UID4355

SECOND_MONITOR
BenQ EX3210U
DISPLAY\BNQ7FA6\5&82E1834&0&UID4357
#>

# Specify the monitor name (BenQ EX3210U)
$targetMonitorName = "BenQ EX3210U"

function Invoke-RebootSecondMonitor()
{
    # Get monitors
    $monitors = Get-PnpDevice -Class Monitor
    $targetMonitor = $monitors | Where-Object { $_.FriendlyName -like "*$targetMonitorName*" }
    if ($targetMonitor)
    {
        $id = $targetMonitor.InstanceId
        $name = $targetMonitor.FriendlyName

        # Disable monitor
        Write-Output "Disabling monitor '$($name)' ..."
        Disable-PnpDevice -InstanceId $id -Confirm:$false
        # Wait
        Write-Output "Waiting...(3 sec)"
        Start-Sleep -Seconds 3

        # Enable monitor
        Write-Output "Enabling monitor '$($name)' ..."
        Enable-PnpDevice -InstanceId $id -Confirm:$false

        Write-Output "Done! Please wait while your monitors reconnect..."
    } else
    {
        Write-Output "The specified monitor '$targetMonitorName' was not found."
        Write-Output "List of connected monitors:"
        $monitors | ForEach-Object { Write-Output " - $($_.FriendlyName)" }
    }
}

Set-Alias -Name reboot_second_monitor -Value Invoke-RebootSecondMonitor
Set-Alias -Name rsm -Value Invoke-RebootSecondMonitor
