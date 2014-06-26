//
//  СhatsViewController.h
//  ChatApp
//
//  Created by Thijs van der Velden on 10/06/2014
//  Copyright (c) 2014 Thijs van der Velden. All rights reserved.
//

#import "ChatsViewController.h"
#import "ChatsPaginator.h"
#import "MainTabBarController.h"
#import "СhatViewController.h"
#import "LoginViewController.h"

@interface ChatsViewController () <UITableViewDelegate, UITableViewDataSource, NMPaginatorDelegate>

@property (nonatomic, strong) NSMutableArray *chats;
@property (nonatomic, weak) IBOutlet UITableView *chatsTableView;
@property (nonatomic, strong) ChatsPaginator *paginator;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation ChatsViewController

@synthesize loaded;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark
#pragma mark ViewController lyfe cycle


- (void)viewDidLoad
{
    //SplashViewController *splashViewController = [[SplashViewController alloc] init];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Your app connects to QuickBlox server here.
    //
    // QuickBlox session creation
	[QBAuth createSessionWithDelegate:self];
    while(loaded != 1)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidLogin)
                                                 name:kUserLoggedInNotification object:nil];
    
    self.chats = [NSMutableArray array];
    ChatsPaginator *chatsPaginator = [[ChatsPaginator alloc] init];
    if(loaded == 1)
    {
        [chatsPaginator dbRequest];
        while([[chatsPaginator usersArray] count] == 0)
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
        if([[chatsPaginator usersArray]objectAtIndex:0] != [NSNull null]){
            for(int i=0;i<[[chatsPaginator usersArray] count]; i++) {
                QBUUser *user = [[QBUUser alloc] init];
                user.login = [[[chatsPaginator usersArray]objectAtIndex:i]fields][@"FriendName"];
                user.ID = (NSInteger)[[[[chatsPaginator usersArray]objectAtIndex:i]fields][@"FriendID"]integerValue];
                [self.chats addObject:user];
            }
        }
    }
}

// QuickBlox API queries delegate
- (void)completedWithResult:(Result *)result{
    
    // QuickBlox session creation  result
    if([result isKindOfClass:[QBAAuthSessionCreationResult class]]){
        
        // Success result
        if(result.success){
            
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                // hide splash
                [self dismissViewControllerAnimated:YES completion:nil];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotification object:nil];
                
                loaded = 1;
                
            });
        }
    }
}

- (void)userDidLogin{
    [self setupTableViewFooter];
    
    // Fetch 10 chats
    [self.paginator fetchFirstPage];
}


#pragma mark
#pragma mark Storyboard

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    // check if chats is logged in
    if([LocalStorageService shared].currentUser == nil){
        [((MainTabBarController *)self.tabBarController) showUserIsNotLoggedInAlert];
        return NO;
    }
    
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    ChatViewController *destinationViewController = (ChatViewController *)segue.destinationViewController;
    QBUUser *user = (QBUUser *)self.chats[((UITableViewCell *)sender).tag];
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
    
    self.chatsTableView.tableFooterView = footerView;
}


#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.chats count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ChatCellIdentifier"];
    QBUUser *user = (QBUUser *)self.chats[indexPath.row];
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
    
    // reload table with chats
    [self.chats addObjectsFromArray:results];
    [self.chatsTableView reloadData];
}

@end
