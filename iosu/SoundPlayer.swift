//
//  SoundPlayer.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit
import AudioToolbox

enum Sound: String {
    case applause = "applause.mp3"
    case comboBreak = "combobreak.mp3"
    case count = "count.wav"
    case count1s = "count1s.wav"
    case count2s = "count2s.wav"
    case count3s = "count3s.wav"
    case drumHitClap = "drum-hitclap.wav"
    case drumHitFinish = "drum-hitfinish.wav"
    case drumHitNormal = "drum-hitnormal.wav"
    case drumHitWhistle = "drum-hitwhistle.wav"
    case drumSliderslide = "drum-sliderslide.wav"
    case drumSlidertick = "drum-slidertick.wav"
    case drumSliderWhistle = "drum-sliderwhistle.wav"
    case failSound = "failsound.mp3"
    case gos = "gos.wav"
    case menuBack = "menuback.wav"
    case menuClick = "menuclick.wav"
    case menuHit = "menuhit.wav"
    case normalHitClap = "normal-hitclap.wav"
    case normalHitFinish = "normal-hitfinish.wav"
    case normalHitNormal = "normal-hitnormal.wav"
    case normalHitWhistle = "normal-hitwhistle.wav"
    case normalSliderSlide = "normal-sliderslide.wav"
    case normalSliderTick = "normal-slidertick.wav"
    case normalSliderWhistle = "normal-sliderwhistle.wav"
    case readys = "readys.wav"
    case sectionfail = "sectionfail.mp3"
    case sectionpass = "sectionpass.mp3"
    case softHitClap = "soft-hitclap.wav"
    case softHitFinish = "soft-hitfinish.wav"
    case softHitNormal = "soft-hitnormal.wav"
    case softHitWhistle = "soft-hitwhistle.wav"
    case softSliderSlide = "soft-sliderslide.wav"
    case softSliderTick = "soft-slidertick.wav"
    case softSliderWhistle = "soft-sliderwhistle.wav"
    case spinnerBonus = "spinnerbonus.wav"
    case spinnerSpin = "spinnerspin.wav"
}

class SoundPlayer: NSObject {
    
    static let instance = SoundPlayer()
    private var soundIDs = [String: SystemSoundID]()

    func playSound(_ sound: Sound) {
        if let soundID = soundIDs[sound.rawValue] {
            AudioServicesPlaySystemSound(soundID)
        } else {
            let fileName = sound.rawValue
            let components = fileName.components(separatedBy: ".")
            let filePath = Bundle.main.path(forResource: components[0], ofType: components[1])!
            let soundURL = NSURL(fileURLWithPath: filePath)
            
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL, &soundID)
            soundIDs[sound.rawValue] = soundID
            
            AudioServicesPlaySystemSound(soundID)
        }
    }
}
