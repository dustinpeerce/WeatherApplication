//
//  Constants.m
//  WeatherApp
//
//  Created by it on 9/17/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "Constants.h"

#pragma mark -
#pragma mark User Defaults
NSString * const WeatherAppUserDefaultsCurrentUserID = @"currentUserID";
NSString * const WeatherAppUserDefaultsCurrentLocation = @"currentLocation";

#pragma mark -
#pragma mark Notifications
NSString * const WeatherAppUserSignedInNotification = @"com.dustinpeerce.WeatherAppUserSignedInNotification";
NSString * const WeatherAppUserSignedOutNotification = @"com.dustinpeerce.WeatherAppUserSignedOutNotification";
NSString * const WeatherAppDidAddLocationNotification = @"com.dustinpeerce.WeatherAppDidAddLocationNotification";
NSString * const WeatherAppLocationDidChangeNotification = @"com.dustinpeerce.WeatherAppLocationDidChangeNotification";
NSString * const WeatherAppReachabilityStatusDidChangeNotification = @"com.dustinpeerce.WeatherAppReachabilityStatusDidChangeNotification";
NSString * const WeatherAppWeatherDataDidChangeChangeNotification = @"com.dustinpeerce.WeatherAppWeatherDataDidChangeChangeNotification";

#pragma mark -
#pragma mark Location Keys
NSString * const LocationKeyLocationID = @"locationID";
NSString * const LocationKeyCity = @"city";
NSString * const LocationKeyCountry = @"country";
NSString * const LocationKeyLatitude = @"latitude";
NSString * const LocationKeyLongitude = @"longitude";

#pragma mark -
#pragma mark Forecast API
NSString * const ForecastAPIKey = @"7fb77e44ae114fe9d80233ed76177adf";

#pragma mark -
#pragma mark Database Keys
NSString * const DatabaseNameKey = @"WeatherAppAccounts.db";
