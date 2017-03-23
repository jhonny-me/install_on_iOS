//
//  SettingViewController.swift
//  Access
//
//  Created by Johnny Gu on 22/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class SettingViewController: NSViewController {

    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var idTextField: NSTextField!
    @IBOutlet weak var appIdentiferTextField: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if
            let token = AppDelegate.token,
            let id = AppDelegate.appid{
            tokenTextField.stringValue = token
            idTextField.stringValue = id
        }
        if let id = AppDelegate.appIdentifier {
            appIdentiferTextField.stringValue = id
        }
    }
    
    @IBAction func getAction(_ sender: Any) {
        APIManager.default.requestAppIdentifier { result in
            result.failureHandler({ error in
                NSAlert(error: error).runModal()
            }).successHandler({ string in
                self.appIdentiferTextField.stringValue = string
                AppDelegate.appIdentifier = string
            })
        }
    }
}

extension SettingViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else { return }
        if textfield == tokenTextField {
            AppDelegate.token = tokenTextField.stringValue
        }else if textfield == idTextField {
            AppDelegate.appid = idTextField.stringValue
        }else if textfield == appIdentiferTextField {
            AppDelegate.appIdentifier = appIdentiferTextField.stringValue
        }
    }
}
