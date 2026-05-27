import Cocoa
import WebKit

final class PreferencesController: NSObject, WKScriptMessageHandler {
    static let shared = PreferencesController()
    
    var window: NSWindow?
    var webView: WKWebView?
    
    func showWindow() {
        if window == nil {
            let width: CGFloat = 800
            let height: CGFloat = 480
            let screenRect = NSScreen.main?.visibleFrame ?? .zero
            let rect = NSRect(x: (screenRect.width - width) / 2, y: (screenRect.height - height) / 2, width: width, height: height)
            
            let win = NSWindow(contentRect: rect,
                               styleMask: [.titled, .closable, .miniaturizable],
                               backing: .buffered,
                               defer: false)
            win.title = "TouchBarCustomizer Preferences"
            win.titlebarAppearsTransparent = true
            win.isMovableByWindowBackground = true
            win.backgroundColor = NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
            
            let config = WKWebViewConfiguration()
            let contentController = WKUserContentController()
            contentController.add(self, name: "swiftBridge")
            config.userContentController = contentController
            
            let web = WKWebView(frame: win.contentView!.bounds, configuration: config)
            web.autoresizingMask = [.width, .height]
            web.setValue(false, forKey: "drawsBackground") // Make background transparent
            
            win.contentView?.addSubview(web)
            self.webView = web
            self.window = win
            
            // Load index.html from bundle resources
            if let indexURL = Bundle.main.url(forResource: "index", withExtension: "html") {
                web.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
            } else {
                NSLog("ERROR: Could not find index.html in bundle resources.")
            }
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Let it load, then query config (delay briefly to ensure page is loaded)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendConfigToWeb()
        }
    }
    
    private func sendConfigToWeb() {
        let path = "/Users/liyiyuan/.gemini/antigravity/scratch/TouchBarCustomizer/config.json"
        guard let configString = try? String(contentsOfFile: path, encoding: .utf8) else { return }
        
        // Escape configuration string for JavaScript execution
        let escaped = configString.replacingOccurrences(of: "\\", with: "\\\\")
                                  .replacingOccurrences(of: "\"", with: "\\\"")
                                  .replacingOccurrences(of: "\n", with: "\\n")
                                  .replacingOccurrences(of: "\r", with: "")
        
        webView?.evaluateJavaScript("loadConfig('\(escaped)')", completionHandler: { _, error in
            if let error = error {
                NSLog("JS Eval Error: \(error)")
            }
        })
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let action = dict["action"] as? String else { return }
        
        if action == "saveConfig", let configData = dict["config"] as? String {
            let path = "/Users/liyiyuan/.gemini/antigravity/scratch/TouchBarCustomizer/config.json"
            do {
                try configData.write(toFile: path, atomically: true, encoding: .utf8)
                NSLog("Configuration saved successfully.")
                
                // Live reload Touch Bar
                DispatchQueue.main.async {
                    TouchBarManager.shared.loadConfig()
                    TouchBarManager.shared.present()
                }
            } catch {
                NSLog("Error saving configuration: \(error)")
            }
        } else if action == "getConfig" {
            sendConfigToWeb()
        }
    }
}
