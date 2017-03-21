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
    @IBOutlet weak var logArea: NSTextField!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var okBtn: NSButton!
    var devices: [Phone] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        let appPath = AppDelegate.downloadPath + "/Starbucks.ipa"
        let logPath = AppDelegate.downloadPath + "/tmp.logs"
        okBtn.isEnabled = false
        DispatchQueue.global().async {
            FileManager.default.createFile(atPath: logPath, contents: nil, attributes: nil)
            let output = FileHandle.init(forUpdatingAtPath: logPath)!
            self.devices.forEach { phone in
                _ = DeviceManager.install(with: appPath, on: phone.uuid, output: output)
                let data = output.readDataToEndOfFile()
                guard let string = String.init(data: data, encoding: .utf8) else { return }
                NSLog("logsss: \(string)")
                self.logArea.stringValue = "Start install:\n" + string
            }
            output.closeFile()
            self.cancelBtn.isEnabled = false
            self.okBtn.isEnabled = true
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
    }
    
}
