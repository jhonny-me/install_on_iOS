//
//  ViewController.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class HomeViewController: NSViewController {
    @IBOutlet weak var tableView: MenuTableView!
    lazy var indicator: NSProgressIndicator = {
        let x = (self.view.frame.width - 100)/2
        let y = (self.view.frame.height - 100)/2
        let indicator = NSProgressIndicator(frame: CGRect(x: x, y: y, width: 100, height: 100))
        indicator.style = .spinningStyle
        indicator.isDisplayedWhenStopped = false
        self.view.addSubview(indicator)
        return indicator
    }()
    var versions: [DisplayableBuild] = []
    var triggleMenuCallback: (() -> ())?
    var orderingFlags: [String: Bool] = [
        "lastUpdatedAt" : false
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        view.register(forDraggedTypes: [NSFilenamesPboardType])
        (view as! DragAcceptView).shouldStartInstall = { appPath in
            self.install(from: appPath)
        }
        tableView.menuConfigClosure = { [unowned self] event in
            let row = self.tableView.row(at: self.tableView.convert(event.locationInWindow, to: nil))
            if row == -1 {
                return nil
            }else {
                if event.type == .rightMouseDown {
                    let version = self.versions[row]
                    let menu = NSMenu(title: "test")
                    if version.existsAtLocal {
                        menu.addItem(withTitle: "show in finder", action: #selector(self.showInFinder), keyEquivalent: "")
                    }
                    menu.addItem(withTitle: "copy download url", action: #selector(self.copyDownloadURL), keyEquivalent: "")
                    return menu
                }
            }
            return nil
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        refreshAction(self)

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @objc private func showInFinder() {
        guard tableView.realMenuIndex != -1 else { return }
        let filePath = self.versions[tableView.realMenuIndex].filepath
        guard let _ = URL(string: filePath) else { return }
        NSWorkspace.shared().selectFile(filePath, inFileViewerRootedAtPath: "")
    }
    @objc private func copyDownloadURL() {
        guard tableView.realMenuIndex != -1 else { return }
        let url = self.versions[tableView.realMenuIndex].copyURLString
        let pasteboard = NSPasteboard.general()
        pasteboard.declareTypes([NSPasteboardTypeString], owner: nil)
        if let url = url {
            pasteboard.setString(url, forType: NSPasteboardTypeString)
        }
    }

    private func install(from path: String) {
        let vc = ConfirmViewController.initWith(.install([], path), devices: AppDelegate.devices)
        presentViewControllerAsSheet(vc)
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        indicator.startAnimation(nil)
        APIManager.default.requestVersions { result in
            self.indicator.stopAnimation(nil)
            switch result {
            case .failure(let error):
                NSAlert.show(error)
            case .success(let devices):
                self.versions = devices
                self.tableView.reloadData()
            }
        }
    }

    @IBAction func installFromLocal(_ sender: Any) {
        let panel = NSOpenPanel()
        guard let window = NSApplication.shared().keyWindow else { return }
        panel.beginSheetModal(for: window){ result in
            if result == NSFileHandlingPanelOKButton {
                guard var path = panel.urls.first?.absoluteString else { return }
                if path.hasPrefix("file://") {
                    path = path.replacingOccurrences(of: "file://", with: "")
                }
                guard let _ = Phone.appType(from: path) else {
                    NSAlert(error: DragAcceptView.DragError.notSupportType).runModal()
                    return
                }
                self.install(from: path)
            }
        }
    }
    @IBAction func uninstall(_ sender: Any) {
        guard AppDelegate.tokens.count > 0 else { return }
        let token = AppDelegate.tokens[AppDelegate.inuseTokenIndex]
        let vc = ConfirmViewController.initWith(.uninstall([], token.extraInfo), devices: AppDelegate.devices)
        presentViewControllerAsSheet(vc)
    }
    
    @IBAction func triggleMenuAction(_ sender: NSButton) {
        triggleMenuCallback?()
        sender.title = sender.title == "open menu" ? "close menu" : "open menu"
    }
}

extension HomeViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return versions.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        guard let string = versions[row].attributedNotes else { return 30 }
        let height = string.boundingRect(with: NSSize(width: 400, height: 100000), options: [.usesLineFragmentOrigin, .usesFontLeading]).height
        return height < 30 ? 30 : height
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn == tableView.tableColumns[0] {
            let cell = tableView.make(withIdentifier: "ButtonCell", owner: self) as? ButtonCell
            cell?.shouldStartDownloadCallback = { [unowned self, weak cell] in
                let filePath = AppDelegate.downloadPath + "/" + self.versions[row].filename
                cell?.setProgress(0)
                guard let buildUrl = self.versions[row].downloadURL?.absoluteString else { return }
                APIManager.default.download(from: buildUrl, to: filePath, progress: { progress in
                    cell?.setProgress(progress)
                }) { result in
                    cell?.setProgress(1)
                    result.failureHandler({ error in
                        NSAlert(error: error).runModal()
                    }).successHandler({ pathURL in
                        cell?.config(with: self.versions[row])
                    })
                }
            }
            cell?.shouldStartInstallCallback = { [unowned self] in
                let path = AppDelegate.downloadPath + "/" + self.versions[row].filename
                let vc = ConfirmViewController.initWith(.install([], path), devices: AppDelegate.devices)
                self.presentViewControllerAsSheet(vc)
            }
            cell?.config(with: versions[row])
            return cell
        }else if tableColumn == tableView.tableColumns[1] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].titleDescription
            return cell
        }else if tableColumn == tableView.tableColumns[2] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].buildDescription
            return cell
        }else if tableColumn == tableView.tableColumns[3] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].versionDescription
            return cell
        }else if tableColumn == tableView.tableColumns[4] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].updateAtDescription
            return cell
        }else if tableColumn == tableView.tableColumns[5] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.attributedStringValue = versions[row].attributedNotes!
            cell?.textField?.sizeToFit()
            return cell
        }else { return nil }
    }
    
    func tableView(_ tableView: NSTableView, mouseDownInHeaderOf tableColumn: NSTableColumn) {
        if tableColumn == tableView.tableColumns[4] {
            guard let lastUpdateAtFlag = orderingFlags["lastUpdatedAt"] else {
                return
            }
            orderingFlags["lastUpdatedAt"] = !lastUpdateAtFlag
            versions.sort(by: { (lhs, rhs) -> Bool in
                return lastUpdateAtFlag ? lhs.updateAtDate < rhs.updateAtDate : lhs.updateAtDate > rhs.updateAtDate
            })
            tableView.reloadData()
        }
    }
    
    
}

class ButtonCell: NSTableCellView {
    @IBOutlet weak var downloadBtn: NSButton!
    @IBOutlet weak var installBtn: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    var shouldStartDownloadCallback: (() -> Void)?
    var shouldStartInstallCallback: (() -> Void)?
    
    func setProgress(_ progress: Double) {
        progressBar.isHidden = false
        downloadBtn.isHidden = true
        installBtn.isHidden = true
        progressBar.doubleValue = progress
        if progress > 0.9999999 {
            progressBar.isHidden = true
            downloadBtn.isHidden = false
            installBtn.isHidden = false
        }
    }
    
    func config(with model: DisplayableBuild) {
        downloadBtn.title = model.existsAtLocal ? "update" : "download"
        installBtn.isEnabled = model.existsAtLocal
    }
    @IBAction func installAction(_ sender: Any) {
        shouldStartInstallCallback?()
    }
    
    @IBAction func downloadAction(_ sender: Any) {
        shouldStartDownloadCallback?()
    }
}

class MenuTableView: NSTableView {
    var menuConfigClosure: ((NSEvent) -> NSMenu?)?
    var realMenuIndex: Int = -1
    override func menu(for event: NSEvent) -> NSMenu? {
        return menuConfigClosure?(event)
    }
    
    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        let row = self.row(at: convert(event.locationInWindow, to: nil))
        realMenuIndex = row
    }
}

