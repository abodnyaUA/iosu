//
//  SongsDownloader.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/15/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit

class SongsDownloader: NSObject {
    
    static let instance = SongsDownloader()
    
    struct Song {
        let beatmapId: String
        let title: String
        let artist: String
        
        var downloadingState: DownloadingState = .didNotStarted
        
        var thumbnailURL: URL {
            return URL(string: "https://b.ppy.sh/thumb/\(beatmapId)l.jpg")!
        }
        
        var coverURL: URL {
            return URL(string: "https://assets.ppy.sh/beatmaps/\(beatmapId)/covers/cover.jpg")!
        }
        
        var downloadURL: URL {
            return URL(string: "https://bloodcat.com/osu/d/\(beatmapId)")!
        }
    }
    
    enum DownloadingState {
        case didNotStarted
        case startedDownloading
        case progress(Double)
        case downloaded
    }
    
    enum DownloadResult {
        case success
        case captchaRequired(Song)
        case failed(Error?)
    }
    
    struct DownloadInfo {
        let song: Song
        let completion: (_ result: DownloadResult) -> Void
    }
    
    let appName = "iosu"
    let appURL = "https://github.com/abodnyaUA/iosu/tree/dev"
    let apiKey = "1882a642bb526cea7dba554e6d836527d36b1334"
    let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Safari/605.1.15"
    
    private var session: URLSession! = nil
    private var tasks = [String: DownloadInfo]()
    private let updateTasksQueue = DispatchQueue(label: "updateTasksQueue")
    
    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    
    func getTask(for key: String) -> DownloadInfo? {
        return updateTasksQueue.sync(execute: { [unowned self] in
            return self.tasks[key]
        })
    }
    
    func addTask(_ downloadInfo: DownloadInfo, key: String) {
        updateTasksQueue.sync {
            self.tasks[key] = downloadInfo
        }
    }
    
    func removeTask(for key: String) {
        _ = updateTasksQueue.sync {
            self.tasks.removeValue(forKey: key)
        }
    }
    
    func songsInDownloading() -> [Song] {
        return updateTasksQueue.sync(execute: { [unowned self] in
            return self.tasks.values.map({ $0.song })
        })
    }
    
    func downloadSong(_ song: Song, completion: @escaping (_ result: DownloadResult) -> Void) {
        let url = song.downloadURL
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        addTask(DownloadInfo(song: song, completion: completion), key: url.absoluteString)
        let task = session.downloadTask(with: request) { [weak self] (localUrl, response, error) in
            self?.removeTask(for: url.absoluteString)
            var invalidResponse = false
            if let response = response as? HTTPURLResponse {
                print("response: \(response)")
                invalidResponse = response.statusCode != 200
                if response.statusCode == 401, let localUrl = localUrl, let html = try? String(contentsOfFile: localUrl.path) {
                    if html.localizedStandardContains("CAPTCHA") {
                        completion(.captchaRequired(song))
                        return
                    }
                }
            }
            if let error = error {
                print("failed with error \(error)")
                completion(.failed(error))
                return
            } else if let localUrl = localUrl {
                if invalidResponse {
                    completion(.failed(nil))
                    return
                }
                print("localUrl: \(localUrl)")
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
                let fileName = "Downloaded-\(song.beatmapId).osz"
                let oszURL = documentsURL.appendingPathComponent(fileName)
                do {
                    try FileManager.default.moveItem(atPath: localUrl.path, toPath: oszURL.path)
                    LocalStorage.shared.scanBeatmaps {
                        completion(.success)
                    }
                } catch let error {
                    print("error moving \(localUrl): \(error)")
                    completion(.failed(error))
                    return
                }
            } else {
                completion(.failed(nil))
            }
        }
        task.resume()
        
        let userInfo: [String : Any] = [
            "url": url.absoluteString,
            "progress": 0.0
        ]
        NotificationCenter.default.post(name: .downloadProgressChanges, object: self, userInfo: userInfo)
    }
    
    func searchSongs(query: String, page: Int = 1, completion: @escaping ([Song]) -> Void) {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
            let url = URL(string: "http://bloodcat.com/osu/?mod=json&m=0&s=&q=\(encodedQuery)&p=\(page)") else {
            completion([])
            return
        }
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let `self` = self else {
                return
            }
            if let data = data {
                let songs = self.parseResult(data: data)
                completion(songs)
            } else {
                if let response = response {
                    print("response \(response)")
                }
                if let error = error {
                    print("error \(error)")
                }
                completion([])
            }
            
        }.resume()
    }
    
    private func parseResult(data: Data) -> [Song] {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)),
            let objects = json as? [[String: Any]] else {
                return []
        }
        return objects.compactMap({ (info) -> Song? in
            guard let id = info["id"] as? String,
                let title = info["titleU"] as? String ?? info["title"] as? String,
                let artist = info["artistU"] as? String ?? info["artist"] as? String else {
                    return nil
            }
            return Song(beatmapId: id, title: title, artist: artist, downloadingState: .didNotStarted)
        })
    }
}

extension SongsDownloader: URLSessionDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.currentRequest?.url?.absoluteString else {
            return
        }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        let userInfo: [String : Any] = [
            "url": url,
            "progress": progress
        ]
        NotificationCenter.default.post(name: .downloadProgressChanges, object: self, userInfo: userInfo)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.currentRequest?.url, let info = getTask(for: url.absoluteString) else {
            return
        }
        removeTask(for: url.absoluteString)
        var invalidResponse = false
        if let response = downloadTask.response as? HTTPURLResponse {
            print("response: \(response)")
            invalidResponse = response.statusCode != 200
            if response.statusCode == 401, let html = try? String(contentsOfFile: location.path) {
                if html.localizedStandardContains("CAPTCHA") {
                    info.completion(.captchaRequired(info.song))
                    return
                }
            }
        }
        if invalidResponse {
            info.completion(.failed(nil))
            return
        }
        print("localUrl: \(location)")
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let fileName = "Downloaded-\(info.song.beatmapId).osz"
        let oszURL = documentsURL.appendingPathComponent(fileName)
        do {
            try FileManager.default.moveItem(atPath: location.path, toPath: oszURL.path)
            LocalStorage.shared.scanBeatmaps {
                info.completion(.success)
            }
        } catch let error {
            print("error moving \(location): \(error)")
            info.completion(.failed(error))
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.currentRequest?.url, let info = getTask(for: url.absoluteString) else {
            return
        }
        removeTask(for: url.absoluteString)
        info.completion(.failed(error))
    }
}

extension NSNotification.Name {
    static let downloadProgressChanges = NSNotification.Name("downloadProgressChanges")
}
