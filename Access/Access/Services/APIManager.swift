//
//  APIManager.swift
//  Access
//
//  Created by Johnny Gu on 21/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Foundation
import AppKit
import Moya

final class APIManager: NSObject {
    enum Method: String {
        case POST, GET
    }
    static let `default` = APIManager()

    private lazy var hockeyApp: MoyaProvider<HockeyApp.Service> = {
        let provider = MoyaProvider<HockeyApp.Service>()
        return provider
    }()
    private lazy var buddyBuild: MoyaProvider<BuddyBuild.Service> = {
        let provider = MoyaProvider<BuddyBuild.Service>()
        return provider
    }()
    lazy var iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.init(identifier: "zh_CN")
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-ddTHH:mm:ssZ"
        return formatter
    }()
    lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(self.iso8601Formatter)
        return decoder
    }()
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.johnny.Access.APIManager.downloadConfig")
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)
    }()
    var downloadCallbackList: [String: DownloadCallback] = [:]
    
    func requestHockeyAppVersions(token: Token, completion: @escaping (Result<[HockeyApp.Build]>) -> Void) {
        hockeyApp.request(.list(token: token.token, appId: token.id)) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                do {
                    let list = try self.jsonDecoder.decode(HockeyApp.BuildList.self, from: response.data)
                    completion(.success(list.appVersions))
                } catch {
                    print(error)
                    completion(.failure(APIError.unknown))
                }
            }
        }
    }

    func requestBuddyBuildVersions(token: Token, completion: @escaping (Result<[BuddyBuild.Build]>) -> Void) {
        buddyBuild.request(.list(token: token.token, appId: token.id, scheme: token.extraInfo)) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                do {
                    let formatter = DateFormatter()
                    formatter.locale = Locale.init(identifier: "zh_CN")
                    formatter.calendar = Calendar(identifier: .iso8601)
                    formatter.timeZone = TimeZone.current
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"

                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                    jsonDecoder.dateDecodingStrategy = .formatted(formatter)

                    let list = try jsonDecoder.decode([BuddyBuild.Build].self, from: response.data)
                    completion(.success(list))
                } catch {
                    print(error)
                    completion(.failure(APIError.unknown))
                }
            }
        }
    }

    func requestVersions(completion: @escaping (Result<[DisplayableBuild]>) -> Void) {
        guard AppDelegate.tokens.count > 0 else {
            completion(.failure(APIError.token))
            return
        }
        let token = AppDelegate.tokens[AppDelegate.inuseTokenIndex]

        switch token.kind {
        case .hockeyApp:
            requestHockeyAppVersions(token: token) { (result) in
                result.successHandler({ (builds) in
                    completion(.success(builds))
                }).failureHandler({ (error) in
                    completion(.failure(error))
                })
            }
        case .buddyBuild:
            requestBuddyBuildVersions(token: token) { (result) in
                result.successHandler({ (builds) in
                    completion(.success(builds))
                }).failureHandler({ (error) in
                    completion(.failure(error))
                })
            }
        }
    }
    
    func requestAppIdentifier(token: String, id: String, completion: @escaping (Result<Token>) -> Void) {
        hockeyApp.request(.getBundleId(token: token, appId: id)) { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                do {
                    let list = try self.jsonDecoder.decode(HockeyApp.AppList.self, from: response.data)
                    guard let app = list.apps.first(where: { $0.publicIdentifier == id }) else {
                        completion(.failure(APIError.unknown))
                        return
                    }
                    let token = Token(token: token, id: id, extraInfo: app.bundleIdentifier, platform: app.platform, kind: .hockeyApp)
                    completion(.success(token))
                } catch {
                    print(error)
                    completion(.failure(APIError.unknown))
                }
            }
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

    func convertToNSError() -> NSError {
        switch self {
        case .unknown:
            return NSError(domain: "NSURLErrorDomain", code: 1000, userInfo: ["NSLocalizedDescription": "unknown error"])
        case .server:
            return NSError(domain: "NSURLErrorDomain", code: 1001, userInfo: ["NSLocalizedDescription": "server error"])
        case .parse:
            return NSError(domain: "CustomErrorDomain", code: 20001, userInfo: ["NSLocalizedDescription": "parse failed"])
        default:
            return NSError(domain: "NSURLErrorDomain", code: 1000, userInfo: ["NSLocalizedDescription": "unknown error"])
        }
    }
}

extension NSAlert {
    static func show(_ error: Error) {
        if let apiError = error as? APIError {
            NSAlert(error: apiError.convertToNSError()).runModal()
        }else {
            NSAlert(error: error).runModal()
        }
    }
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

