import Cocoa

class AppManager {
    static let delegate = AppDelegate()
}

NSApplication.shared.delegate = AppManager.delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
