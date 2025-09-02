//
//  Movie+Conformances.swift
//  Movies
//
//  Created by Rod Brown on 2/9/2025.
//

import FastImageCache

extension Movie: RepositoryAsset {

    var assetPath: String? {
        fileName
    }

}

extension Movie: FICEntity {

    public var fic_UUID: String {
        uuid?.uuidString ?? ""
    }
    
    public var fic_sourceImageUUID: String {
        uuid?.uuidString ?? ""
    }

    public func fic_sourceImageURL(withFormatName formatName: String) -> URL? {
        URL(string: "com.movies." + fic_UUID)
    }

    public func fic_drawingBlock(for image: UIImage, withFormatName formatName: String) -> FICEntityImageDrawingBlock? {
        { context, size in
            UIGraphicsPushContext(context)
            image.drawAspect(filling: CGRect(origin: .zero, size: size))
            UIGraphicsPopContext()
        }
    }



}
