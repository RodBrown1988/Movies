//
//  Repository.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import UIKit
import CoreData
import MobileCoreServices
import FastImageCache
import AVFoundation

@Observable
nonisolated final class Repository: NSObject, Sendable {

    enum Error: Swift.Error {
        case invalidParameter
    }

    let storeURL: URL

    let persistentContainer: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    init?(storeURL: URL) {
        var url = storeURL

        var isDirectory = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)

        if exists {
            if isDirectory.boolValue == false {
                return nil
            }
        } else {
            try? FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)

            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try? url.setResourceValues(resourceValues)
        }

        self.storeURL = url
        self.persistentContainer = NSPersistentContainer(name: "Model")

        super.init()

        let storeDescription = NSPersistentStoreDescription(url: url.appendingPathComponent("Model.sqlite"))
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        persistentContainer.persistentStoreDescriptions = [storeDescription]

        NotificationCenter.default.addObserver(self, selector: #selector(managedObjectContextWillSave(_:)), name: .NSManagedObjectContextWillSave, object: nil)

        persistentContainer.loadPersistentStores { _, error in
            if let error {
                print(error.localizedDescription)
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }

    func importMovies() {
        let movieURLs = urlsForImportableMovies()
        guard movieURLs.isEmpty == false else {
            return
        }

        importMovies(at: movieURLs)
    }

    @MainActor func url(for asset: RepositoryAsset) -> URL? {
        guard let assetPath = asset.assetPath else { return nil }

        let url = storeURL.appendingPathComponent(assetPath, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    func urlsForImportableMovies() -> [URL] {
        var movies = [URL]()

        let fileManager = FileManager.default

        if let documentDirectory = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
           let fileEnumerator = fileManager.enumerator(at: documentDirectory, includingPropertiesForKeys: [.nameKey, .typeIdentifierKey]) {

            for item in fileEnumerator {
                guard let url = item as? URL else { continue }

                if let urlTypeID = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier as CFString?,
                   let urlType = UTType(urlTypeID as String) {
                    if urlType.conforms(to: UTType.movie) {
                        movies.append(url)
                    }
                }
            }
        }
        return movies
    }

    func importMovies(at urls: [URL]) {
        persistentContainer.performBackgroundTask { context in
            for url in urls {
                guard let movedURL = FileManager.default.moveItem(at: url, toDirectory: self.storeURL) else { continue }

                let movie = Movie(context: context)
                movie.fileName = movedURL.lastPathComponent
                movie.name = (url.lastPathComponent as NSString).deletingPathExtension
                movie.uuid = UUID()
            }

            _ = try? context.save()
        }
    }

    @objc
    nonisolated private func managedObjectContextWillSave(_ notification: Notification) {
        guard
            let savedContext = notification.object as? NSManagedObjectContext,
            savedContext.persistentStoreCoordinator == persistentContainer.persistentStoreCoordinator,
            savedContext.deletedObjects.isEmpty == false
        else {
            return
        }

        for case let asset as RepositoryAsset in savedContext.deletedObjects {
            Task { @MainActor in
                if let url = self.url(for: asset) {
                    _ = try?  FileManager.default.removeItem(at: url)
                }
                if let entity = asset as? FICEntity {
                    FICImageCache.shared.deleteImages(for: entity)
                }
            }
        }
    }

}

extension Repository: FICImageCacheDelegate {

    func imageCache(_ imageCache: FICImageCache, wantsSourceImageFor entity: any FICEntity, withFormatName formatName: String) async -> UIImage? {
        guard
            let movie = entity as? Movie,
            let movieURL = self.url(for: movie)
        else {
            return nil
        }
        let movieAsset = AVURLAsset(url: movieURL)
        return await movieAsset.artwork.first(where: { _ in true })
    }

}

protocol RepositoryAsset {
    var assetPath: String? { get }
}
