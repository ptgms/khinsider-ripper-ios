//
//  MainSplitViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 02.04.21.
//

import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    override func viewDidLoad() {
            super.viewDidLoad()
            self.delegate = self
            self.preferredDisplayMode = .oneBesideSecondary
        }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return false
    }

    @available(iOS 14.0, *)
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        return .primary
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}
