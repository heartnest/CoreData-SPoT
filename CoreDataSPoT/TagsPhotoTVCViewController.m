//
//  TagsPhotoTVCViewController.m
//  Shutterbug
//
//  Created by HeartNest on 7/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "TagsPhotoTVCViewController.h"
#import "FlickrFetcher.h"
#import "Photo+Get.h"
#import "Recent+Create.h"

@interface TagsPhotoTVCViewController ()
@property NSArray *thumbnails;
@end

@implementation TagsPhotoTVCViewController



#pragma mark - View Controller Lifecycle

-(void)viewDidLoad{
    [self useDemoDocument];
}



#pragma mark - Properties


-(void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    _managedObjectContext = managedObjectContext;
    
    dispatch_queue_t thumbnailFetchQ = dispatch_queue_create("thumbnial fetching queue", NULL);
    
    dispatch_async(thumbnailFetchQ, ^{
        NSMutableArray *tmp = [[NSMutableArray alloc]init];
        if(self.photos){
            for(Photo *p in self.photos){
                NSData *n = [self getThumbnailPhoto:p];
                if(n){
                    [tmp addObject:n];
                }
            }
            self.thumbnails = [tmp copy];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveContext];
            [self.tableView reloadData];
        });
        
    });
}

-(void)setPhotos:(NSArray *)photos{
    NSSortDescriptor *viewedDescriptor = [[NSSortDescriptor alloc]initWithKey:@"title" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *descriptors = @[viewedDescriptor];
    NSArray *sorted = [photos sortedArrayUsingDescriptors:descriptors];
    _photos = sorted;
}



#pragma mark - Photo relative methods

-(NSData *)getThumbnailPhoto:(Photo *)p{
    
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
    }else{
        img = mPhoto.thumbnail;
    }
    return img;
}


-(void)markViewed:(Photo *)photo{
    
    [Recent recentWithPhoto:photo inManagedObjectContext:self.managedObjectContext];
    
    [self saveContext];
}


-(Photo *)getContextPhotoById:(NSString *)unique{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@",unique];
    NSArray *match =[[self.managedObjectContext executeFetchRequest:request error:nil] mutableCopy];

    if(match)
        return [match lastObject];
    
    NSLog(@"err occured when getting photo with unique id");
    return nil;
}




#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Show Image"]) {
                
                if ([segue.destinationViewController respondsToSelector:@selector(setImageURL:)]) {
                    Photo *photo = self.photos[indexPath.row];
                    NSURL *url = [NSURL URLWithString:photo.imageURL];
                    [self markViewed:[self getContextPhotoById:photo.unique]];
                    [segue.destinationViewController performSelector:@selector(setImageURL:) withObject:url];
                    [segue.destinationViewController setTitle:[self titleForRow:indexPath.row]];
                    
                }
            }
        }
    }
}



#pragma mark - Table view data source

//colon number
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.photos count];
}

//title
-(NSString *)titleForRow:(NSUInteger)row{
    if([self.photos[row] isKindOfClass:[Photo class] ])
    {
        
        Photo *photo = self.photos[row];
        return photo.title;
    }
    return nil;
}

//subtitle
-(NSString *)subTitleForRow:(NSUInteger)row{
    if([self.photos[row] isKindOfClass:[Photo class] ])
    {
        
        Photo *photo = self.photos[row];
        return [photo.subtitle capitalizedString];
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Flicker Photo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [self titleForRow:indexPath.row];
    cell.detailTextLabel.text = [self subTitleForRow:indexPath.row];
    

    if(indexPath.row < [self.thumbnails count]){
        UIImage *image= [[UIImage alloc]initWithData:self.thumbnails[indexPath.row]];
        [[cell imageView]setImage:image];
    }
    
    return cell;
}



#pragma mark  -UIManageddocument and (SQL & Filesystem store)

- (void)useDemoDocument
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"ShutterbugSQL_doc"];
    self.document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [self.document saveToURL:url
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              if (success) {
                  self.managedObjectContext = self.document.managedObjectContext;
              }
          }];
    } else if (self.document.documentState == UIDocumentStateClosed) {
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


@end
