//
//  TokenAndKeyConfigureView.swift
//  Access
//
//  Created by Johnny Gu on 24/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class TokenAndKeyConfigureView: NSView {
    
    @IBOutlet var view: NSView!
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var idTextField: NSTextField!
    @IBOutlet weak var appIdentiferTextField: NSTextField!
    @IBOutlet weak var inUseBtn: NSButton!
    var didTokenUpdated: ((Token) -> Void)?
    var didInuseChanged: Handler?
    var token: Token?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initConfigure()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initConfigure()
    }
    
    override func layoutSubtreeIfNeeded() {
        super.layoutSubtreeIfNeeded()
        view.frame = bounds
    }
    
    private func initConfigure() {
        Bundle.main.loadNibNamed("TokenAndKeyConfigureView", owner: self, topLevelObjects: nil)
        addSubview(view)
        view.frame = bounds
    }
    
    func configure(with token: Token, isInuse: Bool) {
        tokenTextField.stringValue = token.token
        idTextField.stringValue = token.id
        appIdentiferTextField.stringValue = token.appIdentifier
        inUseBtn.state = isInuse ? NSOnState : NSOffState
        self.token = token
    }
    
    @IBAction func getAction(_ sender: Any) {
        APIManager.default.requestAppIdentifier(token: tokenTextField.stringValue, id: idTextField.stringValue) { result in
            result.failureHandler({ error in
                NSAlert.show(error)
            }).successHandler({ token in
                self.appIdentiferTextField.stringValue = token.appIdentifier
                self.token = token
                self.updateModel()
            })
        }
    }
    
    @IBAction func makeMain(_ sender: Any) {
        if inUseBtn.state == NSOffState {
            inUseBtn.state = NSOnState
            return
        }
        didInuseChanged?()
    }
    
    fileprivate func updateModel() {
        guard let type = self.token?.platform else { return }
        let token = Token(token: tokenTextField.stringValue, id: idTextField.stringValue, appIdentifier: appIdentiferTextField.stringValue, platform: type)
        didTokenUpdated?(token)
    }
}


extension TokenAndKeyConfigureView: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else { return }
        if textfield == tokenTextField ||
            textfield == idTextField ||
            textfield == appIdentiferTextField {
            updateModel()
        }
    }
}
