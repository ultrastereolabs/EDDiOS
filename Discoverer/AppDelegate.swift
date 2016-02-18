//
//  AppDelegate.swift
//  UDPexample
//
//  Created by Mac on 1/15/16.
//  Copyright © 2016 USL. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    ////////////////////Global Access////////////////////
    
    //array for persisting data from host name list to detail view and back
    var foundDevicesArray:[EthernetViewController.DiscoveredDevice] = []
    //index path for pulling IP to load webpage
    var foundDeviceIndex = 0
    //persisting button count between device list to detail view
    var buttonPressedCount:Int = 0
    //array for storing sort field strings
    var sortFieldTextDelegate:[String] = []
    var globalCellIndexValue = 0
    //sorting field arrays
    var sortFieldHostNameArray:[String] = []
    var sortFieldIPAddressArray:[String] = []
    var sortFieldMACAddressArray:[String] = []
    var sortFieldLocationArray:[String] = []
    var sortFieldScreenArray:[String] = []
    var sortFieldModelArray:[String] = []
    var sortFieldSerialArray:[String] = []
    var sortFieldStatusArray:[String] = []
    
    //////////////////////////////////////////////////////////////
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        /*
        var sortPickerArray:[String] = []
        
        let pickerHostName = "Host Name"
        let pickerLocation = "Location"
        let pickerScreen = "Screen"
        let pickerIPAddress = "IP Address"
        let pickerMACAddress = "MAC Address"
        let pickerModel = "Model"
        let pickerStatus = "Status"
        
        sortPickerArray.append(pickerHostName)
        sortPickerArray.append(pickerLocation)
        sortPickerArray.append(pickerScreen)
        sortPickerArray.append(pickerIPAddress)
        sortPickerArray.append(pickerMACAddress)
        sortPickerArray.append(pickerModel)
        sortPickerArray.append(pickerStatus)
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("HasLaunchedOnce") {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "HasLaunchedOnce")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        */
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "DRF.coredata" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("coredata", withExtension: "xcdatamodeld")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("USLCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
        
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    //coredata stack
    /*
    //get coredata tools from appdel
    let appDel:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    //define object context
    let context:NSManagedObjectContext = appDel.managedObjectContext
    //get the description of the Entity in question
    let entityDescription = NSEntityDescription.entityForName("Entity", inManagedObjectContext: context)
    //make a managedobject in the database with a given description
    let managedObject = NSManagedObject(entity: entityDescription!, insertIntoManagedObjectContext: context)
    //set a value in the database
    entityObject.setValue(value: AnyObject?, forKey: "attributeName")
    //save database
    do{
    try context.save()
    }catch {
    let saveError = error as NSError
    print(saveError)
    }
    // Configure Fetch
    let fetch = fetchRequest(entityName entityName: String)
    fetchRequest.entity = entityDescription
    do {
    let result = try self.managedObjectContext.executeFetchRequest(fetchRequest)
    for items in results as! [NSManagedObject]{
    let valueString = item.valueForKey("keyName")
    print(valueString!)
    }catch {
    let fetchError = error as NSError
    print(fetchError)
    }
    */
}

