//
//  GIFDetailViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/15/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit
import Gifu
import AVFoundation

class GIFDetailViewController: UIViewController {

    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var imageView: GIFImageView!
    
    lazy var saveButton: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: #selector(self.saveButtonPressed(_:)))
    }()
    
    var gif: GIF? {
        didSet { loadGIF() }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupView()
    }
    
    func setupView() {
        
        navigationItem.rightBarButtonItems = [saveButton]
        
        // GIF aspect ratio
        if let asset = gif?.asset(for: .preview) {
            if let width = asset.width, let height = asset.height {
                let ratio = CGFloat(height) / CGFloat(width)
                imageViewHeight.constant = containerView.frame.width * ratio
            }
        }
        
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1.0
        
    }
    
    func loadGIF() {

        guard let gif = gif else { return }

        gif.data { data in
            guard let data = data else { return }
            self.imageView.animate(withGIFData: data)
        }
    }
    
    
    // MARK: - Actions
    func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        
        gif?.mov { url in
            
            guard let url = url else { return }
            
            let asset = AVURLAsset(url: url)
            let composition = AVMutableComposition(url: url)
            
        }
        
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let vc = segue.destination as? ColorPickerViewController {
            vc.delegate = self
        }
    }
}

extension GIFDetailViewController: ColorPickerViewControllerDelegate {
    
    func colorPicker(_ sender: ColorPickerViewController, didSelect color: UIColor) {
        containerView.backgroundColor = color
    }
    
    func colorPickerSaveButtonPressed(_ sender: ColorPickerViewController) {
        
    }
    
    func colorPickerCancelButtonPressed(_ sender: ColorPickerViewController) {
        containerView.backgroundColor = .white
    }
}
