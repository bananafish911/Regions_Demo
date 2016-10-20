//
//  AppDelegate.m
//  LocationServicesBG
//
//  Created by Victor on 10/20/16.
//  Copyright © 2016 Victor. All rights reserved.
//

#import "AppDelegate.h"
#import "LocationManager.h"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // location manager init
    [LocationManager shared];
    
    // notifications
    [self configureUNUserNotificationCenter];
    [self startMonitoringRegions];
    
    return YES;
}

#pragma mark - Regions monitoring

- (void)startMonitoringRegions {
    // region Entered
    [[NSNotificationCenter defaultCenter] addObserverForName:kLocationEnteredRegion
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull notification) {
                                                      if ([notification.object isKindOfClass:[CLRegion class]]) {
                                                          CLRegion *region = [notification object];
                                                          NSString *event = [NSString stringWithFormat:@"didEnterRegion %@ at %@", region.identifier, [NSDate date]];
                                                          DLog(@"%@", event);
                                                          // Show notification:
                                                          // content
                                                          UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                                                          content.title = @"Did entered region";
                                                          content.subtitle = region.identifier;
                                                          content.body = region.description;
                                                          content.categoryIdentifier = @"message";
                                                          content.sound = [UNNotificationSound defaultSound];
                                                          // show:
                                                          [self presentUserNotification:content];
                                                      }
                                                  }];
}

#pragma mark - UNUserNotificationCenter, delegate

- (UNUserNotificationCenter *)userNotificationCenter {
    return [UNUserNotificationCenter currentNotificationCenter];
}

- (void)configureUNUserNotificationCenter {
    // Ask for permission
    UNAuthorizationOptions authOptions = UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert;
    [[self userNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            DLog(@"UNUserNotificationCenter granted");
        } else {
            DLog(@"UNUserNotificationCenter error: %@", error.localizedDescription);
        }
    }];
    
    // delegate
    [self userNotificationCenter].delegate = self;
}

- (void)presentUserNotification:(UNMutableNotificationContent *)content {
    // trigger
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.1
                                                                                                    repeats:NO];
    // request
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"id-test"
                                                                          content:content
                                                                          trigger:trigger];
    // post notification
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                           withCompletionHandler:nil];
}

#pragma mark UNUserNotificationCenterDelegate:

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    // The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
    completionHandler(UNNotificationPresentationOptionAlert + UNNotificationPresentationOptionSound);
}

@end
