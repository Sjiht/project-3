//
//  UsersPaginator.h
 
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "NMPaginator.h"

@interface ChatsPaginator : NMPaginator

@property (nonatomic,retain)NSMutableArray *usersArray;
- (void) dbRequest;

@end
