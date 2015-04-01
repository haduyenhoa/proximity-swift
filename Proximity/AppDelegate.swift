//
//  AppDelegate.swift
//  Proximity
//
//  Created by Duyen Hoa Ha on 30/03/2015.
//  Copyright (c) 2015 Duyen Hoa Ha. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var prefItem : NSMenuItem = NSMenuItem()
    var quitItem : NSMenuItem = NSMenuItem()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        //Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu
        statusBarItem.title = "Proximity"
        
        //Add menuItem to menu
        prefItem.title = "Preferences"
        prefItem.action = Selector("setWindowVisible:")
        prefItem.keyEquivalent = ""
        menu.addItem(prefItem)
        
        quitItem.title = "Quit"
        quitItem.action = Selector("exit")
        quitItem.keyEquivalent = ""
        menu.addItem(quitItem)
        
        setWindowInvisible()
    }
    
    func exit() {
        NSApplication.sharedApplication().terminate(self)
    }
    
    func setWindowInvisible() {
        // Insert code here to initialize your application
        NSApplication.sharedApplication().windows.last!.close()
    }

    func setWindowVisible(sender: AnyObject) {
        NSApplication.sharedApplication().windows.last!.makeKeyAndOrderFront(nil)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        
        
//        NSApp.activateIgnoringOtherApps(true)
        
//        NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil]; // get a reference to the storyboard
//        myController = [storyBoard instantiateControllerWithIdentifier:@"secondWindowController"]; // instantiate your window controller
//        [myController showWindow:self]; // show the window
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    
    
}

