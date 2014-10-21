//
//  ImageCollectionViewController.m
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import "Image.h"
#import "ImageCollectionViewController.h"
#import "ImageManager.h"
#import "ImageViewController.h"


#define NUM_BUFFER_IMAGES 10


@interface ImageCollectionViewController ()

@property (nonatomic) ImageManager *imageMgr;

@end


@implementation ImageCollectionViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentChangedNotification:)
                                                 name:kImageManagerAddedContentNotification
                                               object:nil];

    self.imageMgr = [ImageManager instance];
    [self.imageMgr cleanup];
    [self.imageMgr loadImageURLsWithKeywords:self.search startIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.imageMgr cleanup];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.imageMgr numImages];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *kIdentifier = @"ImageThumbnailCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kIdentifier
                                                                           forIndexPath:indexPath];
    // Note: we do not need to check if cell == nil or not for UICollectionView.
    // In UITableView, we need to check if cell == nil or not.
    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo-frame.png"]];

    int index = (int)indexPath.row;
    int numImages = [self.imageMgr numImages];

    if (numImages <= index + NUM_BUFFER_IMAGES) {
        [self.imageMgr loadImageURLsWithKeywords:self.search startIndex:numImages];
    } else {
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
        Image *img =  [self.imageMgr imageAtIndex:index];
        [self.imageMgr loadThumbnailImage:img completionBlock:^(void){
            imageView.image = img.tbImage;
        }];
    }

    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showImageDetail"]) {
        NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] objectAtIndex:0];
        Image *img = [self.imageMgr imageAtIndex:(int)selectedIndexPath.row];

        ImageViewController *imageVC = [segue destinationViewController];
        imageVC.url = img.url;
    }
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int numImages = [self.imageMgr numImages];

    NSArray *visibles = [self.collectionView indexPathsForVisibleItems];
    for (NSIndexPath *path in visibles) {
        int index = (int)path.row;
        if (numImages <= index + NUM_BUFFER_IMAGES) {
            [self.imageMgr loadImageURLsWithKeywords:self.search startIndex:numImages];
            break;
        }
    }
}

#pragma mark - Content observer

- (void)contentChangedNotification:(NSNotification *)notification {
    [self.collectionView reloadData];
}

@end
