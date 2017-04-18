//
//  GIFViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/1/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Photos
import PhotosUI
import AVFoundation
import Gifu

class GIFViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchTextField: UITextField!
    
    let dataSource = GIFDataSource()
    var currentURLs: (photoURL: URL, videoURL: URL)?
    var didSelect: ((GIF) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = dataSource
        dataSource.updated = {
            self.searchTextField.resignFirstResponder()
            self.collectionView.reloadData()
        }
        
        GIFManager.shared.trending { gifs in
            self.dataSource.gifs = gifs
            self.dataSource.update()
        }
    }
    
    func updateGIF() {
        
        GIFManager.shared.random { gif in
            
            gif?.livePhoto { livePhoto, info, urls in
                
//                self.imageView.livePhoto = livePhoto
//                self.imageView.startPlayback(with: .hint)
                
                guard let urls = urls,
                    let photoURL = URL(string: urls.0),
                    let videoURL = URL(string: urls.1) else {
                        return
                }
                
                self.currentURLs = (photoURL, videoURL)
            }
        }
    }
}

extension GIFViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dataSource.keyword = textField.text ?? ""
        return true
    }
}


extension GIFViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let asset = dataSource.gifs[indexPath.item].asset(for: .preview) {
            if let height = asset.height, let width = asset.width {
                let ratio = CGFloat(height) / CGFloat(width)
                return CGSize(width: collectionView.frame.width, height: collectionView.frame.width * ratio + 60.0)
            }
        }
        
        
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? GIFCollectionViewCell else { return }
        cell.gif = dataSource.gifs[indexPath.item]
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelect?(dataSource.gifs[indexPath.item])
    }
}
