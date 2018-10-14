//
//  GameViewController.swift
//  iosu
//
//  Created by xieyi on 2017/3/28.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    static var showgame = true
    static var showvideo = true
    static var showsb = true
    var alert: UIAlertController!
    let runtestscene = false
    @IBOutlet weak var backBtn: UIButton!
    
    var songInfo: SongInfo!
    var beatmapFile: BeatmapFile!
    
    class func create(songInfo: SongInfo, beatmapFile: BeatmapFile) -> GameViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "game") as! GameViewController
        viewController.songInfo = songInfo
        viewController.beatmapFile = beatmapFile
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenWidth = UIScreen.main.bounds.width * UIScreen.main.scale
        let screenHeight = UIScreen.main.bounds.height * UIScreen.main.scale
        let screenSize = CGSize(width: screenWidth, height: screenHeight)
        
        guard let folderPath = songInfo.folderPath,
            let beatmapPath = beatmapFile.filePath,
            let beatmap = try? Beatmap(file: beatmapPath) else {
            return
        }
        
        var maxfps: Int
        if #available(iOS 10.3, *) {
            maxfps = UIScreen.main.maximumFramesPerSecond
        } else {
            maxfps = 60
        }
        debugPrint("Max FPS: \(maxfps)")
        view?.autoresizesSubviews=true
        view.backgroundColor = .black
        if runtestscene {
            let scene = TestScene(size: screenSize)
            let skView = self.view as! SKView
            skView.preferredFramesPerSecond = maxfps
            skView.showsFPS = true
            skView.showsNodeCount = true
            skView.showsDrawCount = true
            skView.showsQuadCount = true
            skView.ignoresSiblingOrder = true
            skView.allowsTransparency = true
            scene.scaleMode = .aspectFit
            scene.backgroundColor = .cyan
            skView.presentScene(scene)
            return
        }
        if GameViewController.showsb {
            let storyboard = songInfo.storyboards?.anyObject() as? StoryboardFile
            let sbScene = StoryBoardScene(folderPath: folderPath, storyBoardPath: storyboard?.filePath, osuFilePath: beatmapPath, beatmap: beatmap, size: screenSize, parent: self)
            let sbView = SKView(frame: UIScreen.main.bounds)
            sbView.layer.zPosition = 0
            self.view.addSubview(sbView)
            sbView.preferredFramesPerSecond = maxfps
            sbView.showsFPS = true
            sbView.showsNodeCount = true
            sbView.showsDrawCount = true
            sbView.showsQuadCount = true
            sbView.ignoresSiblingOrder = true
            sbView.layer.zPosition = 0
            sbScene.scaleMode = .aspectFit
            sbView.presentScene(sbScene)
        }
        if GameViewController.showvideo {
            //For video play
            BGVPlayer.initialize()
            BGVPlayer.view?.layer.zPosition = 1
            view.addSubview(BGVPlayer.view!)
        }
        if GameViewController.showgame {
            let gameScene = GamePlayScene(folderPath: folderPath, beatmap: beatmap, size: screenSize)
            //let skView=self.view as! SKView
            let gameView = SKView(frame: UIScreen.main.bounds)
            gameView.preferredFramesPerSecond = maxfps
            gameView.layer.zPosition = 2
            self.view.addSubview(gameView)
            //skView.allowsTransparency=true
            gameView.backgroundColor = .clear
            //(self.view as! SKView).allowsTransparency=true
            if GameViewController.showsb {
                gameView.showsFPS = false
                gameView.showsNodeCount = false
            } else {
                gameView.showsFPS = true
                gameView.showsNodeCount = true
                gameView.showsDrawCount = true
                gameView.showsQuadCount = true
            }
            gameView.ignoresSiblingOrder = true
            gameScene.scaleMode = .aspectFill
            gameScene.backgroundColor = .clear
            gameView.presentScene(gameScene)
        }
        BGMusicPlayer.instance.startPlaying()
        backBtn.removeFromSuperview()
        view.addSubview(backBtn)
        backBtn.layer.zPosition = 5
    }

    @IBAction func onBack(_ sender: Any) {
        BGMusicPlayer.instance.stop()
        BGVPlayer.stop()
        BGVPlayer.view?.removeFromSuperview()
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        debugPrint("scene appears,\(alert)")
        if alert != nil {
            debugPrint("show alert")
            self.present(alert!, animated: true, completion: nil)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .landscape
        } else {
            return .landscape
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
