//
//  UsersPaginator.m
 
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "UsersPaginator.h"

@interface UsersPaginator () <QBActionStatusDelegate>

@end

@implementation UsersPaginator

@synthesize usersArray;
@synthesize userrequestArray;

// database request to get all friends
- (void)dbRequest
{
    usersArray = [[NSMutableArray alloc]init];
    NSMutableDictionary *getRequest = [NSMutableDictionary dictionary];
    [QBCustomObjects objectsWithClassName:@"Friends" extendedRequest:getRequest delegate:self];
    
}

// database request to recieve a specific friend with a specific name
- (void)requestUser: (NSString*) friendName
{
    PagedRequest *pagedRequest = [PagedRequest request];
    pagedRequest.perPage = 50;
    pagedRequest.page = 1;
    
    [QBUsers usersWithLogins:@[friendName] pagedRequest:pagedRequest delegate:self];
}

// database insert query to add a new friend
- (void)addUser:(NSInteger *) friendID : (NSString*) friendName
{
    QBCOCustomObject *object = [QBCOCustomObject customObject];
    object.className = @"Friends"; // your Class name
    // Object fields
    [object.fields setObject:[NSNumber numberWithInt:*friendID] forKey:@"FriendID"];
    [object.fields setObject:friendName forKey:@"FriendName"];
    
    [QBCustomObjects createObject:object delegate:self];
    NSLog(@"Succesvolle insert");
    
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
     
    
    //NSMutableDictionary *getRequest = [NSMutableDictionary dictionary];
    //[QBCustomObjects objectsWithClassName:@"Friends" extendedRequest:getRequest delegate:self];
}

// if a database insert or request is succesful
- (void)completedWithResult:(Result *)result
{
    // if request is succesful
    if(result.success && [result isKindOfClass:QBCOCustomObjectPagedResult.class]){
        QBCOCustomObjectPagedResult *getObjectsResult = (QBCOCustomObjectPagedResult *)result;
        [usersArray addObjectsFromArray:getObjectsResult.objects];
        
        // if the request turns out empty add a temporary empty object
        if(usersArray.count == 0){
            [usersArray addObject:[NSNull null]];
        }
    }
    else{
        [usersArray addObject:[NSNull null]];
    }
    
    // if request is succesful
    if(result.success && [result isKindOfClass:[QBUUserPagedResult class]]){
        QBUUserPagedResult *usersResult = (QBUUserPagedResult *)result;
        userrequestArray = [[NSMutableArray alloc]init];
        NSLog(@"Users=%@", usersResult.users);
        [userrequestArray addObjectsFromArray:usersResult.users];
        if(userrequestArray.count == 0){
            [userrequestArray addObject:[NSNull null]];
        }
        
    }
    else{
        
        [userrequestArray addObject:[NSNull null]];
    }
    // if insert was succesful
    if(result.success && [result isKindOfClass:QBCOCustomObjectResult.class]){
        QBCOCustomObjectResult *createObjectResult = (QBCOCustomObjectResult *)result;
        NSLog(@"Created object: %@", createObjectResult.object);
    
    }else{
        NSLog(@"errors=%@", result.errors);
    }
    
}
@end
