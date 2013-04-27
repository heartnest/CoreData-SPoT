//
//  Tags+Create.m
//  Core Data SPoT
//
//  Created by HeartNest on 18/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "Tags+Create.h"
#import "FlickrFetcher.h"
#import "Photo+Get.h"

@implementation Tags (Create)


//insert photo to db
+ (Tags *)tagsWithFlickrInfo:(NSDictionary *)photoDictionary inManagedObjectContext:(NSManagedObjectContext *)context{
    
    Tags *tagEntity = nil;
    
    //From
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tags" ];
    //Select
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    NSString *rawtags = [photoDictionary objectForKey:@"tags"];
    
    NSArray *arr = [rawtags componentsSeparatedByString:@" "];
   // NSMutableArray *photos = [[NSMutableArray alloc]init];
    
    for(NSString *tmp in arr){
        
        NSString *tag = [tmp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

        
        if(![tag isEqualToString: @"cs193pspot"]&& ![tag isEqualToString: @"portrait"] && ![tag isEqualToString: @"landscape"] ){
            
            //Where
            request.predicate = [NSPredicate predicateWithFormat:@"name = %@", tag];
            
            NSError* err = nil;
            NSArray *matches = [context executeFetchRequest:request error:&err];
            
            if(!matches || [matches count] >1){
                //Err occured
                NSLog(@"Error occured %@",err);
            }else if(![matches count]){
                //tag not found, then create
                tagEntity = [NSEntityDescription insertNewObjectForEntityForName:@"Tags" inManagedObjectContext:context ];
                tagEntity.name = tag;
        
                Photo *photo = [Photo photoWithPhotoDic:photoDictionary inManagedObjectContext:context];
                
                NSSet *photoset = [NSSet setWithObject:photo];
                //tagEntity.photo_number = photo;
                [tagEntity addPhotos:photoset];
                [photo addTags:[NSSet setWithObject:tagEntity]];
                
            }else{
                //tag found
                tagEntity = [matches lastObject];
                
                Photo *photo = [Photo photoWithPhotoDic:photoDictionary inManagedObjectContext:context];
                
                NSSet *photoset = [NSSet setWithObject:photo];
                [tagEntity addPhotos:photoset];
                [photo addTags:[NSSet setWithObject:tagEntity]];
                
            }

        }
        
    }
       
    return tagEntity;
}

@end
