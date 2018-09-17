//
//  BuddyBuild.swift
//  Access
//
//  Created by Johnny Gu on 2018/9/17.
//  Copyright © 2018 Johnny Gu. All rights reserved.
//

import Foundation
import Moya
import Alamofire

struct BuddyBuild {
    enum Service {
        case list(token: String, appId: String, scheme: String?)
    }

    struct Build: Codable {
        let _id: String
        let buildNumber: Int
        let finishedAt: Date
        let links: Links
        let commitInfo: CommitInfo
        let schemeName: String

        struct Links: Codable {
            let download: [Link]
            let install: [Link]
        }
        struct Link: Codable {
            let url: String
        }
        struct CommitInfo: Codable {
            let message: String
        }
    }
}

extension BuddyBuild.Service: TargetType {
    var baseURL: URL {
        return URL(string: "https://api.buddybuild.com/v1/apps")!
    }

    var method: Alamofire.HTTPMethod {
        switch self {
        case .list(_, _, _):
            return .get
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        case .list(_, _, let scheme):
            var param: [String: String] = ["status": "success"]
            if let scheme = scheme { param["scheme"] = scheme }
            return .requestParameters(parameters: param, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String : String]? {
        switch self {
        case .list(let token, _, _):
            return ["Authorization": "Bearer \(token)"]
        }
    }

    var path: String {
        switch self {
        case .list(_, let appId, _):
            return "/\(appId)/builds"
        }
    }
}

extension BuddyBuild.Build: DisplayableBuild {
    var updateAtDate: Date {
        return finishedAt
    }

    var titleDescription: String {
        return schemeName
    }

    var buildDescription: String {
        return "\(buildNumber)"
    }

    var versionDescription: String {
        return "BuddyBuild"
    }

    var updateAtDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: finishedAt)
    }

    var downloadURL: URL? {
        guard let url = links.download.first?.url else { return nil }
        return URL(string: url)
    }
    var copyURLString: String? {
        return links.install.first?.url
    }
    var attributedNotes: NSAttributedString? {
        guard let data = commitInfo.message.data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch let error as NSError {
            NSLog(error.localizedDescription)
            return  nil
        }
    }
    var filename: String {
        return "\(schemeName)_\("buddybuild")_\(buildNumber).\(format)"
    }
    var filepath: String {
        return AppDelegate.downloadPath + "/" + filename
    }
    var format: String {
        guard let buildUrl = copyURLString else { return "ipa" }
        if buildUrl.contains("ios") {
            return "ipa"
        } else {
            return "apk"
        }
    }
    var existsAtLocal: Bool {
        return FileManager.default.fileExists(atPath: filepath)
    }
}
