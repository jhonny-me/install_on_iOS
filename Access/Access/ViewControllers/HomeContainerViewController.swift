//
//  HomeContainerViewController.swift
//  Access
//
//  Created by Johnny Gu on 09/05/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class HomeContainerViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        guard
            let menuViewController = splitViewItems.first?.viewController as? HomeMenuViewController,
            let homeViewController = splitViewItems.last?.viewController as? HomeViewController else { return }
        menuViewController.didSelectToken = { _ in
            homeViewController.refreshAction(homeViewController)
        }
        homeViewController.triggleMenuCallback = { [weak self] in
            guard let isCollapsed = self?.splitViewItems.first?.isCollapsed else { return }
            self?.splitViewItems.first?.animator().isCollapsed = !isCollapsed
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    override func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        let superDecision = super.splitView(splitView, canCollapseSubview: subview)
        guard superDecision else { return false }
        if subview == splitViewItems.first?.viewController.view { return true }
        return false
    }
    
//    override func splitView(_ splitView: NSSplitView, resizeSubviewsWithOldSize oldSize: NSSize) {
////        super.splitView(splitView, resizeSubviewsWithOldSize: oldSize)
//        
//    }
    
//    override func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
//        if dividerIndex == 0 { return 200 }
//        return view.frame.width - 200
//    }
//    
//    override func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
//        if dividerIndex == 0 { return 200 }
//        return 500
//    }
}
