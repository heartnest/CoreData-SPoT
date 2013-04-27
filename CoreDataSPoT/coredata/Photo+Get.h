//
//  Photo+Get.h
//  Core Data SPoT
//
//  Created by HeartNest on 18/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "Photo.h"

@interface Photo (Get)

+(Photo *)photoWithPhotoDic:(NSDictionary *)photoDictionary inManagedObjectContext:(NSManagedObjectContext *)context;
@end
