//
//  NewSaleViewController.m
//  BitBeacon
//
//  Created by Jonah Starling on 9/21/14.
//  Copyright (c) 2014 BitCat. All rights reserved.
//

#import "NewSaleViewController.h"
#import "AppDelegate.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"
#define NOTIFY_MTU      20

@interface NewSaleViewController () <UITextFieldDelegate, NSURLSessionDelegate,CBPeripheralManagerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *moneyTextField;
@property (strong, nonatomic) IBOutlet UILabel *BTCTextField;
@property (strong, nonatomic) NSString *BTCCost;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) int sessionFailureCount;
@property (nonatomic, strong) NSString *currentTransactionURL;
@property (nonatomic, strong) NSString *currentTransactionID;
@property (nonatomic, strong) NSString *currentStatus;
@property (nonatomic, strong) NSString *walletAddress;
@property (nonatomic, strong) NSString *authString;
@property (nonatomic, strong) NSString *bluetoothFinalString;
@property (nonatomic, strong) NSDecimalNumber *amount;

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *initiateButton;

@end

@implementation NewSaleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _moneyTextField.delegate = self;
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    //set up the currency field
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:2];
    
    _moneyTextField.text = [numberFormatter stringFromNumber:[NSNumber numberWithInt:0]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [self.peripheralManager stopAdvertising];
    
    [super viewWillDisappear:animated];
}
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)initiateSale:(id)sender {
    
    [_initiateButton setEnabled:NO];
    

    NSString *apiKey = @"6LWSFXwV0wkASU72sxLWFoe8gxQCI7sP8S3jcJm78";
    
    _amount = [self getCurrency];
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 30.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    NSString *userPasswordString = [NSString stringWithFormat:@"%@:%@", apiKey, @""];
    NSData * userPasswordData = [userPasswordString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64EncodedCredential = [userPasswordData base64EncodedStringWithOptions:0];
    _authString = [NSString stringWithFormat:@"Basic %@", base64EncodedCredential];
NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    sessionConfig.HTTPAdditionalHeaders = @{@"Content-Type": @"application/json",
                                            @"Authorization": self.authString
                                            };

    
    NSDictionary *jsonDict = @{
                               @"price": _amount,
                               @"currency":@"USD",
                               @"transactionSpeed":@"high"
                               };
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:0
                                                         error:nil];
    NSURL *invoiceUrl = [NSURL URLWithString:@"https://test.bitpay.com/api/invoice"];
    
    NSMutableURLRequest *invoiceRequest = [NSMutableURLRequest requestWithURL:invoiceUrl];
    invoiceRequest.HTTPMethod = @"POST";
    invoiceRequest.HTTPBody = JSONData;

    NSURLSessionDataTask *invpostDataTask = [session dataTaskWithRequest:invoiceRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        // The server answers with an error because it doesn't receive the params
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [HTTPResponse statusCode];
        NSLog(@"STATUS CODE: %ld",(long)statusCode);
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              
                              options:kNilOptions 
                              error:&error];
        NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"SERVER RETURNED DATA: %@",dataAsString);
        _currentTransactionURL = [json objectForKey:@"url"];
        _currentTransactionID = [json objectForKey:@"id"];
        _currentStatus = [json objectForKey:@"status"];
        _BTCCost = [json objectForKey:@"btcPrice"];
        [self getBTCAddress];
    }];
    [invpostDataTask resume];
    
    
    
}

-(void) getBTCAddress{
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
     {
         [_BTCTextField setText:[NSString stringWithFormat:@"%@ BTC",_BTCCost]];
         
     }];
    NSURLSessionConfiguration *sessionConfigTwo =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfigTwo.timeoutIntervalForRequest = 30.0;
    sessionConfigTwo.timeoutIntervalForResource = 60.0;
    sessionConfigTwo.HTTPMaximumConnectionsPerHost = 1;
    NSURLSession *sessionTwo = [NSURLSession sessionWithConfiguration:sessionConfigTwo];
    sessionConfigTwo.HTTPAdditionalHeaders = @{@"Accept": @"text/uri-­list",
                                               @"Authorization": self.authString
                                               };
    
    NSURL *invoiceCheckUrl = [NSURL URLWithString:_currentTransactionURL];
    
    NSMutableURLRequest *invoiceCheckRequest = [NSMutableURLRequest requestWithURL:invoiceCheckUrl];
    invoiceCheckRequest.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *invcheckDataTask = [sessionTwo dataTaskWithRequest:invoiceCheckRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [HTTPResponse statusCode];
        NSLog(@"STATUS CODE: %ld",(long)statusCode);
        /*NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              
                              options:kNilOptions
                              error:&error];*/
        NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        //NSLog(@"SERVER RETURNED DATA: %@",dataAsString);
        //_currentTransactionURL = [json objectForKey:@"url"];
        //PARSING the address super hacky like, because BitPay recommended that we do this
        
        NSRange range = [dataAsString rangeOfString:@"bitcoin:"];
        NSString *newString = [dataAsString substringFromIndex:range.location];
        //TODO: this is pretty inefficient
        NSArray* arrayOfStrings = [newString componentsSeparatedByString: @"?"];
        _walletAddress = [[[arrayOfStrings objectAtIndex: 0] componentsSeparatedByString:@":"] objectAtIndex:1];
        NSLog(@"Wallet Address %@",_walletAddress);
        //_walletAddress=@"msj42CCGruhRsFrGATiUuh25dtxYtnpbTx";
        _bluetoothFinalString = [NSString stringWithFormat:@"%@:%@:%@",[_companyNameTextField text],_walletAddress,_BTCCost];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
         {
            [self beginBroadcasting];
             
         }];
        

    }];
    [invcheckDataTask resume];

}

-(void) getBTCStatus{
    
    if(![_currentStatus isEqualToString:@"new"]){
        //the transaction has gone through.
        //TODO: some sort of complete alert!
        AppDelegate *appDelegate = [[UIApplication sharedApplication]delegate];
        appDelegate.numberOfSales ++;
        appDelegate.lastSaleAmount = [_amount doubleValue];
        appDelegate.totalProfit = appDelegate.totalProfit + appDelegate.lastSaleAmount;
        [[self presentingViewController] viewWillAppear:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }else{
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 30.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    sessionConfig.HTTPAdditionalHeaders = @{@"Content-Type": @"application/json",
                                            @"Authorization": self.authString
                                            };

    NSURL *invoiceIDUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://test.bitpay.com/api/invoice/%@",_currentTransactionID]];
    
    NSMutableURLRequest *invoiceIDRequest = [NSMutableURLRequest requestWithURL:invoiceIDUrl];
    invoiceIDRequest.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *invcheckDataTask = [session dataTaskWithRequest:invoiceIDRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = [HTTPResponse statusCode];
        NSLog(@"STATUS CODE: %ld",(long)statusCode);
        NSDictionary* json = [NSJSONSerialization
         JSONObjectWithData:data
         
         options:kNilOptions
         error:&error];
//        NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
//        NSLog(@"SERVER RETURNED DATA: %@",dataAsString);
        _currentStatus = [json objectForKey:@"status"];
        
        
    }];
    [invcheckDataTask resume];
    }
}

- (IBAction)rebroadcast:(id)sender {
    if(_bluetoothFinalString){
        [self.peripheralManager stopAdvertising];
        
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
        
        [_rebroadcastButton setTitle:@"Beacon Rebroadcasted" forState:UIControlStateNormal];
    }
}

-(void) beginBroadcasting {
    if(_bluetoothFinalString){
        [_statusImage setImage:[UIImage imageNamed:@"signal"]];
        //bluetooth
        [_moneyTextField setEnabled:NO];
        //TODO: BTCTextField might not be initialized, so this might crash!
        
        [_companyNameTextField setText:@"Requesting Payment"];
        [_companyNameTextField setEnabled:NO];
        
        [self.peripheralManager startAdvertising:@{ CBAdvertisementDataServiceUUIDsKey : @[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]] }];
        
        [_rebroadcastButton setHidden:NO];
        
        [NSTimer scheduledTimerWithTimeInterval:5.0
                                         target:self
                                       selector:@selector(getBTCStatus)
                                       userInfo:nil
                                        repeats:YES];
    }
}

//https://github.com/peterboni/FormattedCurrencyInput
                        
- (NSDecimalNumber *) getCurrency{
    NSString *textFieldStr = [NSString stringWithFormat:@"%@", _moneyTextField.text];
    
    NSMutableString *textFieldStrValue = [NSMutableString stringWithString:textFieldStr];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    [textFieldStrValue replaceOccurrencesOfString:numberFormatter.currencySymbol
                                       withString:@""
                                          options:NSLiteralSearch
                                            range:NSMakeRange(0, [textFieldStrValue length])];
    
    [textFieldStrValue replaceOccurrencesOfString:numberFormatter.groupingSeparator
                                       withString:@""
                                          options:NSLiteralSearch
                                            range:NSMakeRange(0, [textFieldStrValue length])];
    
    return [NSDecimalNumber decimalNumberWithString:textFieldStrValue];
                            
}
                        
                        
                        
- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSInteger MAX_DIGITS = 8; // $999,999.99
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:2];
    
    NSString *stringMaybeChanged = [NSString stringWithString:string];
    if (stringMaybeChanged.length > 1)
    {
        NSMutableString *stringPasted = [NSMutableString stringWithString:stringMaybeChanged];
        
        [stringPasted replaceOccurrencesOfString:numberFormatter.currencySymbol
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, [stringPasted length])];
        
        [stringPasted replaceOccurrencesOfString:numberFormatter.groupingSeparator
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, [stringPasted length])];
        
        NSDecimalNumber *numberPasted = [NSDecimalNumber decimalNumberWithString:stringPasted];
        stringMaybeChanged = [numberFormatter stringFromNumber:numberPasted];
    }
    
    UITextRange *selectedRange = [textField selectedTextRange];
    UITextPosition *start = textField.beginningOfDocument;
    NSInteger cursorOffset = [textField offsetFromPosition:start toPosition:selectedRange.start];
    NSMutableString *textFieldTextStr = [NSMutableString stringWithString:textField.text];
    NSUInteger textFieldTextStrLength = textFieldTextStr.length;
    
    [textFieldTextStr replaceCharactersInRange:range withString:stringMaybeChanged];
    
    [textFieldTextStr replaceOccurrencesOfString:numberFormatter.currencySymbol
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, [textFieldTextStr length])];
    
    [textFieldTextStr replaceOccurrencesOfString:numberFormatter.groupingSeparator
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, [textFieldTextStr length])];
    
    [textFieldTextStr replaceOccurrencesOfString:numberFormatter.decimalSeparator
                                      withString:@""
                                         options:NSLiteralSearch
                                           range:NSMakeRange(0, [textFieldTextStr length])];
    
    if (textFieldTextStr.length <= MAX_DIGITS)
    {
        NSDecimalNumber *textFieldTextNum = [NSDecimalNumber decimalNumberWithString:textFieldTextStr];
        NSDecimalNumber *divideByNum = [[[NSDecimalNumber alloc] initWithInt:10] decimalNumberByRaisingToPower:numberFormatter.maximumFractionDigits];
        NSDecimalNumber *textFieldTextNewNum = [textFieldTextNum decimalNumberByDividingBy:divideByNum];
        NSString *textFieldTextNewStr = [numberFormatter stringFromNumber:textFieldTextNewNum];
        
        textField.text = textFieldTextNewStr;
        
        if (cursorOffset != textFieldTextStrLength)
        {
            NSInteger lengthDelta = textFieldTextNewStr.length - textFieldTextStrLength;
            NSInteger newCursorOffset = MAX(0, MIN(textFieldTextNewStr.length, cursorOffset + lengthDelta));
            UITextPosition* newPosition = [textField positionFromPosition:textField.beginningOfDocument offset:newCursorOffset];
            UITextRange* newRange = [textField textRangeFromPosition:newPosition toPosition:newPosition];
            [textField setSelectedTextRange:newRange];
        }
    }
    
    return NO;
}

#pragma mark - Peripheral Methods



/** Required protocol method.  A full app should take care of all the possible states,
 *  but we're just waiting for  to know when the CBPeripheralManager is ready
 */
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral
{
    // Opt out from any other state
    if (peripheral.state != CBPeripheralManagerStatePoweredOn) {
        return;
    }
    
    // We're in CBPeripheralManagerStatePoweredOn state...
    NSLog(@"self.peripheralManager powered on.");
    
    // ... so build our service.
    
    // Start with the CBMutableCharacteristic
    self.transferCharacteristic = [[CBMutableCharacteristic alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]
                                                                     properties:CBCharacteristicPropertyNotify
                                                                          value:nil
                                                                    permissions:CBAttributePermissionsReadable];
    
    // Then the service
    CBMutableService *transferService = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]
                                                                       primary:YES];
    
    // Add the characteristic to the service
    transferService.characteristics = @[self.transferCharacteristic];
    
    // And add it to the peripheral manager
    [self.peripheralManager addService:transferService];
}


/** Catch when someone subscribes to our characteristic, then start sending them data
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central subscribed to characteristic");
    
    // Get the data
    if(self.bluetoothFinalString){
        self.dataToSend = [self.bluetoothFinalString dataUsingEncoding:NSUTF8StringEncoding];
    
        // Reset the index
        self.sendDataIndex = 0;
    
        // Start sending
        [self sendData];
    }
}


/** Recognise when the central unsubscribes
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic
{
    NSLog(@"Central unsubscribed from characteristic");
}


/** Sends the next amount of data to the connected central
 */
- (void)sendData
{
    // First up, check if we're meant to be sending an EOM
    static BOOL sendingEOM = NO;
    
    if (sendingEOM) {
        
        // send it
        BOOL didSend = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // Did it send?
        if (didSend) {
            
            // It did, so mark it as sent
            sendingEOM = NO;
            
            NSLog(@"Sent: EOM");
        }
        
        // It didn't send, so we'll exit and wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
        return;
    }
    
    // We're not sending an EOM, so we're sending data
    
    // Is there any left to send?
    
    if (self.sendDataIndex >= self.dataToSend.length) {
        
        // No data left.  Do nothing
        return;
    }
    
    // There's data left, so send until the callback fails, or we're done.
    
    BOOL didSend = YES;
    
    while (didSend) {
        
        // Make the next chunk
        
        // Work out how big it should be
        NSInteger amountToSend = self.dataToSend.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > NOTIFY_MTU) amountToSend = NOTIFY_MTU;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.dataToSend.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        didSend = [self.peripheralManager updateValue:chunk forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
        
        // If it didn't work, drop out and wait for the callback
        if (!didSend) {
            return;
        }
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        
        // Was it the last one?
        if (self.sendDataIndex >= self.dataToSend.length) {
            
            // It was - send an EOM
            
            // Set this so if the send fails, we'll send it next time
            sendingEOM = YES;
            
            // Send it
            BOOL eomSent = [self.peripheralManager updateValue:[@"EOM" dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:self.transferCharacteristic onSubscribedCentrals:nil];
            
            if (eomSent) {
                // It sent, we're all done
                sendingEOM = NO;
                
                NSLog(@"Sent: EOM");
            }
            
            return;
        }
    }
}


/** This callback comes in when the PeripheralManager is ready to send the next chunk of data.
 *  This is to ensure that packets will arrive in the order they are sent
 */
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral
{
    // Start sending again
    [self sendData];
}



@end
