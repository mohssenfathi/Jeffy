//
//  GIFDataSource.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/2/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

class GIFDataSource: NSObject {

    var gifs = [GIF]()
    var updated: (() -> ())?
    
    var keyword: String = "" {
        didSet {
            clear()
            update()
        }
    }
    
    func clear() {
        gifs.removeAll()
    }
    
    func update() {
        
        if keyword == "" {
            GIFManager.shared.trending(count: 25, offset: gifs.count) { gifs in
                self.gifs.append(contentsOf: gifs)
                self.updated?()
            }
        }
        else {
            GIFManager.shared.search(keyword: keyword, count: 25, offset: gifs.count) { gifs in
                self.gifs.append(contentsOf: gifs)
                self.updated?()
            }
        }
    }
 
}

extension GIFDataSource: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 1 }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return gifs.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "GIFCollectionViewCell", for: indexPath)
    }
}
