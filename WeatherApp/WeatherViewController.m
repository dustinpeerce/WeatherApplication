//
//  WeatherViewController.m
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "WeatherViewController.h"
#import "ForecastClient.h"

@interface WeatherViewController () <CLLocationManagerDelegate> {
    BOOL _locationFound;
}

@property (strong, nonatomic) NSDictionary *location;
@property (strong, nonatomic) NSDictionary *response;
@property (strong, nonatomic) NSArray *forecast;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation WeatherViewController


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    
}

- (void)dealloc {
    // Remove Observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)performSetup {
    
    sqlite3_stmt *statement;
    
    // Get the documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDirectory = directoryPaths[0];
    // Build the path to the database file
    NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *accountDB;
    
    BOOL _matchFound = NO;
    int locationID = 0;
    
    if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
        
        // Check if the User has a Location ID (The LocationID represents the Default Location)
        NSString *querySQL = [NSString stringWithFormat:@"SELECT LocationID FROM Users WHERE UserID='%d'", [[[NSUserDefaults standardUserDefaults] objectForKey:WeatherAppUserDefaultsCurrentUserID] intValue]];
        const char *query_stmt = [querySQL UTF8String];
        
        if (sqlite3_prepare_v2(accountDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                _matchFound = YES;
                if (sqlite3_column_text(statement, 0) == NULL) {
                    NSLog(@"User does NOT have a default Location");
                    locationID = 0;
                }
                else {
                    NSLog(@"User has a default Location");
                    locationID = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)] intValue];
                }
            }
            else {
                _matchFound = NO;
            }
            
            sqlite3_finalize(statement);
        }
        
        // If match was found, grab the location
        if (_matchFound && locationID != 0) {
            NSString *querySQL = [NSString stringWithFormat:@"SELECT * FROM Locations WHERE LocationID='%d'", locationID];
            const char *query_stmt = [querySQL UTF8String];
            
            if (sqlite3_prepare_v2(accountDB, query_stmt, -1, &statement, NULL) == SQLITE_OK) {
                if (sqlite3_step(statement) == SQLITE_ROW) {
                    NSLog(@"Default Location Was obtained");
                    
                    // Extract Data from database
                    NSString *city = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 1)];
                    NSString *country = [[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 2)];
                    CLLocationDegrees lat = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 3)] doubleValue];
                    CLLocationDegrees lon = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 4)] doubleValue];
                    
                    // Create Location Dictionary
                    NSDictionary *currentLocation = @{ LocationKeyLocationID : @(locationID),
                                                       LocationKeyCity : city,
                                                       LocationKeyCountry : country,
                                                       LocationKeyLatitude : @(lat),
                                                       LocationKeyLongitude : @(lon) };
                    
                    self.location = currentLocation;
                }
                else {
                    NSLog(@"Default Location was NOT obtained");
                }
                
                sqlite3_finalize(statement);
            }
            
        }
        
        sqlite3_close(accountDB);
    }
    
    
    
    
    if (!_matchFound || locationID == 0) {
        NSLog(@"Beginning the Location Update Process");
        [self.locationManager startUpdatingLocation];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Initialize Location Manager
        self.locationManager = [[CLLocationManager alloc] init];
        
        // Configure Location Manager
        [self.locationManager setDelegate:self];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyKilometer];
        
        
        // Check for iOS 8
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locationManager requestWhenInUseAuthorization];
        }
        
        // Add Observer
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [nc addObserver:self selector:@selector(reachabilityStatusDidChange:) name:WeatherAppReachabilityStatusDidChangeNotification object:nil];
        [nc addObserver:self selector:@selector(weatherDataDidChangeChange:) name:WeatherAppWeatherDataDidChangeChangeNotification object:nil];
        [nc addObserver:self selector:@selector(userSignedIn:) name:WeatherAppUserSignedInNotification object:nil];
        [nc addObserver:self selector:@selector(userSignedOut:) name:WeatherAppUserSignedOutNotification object:nil];
        
    }
    
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    if (![locations count] || _locationFound) return;
    
    // Stop Updating Location
    _locationFound = YES;
    [manager stopUpdatingLocation];
    
    // Current Location
    CLLocation *currentLocation = [locations objectAtIndex:0];
    
    // Reverse Geocode
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if ([placemarks count]) {
            _locationFound = NO;
            [self processPlacemark:[placemarks objectAtIndex:0]];
        }
    }];
    
}

- (void)processPlacemark:(CLPlacemark *)placemark {
    
    int locationID;
    
    // Extract Data from placemark
    NSString *city = [placemark locality];
    NSString *country = [placemark country];
    CLLocationDegrees lat = placemark.location.coordinate.latitude;
    CLLocationDegrees lon = placemark.location.coordinate.longitude;
    
    // Add the location to the database
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    sqlite3_stmt *statement;
    
    // Get the documents directory
    NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDirectory = directoryPaths[0];
    // Build the path to the database file
    NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
    const char *dbpath = [databasePath UTF8String];
    sqlite3 *accountDB;
    
    if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
        
        
        
        // Insert the Location
        NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO Locations (City, Country, Latitude, Longitude, UserID) VALUES ('%@', '%@', '%@', '%@', '%d')", city, country, [[NSNumber numberWithDouble:lat] stringValue], [[NSNumber numberWithDouble:lon] stringValue], [[ud objectForKey:WeatherAppUserDefaultsCurrentUserID] intValue]];
                
        const char *insert_stmt = [insertSQL UTF8String];
                
        sqlite3_prepare_v2(accountDB, insert_stmt, -1, &statement, NULL);
                
        if (sqlite3_step(statement) == SQLITE_DONE) {
            NSLog(@"Location Added to the database");
        }
        else {
            NSLog(@"ERROR: Failed to add location to the database");
        }
                
        sqlite3_finalize(statement);
        
        
        
        
        // Find the New Location's ID Number
        NSString *countSQL = [NSString stringWithFormat:@"SELECT count(*) FROM Locations"];
        const char *count_stmt = [countSQL UTF8String];
        
        if (sqlite3_prepare_v2(accountDB, count_stmt, -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                
                // Extract Data from database
                locationID = [[[NSString alloc] initWithUTF8String:(const char *)sqlite3_column_text(statement, 0)] intValue];
            }
            
            sqlite3_finalize(statement);
        }
        
        
                
        sqlite3_close(accountDB);
    }
    
    // Create Location Dictionary
    NSDictionary *currentLocation = @{ LocationKeyLocationID : @(locationID),
                                       LocationKeyCity : city,
                                       LocationKeyCountry : country,
                                       LocationKeyLatitude : @(lat),
                                       LocationKeyLongitude : @(lon) };
    
    // Update Current Location
    self.location = currentLocation;
    
    
    // Post Notifications
    NSNotification *notification2 = [NSNotification notificationWithName:WeatherAppDidAddLocationNotification object:self userInfo:currentLocation];
    [[NSNotificationCenter defaultCenter] postNotification:notification2];
    
}

- (void)controllerShouldAddCurrentLocation:(LocationsViewController *)controller {
    
    // Start Updating Location
    [self.locationManager startUpdatingLocation];
    
}

- (void)controller:(LocationsViewController *)controller didSelectLocation:(NSDictionary *)location {
    
    // Update Location
    self.location = location;
    
}

- (void)setLocation:(NSDictionary *)location {
    
    if (_location != location) {
        _location = location;
        
        // Set the location as this User's default location
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:location forKey:WeatherAppUserDefaultsCurrentLocation];
        [ud synchronize];
        sqlite3_stmt *statement;
        
        // Get the documents directory
        NSArray *directoryPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsDirectory = directoryPaths[0];
        // Build the path to the database file
        NSString *databasePath = [[NSString alloc] initWithString:[docsDirectory stringByAppendingPathComponent:DatabaseNameKey]];
        const char *dbpath = [databasePath UTF8String];
        sqlite3 *accountDB;
        
        if (sqlite3_open(dbpath, &accountDB) == SQLITE_OK) {
            
            NSString *updateSQL = [NSString stringWithFormat:@"UPDATE Users SET LocationID='%d' WHERE UserID='%d'", [location[LocationKeyLocationID] intValue], [[ud objectForKey:WeatherAppUserDefaultsCurrentUserID] intValue]];
            
            const char *update_stmt = [updateSQL UTF8String];
            
            sqlite3_prepare_v2(accountDB, update_stmt, -1, &statement, NULL);
            
            if (sqlite3_step(statement) == SQLITE_DONE) {
                NSLog(@"User's Default Location has been updated");
            }
            else {
                NSLog(@"Failed to update the User's Default Location");
            }
            
            sqlite3_finalize(statement);
            
            sqlite3_close(accountDB);
        }
        
        // Post Notification
        NSNotification *notification1 = [NSNotification notificationWithName:WeatherAppLocationDidChangeNotification object:self userInfo:location];
        [[NSNotificationCenter defaultCenter] postNotification:notification1];
        
        // Update View
        [self updateView];
        
        // Request Weather for this location
        [self fetchWeatherData];
    }
}

- (void)fetchWeatherData {
    
    // Show Progress HUD
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD show];
    
    // Query Forecast API
    double lat = [[_location objectForKey:LocationKeyLatitude] doubleValue];
    double lng = [[_location objectForKey:LocationKeyLongitude] doubleValue];
    [[ForecastClient sharedClient] requestWeatherForCoordinate:CLLocationCoordinate2DMake(lat, lng) completion:^(BOOL success, NSDictionary *response) {
        
        // Dismiss Progress HUD
        [SVProgressHUD dismiss];
        
        if (response && [response isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // Post Notification on Main Thread
                NSNotification *notification = [NSNotification notificationWithName:WeatherAppWeatherDataDidChangeChangeNotification object:nil userInfo:response];
                [[NSNotificationCenter defaultCenter] postNotification:notification];
            });
        }
    }];
}

- (void)reachabilityStatusDidChange:(NSNotification *)notification {
    ForecastClient *forecastClient = [notification object];
    NSLog(@"Reachability Status > %li", (long)forecastClient.reachabilityManager.networkReachabilityStatus);
    
    // Update Refresh Button
    self.buttonRefresh.enabled = (forecastClient.reachabilityManager.networkReachabilityStatus != AFNetworkReachabilityStatusNotReachable);
}

- (void)weatherDataDidChangeChange:(NSNotification *)notification {
    // Update Response & Forecast
    [self setResponse:[notification userInfo]];
    [self setForecast:self.response[@"hourly"][@"data"]];
    
    // Update View
    [self updateView];
}

- (void)updateView {
    
    // Update Location Label
    [self.labelLocation setText:[NSString stringWithFormat:@"%@, %@", [self.location objectForKey:LocationKeyCity], [self.location objectForKey:LocationKeyCountry]]];
    
    // Update Current Weather
    [self updateCurrentWeather];
     
}

- (void)updateCurrentWeather {
    // Weather Data
    NSDictionary *data = [self.response objectForKey:@"currently"];
    
    // Update Date and Time Label
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setDateFormat:@"EEEE, MMM d"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[data[@"time"] doubleValue]];
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [timeFormatter setDateFormat:@"ha"];
    [self.labelDate setText:[NSString stringWithFormat:@"%@, %@", [dateFormatter stringFromDate:date], [timeFormatter stringFromDate:[NSDate date]]]];
    
    // Update Temperature Label
    [self.labelTemp setText:[NSString stringWithFormat:@"%.0f°", [data[@"temperature"] floatValue]]];
    
    // Update Wind Label
    [self.labelWindData setText:[NSString stringWithFormat:@"%.0fMP", [data[@"windSpeed"] floatValue]]];
    
    // Update Rain Label
    float rainProbability = 0.0;
    if (data[@"precipProbability"]) {
        rainProbability = [data[@"precipProbability"] floatValue] * 100.0;
    }
    [self.labelRainData setText:[NSString stringWithFormat:@"%.0f%%", rainProbability]];
}

- (void)didReceiveMemoryWarning { [super didReceiveMemoryWarning]; }

- (IBAction)buttonRefreshWasClicked:(id)sender {
    NSLog(@"%@", self.location);
    if (self.location) {
        [self fetchWeatherData];
    }
}

- (IBAction)buttonLocationsWasClicked:(id)sender {
    [self.viewDeckController toggleLeftViewAnimated:YES];
}

- (IBAction)buttonAccountWasClicked:(id)sender {
    [self.viewDeckController toggleRightViewAnimated:YES];
}

- (void)userSignedIn:(NSNotification *)notification {
    
    [self performSetup];
    
    if (self.location) {
        [self fetchWeatherData];
    }
}

- (void)userSignedOut:(NSNotification *)notification {
    _location = nil;
    _response = nil;
    _forecast = nil;
}

@end
