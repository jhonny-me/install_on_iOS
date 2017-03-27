//
//  ConfigureKeyViewController.swift
//  Access
//
//  Created by Johnny Gu on 24/03/2017.
//  Copyright © 2017 Johnny Gu. All rights reserved.
//

import Cocoa

class ConfigureKeyViewController: NSViewController {

    @IBOutlet weak var tabView: NSTabView!
    var tokens: [Token] = AppDelegate.tokens
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()

        tokens.enumerated().map { index, token -> NSTabViewItem in
            let item = NSTabViewItem()
            item.label = String(index + 1)
            let tokenView = TokenAndKeyConfigureView()
            tokenView.configure(with: token, isInuse: AppDelegate.inuseTokenIndex == index)
            tokenView.didTokenUpdated = { newToken in
                AppDelegate.tokens[index] = newToken
            }
            tokenView.didInuseChanged = {
                AppDelegate.inuseTokenIndex = index
            }
            
            item.view = tokenView
            return item
            }.forEach({ self.tabView.insertTabViewItem($0, at: self.tabView.tabViewItems.count - 1) })
        if tokens.count < 1 {
            let item = NSTabViewItem()
            item.label = "1"
            let tokenView = TokenAndKeyConfigureView()
            tokenView.didTokenUpdated = { newToken in
                if AppDelegate.tokens.count < 1 {
                    AppDelegate.tokens = [newToken]
                }else {
                    AppDelegate.tokens[0] = newToken
                }
            }
            item.view = tokenView
            tabView.insertTabViewItem(item, at: 0)
        }
        tabView.selectTabViewItem(at: AppDelegate.inuseTokenIndex)
    }
}

extension ConfigureKeyViewController: NSTabViewDelegate {
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        if tabViewItem == tabView.tabViewItems.last {
            let token = Token()
            AppDelegate.tokens.append(token)
            let count = tabView.tabViewItems.count
            let item = NSTabViewItem()
            item.label = String(count)
            let view = TokenAndKeyConfigureView()
            view.configure(with: token, isInuse: false)
            view.didTokenUpdated = { token in
                AppDelegate.tokens[count] = token
            }
            view.didInuseChanged = {
                AppDelegate.inuseTokenIndex = count
            }
            item.view = view
            tabView.insertTabViewItem(item, at: tabView.tabViewItems.count - 1)
            tabView.selectTabViewItem(item)
        }else {
            guard
                let tabViewItem = tabViewItem,
                let view = tabViewItem.view as? TokenAndKeyConfigureView else { return }
            let index = tabView.indexOfTabViewItem(tabViewItem)
            view.configure(with: AppDelegate.tokens[index], isInuse: AppDelegate.inuseTokenIndex == index )
        }
    }
}
