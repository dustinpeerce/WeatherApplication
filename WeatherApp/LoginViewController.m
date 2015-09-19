//
//  ViewController.m
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"

@interface LoginViewController ()

@end

static AppDelegate *appDelegate;

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (IBAction)buttonRegisterWasClicked:(id)sender {
    
    if (![_fieldUsername.text isEqual:@""]) {
        
        sqlite3_stmt *statement;
        // Get the documents directory
        NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDirectory = directoryPaths[0];
        // Build the path to the database file
        NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
        const char *dbpath = [databasePath UTF8String];
        sqlite3 *accountDB;
        
        if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
            
            
            // Check if the Username is taken
            BOOL _matchFound = NO;
            NSString *querySQL = [NSString stringWithFormat:@"SELECT UserID FROM Users WHERE Username='%@'", _fieldUsername.text];
            const char *query_stmt = [querySQL UTF8String];
            
            if (sqlite3_prepare_v2(accountDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    _matchFound = YES;
                    UIAlertView *alertViewSignUpFailure = [[UIAlertView alloc] initWithTitle:@"Oh No!" message:@"That Username already belongs to someone. Sad face." delegate:self cancelButtonTitle:@"Ugh" otherButtonTitles:nil];
                    [alertViewSignUpFailure show];
                }
                else {
                    _matchFound = NO;
                }
                
                sqlite3_finalize(statement);
            }
            
            
            
            // Insert New User if Username is NOT taken
            if (!_matchFound) {
                
                NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO Users (Username) VALUES ('%@')", _fieldUsername.text];
                const char *insert_stmt = [insertSQL UTF8String];
                
                sqlite3_prepare_v2(accountDB, insert_stmt, -1, &statement, NULL);
                
                if (sqlite3_step(statement) == SQLITE_DONE) {
                    NSLog(@"New User Added: '%@'", _fieldUsername.text);
                }
                else {
                    NSLog(@"Failed to add new user");
                }
                
                sqlite3_finalize(statement);
                
            }
            
            
            sqlite3_close(accountDB);
            
            if (!_matchFound) {
                [self logInUser];
            }
        }
    }
}

- (IBAction)buttonLogInWasClicked:(id)sender {
    
    if (![_fieldUsername.text  isEqual: @""]) {
        [self logInUser];
    }
}

- (void)logInUser {
    BOOL _matchFound = NO;
    sqlite3_stmt *statement;
    
    // Get the documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDirectory = directoryPaths[0];
    // Build the path to the database file
    NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *accountDB;
    
    if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
        
        NSString *querySQL = [NSString stringWithFormat:@"SELECT UserID FROM Users WHERE Username='%@'", _fieldUsername.text];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(accountDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                int idField = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)] intValue];
                
                // Set the Current User ID in User Defaults
                NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
                [ud setObject:@(idField) forKey:WeatherAppUserDefaultsCurrentUserID];
                [ud synchronize];
                
                NSLog(@"Logging In!");
                _matchFound = YES;
            }
            else {
                UIAlertView *alertViewSignUpFailure = [[UIAlertView alloc] initWithTitle:@"Whoops" message:@"The Username you entered is incorrect" delegate:self cancelButtonTitle:@"Ughhhh" otherButtonTitles:nil];
                [alertViewSignUpFailure show];
                NSLog(@"ERROR: Failed to Log In");
                _matchFound = NO;
            }
            
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(accountDB);
    }
    
    if (_matchFound) {
        _fieldUsername.text = nil;
        
        // Post Notification on Main Thread
        NSNotification *notification = [NSNotification notificationWithName:WeatherAppUserSignedInNotification object:nil userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning { [super didReceiveMemoryWarning]; }

@end
