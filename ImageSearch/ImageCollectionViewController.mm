//
//  ImageCollectionViewController.m
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import "Image.h"
#import "ImageCollectionViewController.h"
#import "ImageViewController.h"


#define NUM_BUFFER_IMAGES 10


@interface ImageCollectionViewController ()

@property (nonatomic) NSMutableArray *images;
@property (nonatomic) int lastPageStartIndex;
@property (nonatomic) int prevStartIndex;

@end


@implementation ImageCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.lastPageStartIndex = -1;
    self.prevStartIndex = INT_MIN;
    self.images = [[NSMutableArray alloc] init];
    [self loadImageURLs:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.images removeAllObjects];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.images count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *kIdentifier = @"ImageThumbnailCell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kIdentifier
                                                                           forIndexPath:indexPath];
    cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"photo-frame.png"]];

    int index = (int)indexPath.row;
    int numImages = (int)[self.images count];

    if (numImages <= index + NUM_BUFFER_IMAGES) {
        [self loadImageURLs:numImages];
    } else {
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
        Image *img = self.images[index];

        if (img.tbImage) {
            imageView.image = img.tbImage;
        } else {
            // The image is not loaded yet. Load it in the background.
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
                UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:img.tbUrl]];

                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    imageView.image = image;
                    img.tbImage = image;
                });
            });
        }
    }

    return cell;
}

- (void)loadImageURLs:(int)startIndex {
    if (self.search.length > 0
        && startIndex >= self.prevStartIndex + NUM_IMAGES_PER_REQUEST
        && (startIndex <= self.lastPageStartIndex || self.lastPageStartIndex < 0)) {

        [[DownloadManager instance] fetchGoogleImagesForQuery:self.search
                                               withStartIndex:startIndex
                                                     delegate:self];
        self.prevStartIndex = startIndex;
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showImageDetail"]) {
        NSIndexPath *selectedIndexPath = [[self.collectionView indexPathsForSelectedItems] objectAtIndex:0];

        Image *img = self.images[(int)selectedIndexPath.row];
        ImageViewController *imageVC = [segue destinationViewController];
        imageVC.url = img.url;
    }
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int numImages = (int)[self.images count];

    NSArray *visibles = [self.collectionView indexPathsForVisibleItems];
    for (NSIndexPath *path in visibles) {
        int index = (int)path.row;
        if (numImages <= index + NUM_BUFFER_IMAGES) {
            [self loadImageURLs:numImages];
            break;
        }
    }
}

#pragma mark - ImageSearchDelegate

- (void)parseResponse:(NSDictionary *)response {
    NSData *data = response[DATA_KEY];
    __block NSError *error = response[ERROR_KEY];
    if (error) {
        NSLog(@"response error: %@", error);
        return;
    }

    // Parse the data int the background.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONWritingPrettyPrinted
                                                                       error:&error];
        
        if (error) {
            NSLog(@"json serialization error = %@, response = %@", error, responseDict);
            return;
        }
        
        id responseData = responseDict[@"responseData"];
        if (![responseData isKindOfClass:[NSDictionary class]]) {
            NSLog(@"json serialization error = %@, response = %@", error, responseDict);
            return;
        }
        
        NSArray *resultArray = responseData[@"results"];
        NSDictionary *cursor = responseData[@"cursor"];
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self setupViewWithData:resultArray cursor:cursor];
        });
    });
}

- (void)setupViewWithData:(NSArray *)resultArray cursor:(NSDictionary *)cursor {
    DownloadManager *dwnManagr = [DownloadManager instance];
    for (NSDictionary *entry in resultArray) {
        Image *img = [[Image alloc] init];
        img.tbUrl = [dwnManagr urlFromString:entry[@"tbUrl"]];
        img.url = [dwnManagr urlFromString:entry[@"url"]];
        [self.images addObject:img];
    }

    if (cursor && [cursor isKindOfClass:[NSDictionary class]]) {
        NSDictionary *page = [cursor[@"pages"] lastObject];
        self.lastPageStartIndex = [page[@"start"] intValue];
    }

    [self.collectionView reloadData];
}

@end
