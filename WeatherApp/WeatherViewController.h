//
//  WeatherViewController.h
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationsViewController.h"

@interface WeatherViewController : UIViewController <LocationsViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *labelLocation;
@property (weak, nonatomic) IBOutlet UIButton *buttonRefresh;
@property (weak, nonatomic) IBOutlet UILabel *labelTemp;
@property (weak, nonatomic) IBOutlet UILabel *labelDate;
@property (weak, nonatomic) IBOutlet UILabel *labelWindData;
@property (weak, nonatomic) IBOutlet UILabel *labelRainData;


- (IBAction)buttonRefreshWasClicked:(id)sender;
- (IBAction)buttonLocationsWasClicked:(id)sender;
- (IBAction)buttonAccountWasClicked:(id)sender;

@end
