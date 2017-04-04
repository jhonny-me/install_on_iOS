//
//  AppDelegate.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    static let defaultDownloadPath = "~/Downloads/Access"
    static let downloadPathKey = "com.johnny.Access.downloadPath"
    static let devicesKey = "com.johnny.Access.devices"
    static let tokenKey = "com.johnny.Access.token"
    static let inuseTokenIndexKey = "com.johnny.Access.inuseTokenIndexKey"
    static var downloadPath: String {
        get {
            let path = UserDefaults.standard.object(forKey: downloadPathKey) as? String ?? defaultDownloadPath
            let resolvedPath = (path as NSString).expandingTildeInPath
            return resolvedPath
        }
        set {
            UserDefaults.standard.set(newValue, forKey: downloadPathKey)
        }
    }
    static var devices: [Phone] {
        get {
            return (UserDefaults.standard.object(forKey: devicesKey) as? [[String: String]])?.flatMap({Phone($0)}) ?? []
        }
        set {
            let jsons = newValue.map {
                return $0.archive()
            }
            UserDefaults.standard.set(jsons, forKey: devicesKey)
        }
    }
    static var tokens: [Token] {
        get {
            guard let jsons = UserDefaults.standard.array(forKey: tokenKey) as? [[String: String]] else { return [] }
            return jsons.map(Token.init)
        }
        set {
            UserDefaults.standard.set(newValue.map({$0.archive()}), forKey: tokenKey)
        }
    }
    static var inuseTokenIndex: Int {
        get {
            let index = UserDefaults.standard.integer(forKey: inuseTokenIndexKey) 
            if tokens.count < index - 1 {
                return 0
            }
            return index
        }
        set {
            UserDefaults.standard.set(newValue, forKey: inuseTokenIndexKey)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        
        print(FileManager.default.fileExists(atPath: AppDelegate.downloadPath))
        if !FileManager.default.fileExists(atPath: AppDelegate.downloadPath) {
            do {
                try FileManager.default.createDirectory(atPath: AppDelegate.downloadPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSAlert.init(error: error).runModal()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

