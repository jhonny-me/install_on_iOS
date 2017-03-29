//
//  ViewController.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class HomeViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    var versions: [HockeyApp] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.register(forDraggedTypes: [NSFilenamesPboardType])
        (view as! DragAcceptView).shouldStartInstall = { appPath in
            self.install(from: appPath)
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
    
    private func install(from path: String) {
        let vc = ConfirmViewController.initWith(.install([], path), devices: AppDelegate.devices)
        presentViewControllerAsSheet(vc)
    }
    
    @IBAction func refreshAction(_ sender: Any) {
        progressIndicator.startAnimation(nil)
        APIManager.default.requestVersions { result in
            self.progressIndicator.stopAnimation(nil)
            switch result {
            case .failure(let error):
                NSAlert.init(error: error).runModal()
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
        let vc = ConfirmViewController.initWith(.uninstall([], token.appIdentifier), devices: AppDelegate.devices)
        presentViewControllerAsSheet(vc)
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
                APIManager.default.download(from: self.versions[row].downloadURLString, to: filePath, progress: { progress in
                    cell?.setProgress(progress)
                    NSLog("progress: \(progress)")
                }) { result in
                    result.failureHandler({ error in
                        NSAlert(error: error).runModal()
                    }).successHandler({ pathURL in
                        cell?.config(with: self.versions[row])
                        NSLog("path: \(pathURL)")
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
            cell?.textField?.stringValue = versions[row].title
            return cell
        }else if tableColumn == tableView.tableColumns[2] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].build
            return cell
        }else if tableColumn == tableView.tableColumns[3] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].version
            return cell
        }else if tableColumn == tableView.tableColumns[4] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = versions[row].lastUpdatedAt
            return cell
        }else if tableColumn == tableView.tableColumns[5] {
            let cell = tableView.make(withIdentifier: "TextCell", owner: self) as? NSTableCellView
            cell?.textField?.attributedStringValue = versions[row].attributedNotes!
            cell?.textField?.sizeToFit()
            return cell
        }else { return nil }
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
    
    func config(with model: HockeyApp) {
        let exists = FileManager.default.fileExists(atPath: AppDelegate.downloadPath + "/" + model.filename)
        downloadBtn.title = exists ? "update" : "download"
        installBtn.isEnabled = exists
    }
    @IBAction func installAction(_ sender: Any) {
        shouldStartInstallCallback?()
    }
    
    @IBAction func downloadAction(_ sender: Any) {
        shouldStartDownloadCallback?()
    }
}

