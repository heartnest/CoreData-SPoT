//
//  Recent+Create.m
//  Core Data SPoT
//
//  Created by HeartNest on 26/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "Recent+Create.h"
#import "Photo+Get.h"


@implementation Recent (Create)


+(Recent *)recentWithPhoto:(Photo *)photo inManagedObjectContext:(NSManagedObjectContext *)context;
{
    
    Recent *recent = nil;
    NSString *photoid = photo.unique;
    //From
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Recent" ];
    request.predicate = [NSPredicate predicateWithFormat:@"photo.unique = %@", photoid];
    
    NSError* err = nil;
    NSArray *matches = [context executeFetchRequest:request error:&err];
    
    if(!matches || [matches count] >1){
        //Err occured
        NSLog(@"Error occured %@",err);
    }else if(![matches count]){
        //tag not found, then create
        recent = [NSEntityDescription insertNewObjectForEntityForName:@"Recent" inManagedObjectContext:context ];
        NSNumber *times = [NSNumber numberWithInt:1];
        recent.viewedTimes = times;
        recent.photo = photo;
        
    }else{
        recent = [matches lastObject];
        int viewd =  [recent.viewedTimes intValue];
        viewd ++;
        recent.viewedTimes = [NSNumber numberWithInt:viewd];
    }
    
    return recent;
}
@end
