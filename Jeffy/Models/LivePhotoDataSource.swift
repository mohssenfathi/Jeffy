//
//  LivePhotoDataSource.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/17/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class LivePhotoDataSource: NSObject {

    var livePhotos = PhotosManager.shared.livePhotos {
        didSet {
            updated?(livePhotos)
        }
    }
    var updated: (([PHAsset]) -> ())?

}

extension LivePhotoDataSource: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return livePhotos.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "LivePhotoCollectionViewCell", for: indexPath)
    }
}
