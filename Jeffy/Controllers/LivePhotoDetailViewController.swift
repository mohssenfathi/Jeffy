//
//  LivePhotoDetailViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/18/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Photos
import Gifu
import NSGIF2

class LivePhotoDetailViewController: UIViewController {

    @IBOutlet weak var imageView: GIFImageView!
    
    var asset: PHAsset? {
        didSet {
            loadLivePhoto()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func loadLivePhoto() {
        
        guard let asset = asset else { return }
        
        PhotosManager.shared.livePhoto(for: asset) { (livePhoto, info) in
            
            livePhoto?.gif { url in

                guard let url = url else {
                    print("Error creating GIF")
                    return
                }
                
                if let data = try? Data(contentsOf: url) {
                    self.imageView.animate(withGIFData: data)
                }
            }
        }
    }
    
}

extension PHLivePhoto {
    
    func gif(_ completion: @escaping ((URL?) -> ())) {
        
        let resources = PHAssetResource.assetResources(for: self)
        guard  //let imageResource = resources.first,
            let movResource = resources.last else {
            return completion(nil)
        }

        self.save(resource: movResource, with: "/export.mov") { (url, error) in
            
            guard let url = url else {
                print(error?.localizedDescription ?? "")
                return completion(nil)
            }
            
            let request = NSGIFRequest(sourceVideo: url)
            request.framesPerSecond = 8
            NSGIF.create(request, completion: { (url) in
                completion(url)
            })
        }
    }
    
    private func save(resource: PHAssetResource, with name: String, completion: @escaping ((URL?, Error?) -> ())) {
        
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first?.appending(name) else {
            completion(nil, nil)
            return
        }
        
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
     
        PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: nil) { error in
            completion(url, error)
        }
    }
}
