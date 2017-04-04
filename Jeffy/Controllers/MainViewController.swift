//
//  MainViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 3/26/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var titleCollectionView: UICollectionView!
    @IBOutlet weak var contentCollectionView: UICollectionView!
    @IBOutlet weak var underlineLeadingConstraint: NSLayoutConstraint!
    
    lazy var gifViewController: GIFViewController? = {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GIFViewController") as? GIFViewController else { return nil }
        vc.title = "GIFs"
        return vc
    }()
    
    lazy var livePhotoViewController: LivePhotoViewController? = {
        guard let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LivePhotoViewController") as? LivePhotoViewController else { return nil }
        vc.title = "Live Photos"
        return vc
    }()

}

// MARK: - UICollectionView
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if collectionView == contentCollectionView {
            return collectionView.frame.size
        }
        
        return CGSize(width: collectionView.frame.width/2.0, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier = collectionView == contentCollectionView ? "ViewControllerCollectionViewCell" : "PageCollectionViewCell"
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let vco: UIViewController? = (indexPath.item == 0) ? gifViewController : livePhotoViewController
        guard let vc = vco else { return }
        
        
        if collectionView == titleCollectionView {
            guard let cell = cell as? PageCollectionViewCell else { return }
            cell.title = vc.title
        }
        else {
            for subview in cell.subviews { subview.removeFromSuperview() }
            
            cell.addSubview(vc.view)
            vc.view.frame = cell.bounds
            
            vc.view.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
            vc.view.rightAnchor.constraint(equalTo: cell.rightAnchor).isActive = true
            vc.view.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true
            vc.view.leftAnchor.constraint(equalTo: cell.leftAnchor).isActive = true
            
            self.addChildViewController(vc)
            vc.didMove(toParentViewController: self)
        }
        
    }
}


// MARK: - UIScrollView
extension MainViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        guard scrollView == contentCollectionView else { return }
        underlineLeadingConstraint.constant = scrollView.contentOffset.x/2.0
    }
    
}










