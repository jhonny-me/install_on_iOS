//
//  Token.swift
//  Access
//
//  Created by Johnny Gu on 26/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation

struct Token {
    var token: String = ""
    var id: String = ""
    var appIdentifier: String = ""
    var platform: Phone.PhoneType = .iOS
}

extension Token {
    init(with json: [String: String]) {
        if
            let token = json["token"],
            let id = json["id"],
            let appID = json["appID"],
            let type = Phone.PhoneType(rawValue: json["type"] ?? "iOS") {
            self.token = token
            self.id = id
            self.appIdentifier = appID
            self.platform = type
        }
    }
    
    func archive() -> [String: String] {
        return ["token": token, "id": id, "appID": appIdentifier, "type": platform.rawValue]
    }
}
