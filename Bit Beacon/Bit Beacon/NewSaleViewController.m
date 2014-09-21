//
//  NewSaleViewController.m
//  BitBeacon
//
//  Created by Jonah Starling on 9/21/14.
//  Copyright (c) 2014 BitCat. All rights reserved.
//

#import "NewSaleViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "TransferService.h"

@interface NewSaleViewController () <UITextFieldDelegate, NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UITextField *moneyTextField;
@property (strong, nonatomic) IBOutlet UILabel *BTCTextField;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) int sessionFailureCount;
@property (nonatomic, strong) NSString *currentTransactionURL;
@property (nonatomic, strong) NSString *walletAddress;
@property (nonatomic, strong) NSString *authString;

@property (strong, nonatomic) CBPeripheralManager       *peripheralManager;
@property (strong, nonatomic) CBMutableCharacteristic   *transferCharacteristic;
@property (strong, nonatomic) NSData                    *dataToSend;
@property (nonatomic, readwrite) NSInteger              sendDataIndex;

@end

@implementation NewSaleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _moneyTextField.delegate = self;
    
    //bluetooth
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)initiateSale:(id)sender {

    NSString *apiKey = @"6LWSFXwV0wkASU72sxLWFoe8gxQCI7sP8S3jcJm78";
    
    NSDecimalNumber *amount = [self getCurrency];
    
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
                               @"price": amount,
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
        [_BTCTextField setText:[NSString stringWithFormat:@"%@ BTC",[json objectForKey:@"btcPrice"]]];
        [self getBTCAddress];
    }];
    [invpostDataTask resume];
    
    
    
}

-(void) getBTCAddress{
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
        NSLog(@"SERVER RETURNED DATA: %@",dataAsString);
        //_currentTransactionURL = [json objectForKey:@"url"];
        //TODO: This is a dummy address because BitPay test server does not respond to the correct Accept stuff
        _walletAddress=@"msj42CCGruhRsFrGATiUuh25dtxYtnpbTx";
        if(_walletAddress){
            [_statusImage setImage:[UIImage imageNamed:@"rfid_signal"]];
            
        }
    }];
    [invcheckDataTask resume];

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

#pragma mark NSURLSessionDelegate methods

//chirp chirp



@end
