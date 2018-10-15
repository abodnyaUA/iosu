//
//  MainMenuViewController.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/15/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit

class MainMenuViewController: UIViewController {

    @IBOutlet weak var playButton: MainMenuButton!
    @IBOutlet weak var settingButton: MainMenuButton!
    @IBOutlet weak var downloadButton: MainMenuButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        playButton.titleLabel.text = "Play"
        playButton.subtitleLabel.text = "Enjoy some beat-clicking action!"
        playButton.addTarget(self, action: #selector(showSongsSelection), for: .touchUpInside)
        
        settingButton.titleLabel.text = "Settings"
        settingButton.subtitleLabel.text = "Change osu! settings"
        
        downloadButton.titleLabel.text = "Get songs"
        downloadButton.subtitleLabel.text = "Download more songs"
    }
    
    @objc func showSongsSelection() {
        SoundPlayer.instance.playSound(.menuClick)
        let viewController = storyboard!.instantiateViewController(withIdentifier: "selection")
        navigationController?.pushViewController(viewController, animated: true)
    }

}
