//
//  LocationsViewController.h
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LocationsViewControllerDelegate;


@interface LocationsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) id<LocationsViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonEdit;

- (IBAction)buttonEditWasClicked:(id)sender;


@end


@protocol LocationsViewControllerDelegate <NSObject>

- (void)controllerShouldAddCurrentLocation:(LocationsViewController *)controller;
- (void)controller:(LocationsViewController *)controller didSelectLocation:(NSDictionary *)location;

@end