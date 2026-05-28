import Cocoa

class TouchBarManager: NSObject, NSTouchBarDelegate {
    static let shared = TouchBarManager()
    
    // Identifier for our Control Strip Item
    private let controlStripIdentifier = NSTouchBarItem.Identifier("com.custom.touchbar.controlstrip")
    private let touchBarIdentifier = NSTouchBarItem.Identifier("com.custom.touchbar.main")
    
    private var touchBar: NSTouchBar?
    private var configItems: [TouchBarItemConfig] = []
    private var timers: [Timer] = []
    private var isPresented = false
    
    // Pomodoro Timer State
    private var pomodoroTimeRemaining = 1500
    private var pomodoroState = "idle"
    private var pomodoroTimer: Timer?
    private weak var pomodoroButton: NSButton?
    
    // Virtual Pet State
    private var petHunger = 0 // 0-100, 100 is starving
    private var petHappiness = 100 // 0-100
    private var petState = "idle" // idle, sleeping, eating, playing
    private var petTimer: Timer?
    private weak var petButton: NSButton?
    private var petAnimationFrame = 0
    
    struct TouchBarItemConfig: Codable {
        let type: String      // "button", "slider", "label"
        let title: String?
        let action: String?   // "siri", "mute", "volume", "media_play_pause", "media_next", "media_prev", "now_playing", "shell", "dismiss"
        let command: String?
        let interval: Double?
        let color: String?
        let image: String?
    }
    
    func setupControlStrip() {
        // Create the status tray item (Control Strip item)
        let item = NSCustomTouchBarItem(identifier: controlStripIdentifier)
        
        let button = NSButton(title: "", target: self, action: #selector(toggleTouchBar))
        if let image = NSImage(systemSymbolName: "laptopcomputer", accessibilityDescription: "Toggle Touch Bar") {
            image.isTemplate = true
            button.image = image
        }
        button.bezelStyle = .rounded
        item.view = button
        
        NSTouchBarItem.addSystemTrayItem(item)
        
        // Dynamically invoke DFRElementSetControlStripPresenceForIdentifier to avoid static linking issues
        let handle = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_LAZY)
        if let handle = handle {
            if let sym = dlsym(handle, "DFRElementSetControlStripPresenceForIdentifier") {
                typealias FunctionType = @convention(c) (NSTouchBarItem.Identifier, ObjCBool) -> Void
                let function = unsafeBitCast(sym, to: FunctionType.self)
                function(controlStripIdentifier, true)
                print("Control Strip presence set dynamically.")
            } else {
                print("DFRElementSetControlStripPresenceForIdentifier not found.")
            }
            dlclose(handle)
        } else {
            print("Failed to dlopen DFRFoundation.")
        }
        
        print("Control Strip item registered successfully.")
    }
    
    func loadConfig() {
        // Clean up existing timers
        timers.forEach { $0.invalidate() }
        timers.removeAll()
        
        let path = "/Users/liyiyuan/.gemini/antigravity/scratch/TouchBarCustomizer/config.json"
        let fileURL = URL(fileURLWithPath: path)
        
        // Write a default config if none exists
        if !FileManager.default.fileExists(atPath: path) {
            let defaultConfig = """
            [
              {
                "type": "button",
                "title": "",
                "image": "xmark",
                "action": "dismiss",
                "color": "#ef4444"
              },
              {
                "type": "button",
                "title": "Siri",
                "image": "waveform",
                "action": "siri"
              },
              {
                "type": "button",
                "title": "",
                "image": "speaker.slash",
                "action": "mute"
              },
              {
                "type": "button",
                "title": "",
                "image": "minus",
                "action": "volume_down"
              },
              {
                "type": "button",
                "title": "",
                "image": "plus",
                "action": "volume_up"
              },
              {
                "type": "button",
                "title": "",
                "image": "playpause.fill",
                "action": "media_play_pause"
              },
              {
                "type": "button",
                "title": "Now Playing",
                "image": "music.note",
                "action": "now_playing",
                "interval": 2
              },
              {
                "type": "button",
                "title": "Battery",
                "image": "battery.100",
                "action": "shell",
                "command": "pmset -g batt | grep -Eo '\\\\d+%'",
                "interval": 10
              }
            ]
            """
            try? defaultConfig.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            configItems = try JSONDecoder().decode([TouchBarItemConfig].self, from: data)
            print("Loaded \(configItems.count) items from config.json")
        } catch {
            print("Failed to load or parse config.json: \(error)")
            configItems = []
        }
        
        // Build the NSTouchBar
        let bar = NSTouchBar()
        bar.delegate = self
        bar.defaultItemIdentifiers = configItems.enumerated().map { index, _ in
            NSTouchBarItem.Identifier("com.custom.touchbar.item.\(index)")
        }
        self.touchBar = bar
    }
    
    @objc func toggleTouchBar() {
        if isPresented {
            dismiss()
        } else {
            present()
        }
    }
    
    private func triggerObstruction() {
        let handle = dlopen("/System/Library/PrivateFrameworks/DFRFoundation.framework/DFRFoundation", RTLD_LAZY)
        if let handle = handle {
            if let sym = dlsym(handle, "DFRSystemModalShowAppObstruction") {
                let function = unsafeBitCast(sym, to: (@convention(c) () -> Void).self)
                function()
                print("Invoked DFRSystemModalShowAppObstruction dynamically.")
            } else {
                print("DFRSystemModalShowAppObstruction symbol not found.")
            }
            dlclose(handle)
        } else {
            print("Failed to dlopen DFRFoundation.")
        }
    }

    func present() {
        print("DEBUG: present() called")
        loadConfig()
        print("DEBUG: touchBar is nil? \(touchBar == nil)")
        guard let bar = touchBar else {
            print("DEBUG: touchBar is nil, returning early")
            return
        }

        // Try macOS 10.14+ API first, then fall back to older API
        let newSelector = NSSelectorFromString("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:")
        let oldSelector = NSSelectorFromString("presentSystemModalFunctionBar:systemTrayItemIdentifier:")

        print("DEBUG: responds to newSelector \(newSelector): \(NSTouchBar.responds(to: newSelector))")
        print("DEBUG: responds to oldSelector \(oldSelector): \(NSTouchBar.responds(to: oldSelector))")

        if NSTouchBar.responds(to: newSelector) {
            triggerObstruction()
            NSTouchBar.presentSystemModalTouchBar(bar, placement: 1, systemTrayItemIdentifier: controlStripIdentifier)
            print("Presented via presentSystemModalTouchBar.")
        } else if NSTouchBar.responds(to: oldSelector) {
            triggerObstruction()
            NSTouchBar.presentSystemModalFunctionBar(bar, systemTrayItemIdentifier: controlStripIdentifier)
            print("Presented via presentSystemModalFunctionBar.")
        } else {
            print("ERROR: No system modal Touch Bar API available on this macOS version.")
        }
        isPresented = true
    }
    
    func dismiss() {
        guard let bar = touchBar else { return }

        let newSelector = NSSelectorFromString("dismissSystemModalTouchBar:")
        let oldSelector = NSSelectorFromString("dismissSystemModalFunctionBar:")

        if NSTouchBar.responds(to: newSelector) {
            NSTouchBar.dismissSystemModalTouchBar(bar)
        } else if NSTouchBar.responds(to: oldSelector) {
            NSTouchBar.dismissSystemModalFunctionBar(bar)
        }
        isPresented = false
        timers.forEach { $0.invalidate() }
        timers.removeAll()
        print("System Modal Touch Bar dismissed.")
    }
    
    // MARK: - NSTouchBarDelegate
    
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let prefix = "com.custom.touchbar.item."
        guard identifier.rawValue.hasPrefix(prefix),
              let indexStr = identifier.rawValue.split(separator: ".").last,
              let index = Int(indexStr),
              index >= 0 && index < configItems.count else {
            return nil
        }
        
        let config = configItems[index]
        
        if config.type == "slider" && config.action == "volume" {
            let sliderItem = NSSliderTouchBarItem(identifier: identifier)
            sliderItem.label = config.title ?? ""
            sliderItem.slider.minValue = 0.0
            sliderItem.slider.maxValue = 1.0
            sliderItem.slider.doubleValue = Double(Actions.getVolume())
            sliderItem.target = self
            sliderItem.action = #selector(volumeSliderChanged(_:))
            
            // Limit the volume slider width to be compact
            sliderItem.slider.translatesAutoresizingMaskIntoConstraints = false
            sliderItem.slider.widthAnchor.constraint(equalToConstant: 120).isActive = true
            
            if let minImg = NSImage(systemSymbolName: "minus", accessibilityDescription: nil) {
                minImg.isTemplate = true
                sliderItem.minimumValueAccessory = NSSliderAccessory(image: minImg)
            }
            if let maxImg = NSImage(systemSymbolName: "plus", accessibilityDescription: nil) {
                maxImg.isTemplate = true
                sliderItem.maximumValueAccessory = NSSliderAccessory(image: maxImg)
            }
            
            // Periodically sync volume value
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak sliderItem] _ in
                guard let sliderItem = sliderItem else { return }
                sliderItem.slider.doubleValue = Double(Actions.getVolume())
            }
            timers.append(timer)
            
            return sliderItem
        } else if config.type == "button" {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button: NSButton
            
            if config.action == "pomodoro" {
                let image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
                image?.isTemplate = true
                button = NSButton(image: image ?? NSImage(), target: self, action: #selector(pomodoroTapped(_:)))
                button.title = formatPomodoroTime()
                button.imagePosition = .imageLeft
                self.pomodoroButton = button
                
                if pomodoroState == "running" {
                    button.bezelColor = NSColor.systemOrange
                } else if pomodoroState == "paused" {
                    button.bezelColor = NSColor.systemGray
                }
            } else if config.action == "pet" {
                let image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: nil)
                image?.isTemplate = true
                button = NSButton(image: image ?? NSImage(), target: self, action: #selector(petTapped(_:)))
                button.imagePosition = .imageLeft
                self.petButton = button
                refreshPetButton()
                startPetTimer()
            } else if let symbolName = config.image, let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
                image.isTemplate = true
                button = NSButton(image: image, target: self, action: #selector(buttonTapped(_:)))
                if let title = config.title, !title.isEmpty {
                    button.title = title
                    button.imagePosition = .imageLeft
                }
            } else {
                button = NSButton(title: config.title ?? "", target: self, action: #selector(buttonTapped(_:)))
            }
            
            button.tag = index
            button.bezelStyle = .rounded
            
            if let colorHex = config.color, let color = NSColor(hex: colorHex) {
                button.bezelColor = color
            }
            
            item.view = button
            
            // Set up polling if interval is defined
            if let interval = config.interval, interval > 0 {
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak button] _ in
                    guard let button = button else { return }
                    DispatchQueue.global(qos: .background).async {
                        let newTitle: String
                        if let cmd = config.command {
                            let output = Actions.runShell(cmd)
                            newTitle = output.isEmpty ? (config.title ?? "") : output
                        } else if config.action == "now_playing" {
                            let np = Actions.getNowPlaying()
                            newTitle = np.isEmpty ? "🔇 Silence" : np
                        } else if config.action == "network_speed" {
                            newTitle = Actions.getNetworkSpeedString()
                        } else {
                            newTitle = config.title ?? ""
                        }
                        
                        DispatchQueue.main.async {
                            button.title = newTitle
                        }
                    }
                }
                // Run once immediately
                timer.fire()
                timers.append(timer)
            }
            
            return item
        } else if config.type == "label" {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let label = NSTextField(labelWithString: config.title ?? "")
            label.isEditable = false
            label.isSelectable = false
            label.textColor = .white
            label.backgroundColor = .clear
            label.alignment = .center
            item.view = label
            
            if let interval = config.interval, interval > 0 {
                let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak label] _ in
                    guard let label = label else { return }
                    DispatchQueue.global(qos: .background).async {
                        let text: String
                        if let cmd = config.command {
                            text = Actions.runShell(cmd)
                        } else if config.action == "now_playing" {
                            let np = Actions.getNowPlaying()
                            text = np.isEmpty ? "Silence" : np
                        } else if config.action == "network_speed" {
                            text = Actions.getNetworkSpeedString()
                        } else {
                            text = config.title ?? ""
                        }
                        
                        DispatchQueue.main.async {
                            label.stringValue = text
                        }
                    }
                }
                timer.fire()
                timers.append(timer)
            }
            return item
        }
        
        return nil
    }
    
    @objc private func volumeSliderChanged(_ sender: NSSliderTouchBarItem) {
        Actions.setVolume(Float(sender.slider.doubleValue))
    }
    
    @objc private func buttonTapped(_ sender: NSButton) {
        let index = sender.tag
        guard index >= 0 && index < configItems.count else { return }
        let config = configItems[index]
        
        switch config.action {
        case "siri":
            Actions.triggerSiri()
        case "mute":
            let isMuted = Actions.toggleMute()
            sender.title = isMuted ? "🔊 Unmute" : "🔇 Mute"
            sender.bezelColor = isMuted ? NSColor.systemRed : NSColor(hex: config.color ?? "#f59e0b")
        case "media_play_pause":
            Actions.mediaPlayPause()
        case "media_next":
            Actions.mediaNext()
        case "media_prev":
            Actions.mediaPrevious()
        case "volume_down":
            Actions.volumeDown()
        case "volume_up":
            Actions.volumeUp()
        case "window_left":
            Actions.resizeFrontWindow(action: "left")
        case "window_right":
            Actions.resizeFrontWindow(action: "right")
        case "window_maximize":
            Actions.resizeFrontWindow(action: "maximize")
        case "dismiss":
            dismiss()
        case "shell":
            if let cmd = config.command {
                if config.interval == nil {
                    DispatchQueue.global(qos: .userInitiated).async {
                        _ = Actions.runShell(cmd)
                    }
                } else {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let output = Actions.runShell(cmd)
                        DispatchQueue.main.async {
                            sender.title = output.isEmpty ? (config.title ?? "") : output
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Pomodoro Helpers & Action
    
    private func formatPomodoroTime() -> String {
        let minutes = pomodoroTimeRemaining / 60
        let seconds = pomodoroTimeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startPomodoroTimer() {
        pomodoroTimer?.invalidate()
        pomodoroState = "running"
        pomodoroTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.pomodoroTimeRemaining > 0 {
                self.pomodoroTimeRemaining -= 1
                DispatchQueue.main.async {
                    self.pomodoroButton?.title = self.formatPomodoroTime()
                }
            } else {
                self.stopPomodoroTimer()
                self.triggerPomodoroNotification()
            }
        }
    }
    
    private func stopPomodoroTimer() {
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
    }
    
    @objc private func pomodoroTapped(_ sender: NSButton) {
        if pomodoroState == "idle" {
            pomodoroTimeRemaining = 1500
            startPomodoroTimer()
            sender.bezelColor = NSColor.systemOrange
        } else if pomodoroState == "running" {
            pomodoroState = "paused"
            stopPomodoroTimer()
            sender.title = "⏸️ " + formatPomodoroTime()
            sender.bezelColor = NSColor.systemGray
        } else if pomodoroState == "paused" {
            // Reset
            pomodoroState = "idle"
            pomodoroTimeRemaining = 1500
            sender.title = formatPomodoroTime()
            sender.bezelColor = nil
        }
    }
    
    private func triggerPomodoroNotification() {
        let notification = NSUserNotification()
        notification.title = "Pomodoro Finished!"
        notification.informativeText = "Time to take a break!"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        
        DispatchQueue.main.async {
            self.pomodoroButton?.title = "🎉 Break!"
            self.pomodoroButton?.bezelColor = NSColor.systemGreen
            self.pomodoroState = "idle"
            self.pomodoroTimeRemaining = 1500
        }
    }
    
    // MARK: - Virtual Pet Helpers & Action
    
    private func startPetTimer() {
        petTimer?.invalidate()
        var tickCount = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            tickCount += 1
            self.petAnimationFrame = (self.petAnimationFrame + 1) % 4
            
            if tickCount >= 8 {
                tickCount = 0
                self.updatePetStats()
            }
            
            DispatchQueue.main.async {
                self.refreshPetButton()
            }
        }
        self.petTimer = timer
        timers.append(timer)
    }
    
    private func updatePetStats() {
        // Hunger increases
        petHunger = min(100, petHunger + 5)
        // Happiness decays
        if petHunger > 50 {
            petHappiness = max(0, petHappiness - 10)
        } else {
            petHappiness = max(0, petHappiness - 2)
        }
        
        // Randomly fall asleep
        if petState == "idle" && Int.random(in: 1...10) == 1 {
            petState = "sleeping"
        }
    }
    
    private func refreshPetButton() {
        guard let button = petButton else { return }
        var titleText = ""
        
        switch petState {
        case "sleeping":
            let frames = [
                "💤 ( ᵕ≕ᵕ )",
                " ( ᵕ≕ᵕ ) 💤",
                "z ( ᵕ≕ᵕ )",
                "zz ( ᵕ≕ᵕ )"
            ]
            titleText = frames[petAnimationFrame % frames.count]
            
        case "eating":
            let frames = [
                "( ˙Ⱉ˙ ) 🍗",
                "( ˙ⱎ˙ ) 🍖",
                "( ˙Ⱉ˙ ) 🍬",
                "( ˙ⱎ˙ )"
            ]
            titleText = frames[petAnimationFrame % frames.count]
            
        case "playing":
            let frames = [
                "ヾ(✿ﾟ▽ﾟ)ノ",
                "ヾ(●゜▽゜●)ノ",
                "ヾ(✿ﾟ▽ﾟ)ノ ~",
                "ヾ(●゜▽゜●)ノ"
            ]
            titleText = frames[petAnimationFrame % frames.count]
            
        default: // idle
            if petHunger > 70 {
                let frames = [
                    "( 😿 ) 💔",
                    "( 😿 )",
                    "( 😿 ) 💔",
                    "( 😿 )"
                ]
                titleText = frames[petAnimationFrame % frames.count]
            } else if petHappiness < 40 {
                let frames = [
                    "(・Ⱉ・)",
                    "(・Ⱉ・)~",
                    "(｀_´)ゞ",
                    "(｀_´)ゞ~"
                ]
                titleText = frames[petAnimationFrame % frames.count]
            } else {
                let frames = [
                    "🐱 ( ^ω^ )ﾉ",
                    "🐱 ( -ω- )ﾉ",
                    "🐱 ( ^ω^ )~",
                    "🐱 ( ^ω^ )"
                ]
                titleText = frames[petAnimationFrame % frames.count]
            }
        }
        
        button.title = titleText
    }
    
    @objc private func petTapped(_ sender: NSButton) {
        if petState == "sleeping" {
            petState = "idle"
            petHappiness = min(100, petHappiness + 15)
        } else if petHunger > 40 {
            petState = "eating"
            petHunger = max(0, petHunger - 30)
        } else {
            petState = "playing"
            petHappiness = min(100, petHappiness + 25)
        }
        petAnimationFrame = 0
        refreshPetButton()
    }
}


// MARK: - Hex Color Helper
extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
