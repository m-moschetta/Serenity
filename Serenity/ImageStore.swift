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

    /// Prepara un'immagine per l'invio a provider multimodali (ridimensionamento + JPEG).
    /// - Note: Riduciamo la dimensione per evitare payload troppo grandi e timeouts.
    static func jpegDataForUpload(
        _ image: UIImage,
        maxDimension: CGFloat = 1024,
        quality: CGFloat = 0.82,
        maxBytes: Int = 1_500_000
    ) -> Data? {
        // 1) resize (first pass)
        var currentMaxDim = maxDimension
        var resized = image.resizedPreservingAspectRatio(maxDimension: currentMaxDim)

        // 2) compress progressively until within maxBytes (or we hit floor)
        var q = quality
        var data = resized.jpegData(compressionQuality: q)
        if let data, data.count <= maxBytes { return data }

        // Try lowering JPEG quality first
        while q > 0.45 {
            q -= 0.07
            if let d = resized.jpegData(compressionQuality: q) {
                data = d
                if d.count <= maxBytes { return d }
            }
        }

        // If still too big, reduce dimensions and re-run compression loop
        for dim in [896.0, 768.0, 640.0, 512.0] {
            currentMaxDim = CGFloat(dim)
            resized = image.resizedPreservingAspectRatio(maxDimension: currentMaxDim)
            q = min(quality, 0.72)
            if let d0 = resized.jpegData(compressionQuality: q) {
                data = d0
                if d0.count <= maxBytes { return d0 }
            }
            while q > 0.40 {
                q -= 0.06
                if let d = resized.jpegData(compressionQuality: q) {
                    data = d
                    if d.count <= maxBytes { return d }
                }
            }
        }

        // Return best-effort (still compressed/resized) if we couldn't hit the threshold.
        return data
    }
}

private extension UIImage {
    func resizedPreservingAspectRatio(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        guard size.width > 0, size.height > 0 else { return self }
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1 // controlliamo noi la dimensione in pixel
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

