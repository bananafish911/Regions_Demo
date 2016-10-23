//
//  MainVC.m
//  LocationServicesBG
//
//  Created by Victor on 10/20/16.
//  Copyright © 2016 Victor. All rights reserved.
//

#import "MainVC.h"
#import <MapKit/MapKit.h>
#import "LocationManager.h"
#import "RegionAnnotation.h"
#import "RegionAnnotationView.h"

#define REGION_RADIUS 300

@interface MainVC () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@end

@implementation MainVC

#pragma mark - Initialization

- (void)configureOnLoad {
    // title
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0, 200, 40)];
    label.text = @"some long text";
    label.textColor = [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:18];
    label.backgroundColor = [UIColor clearColor];
    label.adjustsFontSizeToFitWidth = YES;
    self.navigationItem.titleView = label;
    
    _mapView.delegate = self;
    
    // Subscribe to location updates notifications
    __weak typeof(self) weakSelf = self;
    
    // location updated
    [[NSNotificationCenter defaultCenter] addObserverForName:kLocationDidUpdateLocation
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull notification) {
                                                      if ([notification.object isKindOfClass:[CLLocation class]]) {
                                                          CLLocation *location = [notification object];
                                                          NSString *event = [NSString stringWithFormat:@"kLocationDidUpdateLocation %@ at %@", location.description, [NSDate date]];
                                                          DLog(@"%@", event);
                                                          
                                                          // Zoom to the current user location.
//                                                          MKCoordinateRegion userLocation = MKCoordinateRegionMakeWithDistance(location.coordinate, 1000.0, 1000.0);
//                                                          [weakSelf.mapView setRegion:userLocation animated:YES];
                                                      }
    }];
    
    // region Entered
    [[NSNotificationCenter defaultCenter] addObserverForName:kLocationEnteredRegion
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull notification) {
                                                      if ([notification.object isKindOfClass:[CLRegion class]]) {
                                                          CLRegion *region = [notification object];
                                                          NSString *event = [NSString stringWithFormat:@"didEnterRegion %@ at %@", region.identifier, [NSDate date]];
                                                          DLog(@"%@", event);
                                                      }
                                                  }];
    // region Exited
    [[NSNotificationCenter defaultCenter] addObserverForName:kLocationExitedRegion
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull notification) {
                                                      if ([notification.object isKindOfClass:[CLRegion class]]) {
                                                          CLRegion *region = [notification object];
                                                          NSString *event = [NSString stringWithFormat:@"didExitRegion %@ at %@", region.identifier, [NSDate date]];
                                                          DLog(@"%@", event);
                                                      }
                                                  }];
    // region monitoring Failed
    [[NSNotificationCenter defaultCenter] addObserverForName:kLocationMonitoringDidFailForRegion
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull notification) {
                                                      if ([notification.object isKindOfClass:[CLRegion class]]) {
                                                          CLRegion *region = [notification object];
                                                          NSString *event = [NSString stringWithFormat:@"monitoringDidFailForRegion %@", region.identifier];
                                                          DLog(@"%@", event);
                                                      }
                                                  }];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureOnLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // ask for permission again
    [[LocationManager shared] requestLocationServicesAuthoriation];
    // Start monitoring
    [[LocationManager shared] startStandardLocationService];
    
    // Set the map's user tracking mode.
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
    
    [self redrawMapView];
}

- (void)redrawMapView {
    // Remove all annotations except User location
    for (id annotation in self.mapView.annotations) {
        if (![annotation isKindOfClass:[MKUserLocation class]]){
            [self.mapView removeAnnotation:annotation];
        }
    }
    
    // Get all regions being monitored for this application.
    NSArray *regions = [[LocationManager shared].monitoredRegions allObjects];
    
    // Iterate through the regions and add annotations to the map for each of them.
    for (int i = 0; i < [regions count]; i++) {
        CLRegion *region = regions[i];
        RegionAnnotation *annotation = [[RegionAnnotation alloc] initWithCLRegion:region];
        [self.mapView addAnnotation:annotation];
    }
    
    // Zoom to the current user location.
    MKCoordinateRegion userLocation = MKCoordinateRegionMakeWithDistance([LocationManager shared].currentLocation.coordinate, 1000.0, 1000.0);
    [self.mapView setRegion:userLocation animated:YES];
}

#pragma mark - Actions

- (IBAction)rightBarButtonAction:(UIBarButtonItem *)sender {
    // add
    [self addRegionAndAnnotation];
}

- (IBAction)lefBarButtonAction:(UIBarButtonItem *)sender {
    // refresh
    [self redrawMapView];
}

/*
 This method creates a new region based on the center coordinate of the map view.
 A new annotation is created to represent the region and then the application starts monitoring the new region.
 */
- (void)addRegionAndAnnotation {
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        // Create a new region based on the center of the map view.
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(self.mapView.centerCoordinate.latitude, self.mapView.centerCoordinate.longitude);
        CLCircularRegion *newRegion = [[CLCircularRegion alloc] initWithCenter:coord
                                                                        radius:REGION_RADIUS
                                                                    identifier:[NSString stringWithFormat:@"%f, %f", self.mapView.centerCoordinate.latitude, self.mapView.centerCoordinate.longitude]];
        newRegion.notifyOnEntry = YES;
        newRegion.notifyOnExit = YES;
        
        // Create an annotation to show where the region is located on the map.
        RegionAnnotation *myRegionAnnotation = [[RegionAnnotation alloc] initWithCLRegion:newRegion];
        myRegionAnnotation.coordinate = newRegion.center;
        myRegionAnnotation.radius = newRegion.radius;
        
        [self.mapView addAnnotation:myRegionAnnotation];
        
        
        // Start monitoring the newly created region.
        [[LocationManager shared] startMonitoringRegion:newRegion];
    }
    else {
        NSLog(@"Region monitoring is not available.");
    }
}

#pragma mark - MKMapViewDelegate

// Return the view for the region annotation callout.
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if([annotation isKindOfClass:[RegionAnnotation class]]) {
        RegionAnnotation *currentAnnotation = (RegionAnnotation *)annotation;
        NSString *annotationIdentifier = [currentAnnotation title];
        RegionAnnotationView *regionView = (RegionAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
        
        if (!regionView) {
            regionView = [[RegionAnnotationView alloc] initWithAnnotation:annotation];
            regionView.map = self.mapView;
            
            // Create a button for the left callout accessory view of each annotation to remove the annotation and region being monitored.
            UIButton *removeRegionButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [removeRegionButton setFrame:CGRectMake(0., 0., 25., 25.)];
            [removeRegionButton setImage:[UIImage imageNamed:@"RemoveRegion"] forState:UIControlStateNormal];
            
            regionView.leftCalloutAccessoryView = removeRegionButton;
        } else {
            regionView.annotation = annotation;
            regionView.theAnnotation = annotation;
        }
        
        // Update or add the overlay displaying the radius of the region around the annotation.
        [regionView updateRadiusOverlay];
        
        return regionView;
    }
    
    return nil;
}

// Return the map overlay that depicts the region.
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    if([overlay isKindOfClass:[MKCircle class]]) {
        // Create the view for the circular overlay.
        
        MKCircleRenderer *circleView = [[MKCircleRenderer alloc] initWithOverlay:overlay];
        circleView.strokeColor = [UIColor blueColor];
        circleView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
        circleView.lineWidth = 2;
        
        return circleView;
    }
    
    return nil;
}

// Enable the user to reposition the pins representing the regions by dragging them.
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if([annotationView isKindOfClass:[RegionAnnotationView class]]) {
        RegionAnnotationView *regionView = (RegionAnnotationView *)annotationView;
        RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
        
        // If the annotation view is starting to be dragged, remove the overlay and stop monitoring the region.
        if (newState == MKAnnotationViewDragStateStarting) {
            [regionView removeRadiusOverlay];
            [[LocationManager shared] stopMonitoringRegion:regionAnnotation.region];
        }
        
        // Once the annotation view has been dragged and placed in a new location, update and add the overlay and begin monitoring the new region.
        if (oldState == MKAnnotationViewDragStateDragging && newState == MKAnnotationViewDragStateEnding) {
            [regionView updateRadiusOverlay];
            
            CLCircularRegion *newRegion = [[CLCircularRegion alloc] initWithCenter:regionAnnotation.coordinate
                                                                            radius:REGION_RADIUS
                                                                        identifier:[NSString stringWithFormat:@"%f, %f", regionAnnotation.coordinate.latitude, regionAnnotation.coordinate.longitude]];
            
            regionAnnotation.region = newRegion;
            
            [[LocationManager shared] startMonitoringRegion:regionAnnotation.region];
        }
    }
}

// The X was tapped on a region annotation, so remove that region form the map, and stop monitoring that region.
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    RegionAnnotationView *regionView = (RegionAnnotationView *)view;
    RegionAnnotation *regionAnnotation = (RegionAnnotation *)regionView.annotation;
    
    // Stop monitoring the region, remove the radius overlay, and finally remove the annotation from the map.
    [[LocationManager shared] stopMonitoringRegion:regionAnnotation.region];
    [regionView removeRadiusOverlay];
    [self.mapView removeAnnotation:regionAnnotation];
}


@end
