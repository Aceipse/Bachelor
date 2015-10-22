//
//  ChatViewController.swift
//  wiserIos
//
//  Created by Peter Helstrup Jensen on 10/09/2015.
//  Copyright © 2015 Peter Helstrup Jensen. All rights reserved.
//

import UIKit
import JsonSerializerSwift


/// A sub-ViewController of RoomPageViewController. This handles the chat logic for the room.
class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, Paged {
    
    //Properties
    let pageIndex = 2
    var roomId: String?
    var messages = [ChatMessage]()
    var updater: Updater?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textMessageInput: UITextField!
    
    //Actions
    @IBAction func sendPressed(sender: AnyObject) {
        
        if let text = textMessageInput.text where text.isEmpty {
            print("empty message not allowed in chat")
            return
        }
        
        let msg = ChatMessage()
        msg.ByUserId = CurrentUser.sharedInstance._id
        msg.RoomId = roomId
        //message timestamp gets created on restApi
        msg.Value = textMessageInput.text
        
        
        let msgJson = JSONSerializer.toJson(msg)
        let body = "ChatMessage=\(msgJson)"
        HttpHandler.requestWithResponse(action: "Chat/CreateChatMessage", type: "POST", body: body) { (data, response, error) in
            NSLog("Chat/CreateChatMessage Done")
        }
        
        textMessageInput.resignFirstResponder()
    }
    
    //Lifecycle
    override func viewDidLoad() {
        print("ChatViewController instantiated, roomId: \(self.roomId)")
        
        textMessageInput.delegate = self
        
        //Load the message
        let body = "roomId=\(roomId!)"
        HttpHandler.requestWithResponse(action: "Chat/GetAllByRoomId", type: "POST", body: body) { (data, response, error) in
            
            if let jsonArray = try? JSONSerializer.toArray(data)  {
                for chatMsg in jsonArray {
                    let m = ChatMessage(jsonDictionary: chatMsg as! NSDictionary)
                    self.messages += [m]
                    let line = DateTimeHelper.getTimeStringFromEpochString(m.Timestamp) + " " + m.Value! + "\n"
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
            else {
                print("could not load chat")
            }
        }
    }
    
    func oldestMessageEpoch() -> Double {
        var oldestTime = 0.0
        for m in self.messages {
            if let timeStamp = m.Timestamp {
                let timeStampDouble = Double(timeStamp.stringByReplacingOccurrencesOfString(",", withString: "."))
                if timeStampDouble > oldestTime {
                    oldestTime = timeStampDouble!
                }
            }
        }
        return oldestTime
    }
    
    //Setup registering for keyboard events
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        updater = Updater(secondsDelay: 1) {
            print("update chat msg")
            
            let body = "roomId=\(self.roomId!)"
            HttpHandler.requestWithResponse(action: "Chat/GetAllByRoomId", type: "POST", body: body) { (data, response, error) in
                
                if let jsonArray = try? JSONSerializer.toArray(data)  {
                    for chatMsg in jsonArray {
                        let m = ChatMessage(jsonDictionary: chatMsg as! NSDictionary)
                        
                        if Double(m.Timestamp!) > self.oldestMessageEpoch() {
                            self.messages += [m]
                        }
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
                else {
                    print("could not load chat")
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        updater?.stop()
    }
    
    //UITableViewController
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = messages[indexPath.row].Value
        return cell
    }
    
    
    //UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        sendPressed(self)
        return true
    }
    
    //UIKeyboardWillShowNotification & UIKeyboardWillHideNotification
    let kbOffset = CGFloat(30)
    //Based upon https://github.com/Lightstreamer/Lightstreamer-example-Chat-client-ios-swift with modifications
    func keyboardWillShow(notification: NSNotification) {
        print("\(__FUNCTION__) has been called")
        
        // Reducing size of table
        let baseView = self.view
        let keyboardFrame = notification.userInfo![UIKeyboardFrameBeginUserInfoKey]!.CGRectValue
        let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue
        
        let visibleRows = tableView!.indexPathsForVisibleRows
        var lastIndexPath : NSIndexPath? = nil
        
        if (visibleRows != nil) && visibleRows!.count > 0 {
            lastIndexPath = visibleRows![visibleRows!.count-1] as NSIndexPath
        }
        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            baseView!.frame = CGRectMake(baseView!.frame.origin.x, baseView!.frame.origin.y, baseView!.frame.size.width, baseView!.frame.size.height - keyboardFrame.height + self.kbOffset)
            }, completion: {
                (finished: Bool) in
                if lastIndexPath != nil {
                    // Scroll down the table so that the last
                    // visible row remains visible
                    self.tableView.scrollToRowAtIndexPath(lastIndexPath!, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                }
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        print("\(__FUNCTION__) has been called")
        
        // Expanding size of table
        let baseView = self.view
        let keyboardFrame = notification.userInfo![UIKeyboardFrameBeginUserInfoKey]!.CGRectValue
        let animationDuration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey]!.doubleValue
        
        UIView.animateWithDuration(animationDuration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            baseView!.frame = CGRectMake(baseView!.frame.origin.x, baseView!.frame.origin.y, baseView!.frame.size.width, baseView!.frame.size.height + keyboardFrame.height - self.kbOffset)
            
            }, completion: nil)
    }
}


















