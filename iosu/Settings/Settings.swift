//
//  Settings.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit

class Settings: NSObject {

    static let instance = Settings()
    let defaults = UserDefaults.standard
    
    override init() {
        super.init()
        defaults.register(defaults: [
            "showGame": true,
            "showVideo": true,
            "showStoryboard": true,
            "useSkin": true,
            "backgroundDim": 0.3,
            "musicVolume": 1.0,
            "effectsVolume": 0.5,
        ])
    }
    
    var showGame: Bool {
        get { return defaults.bool(forKey: "showGame") }
        set { defaults.set(newValue, forKey: "showGame") }
    }
    
    var showVideo: Bool {
        get { return defaults.bool(forKey: "showVideo") }
        set { defaults.set(newValue, forKey: "showVideo") }
    }
    
    var showStoryboard: Bool {
        get { return defaults.bool(forKey: "showStoryboard") }
        set { defaults.set(newValue, forKey: "showStoryboard") }
    }
    
    var useSkin: Bool {
        get { return defaults.bool(forKey: "useSkin") }
        set { defaults.set(newValue, forKey: "useSkin") }
    }
    
    var backgroundDim: Double {
        get { return defaults.double(forKey: "backgroundDim") }
        set { defaults.set(newValue, forKey: "backgroundDim") }
    }
    
    var musicVolume: Double {
        get { return defaults.double(forKey: "musicVolume") }
        set { defaults.set(newValue, forKey: "musicVolume") }
    }
    
    var effectsVolume: Double {
        get { return defaults.double(forKey: "effectsVolume") }
        set { defaults.set(newValue, forKey: "effectsVolume") }
    }
}
