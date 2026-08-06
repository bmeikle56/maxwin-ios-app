//
//  ProfileAvatarStore.swift
//  Maxwin
//
//  Created by Braeden Meikle on 8/5/26.
//

import Foundation
import UIKit

enum ProfileAvatarStore {
    private static var directory: URL {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Avatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for fileName: String) -> URL {
        directory.appendingPathComponent(fileName)
    }

    static func loadImage(fileName: String?) -> UIImage? {
        guard let fileName,
              let data = try? Data(contentsOf: url(for: fileName)) else { return nil }
        return UIImage(data: data)
    }

    /// Downscales and JPEG-compresses picker data, then writes it for `userID`.
    static func save(imageData: Data, userID: UUID) throws -> String {
        guard let jpeg = compressedJPEGData(from: imageData) else {
            throw AuthError.unknown
        }
        let fileName = "\(userID.uuidString).jpg"
        try jpeg.write(to: url(for: fileName), options: .atomic)
        return fileName
    }

    static func delete(fileName: String?) {
        guard let fileName else { return }
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    private static func compressedJPEGData(
        from data: Data,
        maxDimension: CGFloat = 512,
        quality: CGFloat = 0.82
    ) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }

        let scale = min(1, maxDimension / longest)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
