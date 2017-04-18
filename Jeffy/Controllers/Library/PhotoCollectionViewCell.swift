//
//  PhotoCollectionViewCell.swift
//  LumenCamera
//
//  Created by Mohssen Fathi on 6/29/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit
//import UICircularProgressRing

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var loadingView: UIView!
//    @IBOutlet weak var progressIndicator: UICircularProgressRingView!
    @IBOutlet weak var containerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.loadingView.isHidden = true
//        layer.borderColor = UIColor.cellBorder.cgColor
    }
    
    override var isSelected: Bool {
        didSet {
            layer.borderWidth = isSelected ? 4.0 : 0.0
        }
    }
    
    
    func set(progress: Double, animated: Bool) {

        if progress == 1.0 && loadingView.isHidden { return }
        
        DispatchQueue.main.async {
        
            self.loadingView.isHidden = false
//            self.progressIndicator.setProgress(value: CGFloat(progress), animationDuration: 0.2) {
//                if progress == 1.0 {
//                    self.perform(#selector(PhotoCollectionViewCell.hideProgressIndicator), with: nil, afterDelay: 1.0)
//                }
//            }
        }
    }
    
    func hideProgressIndicator() {
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.3, animations: {
                self.loadingView.alpha = 0.0
            }) { (finished) in
                self.loadingView.isHidden = true
                self.loadingView.alpha = 1.0
            }
        }
    }
}
