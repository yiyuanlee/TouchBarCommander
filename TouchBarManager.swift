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
    
    struct TouchBarItemConfig: Codable {
        let type: String      // "button", "slider", "label"
        let title: String?
        let action: String?   // "siri", "mute", "volume", "media_play_pause", "media_next", "media_prev", "now_playing", "shell", "dismiss"
        let command: String?
        let interval: Double?
        let color: String?
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
        DFRElementSetControlStripPresenceForIdentifier(controlStripIdentifier, true)
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
                "title": "❌ Close",
                "action": "dismiss",
                "color": "#ef4444"
              },
              {
                "type": "button",
                "title": "🎙️ Siri",
                "action": "siri",
                "color": "#6366f1"
              },
              {
                "type": "button",
                "title": "🔇 Mute",
                "action": "mute",
                "color": "#f59e0b"
              },
              {
                "type": "slider",
                "title": "Volume",
                "action": "volume"
              },
              {
                "type": "button",
                "title": "🎵 Play",
                "action": "media_play_pause",
                "color": "#10b981"
              },
              {
                "type": "button",
                "title": "🔋 Battery",
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
        loadConfig()
        if let bar = touchBar {
            triggerObstruction()
            NSTouchBar.presentSystemModalFunctionBar(bar, systemTrayItemIdentifier: controlStripIdentifier)
            isPresented = true
            print("System Modal Touch Bar presented.")
        }
    }
    
    func dismiss() {
        if let bar = touchBar {
            NSTouchBar.dismissSystemModalFunctionBar(bar)
            isPresented = false
            timers.forEach { $0.invalidate() }
            timers.removeAll()
            print("System Modal Touch Bar dismissed.")
        }
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
            sliderItem.label = config.title ?? "Vol"
            sliderItem.slider.minValue = 0.0
            sliderItem.slider.maxValue = 1.0
            sliderItem.slider.doubleValue = Double(Actions.getVolume())
            sliderItem.target = self
            sliderItem.action = #selector(volumeSliderChanged(_:))
            
            // Periodically sync volume value
            let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak sliderItem] _ in
                guard let sliderItem = sliderItem else { return }
                sliderItem.slider.doubleValue = Double(Actions.getVolume())
            }
            timers.append(timer)
            
            return sliderItem
        } else if config.type == "button" {
            let item = NSCustomTouchBarItem(identifier: identifier)
            let button = NSButton(title: config.title ?? "", target: self, action: #selector(buttonTapped(_:)))
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
