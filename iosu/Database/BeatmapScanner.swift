//
//  BeatmapProcessor.swift
//  iosu
//
//  Created by xieyi on 2017/3/30.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import Zip

class BeatmapScanner {
    
    struct Song {
        let name: String
        let textColor: UIColor
        let backgroundColor: UIColor
        let thumbnail: UIImage?
    }
    
    public var beatmapdirs = [String]()
    public var bmdirurls = [URL]()
    public var beatmaps = [String]()
    public var storyboards = [String:String]()
    public var dirscontainsb = [String]()
    
    init() {
        let manager = FileManager.default
        let documentsURL = manager.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        guard let contentsOfPath = try? manager.contentsOfDirectory(atPath: documentsURL.path) else {
            return
        }
        for entry in contentsOfPath {
            let entryURL = documentsURL.appendingPathComponent(entry)
            let songFolderURL = entryURL.deletingPathExtension()
            if entryURL.pathExtension == "osz" {
                let zipURL = songFolderURL.appendingPathExtension("zip")
                do {
                    try manager.moveItem(atPath: entryURL.path, toPath: zipURL.path)
                    try Zip.unzipFile(zipURL, destination: songFolderURL, overwrite: true, password: nil)
                    try manager.removeItem(at: zipURL)
                } catch let error {
                    print("error unpacking \(entry): \(error)")
                    continue
                }
            }
            guard let contentsOfBMPath = try? manager.contentsOfDirectory(atPath: songFolderURL.path) else {
                continue
            }
            for subentry in contentsOfBMPath {
                if subentry.hasSuffix(".osu") {
                    beatmapdirs.append(entryURL.path)
                    bmdirurls.append(entryURL)
                    beatmaps.append(subentry)
                }
                if subentry.hasSuffix(".osb") {
                    dirscontainsb.append(entryURL.path)
                    storyboards.updateValue(subentry, forKey: entryURL.path)
                }
            }
        }
    }
    
    func count() -> Int {
        return beatmaps.count
    }
    
    func get(index:Int) -> String {
        return beatmaps[index]
    }
    
}
