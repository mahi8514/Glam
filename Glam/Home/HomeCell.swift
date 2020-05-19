//
//  HomeCell.swift
//  Glam
//
//  Created by Mahin Ibrahim on 08/05/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import UIKit
import Combine
import Kingfisher

struct HomeCellViewModel {
    
    private let category: CDCategory
    
    var name: AnyPublisher<String?, Never> {
        AnyPublisher { $0(.value(self.category.name)) }
    }

    var imageURL: AnyPublisher<String?, Never> {
        AnyPublisher { $0(.value(self.category.highResImage)) }
    }
    
    init(category: CDCategory) {
        self.category = category
    }
}

extension HomeCellViewModel: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(category.id)
    }
}

class HomeCell: UICollectionViewCell {
    
    static let cellIdentifier = "HomeCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    private var cancellable = Set<AnyCancellable>()
    
    func bind(viewModel: HomeCellViewModel) {
        viewModel.name.assign(to: \.text, on: titleLabel).store(in: &cancellable)
        viewModel.imageURL.filterNil().map { $0.url! }.setKfImage(to: imageView).store(in: &cancellable)
    }
    
//    private func setImageView(with regularImageUrl: String, lowDataImageUrl: String) {
//        guard let regularUrl = regularImageUrl.url, let lowDataURL = lowDataImageUrl.url else { return }
//        subscriber = URLSession.shared.adaptiveLoader(regularURL: regularUrl, lowDataURL: lowDataURL)
//            .retry(1)
//            .map { UIImage(data: $0) }
//            .replaceError(with: #imageLiteral(resourceName: "image-placeholder"))
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.image, on: imageView)
//    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        cancellable.removeAll()
    }
    
}
