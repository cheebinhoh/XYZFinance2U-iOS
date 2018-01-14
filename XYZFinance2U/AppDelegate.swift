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
    
    var incomeList = [XYZAccount]()
    
    var iCloudZones = [XYZiCloudZone]()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("-------- notification action")
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print("-------- notification")
        
        // Play a sound.
        completionHandler(UNNotificationPresentationOptions.sound)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     
        if UIApplication.shared.applicationState == .background {
            
            print("-------- app is in background ignore, icloud push notification, we will process them when we are active again")
            completionHandler(.noData)
        } else {
            
            guard let notification:CKRecordZoneNotification = CKNotification(fromRemoteNotificationDictionary: userInfo) as? CKRecordZoneNotification else {
                
                print("-------- failed to get zone notification")
                completionHandler(.failed)
                
                return
            }
            
            print("-------- notifiction \(String(describing: notification.recordZoneID?.zoneName))")
            
            syncWithiCloudAndCoreData()
            completionHandler(.newData)
        }
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
        
        syncWithiCloudAndCoreData()
        
        // Override point for customization after application launch.

        return true
    }

    func registeriCloudSubscription() {
        
        for icloudzone in iCloudZones {
            
            guard let name = (icloudzone.value(forKey: XYZiCloudZone.name) as? String) else {
                
                fatalError("Exception: iCloud zone name is expected")
            }
            
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            
            let ckrecordzone = CKRecordZone(zoneName: name)
            
            let fetchOp = CKFetchSubscriptionsOperation.init(subscriptionIDs: [ckrecordzone.zoneID.zoneName])

            fetchOp.fetchSubscriptionCompletionBlock = {(subscriptionDict, error) -> Void in
                
                print("-------- fetch result of subscription")
                    
                if let _ = subscriptionDict?[ckrecordzone.zoneID.zoneName] {
                    
                    print("-------- subscription exist")
                } else {
                    
                    print("-------- register new subscription")
                    let subscription = CKRecordZoneSubscription.init(zoneID: ckrecordzone.zoneID, subscriptionID: ckrecordzone.zoneID.zoneName)
                    let notificationInfo = CKNotificationInfo()
                    
                    notificationInfo.shouldSendContentAvailable = true
                    subscription.notificationInfo = notificationInfo
                    
                    let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
                    operation.qualityOfService = .utility
                    operation.completionBlock = {
                        
                        print("-------- register subscription complete")
                    }
                    
                    database.add(operation)
                }
            }
            
            database.add(fetchOp)
        }
    }
    
    func syncWithiCloudAndCoreData() {
        
        guard let splitView = self.window?.rootViewController as? MainSplitViewController else {
            
            fatalError("Exception: MainSplitViewController is expected")
        }
        
        guard let tabbarView = splitView.viewControllers.first as? MainUITabBarController else {
            
            fatalError("Exception: MainUITabBarController is expected")
        }
        
        guard let navController = tabbarView.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let incomeView = navController.viewControllers.first as? IncomeTableViewController else {
            
            fatalError("Exception: IncomeTableViewController is expected")
        }
        
        // fetch global data list
        incomeList = loadAccounts()!
        iCloudZones = loadiCloudZone()!
        
        var incomeiCloudZone: XYZiCloudZone?
        
        for icloudzone in iCloudZones {
            
            switch (icloudzone.value(forKey: XYZiCloudZone.name) as? String )! {
                
            case XYZAccount.type:
                incomeiCloudZone = icloudzone
                icloudzone.data = incomeList  // We do not need to keep it in persistent state
                
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
            
            print("-------- attempt to create zone")
            let op = CKModifyRecordZonesOperation(recordZonesToSave: zonesToBeSaved, recordZoneIDsToDelete: nil)
            op.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                
                if nil != error {
                    
                    print("-------- error on creating zone = \(String(describing: error))")
                } else {
                    
                    print("-------- success in create zone" )
                    OperationQueue.main.addOperation {
                        
                        for zone in saved! {
                            
                            let icloudzone = XYZiCloudZone(name: zone.zoneID.zoneName, context: managedContext())
                            
                            switch zone.zoneID.zoneName {
                                
                                case XYZAccount.type:
                                    icloudzone.data = self.incomeList
                                
                                default:
                                    fatalError("Exception: \(zone.zoneID.zoneName) is not supported")
                            }
                            
                            self.iCloudZones.append(icloudzone)
                        }
                        
                        saveManageContext()
                        
                        fetchiCloudZoneChange(saved!, self.iCloudZones, {
                            
                            print("-------- done fetching changes after saving zone")
                            for icloudzone in self.iCloudZones {
                                
                                let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String
                                switch zName! {
                                    
                                    case XYZAccount.type:
                                        self.incomeList = (icloudzone.data as? [XYZAccount])!
                                        
                                        DispatchQueue.main.async {
                                            
                                            incomeView.reloadData()
                                        }
                                        
                                        print("-------- fetch # of incomes = \(self.incomeList.count)")
                                    
                                    default:
                                        fatalError("Exception: \(String(describing: zName)) is not supported")
                                }
                            }
                        })
                    }
                }
            }
            
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            
            database.add(op)
        }
        
        if !zonesToBeFetched.isEmpty {
            
            print("-------- fetch and uppdate changes from/to zones")
            
            fetchAndUpdateiCloud(zonesToBeFetched, self.iCloudZones, {
                
                print("-------- done fetching changes after saving zone")
                for icloudzone in self.iCloudZones {
                    
                    let zName = icloudzone.value(forKey: XYZiCloudZone.name) as? String
                    switch zName! {
                        
                        case XYZAccount.type:
                            self.incomeList = (icloudzone.data as? [XYZAccount])!
                        
                            DispatchQueue.main.async {
                                
                                incomeView.reloadData()
                            
                                self.registeriCloudSubscription()
                            }
                        
                            print("-------- complete of fetch and update with icloud and core data")
                        
                        default:
                            fatalError("Exception: \(String(describing: zName)) is not supported")
                    }
                }
            })
        }
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
        syncWithiCloudAndCoreData()
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

