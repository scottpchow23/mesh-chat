//
//  AppDelegate.swift
//  Mesh Chat
//
//  Created by Scott P. Chow on 1/22/19.
//  Copyright © 2019 cs176b. All rights reserved.
//

import UIKit
import CoreBluetooth

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let thisUUID: String = (UserDefaults.standard.string(forKey: "theUUID")) ?? ""
    let thisUsername: String = (UserDefaults.standard.string(forKey: "theUsername")) ?? ""
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if (thisUUID != "")
        {
            let conversationListViewController = ConversationListViewController()
            
            conversationListViewController.user = thisUsername
            
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController : UINavigationController = mainStoryboard.instantiateInitialViewController() as! UINavigationController
    
            let Start : StartViewController = mainStoryboard.instantiateViewController(withIdentifier: "StartView") as! StartViewController
            let List : ConversationListViewController = mainStoryboard.instantiateViewController(withIdentifier: "ConversationView") as! ConversationListViewController
            
            
            initialViewController.setViewControllers([Start,List], animated: false)
            
            
            window?.rootViewController = initialViewController
            
        }
        // Override point for customization after application launch.
        let server = BLEServer.instance
        server.startManagers()
        server.rxUUID = CBUUID(string: UUID().uuidString)
        print("The uuid for this session is: \(server.rxUUID)")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

