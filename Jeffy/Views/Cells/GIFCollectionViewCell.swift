//
//  GIFCell.swift
//  Keebo
//
//  Created by Mohssen Fathi on 3/4/16.
//  Copyright © 2016 Mohammad Fathi. All rights reserved.
//

import UIKit
import Gifu
import AlamofireImage
import M13ProgressSuite

class GIFCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: GIFImageView!
    @IBOutlet weak var progressBar: M13ProgressViewBar!
    @IBOutlet weak var saveButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.contentMode = .scaleAspectFill
        
        progressBar.showPercentage = false
        progressBar.setProgress(0.0, animated: false)
        self.imageView.startAnimatingGIF()
    }
    
    var isLoading: Bool = false {
        didSet {
            progressBar.indeterminate = isLoading
//            isLoading ? imageView.startAnimatingGIF() : imageView.stopAnimatingGIF()
        }
    }
    
    var gif: GIF? {
        didSet {
            
            imageView.image = nil
            
            if gif?.hasBeenSaved == true {
                self.saveButton.setImage(#imageLiteral(resourceName: "LivePhotoSuccess"), for: .normal)
                self.saveButton.setTitle("  Saved", for: .normal)
            } else {
                self.saveButton.setImage(#imageLiteral(resourceName: "LivePhoto"), for: .normal)
                self.saveButton.setTitle("  Save as Live Photo", for: .normal)
            }

//            guard let urlS = gif?.url, let url = URL(string: urlS) else { return }
//            self.imageView.af_setImage(withURL: url)
            
            guard let gif = gif else { return }
            isLoading = true
            GIFManager.shared.data(for: gif, with: .medium) { data in
                guard let data = data else { return }
                self.imageView.animate(withGIFData: data)
                self.imageView.startAnimatingGIF()
                self.isLoading = false
            }
        }
    }
    
    @IBAction func saveLivePhotoButtonPressed(_ sender: UIButton) {
        
        progressBar.indeterminate = true
        
        guard let gif = gif else {
            failedToSave()
            progressBar.indeterminate = false
            return
        }
        
        GIFManager.shared.exportLivePhoto(for: gif) { (success, error) in
            
            DispatchQueue.main.async {
                
                self.progressBar.indeterminate = false
                if success {
                    self.successfullySaved()
                } else {
                    self.failedToSave()
                    print(error?.localizedDescription ?? "")
                }
            }
        }
    }
    
    func failedToSave() {
        UIView.transition(with: saveButton, duration: 0.25, options: .transitionCrossDissolve, animations: { 
            self.saveButton.setImage(#imageLiteral(resourceName: "LivePhotoFailure"), for: .normal)
            self.saveButton.setTitle("  Couldn't Save Live Photo", for: .normal)
        }) { finished in
            
        }
    }
    
    func successfullySaved() {
        UIView.transition(with: saveButton, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.saveButton.setImage(#imageLiteral(resourceName: "LivePhotoSuccess"), for: .normal)
            self.saveButton.setTitle("  Saved", for: .normal)
        }) { finished in
            
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.prepareForReuse()
    }
}



