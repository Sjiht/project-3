//
//  ChatHistory.h
//  ChatApp
//
//  Created by Thijs van der Velden on 24-06-14.
//  Copyright (c) 2014 Igor Khomenko. All rights reserved.
//

#import "NMPaginator.h"

@interface ChatHistory : NMPaginator
@property (nonatomic,retain)NSMutableArray *chatsArray;
- (void) dbRequest;
- (void)storeMessage: (NSString*) messageText : (NSInteger) recipientID;


@end
