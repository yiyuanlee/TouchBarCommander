import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    
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
