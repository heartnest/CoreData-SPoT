//
//  TagsTVCViewController.h
//  Core Data SPoT
//
//  Created by HeartNest on 7/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "CoreDataTableViewController.h"

@interface TagsTVCViewController : CoreDataTableViewController

// The Model for this class.
// Essentially specifies the database to look in to find all Tags to display in this table.
@property (strong,nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong,nonatomic) UIManagedDocument *document;//For saving in file system

@property bool needCleanStore;//Set YES, delete store in file system on launch, For TESTING
@property bool needDeleteContextElement;//Set YES, delete datas in store on launch, For TESTING

@end
