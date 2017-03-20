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
    static var downloadPath: String {
        get {
            return UserDefaults.standard.object(forKey: downloadPathKey) as? String ?? defaultDownloadPath
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


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        try! FileManager.default.createDirectory(atPath: AppDelegate.downloadPath, withIntermediateDirectories: true, attributes: nil)
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

