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

// MARK: - Keyboard Shortcuts
extension MainSplitViewController {

    /*
     Adds keyboard shortcuts to navigate back in a navigation controller.
     - Shift + left arrow on the simulator
     */
    override public var keyCommands: [UIKeyCommand]? {
        guard viewControllers.count > 1 else { return [] }
        return [UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: .shift, action: #selector(backCommand), discoverabilityTitle: "Navigate up"), UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: .shift, action: #selector(backCommand), discoverabilityTitle: "Navigate down")]
    }

    @objc private func backCommand() {
        //popViewController(animated: true)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}
