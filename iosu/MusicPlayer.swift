//
//  MusicPlayer.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import AVFoundation

enum MusicState {
    case playing
    case paused
    case stopped
}

class MusicPlayer: NSObject {
    
    static let player = MusicPlayer()
    
    private(set) var musicPlayer: AVAudioPlayer?
    open var state: MusicState = .stopped
    
    func loadFile(_ file: String) {
        let url = URL(fileURLWithPath: file)
        self.musicPlayer = try! AVAudioPlayer(contentsOf: url)
        self.musicPlayer?.numberOfLoops = 0
        self.musicPlayer?.volume = Float(Settings.instance.musicVolume)
        self.musicPlayer?.delegate = self
        state = .paused
    }
    
    func pause() {
        if isPlaying() {
            musicPlayer?.pause()
        }
        state = .paused
    }
    
    func play() {
        if !isPlaying() {
            musicPlayer?.play()
        }
        state = .playing
    }
    
    func rewind(at time: TimeInterval) {
        musicPlayer?.currentTime = time
    }
    
    func stop() {
        musicPlayer?.stop()
        state = .stopped
    }
    
    func isPlaying() -> Bool{
        if musicPlayer == nil {
            return false
        }
        return musicPlayer!.isPlaying
    }
}

extension MusicPlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        state = .stopped
    }
}
