$adbPath = "C:\scrcpy\adb.exe"
$scrcpyPath = "C:\scrcpy\scrcpy.exe"

# Track devices and their scrcpy process
$deviceProcesses = @{}

while ($true) {
    # Get currently connected devices
    $connected = & $adbPath devices | ForEach-Object {
        if ($_ -match "^(.*?)\s+device$") { $matches[1] }
    }

    # Handle new devices
    foreach ($deviceId in $connected) {
        if (-not $deviceProcesses.ContainsKey($deviceId)) {
            # Get resolution
            $wmOutput = & $adbPath -s $deviceId shell wm size
            $args = "-s $deviceId"
            if ($wmOutput -match "Physical size: (\d+)x(\d+)") {
                $width = $matches[1]
                $args += " --max-size=$width"
                Write-Output "[$deviceId] Launching scrcpy at ${width} width"
            } else {
                Write-Output "[$deviceId] Launching scrcpy with default size"
            }

            # Start scrcpy process and store it
            $proc = Start-Process $scrcpyPath -ArgumentList $args -PassThru
            $deviceProcesses[$deviceId] = $proc
        }
    }

    # Handle disconnected devices
    foreach ($id in @($deviceProcesses.Keys)) {
        if ($connected -notcontains $id) {
            Write-Output "[$id] Disconnected → closing scrcpy"
            try {
                $deviceProcesses[$id].Kill()
            } catch {
                Write-Output "[$id] Process already closed"
            }
            $deviceProcesses.Remove($id) | Out-Null
        }
    }

    Start-Sleep -Seconds 2
}
