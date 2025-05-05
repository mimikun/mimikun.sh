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
    # gsudo check
    if (-not (Get-Command gsudo -ErrorAction SilentlyContinue))
    {
        Write-Output "Cannot found gsudo."
        Write-Output "Please install gsudo."
        Write-Output "Install it: 'winget install gerardog.gsudo' or 'scoop install gsudo'"
        return
    }

    # Get monitors
    $monitors = Get-PnpDevice -Class Monitor
    $targetMonitor = $monitors | Where-Object { $_.FriendlyName -like "*$targetMonitorName*" }
    if ($targetMonitor)
    {
        $id = $targetMonitor.InstanceId
        $name = $targetMonitor.FriendlyName

        # InstanceId check
        if ($id)
        {
            Write-Output "InstanceId: '$($id)'"

            # Disable monitor
            Write-Output "Disabling monitor '$($name)' ..."
            gsudo { param($deviceId) Disable-PnpDevice -InstanceId $deviceId -Confirm:$false } -args $id

            # Sleep
            Write-Output "Waiting...(5 sec)"
            Start-Sleep -Seconds 5

            # Enable monitor
            Write-Output "Enabling monitor '$($name)' ..."
            gsudo { param($deviceId) Enable-PnpDevice -InstanceId $deviceId -Confirm:$false } -args $id

            Write-Output "Done! Please wait while your monitors reconnect..."
        } else
        {
            Write-Output "InstanceId is null or empty"
            Write-Output "InstanceId: '$($id)'"
        }
    } else
    {
        Write-Output "The specified monitor '$targetMonitorName' was not found."
        Write-Output "List of connected monitors:"
        $monitors | ForEach-Object { Write-Output " - $($_.FriendlyName)" }
    }
}

Set-Alias -Name reboot_second_monitor -Value Invoke-RebootSecondMonitor
Set-Alias -Name rsm -Value Invoke-RebootSecondMonitor
