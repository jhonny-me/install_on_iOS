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
    @IBOutlet weak var decripitionLabel: NSTextField!
    weak var checkboxAll: NSButton!
    var operation: DeviceManager.Operation = .search
    var devices: [Phone] = []
    var selectedIndexes: [Int] = []
    private var manager: DeviceManager!
    lazy var indicator: NSProgressIndicator = {
        let x = (self.view.frame.width - 100)/2
        let y = (self.view.frame.height - 100)/2
        let indicator = NSProgressIndicator(frame: CGRect(x: x, y: y, width: 100, height: 100))
        indicator.style = .spinningStyle
        indicator.isDisplayedWhenStopped = false
        self.view.addSubview(indicator)
        return indicator
    }()
    
    static func initWith(_ operation: DeviceManager.Operation, devices: [Phone]) -> ConfirmViewController {
        let vc = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ConfirmViewController") as! ConfirmViewController
        vc.operation = operation
        var platform = AppDelegate.tokens[AppDelegate.inuseTokenIndex].platform
        switch operation {
        case .install(_, let appPath):
            if let type = Phone.appType(from: appPath) {
                platform = type
            }
        default:
            break
        }
        vc.manager = DeviceManager( platform == .iOS ? IOSDeviceOperator() : AndroidDeviceOperator() )
        vc.devices = devices.filter({ $0.type == platform })

        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        switch operation {
        case .install(_, let appPath):
            
            decripitionLabel.attributedStringValue = "You will install \(appPath) into these devices".makeRed(appPath)
        case .uninstall(_, let appID):
            decripitionLabel.attributedStringValue = "You will uninstall \(appID) from these devices".makeRed(appID)
        default:
            break
        }
        
        let checkBox = NSButton(checkboxWithTitle: "Select All", target: self, action: #selector(selectAllDevices))
        checkBox.state = NSOnState
        checkBox.frame.origin = CGPoint(x: 0, y: 2)
        tableView.headerView?.addSubview(checkBox)
        self.checkboxAll = checkBox
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        indicator.startAnimation(nil)
        DispatchQueue.global().async {
            self.devices = (try? self.manager.start(.search)) as? [Phone] ?? self.devices

            for (index, _) in self.devices.enumerated() {
                self.selectedIndexes.append(index)
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.indicator.stopAnimation(nil)
            }
        }
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
        var newOperation: DeviceManager.Operation
        var selectedDevices: [Phone] = []
        selectedIndexes.forEach { index in
            selectedDevices.append(self.devices[index])
        }
        switch operation {
        case .install(_, let appPath):
            newOperation = .install(selectedDevices, appPath)
        case .uninstall(_, let appID):
            newOperation = .uninstall(selectedDevices, appID)
        case .search:
            newOperation = .search
        }
        let vc = ProgressViewController.initWith(newOperation, manager: manager!)
        presentViewControllerAsSheet(vc)
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
            cell?.textField?.stringValue = devices[row].type.rawValue
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
