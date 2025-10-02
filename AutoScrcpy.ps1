
$adbPath = "C:\scrcpy\adb.exe"
$scrcpyPath = "C:\scrcpy\scrcpy.exe"

# Error log file path
$errorLog = Join-Path -Path $PSScriptRoot -ChildPath "autoscrcpy_error.log"

# Helper function to log errors
function Log-Error {
    param(
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    Write-Error $logEntry
    Add-Content -Path $errorLog -Value $logEntry
}

# Excluded device IDs (serial numbers)
# → Run "adb devices" once to see the IDs of your devices
$excludedDevices = @(
    "SERIAL_1",
    "SERIAL_2"
)

# Track devices and their scrcpy process
$deviceProcesses = @{}

while ($true) {
    # Get currently connected devices (only "device" state, ignore "unauthorized" etc.)

    try {
        $connected = & $adbPath devices | ForEach-Object {
            if ($_ -match "^(.*?)\s+device$") { $matches[1] }
        }
    } catch {
        Log-Error "Failed to get connected devices: $($_.Exception.Message)"
        $connected = @()
    }

    # Handle new or restarted devices
    foreach ($deviceId in $connected) {

        if ($excludedDevices -contains $deviceId) {
            if ($deviceProcesses.ContainsKey($deviceId)) {
                # If excluded device was tracked, make sure scrcpy is not running
                try {
                    if ($deviceProcesses[$deviceId] -and -not $deviceProcesses[$deviceId].HasExited) {
                        $deviceProcesses[$deviceId].Kill()
                    }
                } catch {
                    Log-Error "Error killing scrcpy for excluded device $deviceId: $($_.Exception.Message)"
                }
                $deviceProcesses.Remove($deviceId) | Out-Null
            }
            continue
        }


        if (-not $deviceProcesses.ContainsKey($deviceId)) {
            $deviceProcesses[$deviceId] = $null
        }

        $proc = $deviceProcesses[$deviceId]

        # If no scrcpy process or process exited → start/restart it
        if (-not $proc -or $proc.HasExited) {
            try {
                # Get resolution
                $wmOutput = & $adbPath -s $deviceId shell wm size
            } catch {
                Log-Error "Failed to get screen size for $deviceId: $($_.Exception.Message)"
                $wmOutput = ""
            }
            $args = "-s $deviceId"
            if ($wmOutput -match "Physical size: (\d+)x(\d+)") {
                $width = $matches[1]
                $args += " --max-size=$width"
                Write-Output "[$deviceId] Launching scrcpy at ${width} width"
            } else {
                Write-Output "[$deviceId] Launching scrcpy with default size"
            }

            try {
                # Start scrcpy process
                $proc = Start-Process $scrcpyPath -ArgumentList $args -PassThru
                $deviceProcesses[$deviceId] = $proc
            } catch {
                Log-Error "Failed to start scrcpy for $deviceId: $($_.Exception.Message)"
            }
        }
    }

    # Handle disconnected devices

    foreach ($id in @($deviceProcesses.Keys)) {
        if ($connected -notcontains $id) {
            Write-Output "[$id] Disconnected → closing scrcpy"
            try {
                if ($deviceProcesses[$id] -and -not $deviceProcesses[$id].HasExited) {
                    $deviceProcesses[$id].Kill()
                }
            } catch {
                Log-Error "Error killing scrcpy for disconnected device $id: $($_.Exception.Message)"
            }
            $deviceProcesses.Remove($id) | Out-Null
        }
    }

    Start-Sleep -Seconds 2
}
