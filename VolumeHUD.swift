import Cocoa

class VolumeHUDWindow: NSPanel {
    static let shared = VolumeHUDWindow()
    
    private var progressView: NSView!
    private var progressContainer: NSView!
    private var progressWidthConstraint: NSLayoutConstraint?
    private var volumeIcon: NSImageView!
    private var percentLabel: NSTextField!
    private var fadeTimer: Timer?
    
    init() {
        // Standard square OSD HUD size
        let rect = NSRect(x: 0, y: 0, width: 160, height: 160)
        super.init(contentRect: rect,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .statusBar
        self.isMovable = false
        self.hasShadow = true
        self.alphaValue = 0.0
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        
        setupViews()
    }
    
    private func setupViews() {
        // Visual Effect View for Blur Background
        let effectView = NSVisualEffectView(frame: self.contentView!.bounds)
        effectView.autoresizingMask = [.width, .height]
        effectView.material = .hudWindow
        effectView.blendingMode = .behindWindow
        effectView.state = .active
        effectView.wantsLayer = true
        effectView.layer?.cornerRadius = 20
        self.contentView?.addSubview(effectView)
        
        // Speaker Image View
        let imageView = NSImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.contentTintColor = NSColor.white.withAlphaComponent(0.85)
        effectView.addSubview(imageView)
        self.volumeIcon = imageView
        
        // Text label for percentage
        let label = NSTextField(labelWithString: "50%")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        label.textColor = NSColor.white.withAlphaComponent(0.9)
        label.alignment = .center
        label.isEditable = false
        label.isSelectable = false
        label.isBordered = false
        label.drawsBackground = false
        effectView.addSubview(label)
        self.percentLabel = label
        
        // Outer Progress Bar container
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor
        container.layer?.cornerRadius = 3
        effectView.addSubview(container)
        self.progressContainer = container
        
        // Inner Progress Bar fill
        let fill = NSView()
        fill.translatesAutoresizingMaskIntoConstraints = false
        fill.wantsLayer = true
        fill.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.85).cgColor
        fill.layer?.cornerRadius = 3
        container.addSubview(fill)
        self.progressView = fill
        
        // Setup Constraints
        NSLayoutConstraint.activate([
            // Icon layout (centered horizontally, near top)
            imageView.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
            imageView.topAnchor.constraint(equalTo: effectView.topAnchor, constant: 28),
            imageView.widthAnchor.constraint(equalToConstant: 54),
            imageView.heightAnchor.constraint(equalToConstant: 54),
            
            // Progress Bar Container layout
            container.leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: 18),
            container.trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: -18),
            container.bottomAnchor.constraint(equalTo: effectView.bottomAnchor, constant: -35),
            container.heightAnchor.constraint(equalToConstant: 6),
            
            // Progress Bar Fill layout
            fill.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            fill.topAnchor.constraint(equalTo: container.topAnchor),
            fill.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            // Percent Label layout (at the bottom)
            label.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: effectView.bottomAnchor, constant: -12)
        ])
        
        // Initial multiplier setup (default 50%)
        updateProgressWidth(multiplier: 0.5)
    }
    
    private func updateProgressWidth(multiplier: CGFloat) {
        progressWidthConstraint?.isActive = false
        
        // Use a safe minimum multiplier to avoid Auto Layout warnings for 0-width constraints
        let safeMultiplier = max(0.0001, min(1.0, multiplier))
        progressWidthConstraint = progressView.widthAnchor.constraint(equalTo: progressContainer.widthAnchor, multiplier: safeMultiplier)
        progressWidthConstraint?.isActive = true
    }
    
    func showVolume(_ volume: Float, isMuted: Bool) {
        // Ensure values run on the main thread
        DispatchQueue.main.async {
            let percent = Int(round(volume * 100))
            self.percentLabel.stringValue = isMuted ? "Muted" : "\(percent)%"
            
            // Update progress bar
            let fillMultiplier = isMuted ? 0.0 : CGFloat(volume)
            self.updateProgressWidth(multiplier: fillMultiplier)
            
            // Update Icon based on volume & mute state
            let systemSymbol: String
            if isMuted {
                systemSymbol = "speaker.slash.fill"
            } else if volume == 0 {
                systemSymbol = "speaker.fill"
            } else if volume < 0.33 {
                systemSymbol = "speaker.wave.1.fill"
            } else if volume < 0.67 {
                systemSymbol = "speaker.wave.2.fill"
            } else {
                systemSymbol = "speaker.wave.3.fill"
            }
            
            if let iconImage = NSImage(systemSymbolName: systemSymbol, accessibilityDescription: nil) {
                iconImage.isTemplate = true
                self.volumeIcon.image = iconImage
            }
            
            // Center HUD at the bottom center of the active screen
            if let screen = NSScreen.main {
                let screenRect = screen.frame
                let windowRect = self.frame
                let x = screenRect.origin.x + (screenRect.width - windowRect.width) / 2
                let y = screenRect.origin.y + (screenRect.height - windowRect.height) / 4
                self.setFrameOrigin(NSPoint(x: x, y: y))
            }
            
            // Make the HUD visible
            self.orderFront(nil)
            
            // Cancel existing animations/timers
            self.fadeTimer?.invalidate()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                self.animator().alphaValue = 1.0
            }
            
            // Set fade out timer
            self.fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    self.animator().alphaValue = 0.0
                }, completionHandler: {
                    if self.alphaValue == 0.0 {
                        self.orderOut(nil)
                    }
                })
            }
        }
    }
}
