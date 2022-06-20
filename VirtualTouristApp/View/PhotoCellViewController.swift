//
//  PhotoCellViewController.swift
//  VirtualTouristApp
//
//  Created by Daniel Felipe Valencia Rodriguez on 12/06/22.
//

import Foundation
import UIKit

class PhotoCellViewController: UICollectionViewCell {
    
    @IBOutlet weak var imageCell: UIImageView!
    @IBOutlet weak var activityIndicatorCell: UIActivityIndicatorView!
    
    var id: UUID? = nil
    
    func configure() {
        self.imageCell.image = nil
        self.imageCell.contentMode = .scaleAspectFill
        self.activityIndicatorCell.hidesWhenStopped = true
        //self.couldntLoadImageLabel.isHidden = true
    }
    
}
