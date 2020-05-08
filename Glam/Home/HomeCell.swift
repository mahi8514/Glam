//
//  HomeCell.swift
//  Glam
//
//  Created by Mahin Ibrahim on 08/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import UIKit
import Kingfisher

class HomeCell: UICollectionViewCell {
    
    static let cellIdentifier = "HomeCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var category: CDCategory! {
        didSet {
            titleLabel.text = category.name
            imageView.kf.setImage(with: URL(string: self.category.image!)!)
        }
    }
    
}
