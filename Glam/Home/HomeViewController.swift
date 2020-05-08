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
    private var searchController: UISearchController!
    
    var viewModel: HomeViewModel!
    
    private var cancellable = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
    }
    
    private func configureUI() {
        configureCollectionView()
        configureSearchController()
        configureDataSource()
    }
    
    private func configureCollectionView() {
        collectionView.refreshControl = refreshControl
        collectionView.collectionViewLayout = createLayout()
    }
    
    private func configureSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.definesPresentationContext = true
        navigationItem.searchController = searchController
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, CDCategory>(collectionView: collectionView) {
            (collectionView, indexPath, model) -> UICollectionViewCell? in

            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeCell.cellIdentifier,
                                                                for: indexPath)
                as? HomeCell else { fatalError("Cannot create new cell") }
            cell.category = model
            return cell
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(0.5))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let spacing = CGFloat(10)
        group.interItemSpacing = .fixed(spacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func bindViewModel() {
        let input = HomeViewModel.Input(trigger: Just(()).eraseToAnyPublisher(),
                                        pullToRefreshTrigger: refreshControl.isRefreshingPublisher
                                            .filter { $0 }
                                            .map { _ in Void() }
                                            .eraseToAnyPublisher(),
                                        keywordTrigger: searchController.searchBar.searchTextField.textPublisher,
                                        deleteTrigger: deleteButton.tapPublisher)
        let output = viewModel.transform(input: input)
        
        output.title.assign(to: \.title, on: navigationItem).store(in: &cancellable)
        output.searchBarPlaceHolder.assign(to: \.placeholder, on: searchController.searchBar.searchTextField).store(in: &cancellable)
        
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
    
    private func applySnapShot(with items: [CDCategory], animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CDCategory>()
        snapshot.appendSections([0])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    deinit {
        print("Homevc deinit")
    }

}
