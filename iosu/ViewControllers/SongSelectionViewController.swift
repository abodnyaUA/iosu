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
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var selectedSongName = ""
    
    let resultsController: NSFetchedResultsController<SongInfo> = {
        let request: NSFetchRequest<SongInfo> = SongInfo.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let context = LocalStorage.shared.mainContext
        let controller = NSFetchedResultsController<SongInfo>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "SongSelectionCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "cell")
        
        resultsController.delegate = self
        if LocalStorage.shared.loadingDatabaseCompleted {
            databaseLoaded()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(databaseLoaded), name: .loadingDatabaseCompleted, object: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func databaseLoaded() {
        try! resultsController.performFetch()
        if let first = resultsController.fetchedObjects!.first {
            selectedSongName = first.folderName ?? ""
            backgroundImageView.image = first.backgroundImage
            startPlayingMusic(first)
        }
        tableView.reloadData()
    }
    
    func startGameForSong(_ song: SongInfo) {
        guard let file = song.files?.anyObject() as? BeatmapFile else {
            return
        }
        let viewController = GameViewController.create(songInfo: song, beatmapFile: file)
        present(viewController, animated: false, completion: nil)
    }
    
    func startPlayingMusic(_ song: SongInfo) {
        
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
        let songInfo = resultsController.fetchedObjects![indexPath.row]
        if selectedSongName == songInfo.folderName {
            // second selection
            startGameForSong(songInfo)
        } else {
            selectedSongName = songInfo.folderName ?? ""
            backgroundImageView.image = songInfo.backgroundImage
            startPlayingMusic(songInfo)
            
            tableView.reloadData()
        }
    }
}

extension SongSelectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongSelectionCell
        let songInfo = resultsController.fetchedObjects![indexPath.row]
        cell.backgroundImageView.image = songInfo.backgroundImage
        cell.backgroundColorView.backgroundColor = selectedSongName == songInfo.folderName ? .blue : songInfo.backgroundColor
        cell.nameLabel.textColor = songInfo.primaryColor
        cell.nameLabel.text = songInfo.name
        cell.difficultyLabel.textColor = songInfo.secondaryColor
        cell.difficultyLabel.text = nil
        cell.rateViewContainer.isHidden = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
}
