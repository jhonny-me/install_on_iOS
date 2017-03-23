//
//  File.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation
import AppKit

class DeviceManager {
    let type: DeviceType
    
    init(type: DeviceType) {
        self.type = type
    }
    
    func start(_ operation: DeviceManager.Operation, output: ((String) -> Void)? = nil) throws -> Any? {
        switch operation {
        case .search:
            return searchForIOSDevices()
        case .install(let phones, let path):
            phones.forEach({ phone in
                _ = installOnIOS(with: path, on: phone.uuid, output: output)
            })
        case .uninstall(let phones, let appID):
            phones.forEach({ phone in
                _ = uninstallOnIOS(with: appID, from: phone.uuid, output: output)
            })
        }
        return nil
    }
}
extension DeviceManager {
    
    func searchForIOSDevices() -> [String] {
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
    
    func searchForAndroidDevices() -> [String] {
        return []
    }
    
    func installOnIOS(with appPath: String, on device: String, output: ((String) -> Void)? = nil) -> Bool {
        let path = "/usr/local/bin/mobiledevice"
        let process = Process()
        let standardOutput = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardOutput
        process.launchPath = path
        process.arguments = ["install_app", "-u", device, appPath]
        process.launch()
        process.waitUntilExit()
        let data = standardOutput.fileHandleForReading.readDataToEndOfFile()
        output?(Log.startInstallString(appPath: appPath, device: device))
        guard let string = String.init(data: data, encoding: .utf8) else {
            output?(Log.errorString())
            return false
        }
        output?(Log.stringWithDate(string))
        return string.contains("OK")
    }
    
    func uninstallOnIOS(with appIdentifier: String, from device: String, output: ((String) -> Void)? = nil) -> Bool {
        let path = "/usr/local/bin/mobiledevice"
        let process = Process()
        let standardOutput = Pipe()
        process.standardOutput = standardOutput
        process.launchPath = path
        process.arguments = ["uninstall_app", "-u", device, appIdentifier]
        process.launch()
        process.waitUntilExit()
        let data = standardOutput.fileHandleForReading.readDataToEndOfFile()
        output?(Log.startUninstallString(appID: appIdentifier, device: device))
        guard let string = String.init(data: data, encoding: .utf8) else {
            output?(Log.errorString())
            return false
        }
        output?(Log.stringWithDate(string))
        return string.contains("OK")
    }
}

extension DeviceManager {
    enum Operation {
        case search
        case install([Phone], String)
        case uninstall([Phone], String)
    }
    enum DeviceType: String {
        case iOS
        case android
    }
}

extension DeviceManager.Operation: Equatable {}

func ==(lhs: DeviceManager.Operation, rhs: DeviceManager.Operation) -> Bool {
    switch (lhs, rhs) {
    case (.search, .search):
        return true
    case (.install(_,_), .install(_, _)):
        return true
    case (.uninstall(_,_), .uninstall(_,_)):
        return true
    default:
        return false
    }
}

enum Log {
    static func stringWithDate(_ logs: String) -> String{
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        let dateString = formatter.string(from: date)
        return "\(dateString) : \(logs) \n"
    }
    static func startInstallString(appPath: String, device: String) -> String {
        return stringWithDate("Start install \(appPath) to \(device)")
    }
    static func errorString() -> String {
        return stringWithDate("Unknown error")
    }
    static func startUninstallString(appID: String, device: String) -> String {
        return stringWithDate("Start uinstall \(appID) from \(device)")
    }
}

struct Phone {
    var uuid: String
    var alias: String = ""
    var type: DeviceManager.DeviceType = .iOS
}

extension Phone {
    init(uuid: String) {
        self.uuid = uuid
    }
    
    init?(_ json: [String: String]) {
        guard let uuid = json["uuid"] else { return nil }
        self.uuid = uuid
        alias = json["alias"] ?? ""
        type = DeviceManager.DeviceType(rawValue: json["type"] ?? "iOS")!
    }
    
    func archive() -> [String: String] {
        return ["uuid": uuid, "alias": alias, "type": type.rawValue]
    }
}

extension String {
    func makeRed(_ string: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: self)
        attr.addAttribute(NSForegroundColorAttributeName, value: NSColor.red, range: (self as NSString).range(of: string))
        return attr
    }
}
