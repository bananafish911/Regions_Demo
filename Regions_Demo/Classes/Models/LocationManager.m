//
//  LocationManager.m
//  LocationServicesBG
//
//  Created by Victor on 10/20/16.
//  Copyright © 2016 Victor. All rights reserved.
//

#import "LocationManager.h"
#import <UIKit/UIKit.h>

@interface LocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *manager;

@end

@implementation LocationManager

#pragma mark - Singleton

+ (LocationManager *)shared {
    static LocationManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [LocationManager new];
        [sharedInstance configure];
    });
    return sharedInstance;
}

#pragma mark initialization and deinitialization

- (void)configure {
    // Create location manager
    self.manager = [[CLLocationManager alloc] init];
    // Configure the location manager.
    self.manager.delegate = self;
    self.manager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
    self.manager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [self requestLocationServicesAuthoriation];
    
    // Notifications (subscribing on app's state changes)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.manager.delegate = nil;
}

#pragma mark - Notifications

/// for events like: incoming call, open another app, etc.
- (void)applicationWillResignActive:(NSNotification *)notification {
    //stopping the location service (save battery), starting significant location changes service (try)
    [self startSignificantLocationMonitoring];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    //stopping the significant location changes service and starting the standard location service
    [self startStandardLocationService];
}

- (void)postNotificationWithName:(NSString *)name object:(id)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:object];
    });
}

#pragma mark - CLLocationManagerDelegate

// When the user has granted authorization, start the standard location service.
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) {
        // Start the standard location service.
        [self startStandardLocationService];
    }
}

// A core location error occurred.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    DLog(@"didFailWithError: %@", error);
}

// The system delivered a new location.
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    [self postNotificationWithName:kLocationDidUpdateLocation object:newLocation];
}

// The device entered a monitored region.
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region  {
    [self postNotificationWithName:kLocationEnteredRegion object:region];
}

// The device exited a monitored region.
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self postNotificationWithName:kLocationExitedRegion object:region];
}

// A monitoring error occurred for a region.
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    [self postNotificationWithName:kLocationMonitoringDidFailForRegion object:region];
}

#pragma mark -
#pragma mark -
#pragma mark - Public methods:

#pragma mark - Request location services authoriation

- (void)requestLocationServicesAuthoriation {
    // Request always allowed location service authorization.
    // This is done here, so we can display an alert if the user has denied location services previously
    // Request always allowed location service authorization.
    // This is done here, so we can display an alert if the user has denied location services previously
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        // If status is not determined, then we should ask for authorization.
        [self.manager requestAlwaysAuthorization];
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        // If authorization has been denied previously, inform the user.
        NSLog(@"%s: location services authorization was previously denied by the user.", __PRETTY_FUNCTION__);
    }
}

#pragma mark - Location

- (CLLocation *)currentLocation {
    return self.manager.location;
}

- (void)startStandardLocationService {
    //stopping the significant location changes service and starting the standard location service
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        [self.manager stopMonitoringSignificantLocationChanges];
        [self.manager startUpdatingLocation];
    }
    else {
        DLog(@"ERR: [CLLocationManager significantLocationChangeMonitoringAvailable] is false");
    }
}

- (void)startSignificantLocationMonitoring {
    //stopping the location service (save battery), starting significant location changes service (try)
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        [self.manager stopUpdatingLocation];
        [self.manager startMonitoringSignificantLocationChanges];
    } else {
        DLog(@"ERR: [CLLocationManager significantLocationChangeMonitoringAvailable] is false");
    }
}

#pragma mark - Regions

- (void)startMonitoringRegion:(CLRegion *)region {
    // Start monitoring the newly created region.
    [self.manager startMonitoringForRegion:region];
}

- (void)stopMonitoringRegion:(CLRegion *)region {
    [self.manager stopMonitoringForRegion:region];
}

- (void)clearMonitoringRegions {
    for (CLRegion *monitored in [self.manager monitoredRegions]) {
        [self.manager stopMonitoringForRegion:monitored];
    }
}

- (NSSet *)monitoredRegions {
    return self.manager.monitoredRegions;
}

@end
