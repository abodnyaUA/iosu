//
//  GameScene.swift
//  iosu
//
//  Created by xieyi on 2017/4/2.
//  Copyright © 2017年 xieyi. All rights reserved.
//

import SpriteKit
import SpriteKitEasingSwift
import GameplayKit

class StoryBoardScene: SKScene {
    
    var actiontimepoints = [Int]()
    static var testBMIndex = 4 //The index of beatmap to test in the beatmaps
    var minlayer: CGFloat = 0.0
    var hitaudioHeader: String = "normal-"
    //StoryBoard.stdwidth=854
    var audiofile = ""
    var sb: StoryBoard!
    open weak var viewController: GameViewController?
    static var hasSB = false
    
    let folderPath: String
    let storyBoardPath: String?
    let osuFilePath: String
    let bm: Beatmap
    init(folderPath: String, storyBoardPath: String?, osuFilePath: String, beatmap: Beatmap, size: CGSize, parent: GameViewController) {
        self.viewController = parent
        self.folderPath = folderPath
        self.osuFilePath = osuFilePath
        self.bm = beatmap
        self.storyBoardPath = storyBoardPath
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func sceneDidLoad() {
        self.backgroundColor = .clear
        
        let folderURL = URL(fileURLWithPath: folderPath)
        
        debugPrint("test beatmap:\(folderPath)")
        debugPrint("Enter StoryBoardScene, screen size: \(size.width)*\(size.height)")
        do {
            debugPrint("bgimg:\(bm.bgimg)")
            debugPrint("audio:\(bm.audiofile)")
            debugPrint("colors: \(bm.colors.count)")
            debugPrint("timingpoints: \(bm.timingpoints.count)")
            debugPrint("hitobjects: \(bm.hitobjects.count)")
            audiofile = folderURL.appendingPathComponent(bm.audiofile).path
            if !FileManager.default.fileExists(atPath: audiofile) {
                throw BeatmapError.audioFileNotExist
            }
        } catch BeatmapError.fileNotFound {
            Alerts.show(viewController!, title: "Error", message: "beatmap file not found", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:beatmap file not found")
        } catch BeatmapError.illegalFormat {
            Alerts.show(viewController!, title: "Error", message: "Illegal beatmap format", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:Illegal beatmap format")
        } catch BeatmapError.noAudioFile {
            Alerts.show(viewController!, title: "Error", message: "Audio file not found", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:Audio file not found")
        } catch BeatmapError.audioFileNotExist {
            Alerts.show(viewController!, title: "Error", message: "Audio file does not exist", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:Audio file does not exist")
        } catch BeatmapError.noColor {
            Alerts.show(viewController!, title: "Error", message: "Color not found", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:Color not found")
        } catch BeatmapError.noHitObject{
            Alerts.show(viewController!, title: "Error", message: "No hitobject found", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:No hitobject found")
        } catch let error {
            Alerts.show(viewController!, title: "Error", message: "unknown error(\(error.localizedDescription))", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
            debugPrint("ERROR:unknown error(\(error.localizedDescription))")
        }
        if let storyboardPath = self.storyBoardPath {
            do {
                sb = try StoryBoard(
                    directory: folderPath,
                    osufile: osuFilePath,
                    osbfile: storyboardPath,
                    width: Double(size.width),
                    height: Double(size.height),
                    layer: 0
                )
                debugPrint("storyboard object count: \(String(describing: sb?.sbsprites.count))")
                debugPrint("storyboard earliest time: \(String(describing: sb?.earliest))")
                if (sb?.sbsprites.count)! > 0 {
                    StoryBoardScene.hasSB = true
                } else {
                    return
                }
                if !ImageBuffer.notfoundimages.isEmpty {
                    debugPrint("parent:\(viewController == nil)")
                    viewController?.alert = Alerts.create("Warning", message: ImageBuffer.notfound2str(), style: .alert, action1title: "Cancel", action1style: .cancel, handler1: nil, action2title: "Continue", action2style: .default, handler2: { (action:UIAlertAction)->Void in
                        BGMusicPlayer.instance.sbScene = self
                        BGMusicPlayer.instance.sbEarliest = (self.sb?.sbsprites.first?.starttime)!
                    })
                } else {
                    BGMusicPlayer.instance.sbScene = self
                    BGMusicPlayer.instance.sbEarliest = (sb?.sbsprites.first?.starttime)!
                    BGMusicPlayer.instance.setfile(audiofile)
                }
            } catch StoryBoardError.fileNotFound {
                Alerts.show(viewController!, title: "Error", message: "storyboard file not found", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
                debugPrint("ERROR:storyboard file not found")
            } catch StoryBoardError.illegalFormat {
                Alerts.show(viewController!, title: "Error", message: "illegal storyboard format", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
                debugPrint("ERROR:illegal storyboard format")
            } catch let error {
                Alerts.show(viewController!, title: "Error", message: "unknown error(\(error.localizedDescription))", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
                debugPrint("ERROR:unknown error(\(error.localizedDescription))")
            }
        } else {
            do {
                debugPrint(".osb file not found")
                sb = try StoryBoard(
                    directory: folderPath,
                    osufile: osuFilePath,
                    width: Double(size.width),
                    height: Double(size.height),
                    layer: 0
                )
                debugPrint("storyboard object count: \(String(describing: sb?.sbsprites.count))")
                debugPrint("storyboard earliest time: \(String(describing: sb?.earliest))")
                if (sb?.sbsprites.count)! > 0 {
                    StoryBoardScene.hasSB = true
                } else {
                    return
                }
                if !ImageBuffer.notfoundimages.isEmpty {
                    Alerts.show(viewController!, title: "Warning", message: ImageBuffer.notfound2str(), style: .alert, action1title: "Cancel", action1style: .cancel, handler1: nil, action2title: "Continue", action2style: .default, handler2: { (action:UIAlertAction) -> Void in
                        BGMusicPlayer.instance.sbScene = self
                        BGMusicPlayer.instance.sbEarliest = (self.sb?.sbsprites.first?.starttime)!
                    })
                } else {
                    BGMusicPlayer.instance.sbScene = self
                    BGMusicPlayer.instance.sbEarliest = (sb?.sbsprites.first?.starttime)!
                    BGMusicPlayer.instance.setfile(audiofile)
                }
            } catch StoryBoardError.fileNotFound {
                Alerts.show(viewController!, title: "Error", message: "storyboard file not found", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
                debugPrint("ERROR:storyboard file not found")
            } catch StoryBoardError.illegalFormat {
                Alerts.show(viewController!, title: "Error", message: "illegal storyboard format", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
                debugPrint("ERROR:illegal storyboard format")
            } catch let error {
                Alerts.show(viewController!, title: "Error", message: "unknown error(\(error.localizedDescription))", style: .alert, actiontitle: "OK", actionstyle: .cancel, handler: nil)
                debugPrint("ERROR:unknown error(\(error.localizedDescription))")
            }
        }
    }
    
    var index = 0
    let dispatcher = DispatchQueue(label: "sb_dispatcher")
    
    func destroyNode(_ node: SKNode) {
        for child in node.children {
            destroyNode(child)
        }
        node.removeAllActions()
        node.removeAllChildren()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if BGMusicPlayer.instance.state == .stopped {
            destroyNode(self)
            if let sprites = sb?.sbsprites {
                for img in sprites {
                    img.actions = nil
                }
            }
            sb?.sbactions.removeAll()
            sb = nil
            ImageBuffer.clean()
        }
        dispatcher.async { [unowned self] in
            if BGMusicPlayer.instance.state != .stopped {
                if let sb = self.sb {
                    if self.index < sb.sbsprites.count {
                        var musictime = Int(BGMusicPlayer.instance.getTime() * 1000)
                        while sb.sbsprites[self.index].starttime - musictime <= 2000 {
                            var offset = sb.sbsprites[self.index].starttime - musictime
                            sb.sbsprites[self.index].convertsprite()
                            if offset < 0{
                                offset = 0
                            }
                            if BGMusicPlayer.instance.state == .stopped {
                                return
                            }
                            self.addChild(sb.sbsprites[self.index].sprite!)
                            if sb.sbsprites[self.index].actions != nil {
                                sb.sbsprites[self.index].runaction(offset)
                            }
                            self.index += 1
                            if self.index >= sb.sbsprites.count{
                                return
                            }
                            musictime = Int(BGMusicPlayer.instance.getTime() * 1000)
                        }
                    }
                }
            }
        }
    }
    
}
