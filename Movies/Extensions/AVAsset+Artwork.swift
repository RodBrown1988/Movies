//
//  AVAsset+Artwork.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import AVFoundation
import AsyncAlgorithms
import UIKit

extension AVAsset {

    /// Returns all the artwork images stored in the asset's metadata.
    var artwork: some AsyncSequence<UIImage, Never> {
        get async {
            let covers: [AVMetadataItem]
            do {
                let metadata = try await loadMetadata(for: .iTunesMetadata)
                covers = AVMetadataItem.metadataItems(from: metadata, filteredByIdentifier: .iTunesMetadataCoverArt)
            } catch {
                covers = []
            }
            return covers.async
                .compactMap {
                    try? await $0.load(.dataValue).flatMap { UIImage(data: $0) }
                }
        }
    }
}
