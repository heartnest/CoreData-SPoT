//
//  ImageViewController.m
//  Shutterbug
//
//  Created by HeartNest on 2/4/13.
//  Copyright (c) 2013 HeartNest. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController ()<UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong,nonatomic)UIImageView *imageView;
@end

@implementation ImageViewController

-(void)setImageURL:(NSURL *)imageURL{
    _imageURL = imageURL;
    [self resetImg];
}



-(void)resetImg{
    if(self.scrollView){
        self.scrollView.contentSize = CGSizeZero;//seems does nothing
        self.imageView.image = nil;
        
        [self.spinner startAnimating];// if self.spinner is nil, does nothing

        
        NSURL *imageURL = self.imageURL;// grab the URL before we start (then check it below)
        
        //Assignment 5
        NSString *imgname = [self imgNameFromUrl:imageURL];
        
        dispatch_queue_t imageFetchQ = dispatch_queue_create("image fetcher", NULL);
        
         dispatch_async(imageFetchQ, ^{
             
             // really we should probably keep a count of threads claiming network activity
             [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
             
             //Assignment 5
             NSData *imageData = [self loadImg:imgname];
             if(!imageData){
                 imageData = [[NSData alloc]initWithContentsOfURL:self.imageURL];
                 [self cacheImg:imageData name:imgname];
             }

             
             [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
             
             // UIImage is one of the few UIKit objects which is thread-safe, so we can do this here
             UIImage *image= [[UIImage alloc]initWithData:imageData];
             // check to make sure we are even still interested in this image (might have touched away)
             if(self.imageURL == imageURL){
                 // dispatch back to main queue to do UIKit work
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if (image) {
                         self.scrollView.zoomScale=1.0;//important
                         self.scrollView.contentSize = image.size;
                         self.imageView.image = image;
                         self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
                         
                         float boundx = self.scrollView.bounds.size.width/self.imageView.bounds.size.width;
                         float boundy = self.scrollView.bounds.size.height/self.imageView.bounds.size.height;

                         float zoomscale = (boundx > boundy)? boundx:boundy;
                         self.scrollView.zoomScale = zoomscale;
                     }
                     [self.spinner stopAnimating];
                 
                 });
             }
         });
    }
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return  self.imageView;
}

-(UIImageView *)imageView{
    if(!_imageView)//CGRectZero origion zero size zero
        _imageView = [[UIImageView alloc]initWithFrame:CGRectZero];
    return  _imageView;
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
    self.scrollView.minimumZoomScale = 0.4;
    self.scrollView.maximumZoomScale = 5.0;
    self.scrollView.delegate = self;
    [self resetImg ];
}



#pragma mark functions for img caching


#define IMG_FOLDER_NAME @"photos"
-(NSString *)imgNameFromUrl:(NSURL *)url{
    
    NSArray *splitted = [[url path] componentsSeparatedByString: @"/"];
    NSString *last = [splitted lastObject];
    
    return last;
}

-(NSData *)loadImg:(NSString *)img{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL* path = [[[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:IMG_FOLDER_NAME];
    
    NSData *imageData = [[NSData alloc]initWithContentsOfURL:[path URLByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@",img]]];

    return imageData;
}

-(void)cacheImg:(NSData *)img name:(NSString *)name{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL* path = [[[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:IMG_FOLDER_NAME];
    
    if(![fm fileExistsAtPath:[path path]]){
        NSError*    theError = nil; //error setting
        [fm createDirectoryAtURL:path withIntermediateDirectories:YES
                      attributes:nil error:&theError];
    }
    
    [img writeToFile:[[path path] stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@",name]] atomically:YES];//img is NSData
}

@end
