//
//  MoviePresentation.swift
//  Movies
//
//  Created by Rod Brown on 24/7/2025.
//

import SwiftUI
import UIKit
import AVKit

extension View {

    func moviePresentation(_ video: Binding<Movie?>) -> some View {
        modifier(MoviePresentation(scene: video))
    }

}

private struct MoviePresentation: ViewModifier {

    @Binding var scene: Movie?

    func body(content: Content) -> some View {
        ZStack {
            _MoviePlayerHost(movie: $scene)
            content
        }
    }

}

private struct _MoviePlayerHost: UIViewControllerRepresentable {

    @Binding var movie: Movie?

    @Environment(Repository.self) private var repository

    func makeUIViewController(context: Context) -> MoviePlayerHostController {
        MoviePlayerHostController()
    }

    func updateUIViewController(_ uiViewController: MoviePlayerHostController, context: Context) {
        uiViewController.setCurrentMovie(movie, in: repository)
        uiViewController.sceneDidFinishHandler = {
            movie = nil
        }
    }

}

private final class MoviePlayerHostController: UIViewController, AVPlayerViewControllerDelegate {

    enum PictureInPictureState {
        case active
        case restoring
    }

    func setCurrentMovie(_ scene: Movie?, in repository: Repository) {
        let url = scene.flatMap { repository.url(for: $0) }
        guard url != self.url else {
            return
        }

        if let playerViewController, playerViewController.isBeingDismissed == false {
            if let url {
                if let player = playerViewController.player {
                    player.replaceCurrentItem(with: AVPlayerItem(url: url))
                } else {
                    playerViewController.player = AVPlayer(url: url)
                }
                if pictureInPictureState != .active,
                   playerViewController.presentingViewController == nil || playerViewController.isBeingDismissed {
                    present(playerViewController, animated: true) {
                        playerViewController.player?.play()
                    }
                }
            } else {
                if pictureInPictureState == .active {
                    playerViewController.player?.replaceCurrentItem(with: nil)
                }
                if playerViewController.presentingViewController != nil,
                    playerViewController.isBeingDismissed == false {
                    playerViewController.presentingViewController?.dismiss(animated: true)
                }
            }
        } else if let url {
            let player = AVPlayer(url: url)
            player.isMuted = true
            let viewController = AVPlayerViewController()
            viewController.player = player
            viewController.delegate = self
            self.playerViewController = viewController
            present(viewController, animated: true) {
                player.play()
            }
        }
        self.url = url
    }

    private(set) var url: URL?

    var sceneDidFinishHandler: (@MainActor () -> Void)?

    private var playerViewController: AVPlayerViewController?

    private var pictureInPictureState: PictureInPictureState?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isHidden = true
    }

    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        pictureInPictureState = .active
    }

    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        if pictureInPictureState != .restoring {
            pictureInPictureState = nil
            url = nil
            sceneDidFinishHandler?()
        }
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { [self] _ in
            if pictureInPictureState == nil {
                url = nil
                sceneDidFinishHandler?()
            }
        }
    }

    func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(_ playerViewController: AVPlayerViewController) -> Bool {
        if pictureInPictureState == nil {
            pictureInPictureState = .active
        }
        return true
    }

    func playerViewController(_ playerViewController: AVPlayerViewController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        if presentedViewController == nil {
            pictureInPictureState = .restoring
            present(playerViewController, animated: false) {
                completionHandler(true)
                self.pictureInPictureState = nil
            }
        } else {
            completionHandler(false)
            pictureInPictureState = nil
            url = nil
            sceneDidFinishHandler?()
        }
    }

}

