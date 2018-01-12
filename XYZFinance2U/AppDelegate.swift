//
//  AppDelegate.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 CB Hoh. All rights reserved.
//
//  QA status: checked on dec-29, 2017

import UIKit
import CoreData
import CloudKit
import UserNotifications
import NotificationCenter

@UIApplicationMain
class AppDelegate: UIResponder,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate {
    
    
    // MARK: - property
    
    var iCloudZones: [XYZiCloudZone]?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("-------- notification action = \(response.actionIdentifier)")
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("-------- notification = \(notification.request.content.title)")
        
        // Play a sound.
        completionHandler(UNNotificationPresentationOptions.sound)
    }
    
    
    // MARK: - static
    
    static let appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    
    // MARK: - property
    
    var window: UIWindow?
    var orientation = UIInterfaceOrientationMask.all
    var icloudEnable = false
    
    // MARK: - function
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        
        return orientation
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            
            if let theError = error {
                
                print("-------- requestAuthorization error = \(theError.localizedDescription)")
            } else {
                
            }
        }
        
        application.registerForRemoteNotifications()
        
        // process icloud zone ...
        iCloudZones = loadiCloudZone()
        var incomeiCloudZone: XYZiCloudZone?
        //let aContext = managedContext()
        
        for zone in iCloudZones! {
            
            let data = zone.value(forKey: XYZiCloudZone.changeToken) as? Data
            guard let _ = (NSKeyedUnarchiver.unarchiveObject(with: data!) as? CKServerChangeToken) else {
                
                fatalError("Exception: unachive change token is failed")
            }
            
            //aContext?.delete(zone)
        }
        
        //iCloudZones?.removeAll()

        for zone in iCloudZones! {
            
            switch (zone.value(forKey: XYZiCloudZone.name) as? String )! {
                
                case XYZAccount.type:
                    incomeiCloudZone = zone
                
                default:
                    fatalError("Exception: zone type is not supported")
            }
        }
        
        var zonesToBeFetched = [CKRecordZone]()
        var zonesToBeSaved = [CKRecordZone]()
        let accountCustomZone = CKRecordZone(zoneName: XYZAccount.type)

        if incomeiCloudZone == nil {
            
            zonesToBeSaved.append(accountCustomZone)
        } else {

            zonesToBeFetched.append(accountCustomZone)
        }
        
        if !zonesToBeSaved.isEmpty {
            
            let op = CKModifyRecordZonesOperation(recordZonesToSave: zonesToBeSaved, recordZoneIDsToDelete: nil)
            op.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                
                if nil != error {
                    print("-------- error on creating zone = \(String(describing: error))")
                } else {
                    
                    print("-------- success in create zone" )
                    OperationQueue.main.addOperation {
                        for zone in saved! {
                            
                            let iCloudZone = XYZiCloudZone(name: zone.zoneID.zoneName, context: managedContext())
                            self.iCloudZones?.append(iCloudZone)
                        }
                        
                        fetchiCloudZoneChange(saved!, self.iCloudZones!, {
                            
                            print("---- done fetching 1")
                        })
                    }
                }
            }
            
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            
            database.add(op)
        }
        
        if !zonesToBeFetched.isEmpty {

            fetchiCloudZoneChange(zonesToBeFetched, self.iCloudZones!, {
         
                print("-------- done fetching after startup")
                /* we should only write to icloud if we do have changed after last token change
                 
                OperationQueue.main.addOperation {
                    
                    saveAccountsToiCloud({
                        
                        print("-------- doen saving")
                        
                        OperationQueue.main.addOperation {
                            fetchiCloudZoneChange([accountCustomZone], self.iCloudZones!, {
                                
                                print("-------- fetch change token after upload")
                            })
                        }
                    })
                }
                 */
            } )
        }
        
        // Override point for customization after application launch.
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
        guard let split = self.window?.rootViewController as? UISplitViewController else {
            
            fatalError("Exception: UISplitViewController is expected" )
        }
        
        guard let tabBarController = split.viewControllers.first as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let tableViewController = navController.viewControllers.first as? IncomeTableViewController else {
            
            fatalError("Exception: IncomeTableViewController is expected" )
        }
        
        tableViewController.authenticate()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: AppDelegate.appName)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            
            if let error = error as NSError? {
                
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Exception: Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext() {
        
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            
            do {
                
                try context.save()
            } catch {
                
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Exception: Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

