//
//  Recent+Create.h
//  Core Data SPoT
//
//  Created by HeartNest on 26/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "Recent.h"


@interface Recent (Create)

+(Recent *)recentWithPhoto:(Photo *)photo inManagedObjectContext:(NSManagedObjectContext *)context;


@end
