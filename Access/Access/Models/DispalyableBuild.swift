//
//  DispalyableBuild.swift
//  Access
//
//  Created by Johnny Gu on 2018/9/17.
//  Copyright © 2018 Johnny Gu. All rights reserved.
//

import Foundation

protocol DisplayableBuild {
    var titleDescription: String { get }
    var buildDescription: String { get }
    var versionDescription: String { get }
    var updateAtDate: Date { get }
    var updateAtDescription: String { get }
    var downloadURL: URL? { get }
    var copyURLString: String? { get }
    var attributedNotes: NSAttributedString? { get }
    var filename: String { get }
    var filepath: String { get }
    var format: String { get }
    var existsAtLocal: Bool { get }
}
