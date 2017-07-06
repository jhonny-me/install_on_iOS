//
//  ProgressViewController.swift
//  Access
//
//  Created by Johnny Gu on 21/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class ProgressViewController: NSViewController {

    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var logArea: NSTextView!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var okBtn: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    var operation: DeviceManager.Operation = .search
    var deviceManager: DeviceManager!
    
    static func initWith(_ operation: DeviceManager.Operation, manager: DeviceManager) -> ProgressViewController {
        let viewcontroller = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ProgressViewController") as! ProgressViewController
        viewcontroller.operation = operation
        viewcontroller.deviceManager = manager
        return viewcontroller
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        switch operation {
        case .install(_, let appPath):
            label.attributedStringValue = "Installing \(appPath) ".makeRed(appPath)
        case .uninstall(_, let appID):
            label.attributedStringValue = "Uninstalling \(appID) ".makeRed(appID)
        default:
            break
        }
    }
    
    override func viewDidAppear() {
        okBtn.isEnabled = false
        progressBar.startAnimation(nil)
        DispatchQueue.global().async {
            do {
                _ = try self.deviceManager.start(self.operation) { log in
                    DispatchQueue.main.async {
                        let timeString = log.components(separatedBy: " : ").first!
                        self.logArea.textStorage?.append(log.makeRed(timeString))
                    }
                }
                self.cancelBtn.isEnabled = false
                self.okBtn.isEnabled = true
                self.progressBar.stopAnimation(nil)
            } catch {
                DispatchQueue.main.async {
                    NSAlert(error: error).runModal()
                }
                self.cancelBtn.isEnabled = false
                self.okBtn.isEnabled = true
                self.progressBar.stopAnimation(nil)
            }
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        deviceManager.cancelCurrenOperation()
    }
    
}
