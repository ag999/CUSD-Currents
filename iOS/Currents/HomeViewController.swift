//
//  HomeViewController.swift
//  Currents
//
//  Created by David Gu, Faadhil Moheed on 12/3/15.
//  Copyright © 2015 CUSD. All rights reserved.
//

import UIKit
import Alamofire
import Stormpath
import CoreLocation

class HomeViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var SliderLabel: UILabel!
    @IBOutlet weak var OnOffSwitch: UISegmentedControl!
    @IBOutlet weak var RoomName: UILabel!
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
        
        if (roomon) {
            OnOffSwitch.selectedSegmentIndex = 0;
            SliderLabel.text = "HVAC System is On";
        } else {
            OnOffSwitch.selectedSegmentIndex = 1;
            SliderLabel.text = "HVAC System is Off";
        }
        
        print(roomon);
        print(OnOffSwitch.selectedSegmentIndex);
        
        OnOffSwitch.layer.cornerRadius = 5;
        
        
        
        Stormpath.sharedSession.me{(account, error) -> Void in
            guard let account = account where error == nil else {
                return;
            }
            self.RoomName.text = account.givenName;
        }
        
    }
    
    @IBAction func segmentedControlAction(sender: AnyObject) {
        if(OnOffSwitch.selectedSegmentIndex == 0) {
            SliderLabel.text = "HVAC System is On";
            sendRoomStatus(true);
        } else if(OnOffSwitch.selectedSegmentIndex == 1) {
            SliderLabel.text = "HVAC System is Off";
            sendRoomStatus(false);
        }
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
    
    func sendRoomStatus(status:Bool) {
        let query = "UPDATE room SET wantsofficeon=\(status) WHERE id=\(roomid!);";
        print(query);
        
        Alamofire.request(.POST, url,
            parameters: [
                "query": query,
                "id": id
            ])
            .responseString { response in
                print(response.result)
        }
    }
    
    func locationManager(manager: CLLocationManager,
                         didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
            
        }
        else {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]
        let long = userLocation.coordinate.longitude;
        let lat = userLocation.coordinate.latitude;
        print("locations = \(long) \(lat)")
    }
    
}