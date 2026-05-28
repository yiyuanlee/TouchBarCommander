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
        // Rocket main body (95% scaled and centered)
        path.move(to: NSPoint(x: 9.0, y: 15.65))
        path.curve(to: NSPoint(x: 12.8, y: 7.1),
                   controlPoint1: NSPoint(x: 11.85, y: 12.8),
                   controlPoint2: NSPoint(x: 12.8, y: 9.95))
        path.line(to: NSPoint(x: 14.7, y: 4.25))
        path.line(to: NSPoint(x: 11.85, y: 5.2))
        path.line(to: NSPoint(x: 9.95, y: 3.3))
        path.line(to: NSPoint(x: 9.0, y: 5.2))
        path.line(to: NSPoint(x: 8.05, y: 3.3))
        path.line(to: NSPoint(x: 6.15, y: 5.2))
        path.line(to: NSPoint(x: 3.3, y: 4.25))
        path.line(to: NSPoint(x: 5.2, y: 7.1))
        path.curve(to: NSPoint(x: 9.0, y: 15.65),
                   controlPoint1: NSPoint(x: 5.2, y: 9.95),
                   controlPoint2: NSPoint(x: 6.15, y: 12.8))
        path.close()
        
        // Circular window cutout (95% scaled and centered)
        let windowPath = NSBezierPath(ovalIn: NSRect(x: 7.575, y: 8.05, width: 2.85, height: 2.85))
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
