//
//  PageCollectionViewCell.swift
//  Tile
//
//  Created by Mohssen Fathi on 2/8/17.
//  Copyright © 2017 Mohssen Fathi. All rights reserved.
//

import UIKit

class PageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var leftArrow: UIButton!
    @IBOutlet weak var rightArrow: UIButton!
    @IBOutlet weak var underline: UIView!
    
    var image: UIImage? {
        didSet {
            button.setImage(image, for: .normal)
            button.setTitle(nil  , for: .normal)
        }
    }
    
    var title: String? {
        didSet {
            button.setImage(nil  , for: .normal)
            button.setTitle(title, for: .normal)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
