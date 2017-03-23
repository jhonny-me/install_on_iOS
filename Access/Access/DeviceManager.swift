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
    
    func searchForIOSDevices() -> [Phone] {
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
        let jsons = uuids.map { uuid -> [String : String] in
            let extras = ["ProductVersion", "ProductType", "DeviceName"].map({ key in
                return getExtraInfo(key: key, for: uuid)
            })
            // check model
            var model: String
            switch extras[1] {
                case "iPhone4,1":
                    model = "iPhone 4S"
                case "iPhone5,1", "iPhone5,2":
                    model = "iPhone 5"
                case "iPhone5,3", "iPhone5,4":
                    model = "iPhone 5c"
                case "iPhone6,1", "iPhone6,2":
                    model = "iPhone 5s"
                case "iPhone7,1":
                    model = "iPhone 6 Plus"
                case "iPhone7,2":
                    model = "iPhone 6"
                case "iPhone8,1":
                    model = "iPhone 6s"
                case "iPhone8,2":
                    model = "iPhone 6s plus"
            default:
                model = "unknown"
            }
            
            return ["uuid": uuid, "alias": extras[2], "model": model, "system": extras[0]]
        }
        let devices = jsons.flatMap(Phone.init)
        AppDelegate.devices = devices
        return devices
    }
    
    func getExtraInfo(key: String, for id: String) -> String {
        let path = "/usr/local/bin/mobiledevice"
        let process = Process()
        let output = Pipe()
        process.standardOutput = output
        process.launchPath = path
        process.arguments = ["get_device_prop", "-u", id, key]
        process.launch()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        guard let string = String.init(data: data, encoding: .utf8) else { return "" }
        return string.trimmingCharacters(in: ["\n"])
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
    let uuid: String
    var alias: String = ""
    var type: DeviceManager.DeviceType = .iOS
    var model: String = ""
    var system: String = ""
    var appInstalled: Bool = false
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
        model = json["model"] ?? ""
        system = json["system"] ?? ""
        appInstalled = Bool(json["appInstalled"] ?? "false") ?? false
    }
    
    func archive() -> [String: String] {
        return ["uuid": uuid, "alias": alias, "type": type.rawValue, "model": model, "system": system, "appInstalled": appInstalled.description]
    }
}

extension String {
    func makeRed(_ string: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: self)
        attr.addAttribute(NSForegroundColorAttributeName, value: NSColor.red, range: (self as NSString).range(of: string))
        return attr
    }
}
