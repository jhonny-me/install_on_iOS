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
    var operation: DeviceManager.Operation = .search
    
    static func initWith(_ operation: DeviceManager.Operation) -> ProgressViewController {
        let viewcontroller = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ProgressViewController") as! ProgressViewController
        viewcontroller.operation = operation
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
        DispatchQueue.global().async {
            do {
                _ = try DeviceManager(type: .iOS).start(self.operation) { log in
                    DispatchQueue.main.async {
                        let timeString = log.components(separatedBy: " : ").first!
                        self.logArea.textStorage?.append(log.makeRed(timeString))
                    }
                }
                self.cancelBtn.isEnabled = false
                self.okBtn.isEnabled = true
            } catch {
                DispatchQueue.main.async {
                    NSAlert(error: error).runModal()
                }
                self.cancelBtn.isEnabled = false
                self.okBtn.isEnabled = true
            }
        }
        
//        let logPath = AppDelegate.downloadPath + "/tmp.logs"
//        okBtn.isEnabled = false
//        DispatchQueue.global().async {
//            FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
//            let output = FileHandle.init(forUpdatingAtPath: logPath)!
//            self.devices.forEach { phone in
////                _ = DeviceManager.install(with: self.appPath, on: phone.uuid, output: output)
//                let data = output.readDataToEndOfFile()
//                guard let string = String.init(data: data, encoding: .utf8) else { return }
//                NSLog("logsss: \(string)")
//                self.logArea.stringValue = "Start install:\n" + string
//            }
//            output.closeFile()
//            self.cancelBtn.isEnabled = false
//            self.okBtn.isEnabled = true
//        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
    }
    
}
