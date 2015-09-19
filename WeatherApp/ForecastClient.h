//
//  ForecastClient.h
//  WeatherApp
//
//  Created by it on 9/18/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFHTTPSessionManager.h"

typedef void (^ForecastClientCompletionBlock)(BOOL success, NSDictionary *response);

@interface ForecastClient : AFHTTPSessionManager

+ (ForecastClient *)sharedClient;

- (void)requestWeatherForCoordinate:(CLLocationCoordinate2D)coordinate completion:(ForecastClientCompletionBlock)completion;

@end
