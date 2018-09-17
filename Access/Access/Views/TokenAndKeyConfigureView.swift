//
//  TokenAndKeyConfigureView.swift
//  Access
//
//  Created by Johnny Gu on 24/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class TokenAndKeyConfigureView: NSView {
    
    @IBOutlet weak var popupBtn: NSPopUpButton!
    @IBOutlet var view: NSView!
    @IBOutlet weak var localTokenTextField: NSTextField!
    @IBOutlet weak var localIdTextField: NSTextField!
    @IBOutlet weak var localAppIdentifierTextField: NSTextField!
    @IBOutlet weak var getIdBtn: NSButton!
    @IBOutlet weak var tokenTextField: NSTextField!
    @IBOutlet weak var idTextField: NSTextField!
    @IBOutlet weak var appIdentiferTextField: NSTextField!
    @IBOutlet weak var inUseBtn: NSButton!
    @IBOutlet weak var saveBtn: NSButton!
    var didTokenUpdated: ((Token) -> Void)?
    var didInuseChanged: Handler?
    var token: Token?
    var kind: Token.Kind = .hockeyApp
    
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
        updateView(with: .hockeyApp)
    }
    
    func configure(with token: Token, isInuse: Bool) {
        tokenTextField.stringValue = token.token
        idTextField.stringValue = token.id
        appIdentiferTextField.stringValue = token.extraInfo
        inUseBtn.state = isInuse ? NSOnState : NSOffState
        self.token = token
        updateView(with: token.kind)
    }

    private func updateView(with type: Token.Kind) {
        switch type {
        case .hockeyApp:
            localTokenTextField.stringValue = "Token from HockeyApp"
            localIdTextField.stringValue = "AppID from HockeyApp"
            localAppIdentifierTextField.stringValue = "App Bundle ID"
            getIdBtn.isHidden = false
        case .buddyBuild:
            localTokenTextField.stringValue = "Token from BuddyBuild"
            localIdTextField.stringValue = "AppID from BuddyBuild"
            localAppIdentifierTextField.stringValue = "scheme"
            getIdBtn.isHidden = true
        }
    }
    
    @IBAction func getAction(_ sender: Any) {
        APIManager.default.requestAppIdentifier(token: tokenTextField.stringValue, id: idTextField.stringValue) { result in
            result.failureHandler({ error in
                NSAlert.show(error)
            }).successHandler({ token in
                self.appIdentiferTextField.stringValue = token.extraInfo
                self.token = token
                self.updateModel()
            })
        }
    }

    @IBAction func saveAction(_ sender: Any) {
        updateModel()
    }
    
    @IBAction func makeMain(_ sender: Any) {
        if inUseBtn.state == NSOffState {
            inUseBtn.state = NSOnState
            return
        }
        didInuseChanged?()
    }
    
    @IBAction func popupAction(_ sender: NSPopUpButton) {
        guard
            let title = sender.selectedItem?.title,
            let kind = Token.Kind(rawValue: title) else { return }
        self.kind = kind
        updateView(with: kind)
    }
    fileprivate func updateModel() {
        guard let type = self.token?.platform else { return }
        let token = Token(token: tokenTextField.stringValue, id: idTextField.stringValue, extraInfo: appIdentiferTextField.stringValue, platform: type, kind: kind)
        didTokenUpdated?(token)
    }
}

