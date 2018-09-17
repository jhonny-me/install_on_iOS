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
    var type: Platform = .iOS
    var model: String = ""
    var system: String = ""
    var appInstalled: Bool = false
}

extension Phone {
    enum Platform: String, Codable {
        case iOS = "iOS"
        case android = "Android"
    }
    
    static func appType(from aString: String) -> Platform? {
        if aString.hasSuffix("ipa") { return .iOS }
        if aString.hasSuffix("apk") { return .android }
        return nil
    }
}

extension Phone {
    init(uuid: String) {
        self.uuid = uuid
    }
    
    init(uuid: String, type: Platform) {
        self.uuid = uuid
        self.type = type
    }
    
    init?(_ json: [String: String]) {
        guard let uuid = json["uuid"] else { return nil }
        self.uuid = uuid
        alias = json["alias"] ?? ""
        type = Platform(rawValue: json["type"] ?? "iOS")!
        model = json["model"] ?? ""
        system = json["system"] ?? ""
        appInstalled = Bool(json["appInstalled"] ?? "false") ?? false
    }
    
    func archive() -> [String: String] {
        return ["uuid": uuid, "alias": alias, "type": type.rawValue, "model": model, "system": system, "appInstalled": appInstalled.description]
    }
}
