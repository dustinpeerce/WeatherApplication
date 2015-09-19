//
//  Constants.h
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark User Defaults
extern NSString * const WeatherAppUserDefaultsCurrentUserID;
extern NSString * const WeatherAppUserDefaultsCurrentLocation;

#pragma mark -
#pragma mark Notifications
extern NSString * const WeatherAppUserSignedInNotification;
extern NSString * const WeatherAppUserSignedOutNotification;
extern NSString * const WeatherAppDidAddLocationNotification;
extern NSString * const WeatherAppLocationDidChangeNotification;
extern NSString * const WeatherAppReachabilityStatusDidChangeNotification;
extern NSString * const WeatherAppWeatherDataDidChangeChangeNotification;

#pragma mark -
#pragma mark Location Keys
extern NSString * const LocationKeyLocationID;
extern NSString * const LocationKeyCity;
extern NSString * const LocationKeyCountry;
extern NSString * const LocationKeyLatitude;
extern NSString * const LocationKeyLongitude;

#pragma mark -
#pragma mark Forecast API
extern NSString * const ForecastAPIKey;

#pragma mark -
#pragma mark Database Keys
extern NSString * const DatabaseNameKey;