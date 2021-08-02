//
//  LoadingView.swift
//  Khinsider Ripper
//
//  Created by ptgms on 06.07.21.
//

import UIKit

class LoadingView: UIView {
    @IBOutlet weak var loadingLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        if UIDevice.current.userInterfaceIdiom != .phone {
            loadingLabel.isHidden = true
        }
    }
}
