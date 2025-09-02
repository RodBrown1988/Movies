//
//  FICImageFormat+Movies.swift
//  Movies
//
//  Created by Rod Brown on 24/4/2024.
//

import FastImageCache

extension FICImageFormat {

    static let MovieThumbnailFormatName = "Movies.Thumbnail.MovieGridViewController"

    @MainActor
    static func movieThumbnailImageFormat(for screen: UIScreen) -> FICImageFormat {
        FICImageFormat(name: MovieThumbnailFormatName, family: "Movies.Thumbnail", imageSize: MovieCollectionViewCell.cellSize(forDisplaySize: screen.bounds.size), scale: screen.scale, style: .style32BitBGR, maximumCount: 1000, devices: [.phone, .pad], protectionMode: .completeUntilFirstUserAuthentication)
    }

}
