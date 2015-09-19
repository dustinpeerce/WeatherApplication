//
//  LocationsViewController.m
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "LocationsViewController.h"
#import "WeatherViewController.h"


@interface LocationsViewController ()

@property (strong, nonatomic) NSMutableArray *locations;

@end

static NSString *LocationCell = @"LocationCell";

@implementation LocationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup View
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView reloadData];
}

- (void)dealloc {
    // Remove Observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_delegate) {
        _delegate = nil;
    }
}

- (void)setupView {
    // Register Class for Cell Reuse
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:LocationCell];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
        // Add Observer
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(didAddLocation:) name:WeatherAppDidAddLocationNotification object:nil];
        [nc addObserver:self selector:@selector(userSignedIn:) name:WeatherAppUserSignedInNotification object:nil];
        [nc addObserver:self selector:@selector(userSignedOut:) name:WeatherAppUserSignedOutNotification object:nil];
    }
    
    return self;
}

- (void)didAddLocation:(NSNotification *)notification {
    NSDictionary *location = [notification userInfo];
    [self.locations addObject:location];
    [self.locations sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:LocationKeyCity ascending:YES]]];
    
    NSLog(@"didAddLocation: %lu", (unsigned long)[self.locations count]);
    [self.tableView reloadData];
}

- (void)loadLocations {
    sqlite3_stmt *statement;
    
    // Get the documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDirectory = directoryPaths[0];
    // Build the path to the database file
    NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *accountDB;
    
    
    if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
        
        NSLog(@"Current User ID: %d", [[[NSUserDefaults standardUserDefaults] objectForKey:WeatherAppUserDefaultsCurrentUserID] intValue]);
        
        NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM Locations WHERE UserID='%d'", [[[NSUserDefaults standardUserDefaults] objectForKey:WeatherAppUserDefaultsCurrentUserID] intValue]];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(accountDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            
            NSMutableArray *locations = [[NSMutableArray alloc] init];
            while (sqlite3_step(statement) == SQLITE_ROW) {
                
                // Extract Data
                int idField = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)] intValue];
                NSString *city = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                NSString *country = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
                CLLocationDegrees lat = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)] doubleValue];
                CLLocationDegrees lon = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 4)] doubleValue];
                
                // Create Location Dictionary
                NSDictionary *newLocation = @{ LocationKeyLocationID : @(idField),
                                               LocationKeyCity : city,
                                               LocationKeyCountry : country,
                                               LocationKeyLatitude : @(lat),
                                               LocationKeyLongitude : @(lon) };
                
                // Add the new Location
                [locations addObject:newLocation];
                [locations sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:LocationKeyCity ascending:YES]]];
                
                // Update the Locations Array
                self.locations = locations;
            }
            
            
            sqlite3_finalize(statement);
        }
        
        sqlite3_close(accountDB);
    }
    
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ([self.locations count] + 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LocationCell forIndexPath:indexPath];
    
    // Configure Cell
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [cell.textLabel setText:@"Add Current Location"];
    }
    else {
        // Fetch Location
        NSDictionary *location = [self.locations objectAtIndex:(indexPath.row - 1)];
        
        // Configure Cell
        [cell.textLabel setText:[NSString stringWithFormat:@"%@, %@", location[LocationKeyCity], location[LocationKeyCountry]]];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return NO;
    }
    
    // Fetch Location
    NSDictionary *location = [self.locations objectAtIndex:(indexPath.row - 1)];
    
    return ![self isCurrentLocation:location];
}

- (BOOL)isCurrentLocation:(NSDictionary *)location {
    
    // Fetch Current Location
    NSDictionary *currentLocation = [[NSUserDefaults standardUserDefaults] objectForKey:WeatherAppUserDefaultsCurrentLocation];
    
    if ([location[LocationKeyLocationID] intValue] == [currentLocation[LocationKeyLocationID] intValue]) {
        return YES;
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Fetch Location
        NSDictionary *location = [self.locations objectAtIndex:(indexPath.row - 1)];
        
        
        // Database Stuff...
        sqlite3_stmt *statement;
        // Get the documents directory
        NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDirectory = directoryPaths[0];
        // Build the path to the database file
        NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
        const char *dbpath = [databasePath UTF8String];
        sqlite3 *accountDB;
        
        if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
            
            NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM Locations WHERE LocationID='%d'", [location[LocationKeyLocationID] intValue]];
            
            const char *delete_stmt = [deleteSQL UTF8String];
            
            sqlite3_prepare_v2(accountDB, delete_stmt, -1, &statement, NULL);
            
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"Location was DELETED");
            }
            else {
                NSLog(@"ERROR: Failed to delete the Location");
            }
            
            sqlite3_finalize(statement);
            sqlite3_close(accountDB);
        }
        
        // Update Locations
        [self.locations removeObjectAtIndex:(indexPath.row - 1)];
        
        // Update Table View
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        // Notify Delegate
        [self.delegate controllerShouldAddCurrentLocation:self];
        
    } else {
        // Fetch Location
        NSDictionary *location = [self.locations objectAtIndex:(indexPath.row - 1)];
        
        // Notify Delegate
        [self.delegate controller:self didSelectLocation:location];
    }
    
    // Show Center View Controller
    [self.viewDeckController closeLeftViewAnimated:YES];
}

- (void)didReceiveMemoryWarning { [super didReceiveMemoryWarning]; }

- (IBAction)buttonEditWasClicked:(id)sender {
    
    [self.tableView setEditing:![self.tableView isEditing] animated:YES];
    
    if ([self.tableView isEditing]) {
        self.buttonEdit.title = @"Done";
    }
    else {
        self.buttonEdit.title = @"Edit";
    }
}

- (void)userSignedIn:(NSNotification *)notification {
    [self loadLocations];
}

- (void)userSignedOut:(NSNotification *)notification {
    [_locations removeAllObjects];
    [self.tableView reloadData];
}

@end
