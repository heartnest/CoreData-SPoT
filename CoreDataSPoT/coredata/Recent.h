//
//  Recent.h
//  CoreDataSPoT
//
//  Created by HeartNest on 28/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photo;

@interface Recent : NSManagedObject

@property (nonatomic, retain) NSNumber * viewedTimes;
@property (nonatomic, retain) Photo *photo;

@end
