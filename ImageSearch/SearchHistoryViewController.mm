//
//  SearchHistoryViewController.m
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import "ImageCollectionViewController.h"
#import "SearchHistoryViewController.h"


@interface SearchHistoryViewController ()
@property (nonatomic) NSMutableOrderedSet *searches;
@property (nonatomic) NSArray *filteredSearches;
@end


@implementation SearchHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searches = [NSMutableOrderedSet orderedSetWithArray:@[]];
}

//- (void)viewDidUnload {
//    [super viewDidUnload];
//    self.labelCellNib = nil;
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredSearches count];
    }
    return [self.searches count];
}

//- (id)labelCellNib {
//    if (!_labelCellNib) {
//        Class cls = NSClassFromString(@"UINib");
//        if ([cls respondsToSelector:@selector(nibWithNibName:bundle:)]) {
//            _labelCellNib = [[cls nibWithNibName:@"LabelCell"
//                                          bundle:[NSBundle mainBundle]] retain];
//        }
//    }
//    return _labelCellNib;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kCellIdentifier = @"SearchCell";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:kCellIdentifier];
//        if ([self labelCellNib]) {
//            cell = (CustomCell *)[[[self labelCellNib] instantiateWithOwner:self
//                                                                    options:nil] objectAtIndex:0];
//        } else {
//            cell = (CustomCell *)[[[NSBundle mainBundle] loadNibNamed:@"CustomCell"
//                                                               owner:self
//                                                             options:nil] objectAtIndex:0];
//        }
    }

    NSString *search = @"";
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        search = [self.filteredSearches objectAtIndex:indexPath.row];
    } else {
        search = [self.searches objectAtIndex:indexPath.row];
    }

    cell.textLabel.text = search;

    return cell;
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", searchText];
    self.filteredSearches = [[self.searches array] filteredArrayUsingPredicate:resultPredicate];
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString
            scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                    objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;  // reload the table view.
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *keyWords = searchBar.text;
    [self updateSearchOrder:keyWords];
    [self performSegueWithIdentifier:@"showImageCollection" sender:self];
}

- (void)updateSearchOrder:(NSString *)keyWords {
    // Make sure the latest search shows up on the top of the list.
    [self.searches removeObject:keyWords];
    [self.searches insertObject:keyWords atIndex:0];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showImageCollection"]) {
        NSIndexPath *indexPath = nil;
        NSString *search = @"";
        
        if(sender == self.searchDisplayController.searchResultsTableView) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            search = [self.filteredSearches objectAtIndex:indexPath.row];
        } else {
            indexPath = [self.tableView indexPathForSelectedRow];
            search = [self.searches objectAtIndex:indexPath.row];
        }
        [self updateSearchOrder:search];

        ImageCollectionViewController *destVC = segue.destinationViewController;
        destVC.search = search;
    }
}

@end
