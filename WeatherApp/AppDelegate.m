//
//  AppDelegate.m
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "AppDelegate.h"
#import "WeatherViewController.h"
#import "LocationsViewController.h"
#import "AccountViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


@synthesize viewDeckController;
@synthesize mainStoryboard;
@synthesize databasePath;
@synthesize accountDB;



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Reset User Defaults
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:nil forKey:WeatherAppUserDefaultsCurrentUserID];
    [ud synchronize];
    [ud setObject:nil forKey:WeatherAppUserDefaultsCurrentLocation];
    [ud synchronize];
    
    // Prepare the Accounts Database
    [self prepareWeatherAppAccountsDatabase];
    
    // Initialize View Controllers
    WeatherViewController *centerViewController = [[WeatherViewController alloc] initWithNibName:@"WeatherViewController" bundle:nil];
    LocationsViewController *leftViewController = [[LocationsViewController alloc] initWithNibName:@"LocationsViewController" bundle:nil];
    AccountViewController *rightViewController = [[AccountViewController alloc] initWithNibName:@"AccountViewController" bundle:nil];
    
    // Configure Locations View Controller
    [leftViewController setDelegate:centerViewController];
    
    // Wrap Side Controllers using IISideController
    IISideController *constrainedLeftViewController = [[IISideController alloc] initWithViewController:leftViewController];
    IISideController *constrainedRightViewController = [[IISideController alloc] initWithViewController:rightViewController];
    
    // Initialize View Deck Controller
    viewDeckController = [[IIViewDeckController alloc] initWithCenterViewController:centerViewController leftViewController:constrainedLeftViewController rightViewController:constrainedRightViewController];
    
    // Store the main storyboard
    mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];

    // Initialize Window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Configure Window
    [self.window setRootViewController:viewDeckController];
    [self.window makeKeyAndVisible];
    
    [self.viewDeckController presentViewController:[mainStoryboard instantiateInitialViewController] animated:NO completion:nil];
    
    return YES;
}

- (void)prepareWeatherAppAccountsDatabase {
    
    // Get the documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDirectory = directoryPaths[0];
    
    // Build the path to the database file
    databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:databasePath]) {
        const char *dbpath = [databasePath UTF8String];
        
        // Open the Database
        if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
            
            
            // Create the Users table
            char *errMsg1;
            const char *sql_stmt1 = "CREATE TABLE IF NOT EXISTS Users (UserID INTEGER PRIMARY KEY AUTOINCREMENT, Username TEXT, LocationID INTEGER, FOREIGN KEY(LocationID) REFERENCES Locations(LocationID))";
            
            if (sqlite3_exec(accountDB, sql_stmt1, NULL, NULL, &errMsg1) != SQLITE_OK) {
                NSLog(@"Failed to create Users table");
            }
            
            
            // Create the Locations table
            char *errMsg2;
            const char *sql_stmt2 = "CREATE TABLE IF NOT EXISTS Locations (LocationID INTEGER PRIMARY KEY AUTOINCREMENT, City TEXT, Country TEXT, Latitude TEXT, Longitude TEXT, UserID INTEGER, FOREIGN KEY(UserID) REFERENCES Users(UserID))";
            
            if (sqlite3_exec(accountDB, sql_stmt2, NULL, NULL, &errMsg2) != SQLITE_OK) {
                NSLog(@"Failed to create Locations table");
            }
            
            
            // Close the Database
            sqlite3_close(accountDB);
        }
        else {
            NSLog(@"Failed to open/create the account database");
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application {}

- (void)applicationWillTerminate:(UIApplication *)application {}

@end
