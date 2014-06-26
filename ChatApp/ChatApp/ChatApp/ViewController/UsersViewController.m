//
//  UsersViewController.m
//  ChatApp
//
//  Created by Thijs van der Velden on 10/06/2014
//  Copyright (c) 2014 Thijs van der Velden. All rights reserved.
//

#import "UsersViewController.h"
#import "UsersPaginator.h"
#import "MainTabBarController.h"
#import "СhatViewController.h"

@interface UsersViewController () <UITableViewDelegate, UITableViewDataSource, NMPaginatorDelegate>

@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, weak) IBOutlet UITableView *usersTableView;
@property (nonatomic, strong) UsersPaginator *paginator;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;


@end

@implementation UsersViewController


#pragma mark
#pragma mark ViewController lyfe cycle
- (void)usersLoad{
    self.users = [NSMutableArray array];
    UsersPaginator *usersPaginator = [[UsersPaginator alloc] init];
    [usersPaginator dbRequest];
    while([[usersPaginator usersArray] count] == 0)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    
    if([[usersPaginator usersArray]objectAtIndex:0] != [NSNull null]){
        for(int i=0;i<[[usersPaginator usersArray] count]; i++) {
            QBUUser *user = [[QBUUser alloc] init];
            user.login = [[[usersPaginator usersArray]objectAtIndex:i]fields][@"FriendName"];
            user.ID = (NSInteger)[[[[usersPaginator usersArray]objectAtIndex:i]fields][@"FriendID"]integerValue];
            [self.users addObject:user];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Friends");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin)
                                                 name:kUserLoggedInNotification object:nil];
    
    [self usersLoad];
}

- (void)userDidLogin{
    [self setupTableViewFooter];
    
    // Fetch 10 users
    [self.paginator fetchFirstPage];
}

// Let keyboard disappear when touching anywhere else
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    
    if (![[touch view] isKindOfClass:[UITextField class]]) {
        [self.view endEditing:YES];
    }
    [super touchesBegan:touches withEvent:event];
}

#pragma mark
#pragma mark Storyboard

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    // check if users is logged in
    if([LocalStorageService shared].currentUser == nil){
        [((MainTabBarController *)self.tabBarController) showUserIsNotLoggedInAlert];
        return NO;
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    ChatViewController *destinationViewController = (ChatViewController *)segue.destinationViewController;
    QBUUser *user = (QBUUser *)self.users[((UITableViewCell *)sender).tag];
    destinationViewController.opponent = user;
    
}


#pragma mark
#pragma mark Paginator

- (void)fetchNextPage
{
    [self.paginator fetchNextPage];
    [self.activityIndicator startAnimating];
}

- (void)setupTableViewFooter
{
    // set up label
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    footerView.backgroundColor = [UIColor clearColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.textColor = [UIColor lightGrayColor];
    label.textAlignment = NSTextAlignmentCenter;
    
    self.footerLabel = label;
    [footerView addSubview:label];
    
    // set up activity indicator
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.center = CGPointMake(40, 22);
    activityIndicatorView.hidesWhenStopped = YES;
    
    self.activityIndicator = activityIndicatorView;
    [footerView addSubview:activityIndicatorView];
    
    self.usersTableView.tableFooterView = footerView;
}


#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserCellIdentifier"];
    
    QBUUser *user = (QBUUser *)self.users[indexPath.row];
    
    cell.tag = indexPath.row;
    cell.textLabel.text = user.login;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // when reaching bottom, load a new page
    if (scrollView.contentOffset.y == scrollView.contentSize.height - scrollView.bounds.size.height){
        // ask next page only if we haven't reached last page
        if(![self.paginator reachedLastPage]){
            // fetch next page of results
            [self fetchNextPage];
        }
    }
}


#pragma mark
#pragma mark NMPaginatorDelegate

- (void)paginator:(id)paginator didReceiveResults:(NSArray *)results
{
    [self.activityIndicator stopAnimating];
    
    // reload table with users
    [self.users addObjectsFromArray:results];
    [self.usersTableView reloadData];
}

- (IBAction)AddFriend:(id)sender {
    UITextField *FriendLabel = self.FriendLabel;
    NSString *friendName = FriendLabel.text;
    UsersPaginator *usersPaginator = [[UsersPaginator alloc] init];
    [usersPaginator requestUser:friendName];
    
    while([[usersPaginator userrequestArray] count] == 0)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    QBUUser *user = [[usersPaginator userrequestArray]objectAtIndex:0];
    
    int friendID = user.ID;
    
    // insert into database
    
    [usersPaginator addUser:&friendID:friendName];
    
    // show message
    if ([[usersPaginator userrequestArray] count] != 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Friend added succesfully!"
                                                        message: [NSString stringWithFormat:@"Added: %@ succesfully", friendName]
                                                       delegate:self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles:nil];
        
        
        [alert show];
    }
    if ([[usersPaginator userrequestArray] count] == 0){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"User not found!"
                                                        message: [NSString stringWithFormat:@"There is no user with username: %@", friendName]
                                                       delegate:self
                                              cancelButtonTitle: @"Cancel"
                                              otherButtonTitles:nil];
        
        
        [alert show];
    }
    

    
    
    // deze shit hieronder werkt nog niet
    // refresh de array met alle friends erin
    [self usersLoad];
    
    // refresh de tabel
    [self.usersTableView reloadData];
    
    
}
@end
