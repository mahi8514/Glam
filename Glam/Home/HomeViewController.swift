//
//  HomeViewController.swift
//  Glam
//
//  Created by Mahin Ibrahim on 28/04/2020.
//  Copyright © 2020 Mahi. All rights reserved.
//

import UIKit
import Combine
import CombineCocoa
import CombineDataSources

class HomeViewController: UIViewController {

    var dataSource: UICollectionViewDiffableDataSource<Int, CDCategory>! = nil

    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var collectionView: UICollectionView!
    private let refreshControl = UIRefreshControl()
    
    var viewModel: HomeViewModel!
    
    private var cancellable = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
    }
    
    private func configureUI() {
        configureCollectionView()
        configureDataSource()
    }
    
    func configureCollectionView() {
        collectionView.refreshControl = refreshControl
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, CDCategory>(collectionView: collectionView) {
            (collectionView, indexPath, model) -> UICollectionViewCell? in

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCell.cellIdentifier,
                                                                for: indexPath)
                as? HomeCell else { fatalError("Cannot create new cell") }
            cell.category = model
            return cell
        }
    }
    
    private func bindViewModel() {
        let input = HomeViewModel.Input(trigger: Just(()).eraseToAnyPublisher(),
                                        pullToRefreshTrigger: refreshControl.isRefreshingPublisher
                                            .filter { $0 }
                                            .map { _ in Void() }
                                            .eraseToAnyPublisher(),
                                        deleteTrigger: deleteButton.tapPublisher)
        let output = viewModel.transform(input: input)
        
        output.title.assign(to: \.title, on: navigationItem).store(in: &cancellable)
        
        // MARK: - Using Diffable Data Sources
        output.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in self?.applySnapShot(with: categories, animated: true)}
            .store(in: &cancellable)
        
        /*
        // MARK: - With animation
        output.items
            .receive(on: DispatchQueue.main)
            .bind(subscriber: collectionView.itemsSubscriber(cellIdentifier: HomeCell.cellIdentifier,
                                                             cellType: HomeCell.self,
                                                             cellConfig: { cell, indexPath, model in
                                                                cell.category = model
            }))
            .store(in: &cancellable)
        */
        
        /*
        // MARK: - Without animation
        
        let controller = CollectionViewItemsController<[[CDCategory]]>(cellIdentifier: HomeCell.cellIdentifier, cellType: HomeCell.self) { (cell, indexPath, model) in
            cell.category = model
        }
        controller.animated = false
        
        output.items
            .receive(on: DispatchQueue.main)
            .bind(subscriber: collectionView.itemsSubscriber(controller))
            .store(in: &cancellable)
        */
        
        output.loadingCompleteEvent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.refreshControl.endRefreshing() }
            .store(in: &cancellable)
    }
    
    func applySnapShot(with items: [CDCategory], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CDCategory>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }


}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 30)) / 2
      return CGSize(width: itemSize, height: itemSize + 10)
    }
}
