//
//  HockeyApp.swift
//  Access
//
//  Created by Johnny Gu on 2018/9/16.
//  Copyright © 2018 Johnny Gu. All rights reserved.
//

import Foundation
import Moya
import Alamofire

struct HockeyApp {
    enum Service {
        case list(token: String, appId: String)
        case getBundleId(token: String, appId: String)
    }

    struct Build: Codable {
        let id: Int
        let version: String // build
        let shortversion: String // version
        let title: String
        let notes: String
        let publicUrl: String? // for install
        let timestamp: CUnsignedLongLong
        let buildUrl: String? // for download
    }

    struct BuildList: Codable {
        let appVersions: [Build]
    }

    struct App: Codable {
        let publicIdentifier: String
        let bundleIdentifier: String
        let platform: Phone.Platform
        let title: String
    }
    struct AppList: Codable {
        let apps: [App]
    }
}

extension HockeyApp.Service: TargetType {
    var path: String {
        switch self {
        case .list(_, let appId):
            return "/\(appId)/app_versions"
        case .getBundleId(_, _):
            return "/"
        }
    }

    var method: Alamofire.HTTPMethod {
        switch self {
        default:
            return .get
        }
    }

    var sampleData: Data {
        switch self {
        case .list(token: _):
            return Data()
        case .getBundleId(_, _):
            return Data()
        }
    }

    var task: Task {
        switch self {
        case .list(_):
            return .requestParameters(parameters: ["include_build_urls": "true"], encoding: URLEncoding.queryString)
        case .getBundleId(_, _):
            return .requestPlain
        }
    }

    var headers: [String : String]? {
        switch self {
        case .list(let token, _), .getBundleId(let token, _):
            return ["X-HockeyAppToken": token]
        }
    }

    var baseURL: URL { return URL(string: "https://rink.hockeyapp.net/api/2/apps")! }
}


extension HockeyApp.Build: DisplayableBuild {
    var updateAtDate: Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    var titleDescription: String {
        return title
    }

    var buildDescription: String {
        return version
    }

    var versionDescription: String {
        return shortversion
    }

    var updateAtDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: updateAtDate)
    }

    var downloadURL: URL? {
        return buildUrl.flatMap(URL.init)
    }
    var copyURLString: String? {
        guard let publicUrl = publicUrl else { return nil }
        return "\(publicUrl)/app_versions/\(id)"
    }
    var attributedNotes: NSAttributedString? {
        guard let data = notes.data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return  nil
        }
    }
    var filename: String {
        return "\(title)_\(shortversion)_\(version).\(format)"
    }
    var filepath: String {
        return AppDelegate.downloadPath + "/" + filename
    }
    var format: String {
        guard let buildUrl = buildUrl else { return "" }
        guard let startIndex = buildUrl.range(of: "format=")?.upperBound else { return "ipa" }
        let range = startIndex..<buildUrl.index(startIndex, offsetBy: 3)
        return buildUrl.substring(with: range)
    }
    var existsAtLocal: Bool {
        return FileManager.default.fileExists(atPath: filepath)
    }
}
