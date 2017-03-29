//
//  Phone.swift
//  Access
//
//  Created by Johnny Gu on 26/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation

struct Phone {
    let uuid: String
    var alias: String = ""
    var type: PhoneType = .iOS
    var model: String = ""
    var system: String = ""
    var appInstalled: Bool = false
}

extension Phone {
    enum PhoneType: String {
        case iOS
        case android
    }
    
    static func appType(from aString: String) -> PhoneType? {
        if aString.hasSuffix("ipa") { return .iOS }
        if aString.hasSuffix("apk") { return .android }
        return nil
    }
}

extension Phone {
    init(uuid: String) {
        self.uuid = uuid
    }
    
    init(uuid: String, type: PhoneType) {
        self.uuid = uuid
        self.type = type
    }
    
    init?(_ json: [String: String]) {
        guard let uuid = json["uuid"] else { return nil }
        self.uuid = uuid
        alias = json["alias"] ?? ""
        type = PhoneType(rawValue: json["type"] ?? "iOS")!
        model = json["model"] ?? ""
        system = json["system"] ?? ""
        appInstalled = Bool(json["appInstalled"] ?? "false") ?? false
    }
    
    func archive() -> [String: String] {
        return ["uuid": uuid, "alias": alias, "type": type.rawValue, "model": model, "system": system, "appInstalled": appInstalled.description]
    }
}
