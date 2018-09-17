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
            guard let data = UserDefaults.standard.data(forKey: devicesKey) else { return [] }
            return (try? APIManager.default.jsonDecoder.decode([Phone].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: devicesKey)
            }
        }
    }
    static var tokens: [Token] {
        get {
            guard let data = UserDefaults.standard.data(forKey: tokenKey) else { return [] }
            return (try? APIManager.default.jsonDecoder.decode([Token].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: tokenKey)
            }
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
        
        AndroidDeviceOperator().startService()
        if !FileManager.default.fileExists(atPath: AppDelegate.downloadPath) {
            do {
                try FileManager.default.createDirectory(atPath: AppDelegate.downloadPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSAlert.show(error)
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

