//
//  AccountViewController.h
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *labelUsername;

- (IBAction)buttonSignOutWasClicked:(id)sender;

@end
