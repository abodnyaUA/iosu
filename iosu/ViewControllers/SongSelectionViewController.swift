//
//  SongSelectionViewController.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import CoreData

class SongSelectionViewController: UIViewController {
    
    enum ItemCell {
        case song(SongInfo)
        case file(BeatmapFile)
        
        var songInfo: SongInfo {
            switch self {
            case .song(let song): return song
            case .file(let file): return file.song!
            }
        }
    }
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    
    private let player = MusicPlayer()
    
    var selectedSongName = ""
    var selectedFileName = ""
    
    let resultsController: NSFetchedResultsController<SongInfo> = {
        let request: NSFetchRequest<SongInfo> = SongInfo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let context = LocalStorage.shared.mainContext
        let controller = NSFetchedResultsController<SongInfo>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()
    
    var items = [ItemCell]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        let nib = UINib(nibName: "SongSelectionCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "cell")
        
        resultsController.delegate = self
        if LocalStorage.shared.loadingDatabaseCompleted {
            databaseLoaded()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(databaseLoaded), name: .loadingDatabaseCompleted, object: nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.stop()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func databaseLoaded() {
        try! resultsController.performFetch()
        items = resultsController.fetchedObjects!.map { .song($0) }
        if resultsController.fetchedObjects!.count > 0 {
            selectSong(at: 0)
        }
        tableView.reloadData()
    }
    
    func startGame(for file: BeatmapFile) {
        let viewController = GameViewController.create(songInfo: file.song!, beatmapFile: file)
        navigationController?.pushViewController(viewController, animated: false)
    }
    
    func startPlayingMusic(_ song: SongInfo) {
        if let url = song.musicURL {
            player.loadFile(url.path)
            player.rewind(at: 30.0)
            player.play()
        }
    }
    
    func selectSong(at index: Int) {
        let item = items[index]
        switch item {
        case .song(let selectedSong):
            if selectedSongName != "", let previousSongInfo = resultsController.fetchedObjects!.first(where: { $0.folderName == selectedSongName }) {
                // hide previous selected
                let indexes = items.enumerated()
                    .filter { (index, item) -> Bool in
                        if case .file = item {
                            return true
                        }
                        return false
                    }.map {
                        $0.offset
                    }
                if indexes.count > 0 {
                    let songItem: ItemCell = .song(previousSongInfo)
                    items.replaceSubrange(indexes.first! ... indexes.last!, with: [songItem])
                }
            }
            let insertIndex = items.firstIndex { (item) -> Bool in
                if case .song(let song) = item {
                    return song.folderName! == selectedSong.folderName!
                }
                return false
            }!
            let insertedFiles = (selectedSong.files ?? NSSet())
                .map { $0 as! BeatmapFile}
                .sorted { (file1, file2) -> Bool in
                    return file1.difficulty < file2.difficulty
                }
            let insertedItems = insertedFiles
                .map { (file) -> ItemCell in
                    return .file(file)
                }
            selectedFileName = insertedFiles.first?.fileName ?? ""
            items.replaceSubrange(insertIndex ... insertIndex, with: insertedItems)
            selectedSongName = selectedSong.folderName ?? ""
            backgroundImageView.image = selectedSong.backgroundImage
            startPlayingMusic(selectedSong)
            SoundPlayer.instance.playSound(.menuClick)
            tableView.reloadData()
        case .file(let file):
            if file.fileName == selectedFileName {
                SoundPlayer.instance.playSound(.menuHit)
                startGame(for: file)
            } else {
                selectedFileName = file.fileName ?? ""
                SoundPlayer.instance.playSound(.menuClick)
                tableView.reloadData()
            }
        }
    }
}

extension SongSelectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

extension SongSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        selectSong(at: indexPath.row)
    }
}

extension SongSelectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongSelectionCell
        let item = items[indexPath.row]
        let songInfo = item.songInfo
        cell.backgroundImageView.image = songInfo.backgroundImage
        var textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        switch item {
        case .song:
            cell.backgroundColorView.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            cell.difficultyLabel.text = nil
        case .file(let file):
            cell.backgroundColorView.backgroundColor = selectedFileName == file.fileName ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
            textColor = selectedFileName == file.fileName ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            cell.difficultyLabel.text = "Difficulty: \(file.difficulty)"
        }
        
        cell.nameLabel.textColor = textColor
        cell.nameLabel.text = songInfo.name
        cell.difficultyLabel.textColor = textColor
        cell.rateViewContainer.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
}
