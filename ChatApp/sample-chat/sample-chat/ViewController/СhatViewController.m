//
//  СhatViewController.h
//  ChatApp
//
//  Created by Thijs van der Velden on 10/06/2014
//  Copyright (c) 2014 Thijs van der Velden. All rights reserved.
//

#import "СhatViewController.h"
#import "ChatMessageTableViewCell.h"

@interface ChatViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, weak) IBOutlet UITextField *messageTextField;
@property (nonatomic, weak) IBOutlet UIButton *sendMessageButton;
@property (nonatomic, weak) IBOutlet UITableView *messagesTableView;
@property (nonatomic, strong) NSMutableArray *messages2;
- (IBAction)sendMessage:(id)sender;

@end

@implementation ChatViewController
@synthesize messages2;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Connection to the database table ChatHistory2
    NSMutableDictionary *getRequest = [NSMutableDictionary dictionary];
    [QBCustomObjects objectsWithClassName:@"ChatHistory2" extendedRequest:getRequest delegate:self];
    
    
}


- (void)completedWithResult:(Result *)result{
    // Get objects result
    if(result.success && [result isKindOfClass:QBCOCustomObjectPagedResult.class]){
        QBCOCustomObjectPagedResult *getObjectsResult = (QBCOCustomObjectPagedResult *)result;
        NSMutableArray *messages3 = [[NSMutableArray alloc]init];
        for(int i = 0; i < getObjectsResult.count; i++){
            QBChatMessage *message = [[QBChatMessage alloc] init];
            
                message.recipientID = [[getObjectsResult.objects objectAtIndex:i]fields][@"recipientID"] ;
                message.senderID = [[getObjectsResult.objects objectAtIndex:i]userID];
                message.text = [[getObjectsResult.objects objectAtIndex:i]fields][@"message"];
            //if(message.recipientID == self.opponent.ID && message.senderID == ){
                [messages3 addObject:message];
            //}
        }
        messages2 = messages3;
    }else{
        NSLog(@"errors=%@", result.errors);
    }
    // Create record result
    if(result.success && [result isKindOfClass:QBCOCustomObjectResult.class]){
        QBCOCustomObjectResult *createObjectResult = (QBCOCustomObjectResult *)result;
        NSLog(@"Created object: %@", createObjectResult.object);
    }else{
        NSLog(@"errors=%@", result.errors);
    }
    
    if(self.opponent != nil){
        self.messages = messages2;
        NSLog(@"Check all objects", self.messages);
        self.messagesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.messagesTableView reloadData];
    }else{
        self.messages = [NSMutableArray array];
    }
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    // Set keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    // Set chat notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chatDidReceiveMessageNotification:)
                                                 name:kNotificationDidReceiveNewMessage object:nil];
    
    // Set title
    if(self.opponent != nil){
        self.title = self.opponent.login;
    }
}

-(BOOL)hidesBottomBarWhenPushed
{
    return YES;
}

#pragma mark
#pragma mark Actions

- (IBAction)sendMessage:(id)sender{
    if(self.messageTextField.text.length == 0){
        return;
    }
    
    // 1-1 Chat
    if(self.opponent != nil){
        // send message
        QBChatMessage *message = [[QBChatMessage alloc] init];
        message.recipientID = self.opponent.ID;
        message.text = self.messageTextField.text;
        [[ChatService instance] sendMessage:message];
        NSLog(@"Message zoals je hem stuurt: %@", message);
        // save message to local history
        //[[LocalStorageService shared] saveMessageToHistory:message withUserID:message.recipientID];
        
        QBCOCustomObject *object = [QBCOCustomObject customObject];
        object.className = @"ChatHistory2"; // your Class name
        // Object fields
        [object.fields setObject:[NSNumber numberWithLong:message.recipientID] forKey:@"recipientID"];
        [object.fields setObject:message.text forKey:@"message"];
        
        [QBCustomObjects createObject:object delegate:self];
    }
    // Connection to the database table ChatHistory2
    NSMutableDictionary *getRequest = [NSMutableDictionary dictionary];
    [QBCustomObjects objectsWithClassName:@"ChatHistory2" extendedRequest:getRequest delegate:self];
    
    // Reload table
    self.messagesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.messagesTableView reloadData];
    if(self.messages.count > 0){
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.messages count]-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    
    // Clean text field
    [self.messageTextField setText:nil];
}


#pragma mark
#pragma mark Chat Notifications

- (void)chatDidReceiveMessageNotification:(NSNotification *)notification{
    
    // Reload table
    [self.messagesTableView reloadData];
    if(self.messages.count > 0){
        [self.messagesTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:[self.messages count]-1 inSection:0]
                                      atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}


#pragma mark
#pragma mark UITableViewDelegate & UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *ChatMessageCellIdentifier = @"ChatMessageCellIdentifier";
    
    ChatMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ChatMessageCellIdentifier];
    if(cell == nil){
        cell = [[ChatMessageTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ChatMessageCellIdentifier];
    }
    
    QBChatMessage *message = (QBChatMessage *)self.messages[indexPath.row];
    [cell configureCellWithMessage:message is1To1Chat:self.opponent != nil];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    QBChatMessage *chatMessage = (QBChatMessage *)[self.messages objectAtIndex:indexPath.row];
    CGFloat cellHeight = [ChatMessageTableViewCell heightForCellWithMessage:chatMessage is1To1Chat:self.opponent != nil];
    return cellHeight;
}


#pragma mark
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark
#pragma mark Keyboard notifications

- (void)keyboardWillShow:(NSNotification *)note
{
    [UIView animateWithDuration:0.3 animations:^{
		self.messageTextField.transform = CGAffineTransformMakeTranslation(0, -215);
        self.sendMessageButton.transform = CGAffineTransformMakeTranslation(0, -215);
        self.messagesTableView.frame = CGRectMake(self.messagesTableView.frame.origin.x,
                                                  self.messagesTableView.frame.origin.y,
                                                  self.messagesTableView.frame.size.width,
                                                  self.messagesTableView.frame.size.height-219);
    }];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    [UIView animateWithDuration:0.3 animations:^{
		self.messageTextField.transform = CGAffineTransformIdentity;
        self.sendMessageButton.transform = CGAffineTransformIdentity;
        self.messagesTableView.frame = CGRectMake(self.messagesTableView.frame.origin.x,
                                                  self.messagesTableView.frame.origin.y,
                                                  self.messagesTableView.frame.size.width,
                                                  self.messagesTableView.frame.size.height+219);
    }];
}

@end
