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
    static let appidKey = "com.johnny.Access.appid"
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
    static var token: String? {
        get {
            return UserDefaults.standard.string(forKey: tokenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: tokenKey)
        }
    }
    static var appid: String? {
        get {
            return UserDefaults.standard.string(forKey: appidKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: appidKey)
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


}

