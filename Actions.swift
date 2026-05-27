import Foundation
import AppKit

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
    
    // MARK: - Volume Controls
    
    static func isMuted() -> Bool {
        let result = runAppleScript("output muted of (get volume settings)")
        return result.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "true"
    }
    
    static func toggleMute() -> Bool {
        runAppleScript("set volume output muted not (output muted of (get volume settings))")
        return isMuted()
    }
    
    static func getVolume() -> Float {
        let result = runAppleScript("output volume of (get volume settings)")
        if let percentage = Float(result.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return percentage / 100.0
        }
        return 0.5
    }
    
    static func setVolume(_ volume: Float) {
        let percentage = Int(volume * 100.0)
        runAppleScript("set volume output volume \(percentage)")
    }
    
    // MARK: - Media Controls
    
    static func mediaPlayPause() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to playpause
        else if application "Music" is running then
            tell application "Music" to playpause
        end if
        """
        runAppleScript(script)
    }
    
    static func mediaNext() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to next track
        else if application "Music" is running then
            tell application "Music" to next track
        end if
        """
        runAppleScript(script)
    }
    
    static func mediaPrevious() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify" to previous track
        else if application "Music" is running then
            tell application "Music" to previous track
        end if
        """
        runAppleScript(script)
    }
    
    static func getNowPlaying() -> String {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    return (name of current track) & " - " & (artist of current track)
                end if
            end tell
        else if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    return (name of current track) & " - " & (artist of current track)
                end if
            end tell
        end if
        return ""
        """
        let result = runAppleScript(script)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
