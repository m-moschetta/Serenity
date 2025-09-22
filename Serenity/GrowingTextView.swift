import SwiftUI
import UIKit

struct GrowingTextView: UIViewRepresentable {
    @Binding var text: String
    var minHeight: CGFloat = 32
    var maxHeight: CGFloat = 120
    var font: UIFont = .systemFont(ofSize: 16)
    var textColor: UIColor = .label
    var textInset: UIEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    var onHeightChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = textInset
        tv.textContainer.lineFragmentPadding = 0
        tv.font = font
        tv.textColor = textColor
        tv.delegate = context.coordinator
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Accessibility / typing experience
        tv.keyboardDismissMode = .interactive
        tv.alwaysBounceVertical = false
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = textColor
        uiView.textContainerInset = textInset
        recalcHeight(uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextView
        init(parent: GrowingTextView) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.recalcHeight(textView)
        }
    }

    private func recalcHeight(_ tv: UITextView) {
        // Ensure we have a valid width to measure against
        let targetWidth = tv.bounds.width > 0 ? tv.bounds.width : UIScreen.main.bounds.width - 40
        let fittingSize = CGSize(width: targetWidth, height: .greatestFiniteMagnitude)
        let size = tv.sizeThatFits(fittingSize)
        var height = size.height
        // Clamp height
        height = max(minHeight, min(height, maxHeight))
        // Enable internal scrolling only when content exceeds maxHeight
        let shouldScroll = size.height > maxHeight + 0.5
        if tv.isScrollEnabled != shouldScroll { tv.isScrollEnabled = shouldScroll }
        DispatchQueue.main.async {
            onHeightChange(height)
        }
    }
}
