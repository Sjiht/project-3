//
//  СhatViewController.h
//  ChatApp
//
//  Created by Thijs van der Velden on 10/06/2014
//  Copyright (c) 2014 Thijs van der Velden. All rights reserved.
//

#import "СhatViewController.h"
#import "ChatMessageTableViewCell.h"
#import "ChatHistory.h"

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

- (void)makeMessages
{
    // initiate variables
    ChatHistory *chatHistory = [[ChatHistory alloc] init];
    [chatHistory dbRequest];
    NSMutableArray *messages3;
    messages3 = [[NSMutableArray alloc]init];
    
    // wait until request is done
    while([[chatHistory chatsArray] count] == 0){
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    // make messages from objects from database
    if([[chatHistory chatsArray]objectAtIndex:0] != [NSNull null]){
        for(int i = 0; i < [chatHistory chatsArray].count; i++){
            
            QBChatMessage *message = [[QBChatMessage alloc] init];
            message.recipientID = (NSInteger)[[[[chatHistory chatsArray] objectAtIndex:i]fields][@"recipientID"] integerValue];
            message.senderID = [[[chatHistory chatsArray] objectAtIndex:i]userID];
            message.datetime = [[[chatHistory chatsArray] objectAtIndex:i]createdAt];
            message.text = [[[chatHistory chatsArray] objectAtIndex:i]fields][@"message"];
            // If user is sender while opponent is recipient, or if user is recipient and opponent is sender
            if((message.recipientID == self.opponent.ID && message.senderID == [LocalStorageService shared].currentUser.ID) || (message.recipientID == [LocalStorageService shared].currentUser.ID && message.senderID == self.opponent.ID)) {
                [messages3 addObject:message];
            }
            
        }
        // sort messages on date
        NSSortDescriptor *sort=[NSSortDescriptor sortDescriptorWithKey:@"datetime" ascending: YES];
        [messages3 sortUsingDescriptors:[NSArray arrayWithObject:sort]];
        
        // check if opponent is there
        if(self.opponent != nil){
            self.messages = messages3;
            self.messagesTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            [self.messagesTableView reloadData];
        }else{
            self.messages = [NSMutableArray array];
        }

}
}
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    // Request to the database for the Chathistory

    // Reload the messages array
    [self makeMessages];
}



// message ophalen en inlezen in een andere class (chatMessages.m)
// op dezelfde manier als friends
// al met al: models



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
        
        // Store in ChatHistory database
        ChatHistory *chatHistory = [[ChatHistory alloc] init];
        [chatHistory storeMessage:message.text :message.recipientID];
        
    }
    // Connection to the database table ChatHistory2
    // Reload the messages array with the newly send message
    [self makeMessages];

    
    
    
    
    // Reload table to show new send message
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
