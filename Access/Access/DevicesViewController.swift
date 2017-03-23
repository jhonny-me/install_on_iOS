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
    var uuids: [Phone] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        uuids = AppDelegate.devices
        tableView.reloadData()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        AppDelegate.devices = uuids
    }
    
    @IBAction func searchDevices(_ sender: Any) {

        guard let uuids = (try? DeviceManager(type: .iOS).start(.search)) as? [Phone] else { return }
        self.uuids = uuids
        tableView.reloadData()
    }

    @IBAction func historyAction(_ sender: Any) {
        
    }
}

extension DevicesViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return uuids.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn == tableView.tableColumns[0] {
            guard let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView else { return NSView() }
            cell.textField?.stringValue = uuids[row].uuid
            return cell
        }else {
            guard let cell = tableView.make(withIdentifier: "EditableTextFieldCellView", owner: self) as? EditableTextFieldCellView else { return NSView() }
            if tableColumn == tableView.tableColumns[1] {
                cell.textField?.stringValue = uuids[row].alias
                cell.textDidChangeCallback = { [unowned self] string in
                    self.uuids[row].alias = string
                }
            }else if tableColumn == tableView.tableColumns[2] {
                cell.textField?.stringValue = uuids[row].type.rawValue
                cell.textDidChangeCallback = { [unowned self] string in
                    self.uuids[row].type = DeviceManager.DeviceType(rawValue: string) ?? .iOS
                }
            }else if tableColumn == tableView.tableColumns[3] {
                cell.textField?.stringValue = uuids[row].model
                cell.textDidChangeCallback = { [unowned self] string in
                    self.uuids[row].model = string
                }
            }else if tableColumn == tableView.tableColumns[4] {
                cell.textField?.stringValue = uuids[row].system
                cell.textDidChangeCallback = { [unowned self] string in
                    self.uuids[row].system = string
                }
            }
            return cell
        }
    }
}

class EditableTextFieldCellView: NSTableCellView {
    var textDidChangeCallback: ((String) -> Void)?
}

extension EditableTextFieldCellView: NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        guard let textfield = obj.object as? NSTextField else { return }
        textDidChangeCallback?(textfield.stringValue)
    }
}
