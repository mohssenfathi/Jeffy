//
//  LivePhotoViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/1/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Photos

class LivePhotoViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let dataSource = LivePhotoDataSource()
    var didSelect: ((PHAsset) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = dataSource
        dataSource.updated = { livePhotos in
            self.collectionView.reloadData()
        }
    }
}

extension LivePhotoViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
 
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.width)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let cell = cell as? LivePhotoCollectionViewCell else { return }
        
        PhotosManager.shared.livePhoto(for: dataSource.livePhotos[indexPath.item]) { (livePhoto, info) in
            cell.livePhoto = livePhoto
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelect?(dataSource.livePhotos[indexPath.item])
    }
    
}
