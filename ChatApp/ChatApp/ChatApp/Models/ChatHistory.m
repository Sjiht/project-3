//
//  ChatHistory.m
//  ChatApp
//
//  Created by Thijs van der Velden on 24-06-14.
//  Copyright (c) 2014 Igor Khomenko. All rights reserved.
//

#import "ChatHistory.h"
@interface ChatHistory () <QBActionStatusDelegate>

@end

@implementation ChatHistory

@synthesize chatsArray;
// database request for all saved messages
- (void)dbRequest
{
    NSMutableDictionary *getRequest = [NSMutableDictionary dictionary];
    [QBCustomObjects objectsWithClassName:@"ChatHistory2" extendedRequest:getRequest delegate:self];
}

// database insert for a send message
- (void)storeMessage: (NSString*) messageText : (NSInteger) recipientID
{
    QBCOCustomObject *object = [QBCOCustomObject customObject];
    object.className = @"ChatHistory2";
    [object.fields setObject:[NSNumber numberWithLong:recipientID] forKey:@"recipientID"];
    [object.fields setObject:messageText forKey:@"message"];
    
    [QBCustomObjects createObject:object delegate:self];
}

- (void)completedWithResult:(Result *)result{
    // Create new object
    if(result.success && [result isKindOfClass:QBCOCustomObjectResult.class]){
        QBCOCustomObjectResult *createObjectResult = (QBCOCustomObjectResult *)result;
        NSLog(@"Created object: %@", createObjectResult.object);
    }else{
        NSLog(@"errors=%@", result.errors);
    }
    
    
    // Get objects result

    if(result.success && [result isKindOfClass:QBCOCustomObjectPagedResult.class]){
        QBCOCustomObjectPagedResult *getObjectsResult = (QBCOCustomObjectPagedResult *)result;
        chatsArray = [[NSMutableArray alloc]init];
        [chatsArray addObjectsFromArray:getObjectsResult.objects];
        if(chatsArray.count == 0){
            [chatsArray addObject:[NSNull null]];
        }
    
    }
    else{
        
        [chatsArray addObject:[NSNull null]];
    }
   
    
    
    
    
    }


@end
