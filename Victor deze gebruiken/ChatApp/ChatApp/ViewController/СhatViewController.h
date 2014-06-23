//
//  СhatViewController.h
//  ChatApp
//
//  Created by Thijs van der Velden on 10/06/2014
//  Copyright (c) 2014 Thijs van der Velden. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ChatViewController : UIViewController

@property (nonatomic, strong) QBUUser *opponent;
@property (nonatomic, strong) QBChatRoom *chatRoom;
@property (nonatomic, strong) QBChatMessage *message;
extern NSMutableArray *messages2;

@end
