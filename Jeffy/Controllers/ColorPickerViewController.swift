//
//  ColorPickerViewController.swift
//  Jeffy
//
//  Created by Mohssen Fathi on 4/15/17.
//  Copyright © 2017 mohssenfathi. All rights reserved.
//

import UIKit

protocol ColorPickerViewControllerDelegate {
    func colorPicker(_ sender: ColorPickerViewController, didSelect color: UIColor)
    func colorPickerCancelButtonPressed(_ sender: ColorPickerViewController)
    func colorPickerSaveButtonPressed(_ sender: ColorPickerViewController)
}

class ColorPickerViewController: UIViewController {

    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var spectrumView: SpectrumView!

    var delegate: ColorPickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        delegate?.colorPickerCancelButtonPressed(self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        delegate?.colorPickerSaveButtonPressed(self)
        dismiss(animated: true, completion: nil)
    }

    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        
        let colorLocation = sender.location(in: sender.view)
        var normalizedPoint = CGPoint(x: colorLocation.x / spectrumView.frame.width,
                                      y: colorLocation.y / spectrumView.frame.height)
        
        Tools.clamp(&normalizedPoint.x, low: 0, high: 1)
        Tools.clamp(&normalizedPoint.y, low: 0, high: 1)
        
        let color = spectrumView.color(normalizedPoint)
        delegate?.colorPicker(self, didSelect: color)
    }
    
}
