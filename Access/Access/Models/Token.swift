//
//  Token.swift
//  Access
//
//  Created by Johnny Gu on 26/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation

struct Token: Codable {
    var token: String = ""
    var id: String = ""
    var appIdentifier: String = ""
    var platform: Phone.Platform = .iOS
}
