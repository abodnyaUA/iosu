//
//  DownloadSongsViewController.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/15/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import CoreData
import SDWebImage

class DownloadSongsViewController: UIViewController {
    
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var downloadingLabel: UILabel!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    private var currentPage = 1
    private var songs = [SongsDownloader.Song]()
    private var selectedSongIndex: Int? = nil
    
    private var subsciption: Any? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "SongSelectionCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "cell")
        
        subsciption = NotificationCenter.default.addObserver(forName: .downloadProgressChanges, object: nil, queue: nil, using: { [weak self] (notification) in
            self?.trackProgress(notification: notification)
        })
        
        refetchSongs()
    }
    
    deinit {
        if let subsciption = subsciption {
            NotificationCenter.default.removeObserver(subsciption)
        }
    }
    
    private func refetchSongs() {
        currentPage = 1
        songs = []
        fetchSongs()
    }
    
    private func fetchMoreSongs() {
        currentPage += 1
        fetchSongs()
    }
    
    private func fetchSongs() {
        SongsDownloader.instance.searchSongs(query: "", page: currentPage) { [weak self] (songs) in
            LocalStorage.shared.performBackgroundOperation({ (context) in
                let request: NSFetchRequest<SongInfo> = SongInfo.fetchRequest()
                let existingSongs = (try! context.fetch(request)).dictionary(map: { (song) -> String in
                    return song.beatmapId ?? ""
                })
                var processedSongs = [SongsDownloader.Song]()
                songs.forEach({ (song) in
                    var newSong = song
                    if existingSongs[song.beatmapId] != nil {
                        newSong.downloadingState = .downloaded
                    }
                    processedSongs.append(newSong)
                })
                DispatchQueue.main.async {
                    guard let `self` = self else {
                        return
                    }
                    self.songs.append(contentsOf: processedSongs)
                    if self.selectedSongIndex == nil, self.songs.count > 0 {
                        self.selectedSongIndex = 0
                        self.refreshSelectedSong()
                    }
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func trackProgress(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let url = userInfo["url"] as? String,
            let progress = userInfo["progress"] as? Double else {
                return
        }
        guard let index = songs.firstIndex(where: { $0.downloadURL.absoluteString == url }) else {
            return
        }
        var song = songs[index]
        song.downloadingState = progress == 0 ? .startedDownloading : .progress(progress)
        songs[index] = song
        tableView.reloadData()
        refreshSelectedSong()
    }
    
    func refreshSelectedSong() {
        guard let index = selectedSongIndex else {
            return
        }
        let song = songs[index]
        switch song.downloadingState {
        case .didNotStarted:
            downloadButton.isHidden = false
            downloadingLabel.isHidden = true
            downloadProgressLabel.isHidden = true
        case .startedDownloading:
            downloadButton.isHidden = true
            downloadingLabel.isHidden = false
            downloadProgressLabel.isHidden = true
        case .progress(let progress):
            downloadButton.isHidden = true
            downloadingLabel.isHidden = false
            downloadProgressLabel.isHidden = false
            downloadProgressLabel.text = "\(Int(progress * 100))"
        case .downloaded:
            downloadButton.isHidden = true
            downloadingLabel.isHidden = true
            downloadProgressLabel.isHidden = true
        }
        nameLabel.text = song.title
        backgroundImage.sd_setImage(with: song.coverURL)
    }
    
    private func initiateDownload(song: SongsDownloader.Song, allowCaptcha: Bool = true) {
        SongsDownloader.instance.downloadSong(song, completion: { [weak self] (result) in
            guard let `self` = self else {
                return
            }
            DispatchQueue.main.async {
                switch result {
                case .captchaRequired(let song) where allowCaptcha:
                    let captchaScreen = CaptchaViewController(song: song, completion: { done in
                        if done {
                            self.initiateDownload(song: song, allowCaptcha: false)
                        }
                    })
                    let navigation = UINavigationController(rootViewController: captchaScreen)
                    self.present(navigation, animated: true, completion: nil)
                case .captchaRequired:
                    self.showErrorAlert(error: nil)
                case .failed(let error):
                    self.showErrorAlert(error: error)
                case .success:
                    if let index = self.songs.firstIndex(where: { $0.beatmapId == song.beatmapId }) {
                        var newSong = song
                        newSong.downloadingState = .downloaded
                        self.songs.replaceSubrange(index ... index, with: [newSong])
                        self.tableView.reloadData()
                        self.refreshSelectedSong()
                    }
                }
            }
        })
    }
    
    func showErrorAlert(error: Error?) {
        let controller = UIAlertController(title: "Downloading failed", message: error?.localizedDescription, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func back(_ sender: Any) {
        SoundPlayer.instance.playSound(.menuClick)
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func downloadSelectedSong(_ sender: Any) {
        guard let index = selectedSongIndex else {
            return
        }
        let song = songs[index]
        initiateDownload(song: song)
    }
}

extension DownloadSongsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedSongIndex = indexPath.row
        refreshSelectedSong()
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == songs.count - 1 {
            fetchMoreSongs()
        }
    }
}

extension DownloadSongsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SongSelectionCell
        let song = songs[indexPath.row]
        
        let textColor = selectedSongIndex == indexPath.row ? #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) : #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        cell.backgroundColorView.backgroundColor = selectedSongIndex == indexPath.row ? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        cell.nameLabel.textColor = textColor
        cell.nameLabel.text = song.title
        cell.difficultyLabel.textColor = textColor
        cell.difficultyLabel.text = "Artist: \(song.artist)"
        cell.rateViewContainer.isHidden = false
        cell.rateLabel.textColor = textColor
        cell.backgroundImageView.sd_setImage(with: song.thumbnailURL)
        switch song.downloadingState {
        case .didNotStarted: cell.rateLabel.text = ""
        case .startedDownloading: cell.rateLabel.text = "↧"
        case .downloaded: cell.rateLabel.text = "✔"
        case .progress(let progress): cell.rateLabel.text = "\(Int(progress * 100))"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70.0
    }
}
