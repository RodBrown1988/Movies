//
//  EnvironmentValues+PlayingMovie.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import SwiftUI

extension EnvironmentValues {

    @Entry var playingMovie: Binding<Movie?> = .constant(nil)

}
