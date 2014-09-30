//
//  Image.h
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Image : NSObject

@property (nonatomic) NSURL *tbUrl;       // thumbnail url
@property (nonatomic) UIImage *tbImage;   // thumbnail image
@property (nonatomic) NSURL *url;         // full image url

@end;
