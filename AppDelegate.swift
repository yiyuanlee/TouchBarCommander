import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    
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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the system menu bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = createRocketImage()
        }
        
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: "Toggle Touch Bar", action: #selector(toggleTouchBar), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let reloadItem = NSMenuItem(title: "Reload Config", action: #selector(reloadConfig), keyEquivalent: "r")
        reloadItem.target = self
        menu.addItem(reloadItem)
        
        let editItem = NSMenuItem(title: "Open config.json", action: #selector(editConfig), keyEquivalent: "e")
        editItem.target = self
        menu.addItem(editItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
        
        // Register standard and custom items
        TouchBarManager.shared.setupControlStrip()
        TouchBarManager.shared.loadConfig()
        TouchBarManager.shared.present()
        
        print("TouchBarCustomizer application did finish launching.")
    }
    
    @objc func toggleTouchBar() {
        TouchBarManager.shared.toggleTouchBar()
    }
    
    @objc func reloadConfig() {
        print("Reloading config.json configuration...")
        TouchBarManager.shared.loadConfig()
        // Force presentation refresh
        TouchBarManager.shared.present()
    }
    
    @objc func editConfig() {
        let path = "/Users/liyiyuan/.gemini/antigravity/scratch/TouchBarCustomizer/config.json"
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
    }
    
    @objc func quitApp() {
        print("Exiting application...")
        TouchBarManager.shared.dismiss()
        NSApplication.shared.terminate(nil)
    }
}
