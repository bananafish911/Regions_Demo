//
//  LocationManager.h
//  LocationServicesBG
//
//  Created by Victor on 10/20/16.
//  Copyright © 2016 Victor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

/// Notifications are posted on main thread:
/// May contain object
//
//Location
static NSString* const kLocationDidUpdateLocation = @"kLocationDidUpdateLocation";
//Regions
static NSString* const kLocationEnteredRegion = @"kLocationEnteredRegion";
static NSString* const kLocationExitedRegion = @"kLocationExitedRegion";
static NSString* const kLocationMonitoringDidFailForRegion = @"kLocationMonitoringDidFailForRegion";

@interface LocationManager : NSObject

+ (LocationManager *)shared;

/// Auth
- (void)requestLocationServicesAuthoriation;

/// Location, The last location received. Will be nil until a location has been received
- (CLLocation *)currentLocation;
- (void)startStandardLocationService;
- (void)startSignificantLocationMonitoring;

/// Regions
- (void)startMonitoringRegion:(CLRegion *)region;
- (void)stopMonitoringRegion:(CLRegion *)region;
- (void)clearMonitoringRegions;
- (NSSet *)monitoredRegions;

@end
