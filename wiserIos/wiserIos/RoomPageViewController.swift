//
//  RoomPageViewController.swift
//  wiserIos
//
//  Created by Peter Helstrup Jensen on 10/09/2015.
//  Copyright © 2015 Peter Helstrup Jensen. All rights reserved.
//

import UIKit

class RoomPageViewController: UIViewController, UIPageViewControllerDataSource {
    
    var room: Room? = nil
    var pageViewController: UIPageViewController!
    let pageCount = 3
    
    //https://www.veasoftware.com/tutorials/2015/4/2/uipageviewcontroller-in-swift-xcode-62-ios-82-tutorial
    override func viewDidLoad() {
        
        //Setup the page view controller
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewController.dataSource = self
        
        //Set initial page
        let startVC = viewControllerAtIndex(0)!
        pageViewController.setViewControllers([startVC], direction: .Forward, animated: true, completion: nil)
        pageViewController.view.frame = CGRect(x: 0, y: 30, width: view.frame.size.width, height: view.frame.size.height - 60)
        
        //Add it to the current viewcontroller
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMoveToParentViewController(self)
        
    }
    
    func viewControllerAtIndex(index: Int) -> UIViewController? {
        if index == 0 {
            let questionsViewController = storyboard?.instantiateViewControllerWithIdentifier("QuestionViewController") as! QuestionViewController
            return questionsViewController
        }
        else if index == 1 {
            let chatViewController = storyboard?.instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
            return chatViewController
        }
        
        return nil
    }
    
    //UIPageViewControllerDataSource
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let pagedVC = viewController as? Paged {
            var index = pagedVC.pageIndex
            return self.viewControllerAtIndex(--index)
        }
        else {
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let pagedVC = viewController as? Paged {
            var index = pagedVC.pageIndex
            return self.viewControllerAtIndex(++index)
        }
        else {
            return nil
        }
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageCount
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
