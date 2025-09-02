//
//  FileManager+Extensions.swift
//  Movies
//
//  Created by Rod Brown on 7/2/17.
//  Copyright © 2017 Rod Brown. All rights reserved.
//

import Foundation

extension FileManager {

    /// Moves the item at the specified URL to be contained within the
    /// directory. This method adjusts the file name as required to
    /// avoid a collision.
    ///
    /// - Parameters:
    ///   - url: The initial URL.
    ///   - directoryURL: The destination directory URL.
    /// - Returns: The final URL for the file, or `nil`.
    func moveItem(at url: URL, toDirectory directoryURL: URL) -> URL? {
        return moveItem(at: url, toDirectory: directoryURL, asCopy: false)
    }
    
    /// Copies the item at the specified URL to be contained within the
    /// directory. This method adjusts the file name as required to
    /// avoid a collision.
    ///
    /// - Parameters:
    ///   - url: The initial URL.
    ///   - directoryURL: The destination directory URL.
    /// - Returns: The final URL for the file, or `nil`.
    func copyItem(at url: URL, toDirectory directoryURL: URL) -> URL? {
        return moveItem(at: url, toDirectory: directoryURL, asCopy: true)
    }
    
    private func moveItem(at url: URL, toDirectory directoryURL: URL, asCopy: Bool) -> URL? {
        let fileName = url.deletingPathExtension().lastPathComponent
        let pathExtension = url.pathExtension
        
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path, isDirectory: &isDirectory) else { return nil }
        
        var counter = 1
        
        while counter <= 100 {
            let newFileName: String = counter == 1 ? fileName : "\(fileName) \(counter)"
            var newURL = directoryURL.appendingPathComponent(newFileName, isDirectory: isDirectory.boolValue)
            
            if isDirectory.boolValue == false && pathExtension.isEmpty == false {
                newURL.appendPathExtension(pathExtension)
            }
            
            do {
                if asCopy {
                    try copyItem(at: url, to: newURL)
                } else {
                    try moveItem(at: url, to: newURL)
                }
                return newURL
            } catch {
                counter += 1
            }
        }
        
        return nil
    }
    
}
