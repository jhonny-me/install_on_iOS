//
//  File.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation

struct DeviceManager {
    enum SearchType {
        case iOS
        case android
    }
    static func search(for type: SearchType) -> [String] {
        switch type {
        case .android:
            return []
        case .iOS:
            return searchForIOS()
        }
    }
    
    static func searchForIOS() -> [String] {
        let path = "/usr/local/bin/mobiledevice"
        let process = Process()
        let output = Pipe()
        process.standardOutput = output
        process.launchPath = path
        process.arguments = ["list_devices"]
        process.launch()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let string = String.init(data: data, encoding: .utf8) else { return [] }
        let array = string.components(separatedBy: "\n").dropLast()
        let uuids = [String](array)
        print("devices: \(array)")
        AppDelegate.devices = uuids.map(Phone.init)
        return uuids
    }
    
    static func install(with appName: String, on device: String) -> Bool {
        let path = "/usr/local/bin/mobiledevice"
        let process = Process()
        let output = Pipe()
        process.standardOutput = output
        process.launchPath = path
        process.arguments = ["install_app", "-u", device, appName]
        process.launch()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard
            let string = String.init(data: data, encoding: .utf8),
            string.contains("OK")
        else { return false }
        
        print("install result: \(string)")
        return true
    }
}

struct Phone {
    var uuid: String
    var alias: String = ""
    var type: String = "iOS"
}

extension Phone {
    init(uuid: String) {
        self.uuid = uuid
    }
    
    init?(_ json: [String: String]) {
        guard let uuid = json["uuid"] else { return nil }
        self.uuid = uuid
        alias = json["alias"] ?? ""
        type = json["type"] ?? ""
    }
    
    func archive() -> [String: String] {
        return ["uuid": uuid, "alias": alias, "type": type]
    }
}
