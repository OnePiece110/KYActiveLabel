//
//  KYActiveLabel.swift
//  KYActiveLabel
//
//  Created by keyon on 2022/9/6.
//

import Foundation
import UIKit

class KYActiveLabel: UILabel {

    private let comletion: (URL) -> Void
    
    init(formatting string: String, style: KYFormattedStringStyle, completion: @escaping (URL) -> Void) {
        self.comletion = completion
        super.init(frame: .zero)
        self.attributedText = NSAttributedString(formatting: string, style: style)
        self.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickLabel(gesture:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func clickLabel(gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        let attributedText = NSMutableAttributedString(attributedString: label.attributedText ?? NSAttributedString())
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = label.textAlignment
        attributedText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedText.length))
        let layoutManager = NSLayoutManager()
        // 这边size这样设置是因为NSTextContainer的size只是设置它的限制大小,如果小了会对点击事件造成影响大了无所谓,在iOS10上可能会出现设置label.bounds.height但点击事件有问题的情况 https://stackoverflow.com/questions/21349725/character-index-at-touch-point-for-uilabel
        let textContainer = NSTextContainer(size: CGSize(width: label.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let textStorage = NSTextStorage(attributedString: attributedText)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines

        let locationOfTouchInLabel = gesture.location(in: label)
        
        let indexOfCharacter = layoutManager.glyphIndex(for: locationOfTouchInLabel, in: textContainer)
        
        let lineRect = layoutManager.lineFragmentUsedRect(forGlyphAt: indexOfCharacter, effectiveRange: nil)
        // 解决点击文字后面的空白部分从而响应事件的问题
        if !lineRect.contains(locationOfTouchInLabel) {
            return
        }

        let attributeValue = label.attributedText?.attribute(.link, at: indexOfCharacter, effectiveRange: nil)
        if let value = attributeValue {
            if let url = value as? URL {
                comletion(url)
            }
        }
    }
}
