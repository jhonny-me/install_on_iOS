//
//  File.swift
//  Access
//
//  Created by Johnny Gu on 19/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation
import AppKit

protocol DeviceOperational {
    weak var currentProcess: Process? {get}
    func searchDevices() -> [Phone]
    func getExtraInfo(from id: String, for key: String) -> String
    func install(on device: String, with appPath: String, output: ((String) -> Void)?) -> Bool
    func uninstall(from device: String, with appIdentifier: String, output: ((String) -> Void)?) -> Bool
}

class DeviceManager {
    let deviceOperator: DeviceOperational
    
    init(_ deviceOperator: DeviceOperational) {
        self.deviceOperator = deviceOperator
    }
    
    func start(_ operation: DeviceManager.Operation, output: ((String) -> Void)? = nil) throws -> Any? {
        switch operation {
        case .search:
            return deviceOperator.searchDevices()
        case .install(let phones, let path):
            phones.forEach({ phone in
                _ = deviceOperator.install(on: phone.uuid, with: path, output: output)
            })
        case .uninstall(let phones, let appID):
            phones.forEach({ phone in
                _ = deviceOperator.uninstall(from: phone.uuid, with: appID, output: output)
            })
        }
        return nil
    }

    func cancelCurrenOperation() {
        deviceOperator.currentProcess?.terminate()
    }
}


extension DeviceManager {
    enum Operation {
        case search
        case install([Phone], String)
        case uninstall([Phone], String)
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

class IOSDeviceOperator: DeviceOperational {
    weak var currentProcess: Process?
    func searchDevices() -> [Phone] {
        let data = baseOperate(arguments: ["list_devices"])
        guard let string = String.init(data: data, encoding: .utf8) else { return [] }
        let array = string.components(separatedBy: "\n").dropLast()
        let uuids = [String](Set(array))

        let jsons = uuids.map { uuid -> [String : String] in
            let extras = ["ProductVersion", "ProductType", "DeviceName"].map({ key in
                return getExtraInfo(from: uuid, for: key)
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

        return jsons.flatMap(Phone.init)
    }
    func getExtraInfo(from id: String, for key: String) -> String {
        let data = baseOperate(arguments: ["get_device_prop", "-u", id, key])
        guard let string = String.init(data: data, encoding: .utf8) else { return "" }
        return string.trimmingCharacters(in: ["\n"])
    }
    
    func install(on device: String, with appPath: String, output: ((String) -> Void)?) -> Bool {
        output?(Log.startInstallString(appPath: appPath, device: device))
        let data = baseOperate(arguments: ["install_app", "-u", device, appPath])
        guard let string = String.init(data: data, encoding: .utf8) else {
            output?(Log.errorString())
            return false
        }
        output?(Log.stringWithDate(string))
        return string.contains("OK")
    }
    
    func uninstall(from device: String, with appIdentifier: String, output: ((String) -> Void)?) -> Bool {
        output?(Log.startUninstallString(appID: appIdentifier, device: device))
        let data = baseOperate(arguments: ["uninstall_app", "-u", device, appIdentifier])
        guard let string = String.init(data: data, encoding: .utf8) else {
            output?(Log.errorString())
            return false
        }
        output?(Log.stringWithDate(string))
        return string.contains("OK")
    }
    
    func baseOperate(arguments: [String]) -> Data {
        let path = "/usr/local/bin/mobiledevice"
        let process = Process()
        let standardOutput = Pipe()
        process.standardOutput = standardOutput
        process.launchPath = path
        process.arguments = arguments
        process.launch()
        process.waitUntilExit()
        return standardOutput.fileHandleForReading.readDataToEndOfFile()
    }
}

class AndroidDeviceOperator: DeviceOperational {
    weak var currentProcess: Process?
    func startService() {
        _ = baseOperate(arguments: ["start-server"])
    }
    
    func searchDevices() -> [Phone] {
        let data = baseOperate(arguments: ["devices"])
        guard let string = String.init(data: data, encoding: .utf8) else { return [] }
        let array = string.components(separatedBy: "\n").dropFirst().dropLast(2)
        let uuids = array.map { aString in
            return aString.replacingOccurrences(of: "\tdevice", with: "")
        }
        let jsons = uuids.map { uuid -> [String : String] in
            let extras = ["ro.build.version.release", "ro.product.brand", "net.hostname"].map({ key in
                return getExtraInfo(from: uuid, for: key)
            })
            
            return ["uuid": uuid, "type": "android", "alias": extras[2], "model": extras[1], "system": extras[0]]
        }
        return jsons.flatMap(Phone.init)
    }
    
    func getExtraInfo(from id: String, for key: String) -> String {
        let data = baseOperate(arguments: ["-s", id, "shell", "getprop", key])
        guard let string = String.init(data: data, encoding: .utf8) else { return "" }
        return string.trimmingCharacters(in: ["\r","\n"])
    }
    
    func install(on device: String, with appPath: String, output: ((String) -> Void)?) -> Bool {
        output?(Log.startInstallString(appPath: appPath, device: device))
        let data = baseOperate(arguments: ["-s", device, "install", "-r", appPath])
        guard let string = String.init(data: data, encoding: .utf8) else {
            output?(Log.errorString())
            return false
        }
        output?(Log.stringWithDate(string))
        return string.contains("Success")
    }
    
    func uninstall(from device: String, with appIdentifier: String, output: ((String) -> Void)?) -> Bool {
        output?(Log.startUninstallString(appID: appIdentifier, device: device))
        let data = baseOperate(arguments: ["-s", device, "uninstall", appIdentifier])
        guard let string = String.init(data: data, encoding: .utf8) else {
            output?(Log.errorString())
            return false
        }
        output?(Log.stringWithDate(string))
        return string.contains("Success")
    }
    
    func baseOperate(arguments: [String]) -> Data {
        let path = "/usr/local/bin/adb"
        let process = Process()
        let standardOutput = Pipe()
        process.standardOutput = standardOutput
        process.launchPath = path
        process.arguments = arguments
        process.launch()
        process.waitUntilExit()
        return standardOutput.fileHandleForReading.readDataToEndOfFile()
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


extension String {
    func makeRed(_ string: String) -> NSAttributedString {
        let attr = NSMutableAttributedString(string: self)
        attr.addAttribute(NSForegroundColorAttributeName, value: NSColor.red, range: (self as NSString).range(of: string))
        return attr
    }
}
