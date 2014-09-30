//
//  ImageCollectionViewController.h
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownloadManager.h"


@interface ImageCollectionViewController :
    UICollectionViewController<UIScrollViewDelegate, ImageSearchDelegate>

@property (nonatomic) NSString *search;  // search keywords

@end
