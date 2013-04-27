//
//  Tags+Create.h
//  Core Data SPoT
//
//  Created by HeartNest on 18/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "Tags.h"

@interface Tags (Create)

+ (Tags *)tagsWithFlickrInfo:(NSDictionary *)photoDictionary inManagedObjectContext:(NSManagedObjectContext *)context;
@end
