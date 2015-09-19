//
//  AppDelegate.h
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

// Views
@property (strong, nonatomic) IIViewDeckController *viewDeckController;
@property (strong, nonatomic) UIStoryboard *mainStoryboard;

// Database properties
@property (strong, nonatomic) NSString *databasePath;
@property (nonatomic) sqlite3 *accountDB;


@end

