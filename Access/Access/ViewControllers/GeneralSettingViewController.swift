//
//  GeneralSettingViewController.swift
//  Access
//
//  Created by Johnny Gu on 04/04/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class GeneralSettingViewController: NSViewController {
    
    @IBOutlet weak var workDirTextField: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        workDirTextField.stringValue = AppDelegate.downloadPath
    }
    
    @IBAction func showInFinder(_ sender: Any) {
        
        NSWorkspace.shared().selectFile(AppDelegate.downloadPath, inFileViewerRootedAtPath: "")
    }
}

extension GeneralSettingViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else { return }
        if textfield == workDirTextField {
            AppDelegate.downloadPath = workDirTextField.stringValue
        }
    }
}
