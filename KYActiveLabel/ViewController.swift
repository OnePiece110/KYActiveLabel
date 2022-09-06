//
//  ViewController.swift
//  KYActiveLabel
//
//  Created by keyon on 2022/9/6.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let view = UIView()
        view.backgroundColor = .white

        let input = "M1 delivers up to <b>2.8x faster</b> processing performance than the <a href='%@'>previous generation.</a>"
        let text = String(format: input, "https://support.apple.com/kb/SP799")
        let style = KYFormattedStringStyle(attributes: [
            "body": [.font: UIFont.systemFont(ofSize: 15)],
            "b": [.font: UIFont.boldSystemFont(ofSize: 15)],
            "a": [.underlineColor: UIColor.clear]
        ])

        let label = KYActiveLabel(formatting: text, style: style) { url in
            UIApplication.shared.open(url)
        }
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .center

        view.addSubview(label)
        self.view = view

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])

    }


}

