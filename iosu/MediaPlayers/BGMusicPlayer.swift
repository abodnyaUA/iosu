//
//  MusicPlayer.swift
//  iosu
//
//  Created by xieyi on 2017/3/30.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import Foundation
import AVFoundation
import SpriteKit
import QuartzCore

class BGMusicPlayer: MusicPlayer {
    
    static let instance = BGMusicPlayer()
    
    open var gameEarliest:Int = 0
    open var videoEarliest:Int = 0
    open var sbEarliest:Int = 0
    open weak var gameScene: GamePlayScene?
    open weak var sbScene: StoryBoardScene?
    fileprivate var startTime: Double = 0
    
    func startPlaying() {
        debugPrint("game earliest: \(gameEarliest)")
        debugPrint("video earliest: \(videoEarliest)")
        debugPrint("sb earliest: \(sbEarliest)")
        var offset = -min(gameEarliest,videoEarliest,sbEarliest)
        debugPrint("music offset: \(offset)")
        if offset < 3000 {
            offset = 3000
        } else {
            offset += 100
        }
        startTime = CACurrentMediaTime() + Double(offset)/1000
        let musicnode = SKNode()
        if gameScene != nil {
            gameScene?.addChild(musicnode)
        } else {
            sbScene?.addChild(musicnode)
        }
        musicnode.run(SKAction.sequence([SKAction.wait(forDuration: Double(offset)/1000), SKAction.run { [unowned self] in
            self.musicPlayer?.prepareToPlay()
            self.musicPlayer?.play()
            self.state = .playing
            self.startTime = CACurrentMediaTime()
        }]))
    }
    
    func getTime() -> TimeInterval{
        return CACurrentMediaTime() - startTime
    }
}
