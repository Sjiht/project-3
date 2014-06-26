//
//  СhatViewController.h
//  ChatApp
//
//  Created by Thijs van der Velden on 10/06/2014
//  Copyright (c) 2014 Thijs van der Velden. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UsersViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *FriendLabel;

- (IBAction)AddFriend:(id)sender;

@end
