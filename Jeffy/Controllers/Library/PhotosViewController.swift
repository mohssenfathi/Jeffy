//
//  PhotosViewController.swift
//  LumenCamera
//
//  Created by Mohssen Fathi on 6/29/16.
//  Copyright © 2016 mohssenfathi. All rights reserved.
//

import UIKit
import Photos

protocol PhotosViewControllerDelegate {
    func photosViewController(_ sender: PhotosViewController, didSelect photo: PHAsset)
    func photosViewController(_ sender: PhotosViewController, didLongPress photo: PHAsset, at indexPath: IndexPath)
}

class PhotosViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
//    @IBOutlet weak var noPhotosLabel: UILabel!
    @IBOutlet weak var closeButton: UIBarButtonItem!
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!

    var isSelectedMode: Bool = false {
        didSet {
            if collectionView != nil {
                if isSelectedMode != oldValue { collectionView.reloadData() }
            }
        }
    }
    
    var delegate: PhotosViewControllerDelegate?
    
    var assets = [PHAsset]() {
        didSet {
            if noPhotosLabel  != nil { noPhotosLabel.isHidden = (assets.count > 0) }
            if collectionView != nil { collectionView.reloadData() }
        }
    }
    var selectedIndex: Int = NSNotFound
    var imagesPerRow: Int {
        return min(Int(view.frame.width/100.0), 7)
    }
    let gap: CGFloat = 2.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
//        noPhotosLabel.isHidden = (assets.count > 0)
        collectionView.allowsMultipleSelection = true
        collectionView.reloadData()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: collectionView)
        }
        
    }
    
    @IBAction func closeButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButtonPressed(_ sender: UIBarButtonItem) {
        
    }
    
    
    @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        
        if let indexPath = collectionView.indexPathForItem(at: sender.location(in: collectionView)) {
            delegate?.photosViewController(self, didLongPress: assets[indexPath.item], at: indexPath)
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "photoPreview" {
            let photoPreviewViewController = segue.destination as! PhotoPreviewViewController
            photoPreviewViewController.delegate = self
            if selectedIndex != NSNotFound {
                photoPreviewViewController.asset = assets[selectedIndex]
            }
        }
        
    }

}

extension PhotosViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension PhotosViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
 
    //    MARK: DataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let ipr = isSelectedMode ? imagesPerRow - 1 : imagesPerRow
        let width = (collectionView.frame.width)/CGFloat(ipr) - gap
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if isSelectedMode {
            return UIEdgeInsetsMake(15, 2, 0, 2)
        }
        return UIEdgeInsetsMake(0, 2, 0, 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! PhotoCollectionViewCell
        
        if isSelectedMode {
            cell.containerView.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10)
            cell.imageView.layer.masksToBounds = true
            cell.imageView.layer.cornerRadius = 5.0
        } else {
            cell.containerView.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 0)
            cell.imageView.layer.cornerRadius = 0.0
        }
        
        let asset = assets[(indexPath as NSIndexPath).item]
        let size = cell.frame.size * UIScreen.main.scale
        
        PhotosManager.shared.imageForAsset(asset, size: size, progress: nil) { (resultImage) in
            cell.imageView.image = resultImage
        }
        
        return cell
    }
    
    
    //    MARK: Delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    
}


extension PhotosViewController: PhotoPreviewViewControllerDelegate {
    
    func copy(_ previewController: PhotoPreviewViewController, image: UIImage) {
        UIPasteboard.general.image = image
    }
    
    func share(_ previewController: PhotoPreviewViewController, image: UIImage) {
        
        guard let imageData = UIImageJPEGRepresentation(image, 1.0) else { return }
        
        let activityController = UIActivityViewController(activityItems: [imageData], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }

}


extension PhotosViewController: UIViewControllerPreviewingDelegate {
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
    
    @available(iOS 9.0, *)
    public func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {

        guard let indexPath = collectionView.indexPathForItem(at: location) else { return nil }

        if let attributes = collectionView.layoutAttributesForItem(at: indexPath) {
            selectedIndex = indexPath.item
            previewingContext.sourceRect = attributes.frame
        }
        
        guard let photoPreviewViewController: PhotoPreviewViewController = storyboard?.instantiateViewController(withIdentifier: "PhotoPreviewViewController") as? PhotoPreviewViewController else {
            return nil
        }

        let asset = assets[indexPath.item]
        photoPreviewViewController.asset = asset
        photoPreviewViewController.delegate = self
        
        let ratio: CGFloat = CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
        photoPreviewViewController.preferredContentSize = CGSize(width: view.frame.width, height: view.frame.width * ratio)
        
        return photoPreviewViewController
    }
}

func /(left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width/right, height: left.height/right)
}

func -(left: CGPoint, right: CGSize) -> CGPoint {
    return CGPoint(x: left.x - right.width, y: left.y - right.height)
}

func *(left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}
