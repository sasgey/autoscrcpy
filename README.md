## automate startup of scrcpy

### Prereqs
- Install ADB
   - Get the **Android Platform Tools** from Google:   [Download ADB](https://developer.android.com/tools/releases/platform-tools)
   - Extract it somewhere like `C:\adb`.    
   - Test that ADB detects your device
   - Plug in your Android device with USB debugging enabled.
   - Run: `adb devices` 
     It should list your phone
     (might ask for authorization on the phone the first time).

- Install **scrcpy** → [scrcpy releases](https://github.com/Genymobile/scrcpy)  
    (extract somewhere like `C:\scrcpy`)
    
 -   Add both `adb.exe` and `scrcpy.exe` to your PATH, or reference their full paths in the script.

### Setup

1.  Save as `AutoScrcpy.ps1`.
    
2.  Task Scheduler → run at **logon/startup**, with:
    
    `powershell.exe -ExecutionPolicy Bypass -File  "C:\Path\AutoScrcpy.ps1"` 
    
3.  Set to **Run minimized** so the script stays quiet in the background.

### Behavior

-   **On connect** → starts scrcpy at native resolution.
    
-   **On disconnect** → kills scrcpy for that device.
    
-   **If scrcpy closes/crashes manually** → script notices `HasExited` and restarts it automatically.
