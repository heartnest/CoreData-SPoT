//
//  MostViewedTVCViewController.m
//  Core Data SPoT
//
//  Created by HeartNest on 7/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "MostViewedTVCViewController.h"
#import "FlickrFetcher.h"
#import "Photo+Get.h"
#import "Recent+Create.h"

@interface MostViewedTVCViewController ()

@end

@implementation MostViewedTVCViewController


#define MAX_VIEWED_SHOWN 10



#pragma mark - View Controller Lifecycle

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self useDemoDocument];
}



#pragma mark - Properties

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    if (managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Recent"];
        request.fetchLimit = MAX_VIEWED_SHOWN;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"viewedTimes"
                                                                  ascending:NO
                                                                   selector:@selector(localizedCaseInsensitiveCompare:)]];
        
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
}



#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Image"]) {
                
                if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
                    
                    Recent *r = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    Photo *p = r.photo;
                    NSURL *url = [NSURL URLWithString: p.imageURL];
                    [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
                    [segue.destinationViewController setTitle:p.title];
                }
            }
        }
    }
}



#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flicker Photo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Recent *r = [self.fetchedResultsController objectAtIndexPath:indexPath];
    Photo *p = r.photo;
    int viewed = [r.viewedTimes intValue];
    cell.textLabel.text = p.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ viewed %d times", p.subtitle, viewed ];
    
    NSData *imgdata = [self getThumbnailForPhoto:p];
    if(imgdata){
        UIImage *image= [[UIImage alloc]initWithData:imgdata];
        [[cell imageView]setImage:image];
    }
    
    return cell;
}



#pragma mark - UIManagedDocument (SQLContext & FileSystem)

- (void)useDemoDocument
{
    ;
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"ShutterbugSQL_doc"];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    //folder does not exist
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        
        [self.document saveToURL:url
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:^(BOOL success) {
                   if (success) {
                       self.managedObjectContext = self.document.managedObjectContext;
                   }
               }];
    } else if (self.document.documentState == UIDocumentStateClosed) {
        
        //usually goes here after record are allocated
        [self.document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = self.document.managedObjectContext;
            }else{
                NSLog(@"documente has not been OPENNED !!!!!");
                
            }
        }];
    } else {
        self.managedObjectContext = self.document.managedObjectContext;
    }
}


-(void)saveContext{
    [self.managedObjectContext save:nil];
    [self.document saveToURL:self.document.fileURL
            forSaveOperation:UIDocumentSaveForOverwriting
           completionHandler:^(BOOL success) {
               if (success) {
                   // NSLog(@"doc saved ...");
               }
               else{
                   NSLog(@"doc not saved ...");
               }
           }];
}


#pragma mark - Photo relative methods

-(NSData *)getThumbnailForPhoto:(Photo *)p{
    
    NSData *img = nil;
    
    NSString *photoid = p.unique;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", photoid];
    
    NSArray *match =[[self.managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
    Photo *mPhoto = [match lastObject];
    
    if(!mPhoto.thumbnail){
        NSURL *thumbnailurl = [NSURL URLWithString:p.thumnailURL];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        img = [[NSData alloc]initWithContentsOfURL:thumbnailurl];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        mPhoto.thumbnail = img;
        
        [self saveContext];
        
    }else{
        img = mPhoto.thumbnail;
    }
    return img;
}

@end
