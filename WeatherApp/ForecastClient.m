//
//  ForecastClient.m
//  WeatherApp
//
//  Created by it on 9/18/15.
//  Copyright (c) 2015 dustinpeerce. All rights reserved.
//

#import "ForecastClient.h"

@implementation ForecastClient

+ (ForecastClient *)sharedClient {
    static dispatch_once_t predicate;
    static ForecastClient *_sharedClient = nil;
    
    dispatch_once(&predicate, ^{
        _sharedClient = [self alloc];
        _sharedClient = [_sharedClient initWithBaseURL:[self baseURL]];
        _sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    });
    
    return _sharedClient;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    
    if (self) {
        
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        
        // Reachability
        __weak typeof(self)weakSelf = self;
        [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [[NSNotificationCenter defaultCenter] postNotificationName:WeatherAppReachabilityStatusDidChangeNotification object:weakSelf];
        }];
    }
    
    return self;
}

+ (NSURL *)baseURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.forecast.io/forecast/%@/", ForecastAPIKey]];
}

- (void)requestWeatherForCoordinate:(CLLocationCoordinate2D)coordinate completion:(ForecastClientCompletionBlock)completion {
    
    NSString *path = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
    
    [self GET:path parameters:nil success:^(NSURLSessionDataTask *task, id response) {
        if (completion) {
            completion(YES, response);
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (completion) {
            completion(NO, nil);
            
            NSLog(@"Unable to fetch weather data due to error %@ with user info %@.", error, error.userInfo);
        }
    }];
}

@end
