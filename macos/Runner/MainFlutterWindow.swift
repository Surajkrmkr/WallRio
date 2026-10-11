import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true

    var targetFrame = self.frame
    targetFrame.size = NSMakeSize(1280, 820)
    self.setFrame(targetFrame, display: true)
    self.minSize = NSMakeSize(960, 620)
    self.center()

    super.awakeFromNib()
  }
}
