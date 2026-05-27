import Cocoa

// Disable stdout/stderr buffering so log output is immediate
setbuf(stdout, nil)
setbuf(stderr, nil)

final class App: NSObject {
    let statusBarItem: NSStatusItem
    let menu: NSMenu

    override init() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        menu = NSMenu()
        super.init()

        setupStatusBar()
        setupTouchBar()
        NSLog("TouchBarCommander ready.")
    }

    // MARK: - Status Bar

    private func createRocketImage() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        
        let path = NSBezierPath()
        // Rocket main body (70% scaled and centered)
        path.move(to: NSPoint(x: 9.0, y: 13.9))
        path.curve(to: NSPoint(x: 11.8, y: 7.6),
                   controlPoint1: NSPoint(x: 11.1, y: 11.8),
                   controlPoint2: NSPoint(x: 11.8, y: 9.7))
        path.line(to: NSPoint(x: 13.2, y: 5.5))
        path.line(to: NSPoint(x: 11.1, y: 6.2))
        path.line(to: NSPoint(x: 9.7, y: 4.8))
        path.line(to: NSPoint(x: 9.0, y: 6.2))
        path.line(to: NSPoint(x: 8.3, y: 4.8))
        path.line(to: NSPoint(x: 6.9, y: 6.2))
        path.line(to: NSPoint(x: 4.8, y: 5.5))
        path.line(to: NSPoint(x: 6.2, y: 7.6))
        path.curve(to: NSPoint(x: 9.0, y: 13.9),
                   controlPoint1: NSPoint(x: 6.2, y: 9.7),
                   controlPoint2: NSPoint(x: 6.9, y: 11.8))
        path.close()
        
        // Circular window cutout (70% scaled and centered)
        let windowPath = NSBezierPath(ovalIn: NSRect(x: 7.95, y: 8.3, width: 2.1, height: 2.1))
        path.append(windowPath)
        path.windingRule = .evenOdd
        
        NSColor.black.set()
        path.fill()
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private func setupStatusBar() {
        if let button = statusBarItem.button {
            button.image = createRocketImage()
        }

        addMenuItem("Toggle Touch Bar", action: #selector(toggleTouchBar), key: "t")
        addMenuItem("Customize Touch Bar...", action: #selector(openPreferences), key: "c")
        addMenuItem("Reload Config",    action: #selector(reloadConfig),   key: "r")
        addMenuItem("Open config.json", action: #selector(editConfig),     key: "e")
        menu.addItem(.separator())
        addMenuItem("Quit",             action: #selector(quitApp),        key: "q")

        statusBarItem.menu = menu
    }

    private func addMenuItem(_ title: String, action: Selector, key: String) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
    }

    // MARK: - Touch Bar

    private func setupTouchBar() {
        TouchBarManager.shared.setupControlStrip()
        TouchBarManager.shared.loadConfig()
    }

    // MARK: - Actions

    @objc func toggleTouchBar() {
        TouchBarManager.shared.toggleTouchBar()
    }

    @objc func openPreferences() {
        PreferencesController.shared.showWindow()
    }

    @objc func reloadConfig() {
        TouchBarManager.shared.loadConfig()
        TouchBarManager.shared.present()
    }

    @objc func editConfig() {
        let path = "/Users/liyiyuan/.gemini/antigravity/scratch/TouchBarCustomizer/config.json"
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    @objc func quitApp() {
        TouchBarManager.shared.dismiss()
        NSApplication.shared.terminate(nil)
    }
}

// ── Bootstrap ──────────────────────────────────────────────────────
let nsApp = NSApplication.shared
nsApp.setActivationPolicy(.accessory)

let myApp = App()

withExtendedLifetime(myApp) {
    nsApp.run()
}
