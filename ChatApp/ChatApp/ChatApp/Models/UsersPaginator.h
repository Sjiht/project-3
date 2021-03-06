//
//  UsersPaginator.h
 
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "NMPaginator.h"

@interface UsersPaginator : NMPaginator

@property (nonatomic,retain)NSMutableArray *usersArray;
@property (nonatomic,retain)NSMutableArray *userrequestArray;
- (void) dbRequest;
- (void) requestUser: (NSString *) friendName;
- (void) addUser:(NSInteger *) friendID : (NSString*) friendName;
@end
