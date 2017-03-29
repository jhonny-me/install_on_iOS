//
//  DragAcceptView.swift
//  Access
//
//  Created by Johnny Gu on 29/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa


class DragAcceptView: NSView {
    lazy var draggingHintView: NSView! = {
        let view = NSView(frame: self.bounds)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(red: 0, green: 0, blue: 0, alpha: 0.8).cgColor
        view.isHidden = true
        self.addSubview(view)
        return view
    }()
    var shouldStartInstall: ((String) -> Void)?
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        draggingHintView.isHidden = false
        if
            let types = sender.draggingPasteboard().types,
            types.contains(NSFilenamesPboardType),
            sender.draggingSourceOperationMask().contains(.link) {
            guard
                let filePathes = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? [String],
                filePathes.count == 1 else { return NSDragOperation() }
            return .link
        }
        return NSDragOperation()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        draggingHintView.isHidden = true
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        draggingHintView.isHidden = true
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard
            let filePathes = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? [String],
            let appPath = filePathes.first,
            appPath.hasSuffix("ipa") || appPath.hasSuffix(".apk")
        else {
            let alert = NSAlert(error: DragError.notSupportType)
            alert.messageText = DragError.notSupportType.localizedDescription
            alert.runModal()
            return false
        }
        shouldStartInstall?(appPath)
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
}

extension DragAcceptView {
    enum DragError: Error {
        case tooManyFiles
        case notSupportType
    
        var localizedDescription: String {
            get {
                switch self {
                case .tooManyFiles:
                    return "Only support one file at a time"
                case .notSupportType:
                    return "Only support ipa and apk format file"
                }
            }
        }
    }
}
