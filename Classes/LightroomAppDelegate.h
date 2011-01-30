//
//  LightroomAppDelegate.h
//  Lightroom
//
//  Created by Kevin Griffin on 1/29/11.
//  Copyright 2011 Chariot Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LightroomViewController;

@interface LightroomAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    LightroomViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet LightroomViewController *viewController;

@end

