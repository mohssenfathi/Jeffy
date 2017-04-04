//
//  LivePhotoViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/1/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Gifu

class LivePhotoViewController: UIViewController {
    
    @IBOutlet weak var imageView: GIFImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.imageView.contentMode = .scaleAspectFit
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        GIFManager.shared.random { gif in
            gif?.data { data in
                guard let data = data else { return }
                self.imageView.animate(withGIFData: data)
            }
        }
    }
}
