//
//  TagsTVCViewController.m
//  Core Data SPoT
//
//  Created by HeartNest on 7/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "TagsTVCViewController.h"
#import "FlickrFetcher.h"
#import "Photo.h"
#import "Tags+Create.h"

@interface TagsTVCViewController ()
@end

@implementation TagsTVCViewController



#pragma mark - View Controller Lifecycle


// Just sets the Refresh Control's target/action since it can't be set in Xcode (bug?).

- (void)viewDidLoad
{
    //set flags on launch
    self.needCleanStore = NO;
    self.needDeleteContextElement = NO;
    
    [super viewDidLoad];
    [self.refreshControl addTarget:self
                            action:@selector(refresh)
                  forControlEvents:UIControlEventValueChanged];
}

// Whenever the table is about to appear, if we have not yet opened/created or demo document, do so.
// And add observer to the notification center

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.managedObjectContext) [self useDemoDocument];
}


#pragma mark - Refreshing


// Fires off a block on a queue to fetch data from Flickr.
// When the data comes back, it is loaded into Core Data by posting a block to do so on
//   self.managedObjectContext's proper queue (using performBlock:).
// Data is loaded into Core Data by calling photoWithFlickrInfo:inManagedObjectContext: category method.

- (IBAction)refresh
{
    [self beginRefreshingTableView];

    dispatch_queue_t fetchQ = dispatch_queue_create("Flickr Fetch", NULL);
    dispatch_async(fetchQ, ^{
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        NSArray *photos = [FlickrFetcher stanfordPhotos];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        // put the photos in Core Data
        [self.managedObjectContext performBlock:^{
            for (NSDictionary *photo in photos) {
                [Tags  tagsWithFlickrInfo:photo inManagedObjectContext:self.managedObjectContext];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
                [self saveContext];
                 //[self.tableView reloadData]; //doesn't work
            });
        }];
    });
}

//method for solving doesn't refresh issue
- (void)beginRefreshingTableView {
    
    [self.refreshControl beginRefreshing];
    
    if (self.tableView.contentOffset.y == 0) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^(void){
            self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
        } completion:^(BOOL finished){
        }];
    }
}


#pragma mark - Properties


// The Model for this class.
//
// When it gets set, we create an NSFetchRequest to get all Tags in the database associated with it.
// Then we hook that NSFetchRequest up to the table view using an NSFetchedResultsController.

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    if (managedObjectContext) {

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tags"];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = nil; // all tags
        
        if(self.needDeleteContextElement){
            NSArray *arr = [managedObjectContext executeFetchRequest:request error: nil];
            for(id x in arr){
                [managedObjectContext deleteObject:x];
            }
            [managedObjectContext save:nil];
        }else{
            self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        }
    } else {
        self.fetchedResultsController = nil;
    }
}



#pragma mark - UITableViewDataSource


// Uses NSFetchedResultsController's objectAtIndexPath: to find the Tag for this row in the table.
// Then uses that Tag to set the cell up.

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tags *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Flicker Tag"];
    cell.textLabel.text = [tag.name capitalizedString];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d photos", [tag.photos count]];

    return cell;
}

#pragma mark - Segue

// Gets the NSIndexPath of the UITableViewCell which is sender.
// Then uses that NSIndexPath to find the PHOTOS of the Tag in question using NSFetchedResultsController
// Prepares a destination view controller through the "setPhotos:" segue by sending that to it.

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    
    if (indexPath) {
        if ([segue.identifier isEqualToString:@"Show photo by tag"]) {
            Tags *tag = [self.fetchedResultsController objectAtIndexPath:indexPath];
            NSArray *photos =[[tag.photos allObjects] copy];
            if ([segue.destinationViewController respondsToSelector:@selector(setPhotos:)]) {
                [segue.destinationViewController performSelector:@selector(setPhotos:) withObject:photos];
                [segue.destinationViewController setTitle:[tag.name capitalizedString]];
            }
        }
    }
}


#pragma mark - UIManagedDocument (SQLContext & FileSystem)


// Either creates, opens or just uses the demo document
//   (actually, it will never "just use" it since it just creates the UIManagedDocument instance here;
//    the "just uses" case is just shown that if someone hands you a UIManagedDocument, it might already
//    be open and so you can just use it if it's documentState is UIDocumentStateNormal).
//
// Creating and opening are asynchronous, so in the completion handler we set our Model (managedObjectContext).
- (void)useDemoDocument
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"ShutterbugSQL_doc"];
    
    if(self.needCleanStore){ //Test only
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtURL:url  error:nil];
        NSLog(@"store cleaned");
    }
    else{
        self.document = [[UIManagedDocument alloc] initWithFileURL:url];
        //Document does not exist
        if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            
            [self.document saveToURL:url
                    forSaveOperation:UIDocumentSaveForCreating
                   completionHandler:^(BOOL success) {
                       if (success) {
                           self.managedObjectContext = self.document.managedObjectContext;
                           [self.tableView reloadData];
                           [self refresh];
                       }
                   }];
        } else if (self.document.documentState == UIDocumentStateClosed) {
            //Open document
            [self.document openWithCompletionHandler:^(BOOL success) {
                if (success) {
                    self.managedObjectContext = self.document.managedObjectContext;
                }else{
                    NSLog(@"WARNING document has not been OPENNED !!!!!");
                }
            }];
        } else {
            //accept a document passed from other, rare case
            self.managedObjectContext = self.document.managedObjectContext;
        }
    }}

//Force saving, because automatic saving takes too long ...
-(void)saveContext{
    [self.managedObjectContext save:nil];
    [self.document saveToURL:self.document.fileURL
            forSaveOperation:UIDocumentSaveForOverwriting
           completionHandler:^(BOOL success) {
               if (success) {
                   [self useDemoDocument];
                   // NSLog(@"doc saved ...");
               }
               else{
                   NSLog(@"doc not saved ...");
               }
           }];
}


@end
