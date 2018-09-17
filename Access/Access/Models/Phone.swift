//
//  Phone.swift
//  Access
//
//  Created by Johnny Gu on 26/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation

struct Phone: Codable {
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
