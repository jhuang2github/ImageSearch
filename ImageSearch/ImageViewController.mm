//
//  ImageViewController.m
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@end


@implementation ImageViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:_url]];
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            _imageView.image = image;
        });
    });

//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    [queue addOperationWithBlock:^{
//        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:_url];
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            _imageView.image = image;
//        }];
//    }];

}

@end
