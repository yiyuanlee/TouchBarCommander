import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the system menu bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.title = "🎛️"
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
