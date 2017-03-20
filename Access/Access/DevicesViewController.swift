//
//  DevicesViewController.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class DevicesViewController: NSViewController {

    @IBOutlet weak var button: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    var uuids: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func searchDevices(_ sender: Any) {

        uuids = DeviceManager.search(for: .iOS)
        tableView.reloadData()
    }

    @IBAction func installAction(_ sender: Any) {
        let appPath = AppDelegate.downloadPath + "/Starbucks.ipa"
        uuids.forEach { (uuid) in
            print(DeviceManager.install(with: appPath, on: uuid))
            
        }
    }
}

extension DevicesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return uuids.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.make(withIdentifier: "BaseCell", owner: self) as? NSTableCellView else { return NSView() }
        cell.textField?.stringValue = uuids[row]
        return cell
    }
}
