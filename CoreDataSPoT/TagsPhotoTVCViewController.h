//
//  TagsPhotoTVCViewController.h
//  Core Data SPoT
//
//  Created by HeartNest on 7/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TagsPhotoTVCViewController : UITableViewController

@property (nonatomic,strong)NSArray *photos;
@property (strong,nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong,nonatomic) UIManagedDocument *document;


@end
