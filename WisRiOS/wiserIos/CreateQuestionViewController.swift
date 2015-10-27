//
//  CreateQuestionViewController.swift
//  wiserIos
//
//  Created by Peter Helstrup Jensen on 21/09/2015.
//  Copyright © 2015 Peter Helstrup Jensen. All rights reserved.
//

import UIKit
import JsonSerializerSwift

/// The ViewController which handles the creation of a question inside a room.
class CreateQuestionViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    //MARK: Properties
    //Gets instantiated by RoomPageViewController in prepareForSegue
    var room: Room!
    var questionListViewController: QuestionListViewController!
    
    var responseOptions = [ResponseOption]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    var questionText: TextInputCell?
    var durationInput: NumberInputCell?
    var imageTableCell: UITableViewCell?
    var selectedImage: UIImage?
    var addResponseCell: TextInputCell?
    
    var photoSelected = false {
        didSet {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "addQuestion")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "dismiss:")
    }
    
    //MARK: Utilities
    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addQuestion() {
        
        var missingInformation = false
        var informationText = String()
        
        if self.questionText?.inputField.text == "" {
            missingInformation = true
            informationText += "Question text cannot be empty. "
        }
        if self.durationInput?.inputField.text == "" || Double((self.durationInput?.inputField.text)!) == nil {
            missingInformation = true
            informationText += "Enter a number in duration. "
        }
        if responseOptions.count <= 0 {
            missingInformation = true
            informationText += "Need at least one response option."
        }
        if missingInformation {
            let alert = UIAlertController(title: "Missing information", message: informationText, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .Cancel, handler: { action in
                //Do nothing
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        //Upload indicator
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        indicator.color = UIColor.blackColor()
        indicator.center = self.view.center
        indicator.startAnimating()
        self.view.addSubview(indicator)
        
        //Create question object and send it
        let q = Question()
        q.CreatedById = CurrentUser.sharedInstance._id
        
        //http://stackoverflow.com/questions/11251340/convert-uiimage-to-base64-string-in-objective-c-and-swift
        if let selectedImage = selectedImage {
            let imageData = UIImageJPEGRepresentation(selectedImage, 0.8)
            if let imageData = imageData {
                let b64 = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.EncodingEndLineWithCarriageReturn)
                q.Img = b64
            }
        }
        q.ResponseOptions = responseOptions
        q.QuestionText = questionText?.inputField.text
        q.RoomId = room._id
        q.ExpireTimestamp = durationInput?.inputField.text
        
        let jsonQ = JSONSerializer.toJson(q)
        let body = "roomId=\(room._id!)&question=\(jsonQ)&type=MultipleChoiceQuestion"
        
        HttpHandler.requestWithResponse(action: "Question/CreateQuestion", type: "POST", body: body) { (data, response, error) in
            if error != nil {
                NSLog("Question tried Created")
                
                dispatch_async(dispatch_get_main_queue()) {
                    indicator.stopAnimating()
                    indicator.removeFromSuperview()
                }
                
                Toast.showToast("Question created", durationMs: 1500, presenter: self, imageName: "Checkmark") {
                    self.questionListViewController.fetchQuestions()
                    self.dismiss()
                }
            }
        }
    }
    
    func addResponseOption() {
        if let responseText = addResponseCell?.inputField.text where responseText != "" {
            let r = ResponseOption(value: responseText, weight: 1)
            responseOptions += [r]
        }
        
        let numberOfRows = tableView.numberOfRowsInSection(1)
        if numberOfRows > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfRows-1, inSection: 1), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
        
    }
    
    //MARK: UITableViewController
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Question parameters"
        }
        else {
            return "Reponse options"
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        }
        else {
            return responseOptions.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                
                let cellIdentifier = "TextInputCell"
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TextInputCell
                cell.label.text = "Question text"
                cell.inputField.placeholder = "Ask a question"
                questionText = cell
                cell.selectionStyle = .None
                return cell
            }
            else if indexPath.row == 1 {
                let cellIdentifier = "NumberInputCell"
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! NumberInputCell
                cell.label.text = "Duration"
                cell.inputField.placeholder = "Duration in minutes"
                durationInput = cell
                cell.selectionStyle = .None
                return cell
            }
            else if indexPath.row == 2 {
                let cell = UITableViewCell()
                imageTableCell = cell
                cell.textLabel?.text = "Select image"
                if selectedImage != nil {
                    cell.imageView?.image = selectedImage
                }
                cell.selectionStyle = .None
                return cell
            }
            else if indexPath.row == 3 {
                let cellIdentifier = "TextInputCell"
                let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! TextInputCell
                cell.label.text = "Add Response"
                cell.inputField.placeholder = "A response option"
                cell.inputField.delegate = self
                cell.inputField.returnKeyType = .Done
                cell.inputField.clearsOnBeginEditing = true
                
                addResponseCell = cell
                cell.selectionStyle = .None
                return cell
            }
        }
        else { //section == 1
            let cell = UITableViewCell()
            cell.textLabel?.text = responseOptions[indexPath.row].Value
            return cell
        }
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 2 && photoSelected {
            return CGFloat(64*3)
        }
        else {
            return CGFloat(64)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        responseOptions.removeAtIndex(indexPath.row)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 && indexPath.row == 2 {
            questionText?.resignFirstResponder()    //hide keyboard
            
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self
            
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
                imagePickerController.sourceType = .Camera
            }
            else {
                imagePickerController.sourceType = .PhotoLibrary
            }
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "Photo Library", style: .Default, handler: { action in
                imagePickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
                self.presentViewController(imagePickerController, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { action in
                imagePickerController.sourceType = UIImagePickerControllerSourceType.Camera
                self.presentViewController(imagePickerController, animated: true, completion: nil)
            }))
            
            //http://stackoverflow.com/questions/25759885/uiactionsheet-from-popover-with-ios8-gm
            //iPad support
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0, 1.0, 1.0)
            
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        self.photoSelected = true
        selectedImage = (info[UIImagePickerControllerOriginalImage] as! UIImage)
        imageTableCell?.imageView?.image = selectedImage
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        print("returning form textfield add choice")
        addResponseOption()
        return true
    }
}