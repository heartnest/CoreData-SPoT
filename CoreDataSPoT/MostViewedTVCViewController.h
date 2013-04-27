//
//  MostViewedTVCViewController.h
//  Core Data SPoT
//
//  Created by HeartNest on 7/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//


#import "CoreDataTableViewController.h"

@interface MostViewedTVCViewController:CoreDataTableViewController

@property (strong,nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong,nonatomic) UIManagedDocument *document;

@end
