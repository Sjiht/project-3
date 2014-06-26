//
//  UsersPaginator.m
 
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "ChatsPaginator.h"

@interface ChatsPaginator () <QBActionStatusDelegate>

@end

@implementation ChatsPaginator

@synthesize usersArray;

- (void)dbRequest
{
    usersArray = [[NSMutableArray alloc]init];
    NSMutableDictionary *getRequest = [NSMutableDictionary dictionary];
    [QBCustomObjects objectsWithClassName:@"Friends" extendedRequest:getRequest delegate:self];
}

- (void)fetchResultsWithPage:(NSInteger)page pageSize:(NSInteger)pageSize
{
    // Retrieve QuickBlox users
    // 10 users per page
    //
    PagedRequest *request = [[PagedRequest alloc] init];
	request.perPage = pageSize;
	request.page = page;
	[QBUsers usersWithPagedRequest:request delegate:self];
}


#pragma mark
#pragma mark QBActionStatusDelegate

- (void)completedWithResult:(Result *)result
{
    if(result.success && [result isKindOfClass:QBCOCustomObjectPagedResult.class]){
        QBCOCustomObjectPagedResult *getObjectsResult = (QBCOCustomObjectPagedResult *)result;
        [usersArray addObjectsFromArray:getObjectsResult.objects];
        if(usersArray.count == 0){
            [usersArray addObject:[NSNull null]];
        }
    }
    else{
        [usersArray addObject:[NSNull null]];
    }
}

@end
