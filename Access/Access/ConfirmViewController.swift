//
//  ConfirmViewController.swift
//  Access
//
//  Created by Johnny Gu on 21/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class ConfirmViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    weak var checkboxAll: NSButton!
    var devices: [Phone] = []
    var selectedIndexes: [Int] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        let checkBox = NSButton.init(checkboxWithTitle: "Select All", target: self, action: #selector(selectAllDevices))
        checkBox.state = NSOnState
        checkBox.frame.origin = CGPoint(x: 0, y: 2)
        tableView.headerView?.addSubview(checkBox)
        self.checkboxAll = checkBox
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        devices = AppDelegate.devices
        
        for (index, _) in devices.enumerated() {
            selectedIndexes.append(index)
        }
        tableView.reloadData()
    }
    func selectAllDevices(_ sender: Any) {
        if checkboxAll.state == NSOnState {
            for (index, _) in devices.enumerated() {
                selectedIndexes.append(index)
            }
        }else {
            selectedIndexes.removeAll()
        }
        tableView.reloadData()
    }
    
    @IBAction func continueAction(_ sender: Any) {
        let viewcontroller = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ProgressViewController") as! ProgressViewController
        var selectedDevices: [Phone] = []
        selectedIndexes.forEach { index in
            selectedDevices.append(self.devices[index])
        }
        viewcontroller.devices = selectedDevices
        presentViewControllerAsSheet(viewcontroller)
    }
}

extension ConfirmViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn == tableView.tableColumns.first {
            let cell = tableView.make(withIdentifier: "CheckCell", owner: self) as? CheckCell
            cell?.checked = selectedIndexes.contains(row)
            cell?.checkValuedChanged = { [unowned self] state in
                if self.selectedIndexes.contains(row) && state == false {
                    self.selectedIndexes.remove(at: self.selectedIndexes.index(of: row)!)
                }else if !self.selectedIndexes.contains(row) && state == true {
                    self.selectedIndexes.append(row)
                }
                self.tableView.reloadData(forRowIndexes: [row], columnIndexes: [0])
            }
            return cell
        }else if tableColumn == tableView.tableColumns[1] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = devices[row].uuid
            return cell
        }else if tableColumn == tableView.tableColumns[2] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = devices[row].type
            return cell
        }else {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = devices[row].alias
            return cell
        }
    }
}

class CheckCell: NSTableCellView {
    
    @IBOutlet weak var checkbox: NSButton!
    var checked: Bool {
        set {
            checkbox.state = newValue ? NSOnState : NSOffState
        }
        get {
            return checkbox.state == NSOnState
        }
    }
    var checkValuedChanged: ((Bool) -> Void)?
    
    @IBAction func checkAction(_ sender: Any) {
        checkValuedChanged?(checkbox.state == NSOnState)
    }
}
