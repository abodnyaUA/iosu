//
//  LocalStorage.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import CoreData
import Zip
import UIImageColors

class LocalStorage: NSObject {
    
    static let shared = LocalStorage()
    
    var mainContext: NSManagedObjectContext
    
    private var managedObjectModel: NSManagedObjectModel!
    private var persistentStoreCoordinator: NSPersistentStoreCoordinator!
    private(set) var loadingDatabaseCompleted = false
    
    override init() {
        func excludeFromBackup(url: URL) {
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try (url as NSURL).setResourceValue(true, forKey: .isExcludedFromBackupKey)
                } catch let errorBackup as NSError {
                    print("Error excluding %@ from backup %@", url.lastPathComponent, errorBackup)
                }
            }
        }
        
        do {
            let fileManager = FileManager.default
            let modelURL = Bundle.main.url(forResource: "Database", withExtension: "momd")!
            managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
            let homeURL = NSURL(fileURLWithPath: documentsPath!)
            let DBFolder = homeURL.appendingPathComponent(".CoreData")!
            if !fileManager.fileExists(atPath: DBFolder.path) {
                try fileManager.createDirectory(at: DBFolder, withIntermediateDirectories: true, attributes: nil)
                excludeFromBackup(url: DBFolder)
            }
            
            let storeURL = DBFolder.appendingPathComponent("DataBase.sqlite")
            excludeFromBackup(url: storeURL)
            
            persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            let options: [String: Any] = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
            
            mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            mainContext.persistentStoreCoordinator = persistentStoreCoordinator
            mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        } catch let error as NSError {
            fatalError("Fail setup database: " + error.description)
        }
        super.init()
        scanBeatmaps { [unowned self] in
            self.loadingDatabaseCompleted = true
            DispatchQueue.main.async { [unowned self] in
                NotificationCenter.default.post(name: .loadingDatabaseCompleted, object: self)
            }
        }
    }
    
    func createContext(withConcurrencyType concurrencyType: NSManagedObjectContextConcurrencyType) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.persistentStoreCoordinator = persistentStoreCoordinator
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    func performBackgroundOperation(_ operation: @escaping (_ context: NSManagedObjectContext) -> Void) {
        let context = createContext(withConcurrencyType: .privateQueueConcurrencyType)
        context.perform { [weak self] in
            guard let `self` = self else {
                return
            }
            operation(context)
            self.saveChanges(context: context)
            context.reset()
        }
    }
    
    var observers = [NSManagedObjectContext]()
    func observeChangesForContext(context: NSManagedObjectContext) {
        observers.append(context)
    }
    
    func saveChanges(context: NSManagedObjectContext) {
        if context != mainContext {
            NotificationCenter.default.addObserver(self, selector: #selector(contextDidSaved(notification:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
        }
        do {
            try context.save()
        } catch let error as NSError {
            print("Fail background save: " + error.description)
        }
        if context != self.mainContext {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
        }
    }
    
    @objc private func contextDidSaved(notification: NSNotification) {
        mainContext.perform { [weak self] in
            guard let `self` = self else {
                return
            }
            self.mainContext.mergeChanges(fromContextDidSave: notification as Notification)
            for context in self.observers {
                context.mergeChanges(fromContextDidSave: notification as Notification)
            }
            self.saveChanges(context: self.mainContext)
        }
    }
    
    func scanBeatmaps(completion: @escaping () -> Void) {
        performBackgroundOperation { [unowned self] (context) in
            let request: NSFetchRequest<SongInfo> = SongInfo.fetchRequest()
            var existingSongs = (try! context.fetch(request)).dictionary(map: { (song) -> String in
                return song.folderName ?? ""
            })
            let manager = FileManager.default
            let documentsURL = manager.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
            print("start scan \(documentsURL.path)")
            guard let contentsOfPath = try? manager.contentsOfDirectory(atPath: documentsURL.path) else {
                return
            }
            for entry in contentsOfPath {
                let entryURL = documentsURL.appendingPathComponent(entry)
                let songFolderURL = entryURL.deletingPathExtension()
                if entryURL.pathExtension == "osz", !self.unarchiveBeatmap(at: entryURL) {
                    continue
                }
                let folderName = songFolderURL.lastPathComponent
                guard !existingSongs.keys.contains(folderName) else {
                    continue
                }
                guard let contentsOfBMPath = try? manager.contentsOfDirectory(atPath: songFolderURL.path) else {
                    continue
                }
                let song = existingSongs[folderName] ?? SongInfo(context: context)
                song.folderName = folderName
                for subentry in contentsOfBMPath {
                    let url = songFolderURL.appendingPathComponent(subentry)
                    if url.pathExtension == "osu" {
                        guard let beatmap = try? Beatmap(file: url.path) else {
                            continue
                        }
                        let beatmapFile = BeatmapFile(context: context)
                        beatmapFile.fileName = subentry
                        beatmapFile.song = song
                        beatmapFile.difficulty = beatmap.difficulty?.overallDifficulty ?? 0.0
                        beatmapFile.version = beatmap.meta?.version
                        
                        if song.backgroundImageFilename == nil {
                            song.backgroundImageFilename = beatmap.bgimg
                            let imageURL = songFolderURL.appendingPathComponent(beatmap.bgimg)
                            if let image = UIImage(contentsOfFile: imageURL.path) {
                                let colors = image.getColors()
                                song.primaryColorHex = colors.primary.hexString
                                song.secondaryColorHex = colors.secondary.hexString
                                song.backgroundColorHex = colors.background.hexString
                            }
                        }
                        if song.audioFilename == nil {
                            song.audioFilename = beatmap.audiofile
                        }
                        if song.name == nil {
                            song.name = beatmap.meta?.title
                            song.artist = beatmap.meta?.artist
                        }
                        if song.beatmapId == nil {
                            song.beatmapId = beatmap.meta?.beatmapId
                        }
                    } else if url.pathExtension == "osb" {
                        let storyboardFile = StoryboardFile(context: context)
                        storyboardFile.fileName = subentry
                        storyboardFile.song = song
                    }
                }
                if (song.files?.count ?? 0) == 0 {
                    context.delete(song)
                } else {
                    if song.name == nil {
                        song.name = folderName
                    }
                    existingSongs[folderName] = song
                }
            }
            completion()
        }
    }
    
    private func unarchiveBeatmap(at url: URL) -> Bool {
        let songFolderURL = url.deletingPathExtension()
        let zipURL = songFolderURL.appendingPathExtension("zip")
        do {
            try FileManager.default.moveItem(atPath: url.path, toPath: zipURL.path)
            try Zip.unzipFile(zipURL, destination: songFolderURL, overwrite: true, password: nil)
            try FileManager.default.removeItem(at: zipURL)
        } catch let error {
            print("error unpacking \(url): \(error)")
            return false
        }
        return true
    }
}

extension NSNotification.Name {
    static let loadingDatabaseCompleted = NSNotification.Name("loadingDatabaseCompleted")
}
