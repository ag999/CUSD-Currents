//
//  SettingsViewController.swift
//  Currents
//
//  Created by David Gu, Faadhil Moheed on 12/3/15.
//  Copyright © 2015 CUSD. All rights reserved.
//

import UIKit
import Stormpath

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait,UIInterfaceOrientationMask.Portrait]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Status bar coloring
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func logout(sender: AnyObject) {
        Stormpath.sharedSession.logout();
        let SignUpLoginVC = self.storyboard!.instantiateViewControllerWithIdentifier("SignUpLoginVC") as UIViewController
        self.presentViewController(SignUpLoginVC, animated: true, completion: nil)
    }
}
