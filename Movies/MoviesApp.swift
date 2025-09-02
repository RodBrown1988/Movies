//
//  MoviesApp.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import AVFoundation
import FastImageCache
import SwiftUI

@main
struct MoviesApp: App {

    @State private var playingMovie: Movie?

    let repository: Repository

    init() {
        repository = Repository(storeURL: FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!.appendingPathComponent("Repository", isDirectory: true))!
        FICImageCache.shared.delegate = repository
        FICImageCache.shared.setFormats([FICImageFormat.movieThumbnailImageFormat(for: UIScreen.main)])
        _ = try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MovieGrid()
            }
            .moviePresentation($playingMovie)
            .environment(\.playingMovie, $playingMovie)
            .environment(\.managedObjectContext, repository.viewContext)
            .environment(repository)
            .onAppear {
                repository.importMovies()
            }
        }
    }

}
