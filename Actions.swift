import Foundation
import AppKit
import AudioToolbox

struct Actions {
    
    // MARK: - AppleScript Execution
    
    @discardableResult
    static func runAppleScript(_ source: String) -> String {
        guard let script = NSAppleScript(source: source) else {
            return "Error: Could not compile AppleScript"
        }
        var error: NSDictionary?
        let descriptor = script.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript error: \(error)")
            return "Error: \(error[NSAppleScript.errorMessage] ?? "Unknown error")"
        }
        return descriptor.stringValue ?? ""
    }
    
    // MARK: - Shell Command Execution
    
    static func runShell(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Shell execution error: \(error)")
        }
        return ""
    }
    
    // MARK: - Siri Action
    
    static func triggerSiri() {
        // Try simulating Command+Space. If user has a custom shortcut, they can configure it.
        let script = """
        tell application "System Events"
            key code 49 using {command down}
        end tell
        """
        runAppleScript(script)
    }
    
    // MARK: - Volume Controls (CoreAudio native, non-blocking)
    
    private static func getDefaultOutputDevice() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
        var deviceIDSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: 0
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &deviceIDSize,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    static func isMuted() -> Bool {
        guard let deviceID = getDefaultOutputDevice() else { return false }
        var mute: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        let status = AudioObjectGetPropertyData(
            deviceID,
            &muteAddress,
            0,
            nil,
            &muteSize,
            &mute
        )
        return status == noErr ? (mute != 0) : false
    }
    
    @discardableResult
    static func toggleMute() -> Bool {
        guard let deviceID = getDefaultOutputDevice() else { return false }
        let muteState = !isMuted()
        var muteVal: UInt32 = muteState ? 1 : 0
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        AudioObjectSetPropertyData(
            deviceID,
            &muteAddress,
            0,
            nil,
            UInt32(MemoryLayout<UInt32>.size),
            &muteVal
        )
        VolumeHUDWindow.shared.showVolume(getVolume(), isMuted: muteState)
        return muteState
    }
    
    static func getVolume() -> Float {
        guard let deviceID = getDefaultOutputDevice() else { return 0.5 }
        var volume = Float32(0.0)
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        let status = AudioObjectGetPropertyData(
            deviceID,
            &volumeAddress,
            0,
            nil,
            &volumeSize,
            &volume
        )
        return status == noErr ? Float(volume) : 0.5
    }
    
    static func setVolume(_ volume: Float) {
        guard let deviceID = getDefaultOutputDevice() else { return }
        var vol = Float32(volume)
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )
        AudioObjectSetPropertyData(
            deviceID,
            &volumeAddress,
            0,
            nil,
            UInt32(MemoryLayout<Float32>.size),
            &vol
        )
    }
    
    static func volumeDown() {
        let current = getVolume()
        let targetVolume = max(0.0, current - 0.0625)
        setVolume(targetVolume)
        VolumeHUDWindow.shared.showVolume(targetVolume, isMuted: isMuted())
    }
    
    static func volumeUp() {
        let current = getVolume()
        let targetVolume = min(1.0, current + 0.0625)
        setVolume(targetVolume)
        VolumeHUDWindow.shared.showVolume(targetVolume, isMuted: isMuted())
    }
    
    
    // MARK: - Media Controls
    
    static func mediaPlayPause() {
        let script = """
        if application "Music" is running then
            tell application "Music" to playpause
        else
            try
                set spotifyApp to application id "com.spotify.client"
                if spotifyApp is running then
                    using terms from application "Music"
                        tell spotifyApp to playpause
                    end using terms from
                end if
            end try
        end if
        """
        runAppleScript(script)
    }
    
    static func mediaNext() {
        let script = """
        if application "Music" is running then
            tell application "Music" to next track
        else
            try
                set spotifyApp to application id "com.spotify.client"
                if spotifyApp is running then
                    using terms from application "Music"
                        tell spotifyApp to next track
                    end using terms from
                end if
            end try
        end if
        """
        runAppleScript(script)
    }
    
    static func mediaPrevious() {
        let script = """
        if application "Music" is running then
            tell application "Music" to previous track
        else
            try
                set spotifyApp to application id "com.spotify.client"
                if spotifyApp is running then
                    using terms from application "Music"
                        tell spotifyApp to previous track
                    end using terms from
                end if
            end try
        end if
        """
        runAppleScript(script)
    }
    
    static func getNowPlaying() -> String {
        let script = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    return (name of current track) & " - " & (artist of current track)
                end if
            end tell
        else
            try
                set spotifyApp to application id "com.spotify.client"
                if spotifyApp is running then
                    using terms from application "Music"
                        tell spotifyApp
                            if player state is playing then
                                return (name of current track) & " - " & (artist of current track)
                            end if
                        end tell
                    end using terms from
                end if
            end try
        end if
        return ""
        """
        let result = runAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Window Manager Action (Accessibility/AppleScript)
    
    static func resizeFrontWindow(action: String) {
        let script = """
        tell application "Finder"
            set desktopRect to bounds of window of desktop
            set screenWidth to item 3 of desktopRect
            set screenHeight to item 4 of desktopRect
        end tell
        
        tell application "System Events"
            try
                set frontmostProcess to first process whose frontmost is true
                set frontmostWindow to first window of frontmostProcess
                
                if "\(action)" = "left" then
                    set position of frontmostWindow to {0, 23}
                    set size of frontmostWindow to {screenWidth / 2, screenHeight - 23}
                else if "\(action)" = "right" then
                    set position of frontmostWindow to {screenWidth / 2, 23}
                    set size of frontmostWindow to {screenWidth / 2, screenHeight - 23}
                else if "\(action)" = "maximize" then
                    set position of frontmostWindow to {0, 23}
                    set size of frontmostWindow to {screenWidth, screenHeight - 23}
                end if
            end try
        end tell
        """
        runAppleScript(script)
    }
    
    // MARK: - Network Speed Monitor (Core OS stats)
    
    static func getNetworkBytes() -> (ibytes: UInt64, obytes: UInt64) {
        var ibytes: UInt64 = 0
        var obytes: UInt64 = 0
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        
        guard getifaddrs(&ifaddr) == 0 else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Only count Wi-Fi (en0) and ethernet (en1, etc.)
            if name.hasPrefix("en") {
                if let data = interface.ifa_data {
                    let type = interface.ifa_addr.pointee.sa_family
                    if type == AF_LINK {
                        let ifData = data.assumingMemoryBound(to: if_data.self)
                        ibytes += UInt64(ifData.pointee.ifi_ibytes)
                        obytes += UInt64(ifData.pointee.ifi_obytes)
                    }
                }
            }
        }
        return (ibytes, obytes)
    }
    
    private static var lastNetTime = Date()
    private static var lastIbytes: UInt64 = 0
    private static var lastObytes: UInt64 = 0
    
    static func getNetworkSpeedString() -> String {
        let now = Date()
        let timeDiff = now.timeIntervalSince(lastNetTime)
        let bytes = getNetworkBytes()
        
        if lastIbytes == 0 && lastObytes == 0 {
            lastIbytes = bytes.ibytes
            lastObytes = bytes.obytes
            lastNetTime = now
            return "↓0K ↑0K"
        }
        
        let ibytesDiff = Double(bytes.ibytes > lastIbytes ? bytes.ibytes - lastIbytes : 0)
        let obytesDiff = Double(bytes.obytes > lastObytes ? bytes.obytes - lastObytes : 0)
        
        lastIbytes = bytes.ibytes
        lastObytes = bytes.obytes
        lastNetTime = now
        
        let seconds = timeDiff > 0 ? timeDiff : 1.0
        let downSpeed = ibytesDiff / seconds
        let upSpeed = obytesDiff / seconds
        
        func formatSpeed(_ speed: Double) -> String {
            if speed >= 1024 * 1024 {
                return String(format: "%.1fM", speed / (1024 * 1024))
            } else if speed >= 1024 {
                return String(format: "%.0fK", speed / 1024)
            } else {
                return "\(Int(speed))B"
            }
        }
        
        return "↓\(formatSpeed(downSpeed)) ↑\(formatSpeed(upSpeed))"
    }
}
