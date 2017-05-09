//
//  HomeMenuViewController.swift
//  Access
//
//  Created by Johnny Gu on 09/05/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class HomeMenuViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    var apps: [Token] = []
    var didSelectToken: ((Token) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        tableView.doubleAction = #selector(tableViewDoubleClicked)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        apps = AppDelegate.tokens
        tableView.reloadData()
        
    }
    
    func tableViewDoubleClicked() {
        let row = tableView.clickedRow
        if row == -1 { return }
        AppDelegate.inuseTokenIndex = row
        didSelectToken?(apps[row])
    }
}

extension HomeMenuViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return apps.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "AppPreviewCell", owner: self) as? AppPreviewCell
        cell?.configure(with: apps[row])
        
        return cell
    }
    
//    tableviewdouble
}

class AppPreviewCell: NSTableCellView {
    
    func configure(with app: Token) {
        textField?.stringValue = app.appIdentifier
    }
}
