//
//  ImageStore.swift
//  Serenity
//
//  Simple utilities to persist/load images in app's Documents.
//

import UIKit

enum ImageStore {
    static func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func saveJPEG(_ image: UIImage, quality: CGFloat = 0.9) throws -> String {
        let name = "img_\(UUID().uuidString).jpg"
        let url = documentsURL().appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: quality) else { throw NSError(domain: "ImageStore", code: 1) }
        try data.write(to: url)
        return name
    }
    
    static func load(_ relativePath: String) -> UIImage? {
        let url = documentsURL().appendingPathComponent(relativePath)
        return UIImage(contentsOfFile: url.path)
    }
}

