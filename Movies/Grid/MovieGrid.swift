//
//  MovieGrid.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import CoreData
import SwiftUI

struct MovieGrid: View {

    @Environment(\.managedObjectContext) private var context

    @State private var editMode = EditMode.inactive

    @State private var selectedMovies: Set<Movie> = []

    var body: some View {
        MovieGridRepresentable(selectedMovies: $selectedMovies)
            .ignoresSafeArea()
            .id(context)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                if editMode.isEditing == true {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        deleteSelectedMovies()
                    }
                    .tint(.red)
                    .disabled(selectedMovies.isEmpty)
                }
                EditButton()
            }
            .navigationTitle("Movies")
            .environment(\.editMode, $editMode)
    }

    private func deleteSelectedMovies() {
        selectedMovies.forEach {
            context.delete($0)
        }
        do {
            try context.save()
        } catch {
            // I should probably handle this...
        }
        selectedMovies.removeAll()
    }

}

private struct MovieGridRepresentable: UIViewControllerRepresentable {

    @Binding var selectedMovies: Set<Movie>

    @Environment(\.playingMovie) private var playingMovie: Binding<Movie?>

    @Environment(\.managedObjectContext) private var managedObjectContext

    @Environment(\.editMode) private var editMode

    func makeUIViewController(context: Context) -> MovieGridViewController {
        MovieGridViewController(context: managedObjectContext)
    }

    func updateUIViewController(_ uiViewController: MovieGridViewController, context: Context) {
        uiViewController.playingMovie = playingMovie
        uiViewController.isEditing = editMode?.wrappedValue == .active
        uiViewController.selectedMovies = selectedMovies
        uiViewController.selectedMoviesDidChange = {
            selectedMovies = $0
        }
    }

}
