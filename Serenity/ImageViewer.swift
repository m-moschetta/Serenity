//
//  ImageViewer.swift
//  Serenity
//
//  Full-screen image viewer with zoom
//

import SwiftUI

struct ImageViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                    }
                    .onEnded { value in
                        lastScale = scale
                    }
                )
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill").font(.largeTitle).foregroundStyle(.white)
            }
            .padding()
        }
    }
}

extension UIImage: Identifiable {
    public var id: UUID { UUID() }
}

