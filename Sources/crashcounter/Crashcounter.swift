import ApplicationServices
import AppKit

@main
public struct Crashcounter {
    var counter = 0

    public static func main() {
        checkForAccessibilityEnabled()

        var counter = Crashcounter()

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                application.bundleIdentifier == "com.apple.dt.Xcode"
            else { return }

            Task {
                guard let crashReport = await waitForCrashReport() else { return }
                let reportElements = await waitForCrashWindow(application: crashReport)
                counter.closeReport(elements: reportElements)
            }
        }

        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }

    private mutating func closeReport(elements: [AXUIElement]) {
        counter += 1
        print("Xcode crashed. Total \(counter) times now.")
        for child in elements {
            let title: String? = child.copyAttribute(named: kAXTitleAttribute)
            guard title == "Reopen" else { continue }
            AXUIElementPerformAction(child, kAXPressAction as CFString)
        }
    }
}

func waitForCrashReport() async -> NSRunningApplication? {
    let clock = ContinuousClock()
    for _ in 0...10 {
        if let crashReport = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.UserNotificationCenter" }) {
            return crashReport
        }
        try? await clock.sleep(until: .now + .seconds(1))
    }

    return nil
}

func waitForCrashWindow(application: NSRunningApplication) async -> [AXUIElement] {
    let clock = ContinuousClock()
    while true {
        try? await clock.sleep(until: .now + .seconds(1))

        let element = AXUIElementCreateApplication(application.processIdentifier)
        guard
            let windows: [AXUIElement] = element.copyAttribute(named: kAXWindowsAttribute),
            let firstWindow = windows.first,
            let children: [AXUIElement] = firstWindow.copyAttribute(named: kAXChildrenAttribute)
        else { continue }
        for child in children {
            let value: String? = child.copyAttribute(named: kAXValueAttribute)
            if value == "Xcode quit unexpectedly." {
                return children
            }
        }
    }
}

private extension AXUIElement {
    func copyAttribute<Value>(named attributeName: String) -> Value? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, attributeName as CFString, &value) == .success else { return nil }

        return value as? Value
    }
}


func checkForAccessibilityEnabled() {
    let options = [
        kAXTrustedCheckOptionPrompt.takeRetainedValue(): true
    ]
    _ = !AXIsProcessTrustedWithOptions(options as CFDictionary)
}
