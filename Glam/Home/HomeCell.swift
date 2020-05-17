//
//  HomeCell.swift
//  Glam
//
//  Created by Mahin Ibrahim on 08/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import UIKit
import Combine
//import Kingfisher

class HomeCell: UICollectionViewCell {
    
    static let cellIdentifier = "HomeCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var subscriber: AnyCancellable?
    
    var category: CDCategory! {
        didSet {
            titleLabel.text = category.name
            if let regularImageUrl = category.highResImage,
                let lowDataImageUrl = category.lowResImage { setImageView(with: regularImageUrl, lowDataImageUrl: lowDataImageUrl) }
            //if let imageUrl = category.image { imageView.kf.setImage(with: imageUrl.url) }
        }
    }
    
    private func setImageView(with regularImageUrl: String, lowDataImageUrl: String) {
        guard let regularUrl = regularImageUrl.url, let lowDataURL = lowDataImageUrl.url else { return }
        subscriber = URLSession.shared.adaptiveLoader(regularURL: regularUrl, lowDataURL: lowDataURL)
            .retry(1)
            .map { UIImage(data: $0) }
            .replaceError(with: #imageLiteral(resourceName: "image-placeholder"))
            .receive(on: DispatchQueue.main)
            .assign(to: \.image, on: imageView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        subscriber?.cancel()
    }
    
}
