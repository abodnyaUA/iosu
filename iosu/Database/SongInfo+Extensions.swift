//
//  SongInfo+Extensions.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import Foundation
import CoreData

extension SongInfo {
    
    var folderPath: String? {
        guard let name = self.folderName else {
            return nil
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        return documentsURL.appendingPathComponent(name).path
    }
    
    var backgroundImage: UIImage? {
        guard let folderPath = self.folderPath, let imageName = backgroundImageFilename else {
            return nil
        }
        let songFolderURL = URL(fileURLWithPath: folderPath)
        let url = songFolderURL.appendingPathComponent(imageName)
        return UIImage(contentsOfFile: url.path)
    }
    
    var primaryColor: UIColor {
        guard let hex = primaryColorHex else {
            return .black
        }
        return UIColor(hex: hex)
    }
    
    var secondaryColor: UIColor {
        guard let hex = secondaryColorHex else {
            return .darkGray
        }
        return UIColor(hex: hex)
    }
    
    var backgroundColor: UIColor {
        guard let hex = backgroundColorHex else {
            return .white
        }
        return UIColor(hex: hex)
    }
    
    var musicURL: URL? {
        guard let folderPath = self.folderPath, let filename = audioFilename else {
            return nil
        }
        let songFolderURL = URL(fileURLWithPath: folderPath)
        let url = songFolderURL.appendingPathComponent(filename)
        return url
    }
}

extension BeatmapFile {
    
    var filePath: String? {
        guard let folderPath = song?.folderPath, let fileName = self.fileName else {
            return nil
        }
        return URL(fileURLWithPath: folderPath).appendingPathComponent(fileName).path
    }
}

extension StoryboardFile {
    
    var filePath: String? {
        guard let folderPath = song?.folderPath, let fileName = self.fileName else {
            return nil
        }
        return URL(fileURLWithPath: folderPath).appendingPathComponent(fileName).path
    }
}
