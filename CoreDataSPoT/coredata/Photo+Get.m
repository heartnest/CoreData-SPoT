//
//  Photo+Get.m
//  Core Data SPoT
//
//  Created by HeartNest on 18/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "Photo+Get.h"
#import "FlickrFetcher.h"
#import "Tags+Create.h"

@implementation Photo (Get)

+(Photo *)photoWithPhotoDic:(NSDictionary *)photoDictionary inManagedObjectContext:(NSManagedObjectContext *)context{
    
    Photo *photo = nil;
    
    // This is just like Photo(Flickr)'s method.  Look there for commentary.
    
    if (photoDictionary) {
        
        NSString *photoid = photoDictionary[FLICKR_PHOTO_ID];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"title"
                                                                  ascending:YES
                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", photoid];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if (!matches || ([matches count] > 1)) {
            // handle error
            NSLog(@"an error occured when fetching photo %@",error);
        } else if (![matches count]) {
            //no photo well i set and insert
            photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
            photo.title = [photoDictionary[FLICKR_PHOTO_TITLE] description];
            photo.subtitle = [[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION]  description];//attention value4keyPath
            photo.imageURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString] ;
            photo.thumnailURL = [[FlickrFetcher urlForPhoto:photoDictionary format:FlickrPhotoFormatSquare] absoluteString];
            photo.unique = [photoDictionary[FLICKR_PHOTO_ID] description];
        } else {
            photo = [matches lastObject]; 
        }
    }
    
    return photo;
    
}


@end
