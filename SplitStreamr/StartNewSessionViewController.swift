//
//  StartNewSessionViewController.swift
//  SplitStreamr
//
//  Created by James on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class StartNewSessionViewController: UIViewController {
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
    let sessionManager = SessionManager.sharedInstance
    
    @IBOutlet weak var peerTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerTableView.addSubview(refreshControl)
    }

    func handleRefresh(refreshControl: UIRefreshControl) {
        self.peerTableView.reloadData()
        refreshControl.endRefreshing()
    }
}

extension StartNewSessionViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionManager.peerCount()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = "Peer: \(sessionManager.peerNameAtIndex(indexPath.row))"
        
        return cell
    }
}

extension StartNewSessionViewController : UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        sessionManager.invitePeerAtIndex(indexPath.row)
    }
}
