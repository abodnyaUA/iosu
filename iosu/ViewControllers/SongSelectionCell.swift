//
//  SongSelectionCell.swift
//  iosu
//
//  Created by Alexey Bodnya on 10/14/18.
//  Copyright © 2018 iosu. All rights reserved.
//

import UIKit

class SongSelectionCell: UITableViewCell {

    @IBOutlet weak var container: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var backgroundColorView: UIView!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var rateViewContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        container.layer.cornerRadius = 3.0
        container.layer.borderColor = UIColor.black.cgColor
        container.layer.borderWidth = 1.0
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.3
        container.layer.shadowOffset = CGSize(width: 1.0, height: 2.0)
    }
}
