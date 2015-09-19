//
//  AccountViewController.m
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "AccountViewController.h"
#import "AppDelegate.h"

@interface AccountViewController ()

@end

static AppDelegate *appDelegate;

@implementation AccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        // Add Observer
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(userSignedIn:) name:WeatherAppUserSignedInNotification object:nil];
        
    }
    
    return self;
}

- (void)didReceiveMemoryWarning { [super didReceiveMemoryWarning]; }

- (IBAction)buttonSignOutWasClicked:(id)sender {
    
    // Post Notification on Main Thread
    NSNotification *notification = [NSNotification notificationWithName:WeatherAppUserSignedOutNotification object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    
    // Reset User Defaults
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:nil forKey:WeatherAppUserDefaultsCurrentUserID];
    [ud synchronize];
    [ud setObject:nil forKey:WeatherAppUserDefaultsCurrentLocation];
    [ud synchronize];
    
    [self.viewDeckController closeRightView];
    [self.viewDeckController presentViewController:[appDelegate.mainStoryboard instantiateInitialViewController] animated:NO completion:nil];
}

- (void)userSignedIn:(NSNotification *)notification {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    int userID = [[ud objectForKey:WeatherAppUserDefaultsCurrentUserID] intValue];
    
    sqlite3_stmt *statement;
    
    // Get the documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDirectory = directoryPaths[0];
    // Build the path to the database file
    NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *accountDB;
    
    if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
        
        NSString *querySQL = [NSString stringWithFormat:@"SELECT Username FROM Users WHERE UserID='%d'", userID];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(accountDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                NSLog(@"Username was Found for the Account Profile");
               NSString *username = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)];
                _labelUsername.text = username;
            }
            else {
                NSLog(@"Username could not be obtained");
            }
            
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(accountDB);
    }

}

@end
