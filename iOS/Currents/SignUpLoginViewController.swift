//
//  SignUpLoginViewController.swift
//  Currents
//
//  Created by David Gu, Faadhil Moheed on 12/3/15.
//  Copyright © 2015 CUSD. All rights reserved.
//

import UIKit
import Stormpath
import Alamofire

var roomid:String? = nil;
var roomon:Bool=false;
let id = "m77zi5aQ46iWNuA6Qhkn21kX5A03EwzS";
let url = "http://currents.us-west-2.elasticbeanstalk.com/index.php";

class SignUpLoginViewController: UIViewController {
    @IBOutlet weak var LoginSegmentedControl: UISegmentedControl!
    @IBOutlet weak var TopView: UIView!
    @IBOutlet weak var EntireView: UIView!
    @IBOutlet weak var NetIDTextField: UITextField!
    @IBOutlet weak var PassTextField: UITextField!
    @IBOutlet weak var PassConfTextField: UITextField!
    @IBOutlet weak var RoomNumTextField: UITextField!
    @IBOutlet weak var LoginButton: UIButton!
    @IBOutlet weak var SignUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LoginButton.layer.cornerRadius = 5
        SignUpButton.layer.cornerRadius = 5
        LoginSegmentedControl.selectedSegmentIndex = 1
        
        goToLogin()
        
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait,UIInterfaceOrientationMask.Portrait]
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        UIView.animateWithDuration(0.3, animations: {
            self.view.frame = CGRectOffset(self.view.frame, 0, -210)
        })
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        UIView.animateWithDuration(0.2, animations: {
            self.view.frame = CGRectOffset(self.view.frame, 0, 210)
        })
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?){
        view.endEditing(true)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentChanged(sender: AnyObject) {
        switch LoginSegmentedControl.selectedSegmentIndex {
        case 0 :
            goToSignUp()
        case 1 :
            goToLogin()
        default:
            ()
        }
    }
    
    func goToLogin () {
        NetIDTextField.hidden = false;
        PassTextField.hidden = false;
        PassConfTextField.hidden = true;
        RoomNumTextField.hidden = true;
        LoginButton.hidden = false;
        SignUpButton.hidden = true;
        NetIDTextField.text = "";
        PassTextField.text = "";
        PassConfTextField.text = "";
        RoomNumTextField.text = "";
    }
    
    func goToSignUp () {
        NetIDTextField.hidden = false;
        PassTextField.hidden = false;
        PassConfTextField.hidden = false;
        RoomNumTextField.hidden = false;
        LoginButton.hidden = true;
        SignUpButton.hidden = false;
        NetIDTextField.text = "";
        PassTextField.text = "";
        PassConfTextField.text = "";
        RoomNumTextField.text = "";
    }
    
    @IBAction func signUpClicked(sender: AnyObject) {
        let netid = (NetIDTextField.text!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
        let email = netid + "@cornell.edu";
        let password = PassTextField.text!;
        let confpassword = PassConfTextField.text!;
        let room = (RoomNumTextField.text!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
        
        // Always clear the password lines
        PassTextField.text = "";
        PassConfTextField.text = "";
        
        // Check if inputs are valid
        if (netid == "") {
            displayAlert("Don't have a NetID? Why you at Cornell?");
            return
        }
        
        if (password != confpassword) {
            displayAlert("Password and Confirm Password do not match!");
            return
        }
        
        if (password == "") {
            displayAlert("Oh come on, don't be lazy and actually create a password!");
            return
        }
        
        if (room == "") {
            displayAlert("Are you roomless? What a shame...");
            return
        }
        
        // Start the activityIndicator
        displayActivityIndicator(true);
        
        // Create the registration model
        let newUser = RegistrationModel(email: email, password: password)
        newUser.username = netid;
        newUser.givenName = room;
        newUser.surname = netid;
        
        // Register the new user
        Stormpath.sharedSession.register(newUser) { (account, error) -> Void in
            guard let account = account where error == nil else {
                self.displayAlert((error?.localizedDescription)!);
                self.displayActivityIndicator(false);
                return
            }
            
            // Add data to db
            roomid = self.addUserToDBRetrieveRoomID(netid, roomName: room);
            if (roomid != nil) {
                self.displayAlert("Error adding you and/or your room to the database!");
            } else {
                roomid = nil;
            }
            
            // If they need to verify their email, display alert
            if account.status == .Unverified {
                self.displayAlert("Please check your email to verify your account", title: "Registration Complete!");
            } else {
                Stormpath.sharedSession.login(newUser.username, password: newUser.password, completionHandler: { (success, error) -> Void in
                    if success {
                        self.switchToTabViewController();
                    } else {
                        self.displayAlert((error?.localizedDescription)!);
                    }
                })
            }
            self.displayActivityIndicator(false);
        }
    }
    
    @IBAction func loginClicked(sender: AnyObject) {
        displayActivityIndicator(true);
        
        let netid = (NetIDTextField.text!).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
        let password = PassTextField.text!;
        
        PassTextField.text = "";
        switchToTabViewController();
        
        Stormpath.sharedSession.login(netid, password: password) { (success, error) -> Void in
            guard error == nil else {
                self.displayAlert((error?.localizedDescription)!);
                self.displayActivityIndicator(false);
                return
            }
            
            Stormpath.sharedSession.me{(account, error) -> Void in
                guard let account = account where error == nil else {
                    return;
                }
                let roomName = account.givenName;
                
                // Getting roomid and whether or not it is on
                let query = "SELECT room.id AS id, thermostat.ison AS on FROM room, thermostat WHERE room.rname='\(roomName)' AND room.id=thermostat.roomid";
                
                Alamofire.request(.GET, url,
                    parameters: [
                        "query": query,
                        "id": id
                    ])
                    .responseString { response in
                        if let responseData = response.result.value {
                            let data = self.formatResponse(responseData);
                            roomid = data[0];
                            roomon = data[1]=="t";
                            
                            self.switchToTabViewController()
                            self.displayActivityIndicator(false);
                        }
                }
            }
            
        }
    }
    
    func exit() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func displayAlert(message:String, title:String="Error") {
        let alertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert);
        alertController.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default,handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func switchToTabViewController() {
        let TabBarController = self.storyboard!.instantiateViewControllerWithIdentifier("TabBarController") as UIViewController
        self.presentViewController(TabBarController, animated: true, completion: nil)
    }
    
    func displayActivityIndicator(show:Bool) {
        if (show) {
            LoginButton.setTitle("Loading...", forState:.Normal);
            SignUpButton.setTitle("Loading...", forState:.Normal);
            LoginButton.enabled = false;
            SignUpButton.enabled = false;
        } else {
            LoginButton.setTitle("LOGIN", forState:.Normal);
            SignUpButton.setTitle("SIGN UP", forState:.Normal);
            LoginButton.enabled = true;
            SignUpButton.enabled = true;
        }
    }
    
    func addUserToDBRetrieveRoomID(netid:String, roomName:String) -> String? {
        var roomid : String? = nil;
        
        var query = "INSERT INTO room(id,rname,xbeeinrange,piron,eventstart,ml,wantsofficeon) SELECT COALESCE(MAX(id)+1,0),'\(roomName)',False,False,False,False,False FROM room;";
        
        Alamofire.request(.POST, url,
            parameters: [
                "query": query,
                "id": id
            ])
            .responseString { response in
                if response.result.value != nil {
                    // Getting roomid
                    query = "SELECT id FROM room WHERE rname='\(roomName)'";
                    
                    Alamofire.request(.GET, url,
                        parameters: [
                            "query": query,
                            "id": id
                        ])
                        .responseString { response in
                            if let responseData = response.result.value {
                                let data = self.formatResponse(responseData);
                                roomid = data[0];
                                
                                if (roomid != nil) {
                                    // Getting roomid
                                    query = "INSERT INTO person(id,netid,roomid) SELECT COALESCE(id,0),'\(netid)',\(roomid!) FROM (SELECT MAX(id) + 1 as id FROM person) tbl;"
                                    
                                    Alamofire.request(.POST, url,
                                        parameters: [
                                            "query": query,
                                            "id": id
                                        ])
                                        .responseString { response in
                                            if (response.result.value == nil) {
                                                roomid = nil;
                                            }
                                    }
                                }
                                
                            };
                    }
                }
                
        }
        return roomid;
    }
    
    func formatResponse(html:String) -> [String] {
        func trimWhitespace(string:String) -> String {
            return string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet());
        }
        
        var array = html.componentsSeparatedByCharactersInSet(NSCharacterSet (charactersInString: "$$"));
        if (array.count <= 2) {
            array = array[0].componentsSeparatedByCharactersInSet(NSCharacterSet (charactersInString: "|"));
            for index in 0...(array.count-1) {
                array[index] = trimWhitespace(array[index]);
            };
            
            return array;
        } else {
            array = array[2].componentsSeparatedByCharactersInSet(NSCharacterSet (charactersInString: "|"));
            for index in 0...(array.count-1) {
                array[index] = trimWhitespace(array[index]);
            };
            
            return array;
        };
    }
    
}
