//
//  APIManager.swift
//  Access
//
//  Created by Johnny Gu on 21/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation
import AppKit

final class APIManager: NSObject {
    enum Method: String {
        case POST, GET
    }
    static let `default` = APIManager()
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.johnny.Access.APIManager.downloadConfig")
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    var downloadCallbackList: [String: DownloadCallback] = [:]
    
    func request(url: String, params: [String: Any] = [:], method: Method = .GET, headers: [String: Any] = [:], completion: @escaping (Result<[String: Any]>) -> Void ){
        guard let token = AppDelegate.token else {
            completion(.failure(APIError.token))
            return
        }
        var request = URLRequest(url: URL(string: url)!)
        
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields?["X-HockeyAppToken"] = token
        request.allHTTPHeaderFields?["Accept"] = "application/json"
        session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                if error != nil { completion(.failure(error!)); return }
                guard
                    let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] else {
                        completion(.failure(APIError.parse))
                        return
                }
                completion(.success(json))
            }
        }.resume()
        
    }
    
    func requestVersions(completion: @escaping (Result<[HockeyApp]>) -> Void) {
        guard let id = AppDelegate.appid else {
            completion(.failure(APIError.token))
            return
        }
        let url = "https://rink.hockeyapp.net/api/2/apps/\(id)/app_versions?include_build_urls=true"
        request(url: url) { result in
            result.failureHandler({ error in
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }).successHandler({ json in
                guard let versions = json["app_versions"] as? [[String: Any]] else { completion(.failure(APIError.server)); return }
                let apps = versions.flatMap(HockeyApp.init)
                
                completion(.success(apps))
            })
        }
    }
    
    func requestAppIdentifier(completion: @escaping (Result<String>) -> Void) {
        guard let id = AppDelegate.appid else {
            completion(.failure(APIError.token))
            return
        }
        let url = "https://rink.hockeyapp.net/api/2/apps"
        request(url: url) { result in
            result.failureHandler({ error in
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }).successHandler({ json in
                guard let apps = json["apps"] as? [[String: Any]]
                    else { completion(.failure(APIError.server)); return }
                let app = apps.filter({ (value) -> Bool in
                    guard let public_identifier = value["public_identifier"] as? String else { return false }
                    return public_identifier == id
                }).first
                guard let bundle_identifier = app?["bundle_identifier"] as? String else { completion(.failure(APIError.server)); return }
                completion(.success(bundle_identifier))
                if let platform = app?["platform"] as? String {
                    if platform == "Android" { AppDelegate.platform = .android }
                    else if platform == "iOS" { AppDelegate.platform = .iOS }
                }
            })
        }
    }
    
    @discardableResult func download(from url: String, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL>) -> Void) -> URLSessionDownloadTask {
        downloadCallbackList[url] = DownloadCallback(progressCallback: progress, completionCallback: completion)
        let task = downloadSession.downloadTask(with: URL(string: url)!)
        task.resume()
        return task
    }
    
    @discardableResult func download(from url: String, to path: String, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL>) -> Void) -> URLSessionDownloadTask {
        let task = download(from: url, progress: progress) { result in
            result.failureHandler({ error in
                completion(.failure(error))
            }).successHandler({ url in
                let pathURL = URL(fileURLWithPath: path)
                do{
                    if FileManager.default.fileExists(atPath: path) {
                        try FileManager.default.removeItem(atPath: path)
                    }
                    try FileManager.default.copyItem(at: url, to: pathURL)
                }catch {
                    completion(.failure(error))
                    return
                }
                completion(.success(pathURL))
            })
        }
        return task
    }
}

extension APIManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url?.absoluteString else { return }
        downloadCallbackList[url]?.completionCallback(.success(location))
        downloadCallbackList.removeValue(forKey: url)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url?.absoluteString else { return }
        let progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
        downloadCallbackList[url]?.progressCallback(progress)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard
            let url = task.currentRequest?.url?.absoluteString,
            let error = error
        else { return }
        downloadCallbackList[url]?.completionCallback(.failure(error))
        downloadCallbackList.removeValue(forKey: url)
    }
}

struct DownloadCallback {
    let progressCallback: (Double) -> Void
    let completionCallback: (Result<URL>) -> Void
}

enum APIError: Error {
    case unknown
    case server
    case parse
    case token
}

enum Result<T> {
    case success(T)
    case failure(Error)
    @discardableResult func failureHandler(_ closure: (Error) -> Void) -> Result<T> {
        if case .failure(let error) = self {
            closure(error)
        }
        return self
    }
    @discardableResult func successHandler(_ closure: (T) -> Void) -> Result<T> {
        if case .success(let value) = self {
            closure(value)
        }
        return self
    }
}

struct HockeyApp {
    let build: String
    let version: String
    let title: String
    let notes: String
    let downloadURLString: String
    let timestamp: CUnsignedLongLong
}

extension HockeyApp {
    init?(with json: [String: Any]) {
        guard
            let build = json["version"] as? String,
            let version = json["shortversion"] as? String,
            let title = json["title"] as? String,
            let notes = json["notes"] as? String,
            let timestamp = json["timestamp"] as? CUnsignedLongLong,
            let downloadURLString = json["build_url"] as? String else {
            return nil
        }
        self.build = build
        self.version = version
        self.title = title
        self.notes = notes
        self.timestamp = timestamp
        self.downloadURLString = downloadURLString
    }
}

extension HockeyApp {
    var downloadURL: URL? {
        return URL(string: downloadURLString)
    }
    var lastUpdatedAt: String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        return dateFormatter.string(from: date)
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
        return "\(title)_\(version)_\(build).\(format)"
    }
    var format: String {
        guard let startIndex = downloadURLString.range(of: "format=")?.upperBound else { return "ipa" }
        let range = startIndex..<downloadURLString.index(startIndex, offsetBy: 3)
        return downloadURLString.substring(with: range)
    }
}
