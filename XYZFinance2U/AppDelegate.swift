//
//  AppDelegate.swift
//  XYZFinance2U
//
//  Created by Chee Bin Hoh on 11/27/17.
//  Copyright © 2017 - 2020 Chee Bin Hoh. All rights reserved.

import UIKit
import CoreData
import CloudKit
import UserNotifications
import NotificationCenter
import os.log

@UIApplicationMain
class AppDelegate: UIResponder,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate {

    // MARK: - static
    
    static let appName: String = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    static let appDisplayName : String = Bundle.main.localizedInfoDictionary?["CFBUNDLE_DISPLAYNAME"]as? String ?? ""
    
    // MARK: - property
    
    var lastAuthenticated: Date?
    var expenseList = [XYZExpense]()
    var incomeList = [XYZAccount]()
    var budgetList = [XYZBudget]()
    var iCloudZones = [XYZiCloudZone]()
    var shareiCloudZones = [XYZiCloudZone]()
    var privateiCloudZones = [XYZiCloudZone]()
    var window: UIWindow?
    var orientation = UIInterfaceOrientationMask.all
    var authentictatedAlready = false
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    /// var launchedShortcutItem: UIApplicationShortcutItem?
    
    func fetchSharediCloudZone() {

        let database = CKContainer.default().sharedCloudDatabase
        var zones = [CKRecordZone]()
        
        for icloudZone in self.shareiCloudZones {

            let name = icloudZone.name
            
            if name != "" {
                
                let privateiCloudZone = self.privateiCloudZones.first(where: {
                    
                    let privateName = $0.name
                    
                    return privateName != "" && name == privateName
                })
                
                if let _ = privateiCloudZone {
                    
                    icloudZone.data = privateiCloudZone?.data
                }
                
                if icloudZone.ownerName != "" {
                    
                    let zoneId = CKRecordZone.ID(zoneName: name, ownerName: icloudZone.ownerName)
                    let zone = CKRecordZone(zoneID: zoneId)
                
                    zones.append(zone)
                }
            }
        }
        
        if !zones.isEmpty {
            
            fetchiCloudZoneChange(database: database, zones: zones, icloudZones: self.shareiCloudZones, completionblock: {
                
                DispatchQueue.main.async {
                    
                    for iCloudZone in self.shareiCloudZones {
                        
                        switch iCloudZone.name {
                        
                            case XYZExpense.type:
                                guard let tabBarController = self.window?.rootViewController as? XYZMainUITabBarController else {
                                    
                                    fatalError("Exception: XYZMainUITabBarController is expected")
                                }
                                
                                guard let expenseNavController = tabBarController.viewControllers?[1] as? UINavigationController else {
                                    
                                    fatalError("Exception: UINavigationController is expected")
                                }
                                
                                guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
                                    
                                    fatalError("Exception: XYZExpenseTableViewController is expected")
                                }
                                
                                let zone = CKRecordZone(zoneName: XYZExpense.type)
                                let privateiCloudZone = GetiCloudZone(of: zone, share: false, icloudZones: self.privateiCloudZones)
                                
                                privateiCloudZone?.data = iCloudZone.data
                                self.expenseList = (iCloudZone.data as? [XYZExpense])!
                                expenseView.reloadData()
                                
                            default:
                                fatalError("Exception: \(String(describing: iCloudZone.name)) is not supported")
                        } // switch name!
                    } // for iCloudZone in self.shareiCloudZones
                } // DispatchQueue.main.async
            }) // fetchiCloudZoneChange(database: ...
        } // if !zones.isEmpty
    }
    
    func application(_ application: UIApplication,
                     userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        let acceptSharesOp = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        
        acceptSharesOp.acceptSharesCompletionBlock = { error in
            
            guard error == nil else {
                
                return
            }
            
            let recordName = cloudKitShareMetadata.rootRecordID.recordName
            let database = CKContainer.default().sharedCloudDatabase
            
            var zones = [CKRecordZone]()
            var shareicloudZone: XYZiCloudZone?
            
            for icloudZone in self.shareiCloudZones {
                
                if icloudZone.name == cloudKitShareMetadata.share.recordID.zoneID.zoneName {
                 
                    if icloudZone.ownerName == cloudKitShareMetadata.share.recordID.zoneID.ownerName {
                        
                        let newZone = CKRecordZone(zoneID: cloudKitShareMetadata.share.recordID.zoneID)
                        zones.append(newZone)
                        
                        let privateiCloudZone = self.privateiCloudZones.first(where: {
                                
                            let privateName = $0.name
                            
                            return privateName != "" && privateName == icloudZone.name
                        })
                     
                        if let _ = privateiCloudZone {
                            
                            icloudZone.data = privateiCloudZone?.data
                        }

                        shareicloudZone = icloudZone
                        
                        break
                    }
                }
            }
            
            DispatchQueue.main.async {
                
                if zones.isEmpty {
                    
                    let icloudZone = XYZiCloudZone(name: cloudKitShareMetadata.share.recordID.zoneID.zoneName,
                                                   owner: cloudKitShareMetadata.share.recordID.zoneID.ownerName,
                                                   context: managedContext())
                    
                    icloudZone.inShareDB = true
                    self.shareiCloudZones.append(icloudZone)
                    
                    let newZone = CKRecordZone(zoneID: cloudKitShareMetadata.share.recordID.zoneID)
                    zones.append(newZone)
                    
                    saveManageContext()
                    
                    shareicloudZone = icloudZone
                    
                    let privateiCloudZone = self.privateiCloudZones.first(where: {
                        
                        let privateName = $0.name
                        
                        return privateName != "" && privateName == cloudKitShareMetadata.share.recordID.zoneID.zoneName
                    })
                    
                    if let _ = privateiCloudZone {
                        
                        icloudZone.data = privateiCloudZone?.data
                    }
                }
 
                // we always fetch all from the share zone if we accept any, TODO: we need to provide
                // a way to keep track of change token per url link
                //let archivedChangeToken = NSKeyedArchiver.archivedData(withRootObject: "" )
                //shareicloudZone!.setValue(archivedChangeToken, forKey: XYZiCloudZone.changeToken)
                //shareicloudZone!.setValue(Date(), forKey: XYZiCloudZone.changeTokenLastFetch)
                
                saveManageContext()
                
                fetchiCloudZoneChange(database: database, zones: zones, icloudZones: [shareicloudZone!], completionblock: {
                    
                    DispatchQueue.main.async {
                        
                        for iCloudZone in [shareicloudZone!] {

                            switch iCloudZone.name {
                            
                                case XYZExpense.type:
                                    guard let tabBarController = self.window?.rootViewController as? XYZMainUITabBarController else {
                                        
                                        fatalError("Exception: XYZMainUITabBarController is expected")
                                    }
                            
                                    guard let expenseNavController = tabBarController.viewControllers?[1] as? UINavigationController else {
                                        
                                        fatalError("Exception: UINavigationController is expected")
                                    }
                                    
                                    guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
                                        
                                        fatalError("Exception: XYZExpenseTableViewController is expected")
                                    }
                                
                                    let zone = CKRecordZone(zoneName: XYZExpense.type)
                                    let privateiCloudZone = GetiCloudZone(of: zone, share: false, icloudZones: self.privateiCloudZones)
                                
                                    privateiCloudZone?.data = iCloudZone.data
                                    self.expenseList = (iCloudZone.data as? [XYZExpense])!
                                    
                                    for expense in self.expenseList {
                                        
                                        if expense.recordId == recordName {
                                            
                                            if let isShare = expense.value(forKey: XYZExpense.isShared) as? Bool, isShare {
                                                
                                                expense.setValue(false, forKey: XYZExpense.isSoftDelete)
                                                expense.setValue(Date(), forKey: XYZExpense.lastRecordChange)
                                                
                                                saveManageContext()
                                                
                                                break
                                            }
                                        }
                                    }
                                    
                                    expenseView.reloadData()
                                    
                                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                                    let ckrecordzone = CKRecordZone(zoneName: XYZExpense.type)
                
                                    fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase,
                                                         zones: [ckrecordzone],
                                                         iCloudZones: [privateiCloudZone!], completionblock: {
                                                            
                                        // if we implement synchronization of content, then time to refresh it.
                                        DispatchQueue.main.async {
                                            
                                            appDelegate?.expenseList = (privateiCloudZone?.data as? [XYZExpense])!
                                            expenseView.reloadData()
                                        }
                                    })
                                
                                default:
                                    fatalError("Exception: \(String(describing: iCloudZone.name)) is not supported")
                            } // switch name!
                        } // for iCloudZone in [shareicloudZone!]
                    } // DispatchQueue.main.async
                }) // fetchiCloudZoneChange(database: ...
            } // if zones.isEmpty
        } // DispatchQueue.main.async
        
        CKContainer.default().add(acceptSharesOp)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
           
        let userinfo = response.notification.request.content.userInfo
        
        if let _ = userinfo[XYZAccount.type] {

            guard let tabBarController = self.window?.rootViewController as? UITabBarController else {
                
                fatalError("Exception: UITabBarController is expected" )
            }
            
            tabBarController.selectedIndex = 0
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        completionHandler(UNNotificationPresentationOptions.sound)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
     
        if UIApplication.shared.applicationState == .background {
            
            completionHandler(.noData)
        } else {
            
            guard let notification:CKRecordZoneNotification = CKNotification(fromRemoteNotificationDictionary: userInfo)! as? CKRecordZoneNotification else {
                
                completionHandler(.failed)
                
                return
            }
            
            let _ = "-------- notifiction \(String(describing: notification.recordZoneID?.zoneName))"
            
            syncWithiCloudAndCoreData()
            fetchSharediCloudZone()
            completionHandler(.newData)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {

        // FIXME: throw alert to user
    }

    
    // MARK: - function
    
    func handleShortCutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {

        guard let _ = shortcutItem.type as String? else {
            
            return false
        }

        return true
    }
    
    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        
    }

    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
 
        self.lastAuthenticated = nil
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        
        return orientation
    }
    
    
    /*
     Called when the user activates your application by selecting a shortcut on the home screen, except when
     application(_:,willFinishLaunchingWithOptions:) or application(_:didFinishLaunchingWithOptions) returns `false`.
     You should handle the shortcut in those callbacks and return `false` if possible. In that case, this
     callback is used if your application is already launched in the background.
     */
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {

        guard let tabBarController = self.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        guard let navigationController = tabBarController.viewControllers?[1] as! UINavigationController? else {
            
            fatalError("Exception: UINavigationController is expected")
        }

        tabBarController.selectedViewController = navigationController
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let tableViewController = navController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected" )
        }
        
        DispatchQueue.main.async {
            
            if tableViewController.lockScreenDisplayed {
                
                tabBarController.dismiss(animated: false, completion: nil)
                
                tableViewController.lockScreenDisplayed = false
                tabBarController.popOverNavigatorController = navController
            }
            
            guard let tableViewController = navigationController.viewControllers[0] as? XYZExpenseTableViewController else {
                
                fatalError("Exception: XYZExpenseTableViewController is expected")
            }
            
            tableViewController.add(tableViewController.navigationItem.rightBarButtonItem!)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true
        
        // If a shortcut was launched, display its information and take the appropriate action.
        if let _ = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {

            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = true
        }

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            
            if let _ = error {
                
            } else {
             
            }
        }
        
        application.registerForRemoteNotifications()
        
        syncWithiCloudAndCoreData()
        
        fetchSharediCloudZone()

        authentictatedAlready = false
        
        return shouldPerformAdditionalDelegateHandling
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        self.authentictatedAlready = false
        
        self.lastAuthenticated = Date()
        
        guard let tabBarController = self.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let tableViewController = navController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected" )
        }
        
        if tableViewController.authenticatedMechanismExist
            && nil == tabBarController.popOverNavigatorController {
            
            let defaults = UserDefaults.standard;
            let required = defaults.value(forKey: requiredAuthenticationKey) as? Bool ?? false
            
            if required {
            
                if let _ = tabBarController.popOverAlertController {
                    
                    tabBarController.dismiss(animated: true, completion: nil)
                    tabBarController.popOverAlertController = nil
                }
                
                tableViewController.lockout()
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {

        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

        guard let tabBarController = self.window?.rootViewController as? UITabBarController else {
            
            fatalError("Exception: UITabBarController is expected" )
        }
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let tableViewController = navController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected" )
        }

        application.registerForRemoteNotifications()
        
        tableViewController.validateiCloud()
        
        syncWithiCloudAndCoreData()
        
        fetchSharediCloudZone()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        
        if !authentictatedAlready {
            
            guard let tabBarController = self.window?.rootViewController as? UITabBarController else {
                
                fatalError("Exception: UITabBarController is expected" )
            }
            
            guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
                
                fatalError("Exception: UINavigationController is expected")
            }
            
            guard let tableViewController = navController.viewControllers.first as? XYZIncomeTableViewController else {
                
                fatalError("Exception: XYZIncomeTableViewController is expected" )
            }
            
            DispatchQueue.main.async {
                
                tableViewController.authenticate()
            
                self.authentictatedAlready = true
            }
        }
        
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
                fatalError("Exception: error on load core data persistent store, \(error), \(error.userInfo)")
            }
        })
        
        return container
    }()
    
    // MARK: - iCloud
    
    func syncWithiCloudAndCoreData() {
        
        guard let tabBarController = self.window?.rootViewController as? XYZMainUITabBarController else {
            
            fatalError("Exception: XYZMainUITabBarController is expected")
        }
        
        guard let navController = tabBarController.viewControllers?.first as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let incomeView = navController.viewControllers.first as? XYZIncomeTableViewController else {
            
            fatalError("Exception: XYZIncomeTableViewController is expected")
        }
        
        guard let expenseNavController = tabBarController.viewControllers?[1] as? UINavigationController else {
            
            fatalError("Exception: UINavigationController is expected")
        }
        
        guard let expenseView = expenseNavController.viewControllers.first as? XYZExpenseTableViewController else {
            
            fatalError("Exception: XYZExpenseTableViewController is expected")
        }
        
        guard let budgetNavController = tabBarController.viewControllers?[2] as? UINavigationController else {
            
            fatalError("Exception: budgetNavController is expected")
        }
        
        guard let budgetView = budgetNavController.viewControllers.first as? XYZBudgetTableViewController else {
            
            fatalError("Exception: XYZBudgetTableViewController is expected")
        }
        
        // fetch global data list
        incomeList = loadAccounts()!
        expenseList = loadExpenses()!
        budgetList = loadBudgets()!
        iCloudZones = loadiCloudZone()!
        shareiCloudZones = [XYZiCloudZone]()
        privateiCloudZones = [XYZiCloudZone]()

        var incomeiCloudZone: XYZiCloudZone?
        var expenseiCloudZone: XYZiCloudZone?
        var expenseShareiCloudZone: XYZiCloudZone?
        var budgetiCloudZone: XYZiCloudZone?
      
        for icloudzone in iCloudZones {
            
            switch icloudzone.name {
                
                case XYZAccount.type:
                    icloudzone.data = incomeList  // We do not need to keep it in persistent state as it is already stored core data
                    incomeiCloudZone = icloudzone
                    privateiCloudZones.append(icloudzone)
                
                case XYZExpense.type:
                    if icloudzone.inShareDB {
                        
                        expenseShareiCloudZone = icloudzone
                        shareiCloudZones.append(icloudzone)
                    } else {
                        
                        icloudzone.data = expenseList
                        expenseiCloudZone = icloudzone
                        privateiCloudZones.append(icloudzone)
                    }
                
                case XYZBudget.type:
                    icloudzone.data = budgetList  // We do not need to keep it in persistent state as it is already stored core data
                    budgetiCloudZone = icloudzone
                    privateiCloudZones.append(icloudzone)
                
                default:
                    fatalError("Exception: zone type is not supported")
            }
        }
        
        var zonesToBeFetched = [CKRecordZone]()
        var zonesToBeSaved = [CKRecordZone]()
        let incomeCustomZone = CKRecordZone(zoneName: XYZAccount.type)
        let budgetCustomZone = CKRecordZone(zoneName: XYZBudget.type)
        let expenseCustomZone = CKRecordZone(zoneName: XYZExpense.type)
        
        if incomeiCloudZone == nil {
            
            zonesToBeSaved.append(incomeCustomZone)
        } else {
            
            zonesToBeFetched.append(incomeCustomZone)
        }
        
        if expenseiCloudZone == nil {
            
            zonesToBeSaved.append(expenseCustomZone)
        } else {
            
            zonesToBeFetched.append(expenseCustomZone)
        }
        
        if let _ = expenseShareiCloudZone {
            
        } else {
            
            // we ignore it, we do nothing as share zone is dynamically maintained per user
        }
        
        if budgetiCloudZone == nil {
            
            zonesToBeSaved.append(budgetCustomZone)
        } else {
            
            zonesToBeFetched.append(budgetCustomZone)
        }

        if !zonesToBeSaved.isEmpty {
            
            let op = CKModifyRecordZonesOperation(recordZonesToSave: zonesToBeSaved, recordZoneIDsToDelete: nil)
            
            op.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
                
                guard nil == error  else {
                    
                    return
                }

                OperationQueue.main.addOperation {
                    
                    for zone in saved! {
                        
                        let icloudzone = XYZiCloudZone(name: zone.zoneID.zoneName, owner: "", context: managedContext())
                        
                        switch zone.zoneID.zoneName {
                            
                            case XYZAccount.type:
                                icloudzone.data = self.incomeList
                            
                            case XYZExpense.type:
                                icloudzone.data = self.expenseList
                            
                            case XYZBudget.type:
                                icloudzone.data = self.budgetList
                            
                            default:
                                fatalError("Exception: \(zone.zoneID.zoneName) is not supported")
                        }
                        
                        self.iCloudZones.append(icloudzone)
                        self.privateiCloudZones.append(icloudzone)
                    }
                    
                    saveManageContext()
                    
                    fetchiCloudZoneChange(database: CKContainer.default().privateCloudDatabase,
                                          zones: saved!,
                                          icloudZones: self.privateiCloudZones, completionblock: {
                        
                        for icloudzone in self.privateiCloudZones {
                            
                            var tableViewToBeReload : XYZTableViewReloadData?

                            switch icloudzone.name {
                                
                                case XYZAccount.type:
                                    self.incomeList = (icloudzone.data as? [XYZAccount])!
                                    self.incomeList = sortAcounts(self.incomeList)
                                    tableViewToBeReload = incomeView
                                    
                                case XYZExpense.type:
                                    self.expenseList = (icloudzone.data as? [XYZExpense])!
                                    tableViewToBeReload = expenseView
                                    
                                case XYZBudget.type:
                                    self.budgetList = (icloudzone.data as? [XYZBudget])!
                                    self.budgetList = sortBudgets(self.budgetList)
                                    tableViewToBeReload = budgetView
                                    
                                default:
                                    fatalError("Exception: \(String(describing: icloudzone.name )) is not supported")
                            }
                            
                            if let tableViewToBeReload = tableViewToBeReload {
                                
                                DispatchQueue.main.async {
                                    
                                    tableViewToBeReload.reloadData()
                                }
                            }
                        } // for icloudzone in self.privateiCloudZones
                    }) // fetchiCloudZoneChange(database: ...
                } // OperationQueue.main.addOperation
            } // op.modifyRecordZonesCompletionBlock = { (saved,  ...
            
            let container = CKContainer.default()
            let database = container.privateCloudDatabase
            
            database.add(op)
        } // if !zonesToBeSaved.isEmpty
        
        if !zonesToBeFetched.isEmpty {
            
            var changeTokens = [CKServerChangeToken?]()
            
            for icloudzone in self.privateiCloudZones {
                
                var changeToken: CKServerChangeToken? = nil
                
                let data = icloudzone.changeToken
                
                if data.count > 0 {
                    
                    changeToken = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken
                }
                
                changeTokens.append(changeToken)
            }
            
            fetchAndUpdateiCloud(database: CKContainer.default().privateCloudDatabase, zones: zonesToBeFetched, iCloudZones: self.privateiCloudZones, completionblock: {

                for (index, icloudzone) in self.privateiCloudZones.enumerated() {

                    var changeToken: CKServerChangeToken? = nil
                    
                    let data = icloudzone.changeToken
                    
                    if data.count > 0 {
                        
                        changeToken = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken 
                    }
                    
                    let needreload = ( nil == changeToken
                                       || nil == changeTokens[index]
                                       || changeToken != changeTokens[index] )

                    var tableViewToBeReload : XYZTableViewReloadData?
                    
                    switch icloudzone.name {
                        
                        case XYZAccount.type:
                            self.incomeList = (icloudzone.data as? [XYZAccount])!
                            self.incomeList = sortAcounts(self.incomeList)
                            tableViewToBeReload = incomeView
                            
                        case XYZExpense.type:
                            self.expenseList = (icloudzone.data as? [XYZExpense])!
                            tableViewToBeReload = expenseView
                            
                        case XYZBudget.type:
                            self.budgetList = (icloudzone.data as? [XYZBudget])!
                            self.budgetList = sortBudgets(self.budgetList)
                            tableViewToBeReload = budgetView
                        
                        default:
                            fatalError("Exception: \(String(describing: icloudzone.name)) is not supported")
                    }
                    
                    if let tableViewToBeReload = tableViewToBeReload {
                        
                        DispatchQueue.main.async {
                            
                            if needreload {
                                
                                tableViewToBeReload.reloadData()
                            }
                            
                            registeriCloudSubscription(database: CKContainer.default().privateCloudDatabase, iCloudZones: [icloudzone])
                        } // DispatchQueue.main.async
                    } // if let tableViewToBeReload = tableViewToBeReload
                } // for (index, icloudzone) in self.privateiCloudZones.enumerated()
            }) // fetchAndUpdateiCloud(database: ...
        } // if !zonesToBeFetched.isEmpty
    } // if !zonesToBeSaved.isEmpty
}

