//
//  LivePhotoCollectionViewCell.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/17/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import PhotosUI

enum LivePhotoState: Int {
    case stopped = 0
    case playing
}

class LivePhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: PHLivePhotoView!
    
    var state: LivePhotoState = .stopped {
        didSet {
            if state != oldValue {
                state == .playing ? imageView.startPlayback(with: .full) : imageView.stopPlayback()
            }
        }
    }
    
    var livePhoto: PHLivePhoto? {
        didSet { updateLivePhoto() }
    }
    
    func updateLivePhoto() {
        imageView.livePhoto = livePhoto
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // TODO: - Use long press gesture if force not available
        state = touch.force > 2.0 ? .playing : .stopped
    }
}
