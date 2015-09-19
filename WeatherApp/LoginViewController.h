//
//  ViewController.h
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *fieldUsername;

- (IBAction)buttonRegisterWasClicked:(id)sender;
- (IBAction)buttonLogInWasClicked:(id)sender;

@end

