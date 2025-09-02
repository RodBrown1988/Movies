//
//  MovieGridViewController.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import CoreData
import FastImageCache
import SwiftUI
import UIKit

final class MovieGridViewController: UICollectionViewController {

    let context: NSManagedObjectContext

    var playingMovie: Binding<Movie?>?

    var selectedMovies: Set<Movie> = []

    var selectedMoviesDidChange: ((Set<Movie>) -> Void)?

    private let fetchedResultsController: NSFetchedResultsController<Movie>

    private var diffableDataSource: UICollectionViewDiffableDataSource<String, NSManagedObjectID>?

    private let cache = NSCache<NSManagedObjectID, UIImage>()


    init(context: NSManagedObjectContext) {
        self.context = context

        let layout = UICollectionViewCompositionalLayout { _, environment in
            let itemSize = MovieCollectionViewCell.cellSize(forDisplaySize: environment.container.contentSize)
            let contentWidth = environment.container.effectiveContentSize.width

            // Get max count of cells possible to fit in this width with padding
            let preferredCellCount = floor((contentWidth - 20.0) / (itemSize.width + 20.0))
            let maxCellCount = max(preferredCellCount, 1.0)

            // Get a floored separation. Floor it so we don't end up with bad maths if frameworks round values and we end up with too much separation to fit
            let cellOnlyWidth = ceil(maxCellCount * itemSize.width)
            let nonCellWidth = floor(contentWidth - cellOnlyWidth)
            let separation = floor(nonCellWidth / (maxCellCount + 1))

            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .absolute(itemSize.width),
                heightDimension: .absolute(itemSize.height)
            ))

            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(itemSize.height)),
                repeatingSubitem: item,
                count: Int(preferredCellCount)
            )
            group.interItemSpacing = .fixed(separation)

            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = min(10.0, separation / 4.0 * 3.0)
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: separation, bottom: 16, trailing: 16)
            return section
        }

        let movieRequest = Movie.fetchRequest()
        movieRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: movieRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        super.init(collectionViewLayout: layout)
        fetchedResultsController.delegate = self
    }

    @available(*, unavailable, message: "This class does not support NSCoding")
    required init?(coder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        clearsSelectionOnViewWillAppear = false

        guard let collectionView else { return }

        collectionView.alwaysBounceVertical = true
        collectionView.allowsMultipleSelectionDuringEditing = true

        let cellRegistration = UICollectionView.CellRegistration<MovieCollectionViewCell, Movie> { [weak self] cell, path, movie in
            cell.lastFetchedForIndexPath = path

            if let image = self?.cache.object(forKey: movie.objectID) {
                cell.imageView.image = image
            } else {
                var synchronous = true
                if FICImageCache.shared.retrieveImage(
                    for: movie, withFormatName: FICImageFormat.MovieThumbnailFormatName,
                    completionBlock: { entity, uuid, image in
                        guard let image else { return }

                        self?.cache.setObject(image, forKey: movie.objectID)

                        if synchronous {
                            cell.imageView.image = image
                        } else if let indexPathForFile = self?.fetchedResultsController.indexPath(forObject: movie) {
                            let foundCell: MovieCollectionViewCell

                            // Don't use the current cell - it could have been reused.
                            // Try fetching the current cell, or seeing if the previous cell was last fetched for
                            // this index path.
                            if let cell = collectionView.cellForItem(at: indexPathForFile) as? MovieCollectionViewCell {
                                foundCell = cell
                            } else if cell.lastFetchedForIndexPath == indexPathForFile {
                                foundCell = cell
                            } else {
                                return
                            }

                            let imageView = cell.imageView
                            imageView.image = image

                            if foundCell.window != nil {
                                UIView.transition(with: imageView, duration: 0.2, options: .transitionCrossDissolve, animations: nil)
                            }
                        }
                    }
                ) == false {
                    cell.imageView.image = nil
                }
                synchronous = false
            }
        }

        diffableDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collection, path, itemID in
            collection.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: path,
                item: self?.fetchedResultsController.object(at: path)
            )
        }

        try? fetchedResultsController.performFetch()
    }

    // MARK: - Collection view delegate

    override func collectionView(_ collectionView: UICollectionView, performPrimaryActionForItemAt indexPath: IndexPath) {
        play(fetchedResultsController.object(at: indexPath))
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditing {
            selectedMovies.insert(fetchedResultsController.object(at: indexPath))
            selectedMoviesDidChange?(selectedMovies)
        } else {
            // We don't support selection when not editing, we just use primary actions
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard isEditing else {
            return
        }
        selectedMovies.remove(fetchedResultsController.object(at: indexPath))
        selectedMoviesDidChange?(selectedMovies)
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard
            let id = configuration.identifier as? NSManagedObjectID,
            let movie = fetchedResultsController.managedObjectContext.object(with: id) as? Movie
        else {
            animator.preferredCommitStyle = .dismiss
            return
        }

        animator.preferredCommitStyle = .pop
        animator.addCompletion {
            self.play(movie)
        }
    }

    func deleteMovies(_ movies: [Movie]) {
        for movie in movies {
            fetchedResultsController.managedObjectContext.delete(movie)
        }
        try? context.save()
    }

    func play(_ movie: Movie) {
        playingMovie?.wrappedValue = movie
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard
            collectionView.isEditing == false,
            indexPaths.count == 1,
            let movie = indexPaths.first.map(fetchedResultsController.object(at:))
        else {
            return nil
        }

        return UIContextMenuConfiguration(
            identifier: movie.objectID,
            actionProvider:  { [weak self] _ in
                let delete = UIAction(
                    title: "Delete",
                    image: UIImage(systemName: "trash"),
                    attributes: .destructive,
                    handler: { _ in
                        self?.deleteMovies([movie])
                    }
                )
                return UIMenu(children: [delete])
            }
        )
    }

}


// MARK: - Fetched results controller delegate

extension MovieGridViewController: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        let castSnapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
        diffableDataSource?.apply(castSnapshot)
    }

}

