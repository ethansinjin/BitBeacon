//
//  BRSettingsViewController.m
//  BreadWallet
//
//  Created by Aaron Voisine on 6/11/13.
//  Copyright (c) 2013 Aaron Voisine <voisine@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "BRSettingsViewController.h"
#import "BRRootViewController.h"
#import "BRTxDetailViewController.h"
#import "BRPINViewController.h"
#import "BRWalletManager.h"
#import "BRWallet.h"
#import "BRPeerManager.h"
#import "BRTransaction.h"
#import "BRCopyLabel.h"
#import "BRBubbleView.h"

#define TRANSACTION_CELL_HEIGHT 75

@interface BRSettingsViewController ()

@property (nonatomic, strong) NSArray *transactions;
@property (nonatomic, assign) BOOL moreTx;
@property (nonatomic, strong) NSMutableDictionary *txDates;
@property (nonatomic, strong) id balanceObserver, txStatusObserver;
@property (nonatomic, strong) UIImageView *wallpaper;
@property (nonatomic, strong) UITableViewController *selectorController;
@property (nonatomic, strong) NSArray *selectorOptions;
@property (nonatomic, strong) NSString *selectedOption;
@property (nonatomic, strong) UINavigationController *pinNav;

@end

@implementation BRSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.txDates = [NSMutableDictionary dictionary];
    self.wallpaper = [[UIImageView alloc] initWithFrame:self.navigationController.view.bounds];
    self.wallpaper.image = [UIImage imageNamed:@"wallpaper-default"];
    self.wallpaper.contentMode = UIViewContentModeLeft;
    [self.navigationController.view insertSubview:self.wallpaper atIndex:0];
    self.navigationController.delegate = self;
    self.moreTx = ([BRWalletManager sharedInstance].wallet.recentTransactions.count > 5) ? YES : NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    BRWalletManager *m = [BRWalletManager sharedInstance];
    NSArray *a = m.wallet.recentTransactions;
    
    self.transactions = [a subarrayWithRange:NSMakeRange(0, (a.count > 5 && self.moreTx) ? 5 : a.count)];

    if (! self.balanceObserver) {
        self.balanceObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRWalletBalanceChangedNotification object:nil
            queue:nil usingBlock:^(NSNotification *note) {
                BRTransaction *tx = self.transactions.firstObject;
                NSArray *a = m.wallet.recentTransactions;

                if (! m.wallet) return;

                if (self.moreTx) {
                    self.transactions = [a subarrayWithRange:NSMakeRange(0, a.count > 5 ? 5 : a.count)];
                    self.moreTx = (a.count > 5) ? YES : NO;
                }
                else self.transactions = [NSArray arrayWithArray:a];

                self.navigationItem.title = [NSString stringWithFormat:@"%@ (%@)", [m stringForAmount:m.wallet.balance],
                                             [m localCurrencyStringForAmount:m.wallet.balance]];

                if (self.transactions.firstObject != tx) {
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                     withRowAnimation:UITableViewRowAnimationAutomatic];
                }
                else [self.tableView reloadData];
            }];
    }

    if (! self.txStatusObserver) {
        self.txStatusObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:BRPeerManagerTxStatusNotification object:nil
            queue:nil usingBlock:^(NSNotification *note) {
                if (! m.wallet) return;
                [self.tableView reloadData];
            }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    if (self.navigationController.isBeingDismissed) {
        if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
        self.balanceObserver = nil;
        if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
        self.txStatusObserver = nil;
    }

    [super viewWillDisappear:animated];
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    [super prepareForSegue:segue sender:sender];
//
//    [segue.destinationViewController setTransitioningDelegate:self];
//    [segue.destinationViewController setModalPresentationStyle:UIModalPresentationCustom];
//}

- (void)dealloc
{
    if (self.navigationController.delegate == self) self.navigationController.delegate = nil;
    if (self.balanceObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.balanceObserver];
    if (self.txStatusObserver) [[NSNotificationCenter defaultCenter] removeObserver:self.txStatusObserver];
}

- (void)setBackgroundForCell:(UITableViewCell *)cell tableView:(UITableView *)tableView indexPath:(NSIndexPath *)path
{
    if (! cell.backgroundView) {
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.frame.size.width, 0.5)];
        
        v.tag = 100;
        cell.backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        cell.backgroundView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.67];
        v.backgroundColor = tableView.separatorColor;
        [cell.backgroundView addSubview:v];
        v = [[UIView alloc] initWithFrame:CGRectMake(0, cell.frame.size.height - 0.5, cell.frame.size.width, 0.5)];
        v.tag = 101;
        v.backgroundColor = tableView.separatorColor;
        [cell.backgroundView addSubview:v];
    }
    
    [cell viewWithTag:100].frame = CGRectMake(path.row == 0 ? 0 : 15, 0, cell.frame.size.width, 0.5);
    [cell viewWithTag:101].hidden = (path.row + 1 < [self tableView:tableView numberOfRowsInSection:path.section]);
}

- (NSString *)dateForTx:(BRTransaction *)tx
{
    static NSDateFormatter *f1 = nil, *f2 = nil, *f3 = nil;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate], w = now - 6*24*60*60, y = now - 365*24*60*60;
    NSString *date = self.txDates[tx.txHash];

    if (date) return date;

    if (! f1) { //BUG: need to watch for NSCurrentLocaleDidChangeNotification
        f1 = [NSDateFormatter new];
        f2 = [NSDateFormatter new];
        f3 = [NSDateFormatter new];

        f1.dateFormat = [[[[[[[NSDateFormatter dateFormatFromTemplate:@"Mdja" options:0 locale:[NSLocale currentLocale]]
                              stringByReplacingOccurrencesOfString:@", " withString:@" "]
                             stringByReplacingOccurrencesOfString:@" a" withString:@"a"]
                            stringByReplacingOccurrencesOfString:@"hh" withString:@"h"]
                           stringByReplacingOccurrencesOfString:@" ha" withString:@"@ha"]
                          stringByReplacingOccurrencesOfString:@"HH" withString:@"H"]
                         stringByReplacingOccurrencesOfString:@"H " withString:@"H'h' "];
        f1.dateFormat = [f1.dateFormat stringByReplacingOccurrencesOfString:@"H" withString:@"H'h'"
                         options:NSBackwardsSearch|NSAnchoredSearch range:NSMakeRange(0, f1.dateFormat.length)];
        f2.dateFormat = [[NSDateFormatter dateFormatFromTemplate:@"Md" options:0 locale:[NSLocale currentLocale]]
                         stringByReplacingOccurrencesOfString:@", " withString:@" "];
        f3.dateFormat = [[NSDateFormatter dateFormatFromTemplate:@"yyMd" options:0 locale:[NSLocale currentLocale]]
                          stringByReplacingOccurrencesOfString:@", " withString:@" "];
    }
    
    NSTimeInterval t = [[BRPeerManager sharedInstance] timestampForBlockHeight:tx.blockHeight];
    NSDateFormatter *f = (t > w) ? f1 : ((t > y) ? f2 : f3);

    date = [[[[f stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:t - 5*60]] lowercaseString]
             stringByReplacingOccurrencesOfString:@"am" withString:@"a"]
            stringByReplacingOccurrencesOfString:@"pm" withString:@"p"];
    self.txDates[tx.txHash] = date;
    return date;
}

#pragma mark - IBAction

- (IBAction)done:(id)sender
{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)scanQR:(id)sender
{
    //TODO: show scanner in settings rather than dismissing
    UINavigationController *nav = (id)self.navigationController.presentingViewController;

    nav.view.alpha = 0.0;

    [nav dismissViewControllerAnimated:NO completion:^{
        [(id)[nav.viewControllers.firstObject sendViewController] scanQR:nil];
        [UIView animateWithDuration:0.1 delay:1.5 options:0 animations:^{ nav.view.alpha = 1.0; } completion:nil];
    }];
}

- (IBAction)toggle:(id)sender
{
    UILabel *l = (id)[[sender superview] viewWithTag:2];

    [[NSUserDefaults standardUserDefaults] setBool:[sender isOn] forKey:SETTINGS_SKIP_FEE_KEY];

    l.hidden = NO;
    l.alpha = ([sender isOn]) ? 0.0 : 1.0;

    [UIView animateWithDuration:0.2 animations:^{
        l.alpha = ([sender isOn]) ? 1.0 : 0.0;
    } completion:^(BOOL finished) {
        l.alpha = 1.0;
        l.hidden = ([sender isOn]) ? NO : YES;
    }];
}

- (IBAction)about:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://breadwallet.com"]];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.selectorController.tableView) return 1;
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.selectorController.tableView) return self.selectorOptions.count;

    switch (section) {
        case 0:
            if (self.transactions.count == 0) return 1;
            return (self.moreTx) ? self.transactions.count + 1 : self.transactions.count;

        case 1:
            return 2;

        case 2:
            return 3;

        case 3:
            return 2;

        case 4:
            return 1;
            
        default:
            NSAssert(FALSE, @"%s:%d %s: unkown section %d", __FILE__, __LINE__,  __func__, (int)section);
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *noTxIdent = @"NoTxCell", *transactionIdent = @"TransactionCell", *actionIdent = @"ActionCell",
                    *toggleIdent = @"ToggleCell", *disclosureIdent = @"DisclosureCell", *restoreIdent = @"RestoreCell",
                    *selectorIdent = @"SelectorCell", *selectorOptionCell = @"SelectorOptionCell";
    UITableViewCell *cell = nil;
    UILabel *textLabel, *unconfirmedLabel, *sentLabel, *localCurrencyLabel, *balanceLabel, *localBalanceLabel,
            *toggleLabel;
    UISwitch *toggleSwitch;
    BRCopyLabel *detailTextLabel;
    BRWalletManager *m = [BRWalletManager sharedInstance];

    if (tableView == self.selectorController.tableView) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:selectorOptionCell];
        [self setBackgroundForCell:cell tableView:tableView indexPath:indexPath];
        cell.textLabel.text = self.selectorOptions[indexPath.row];

        if ([self.selectedOption isEqual:self.selectorOptions[indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        else cell.accessoryType = UITableViewCellAccessoryNone;

        return cell;
    }

    switch (indexPath.section) {
        case 0:
            if (indexPath.row > 0 && indexPath.row >= self.transactions.count) {
                cell = [tableView dequeueReusableCellWithIdentifier:actionIdent];
                cell.textLabel.text = NSLocalizedString(@"more...", nil);
                cell.imageView.image = nil;
            }
            else if (self.transactions.count > 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:transactionIdent];
                textLabel = (id)[cell viewWithTag:1];
                detailTextLabel = (id)[cell viewWithTag:2];
                unconfirmedLabel = (id)[cell viewWithTag:3];
                localCurrencyLabel = (id)[cell viewWithTag:5];
                sentLabel = (id)[cell viewWithTag:6];
                balanceLabel = (id)[cell viewWithTag:7];
                localBalanceLabel = (id)[cell viewWithTag:8];

                BRTransaction *tx = self.transactions[indexPath.row];
                uint64_t received = [m.wallet amountReceivedFromTransaction:tx],
                         sent = [m.wallet amountSentByTransaction:tx],
                         balance = [m.wallet balanceAfterTransaction:tx];
                uint32_t height = [[BRPeerManager sharedInstance] lastBlockHeight],
                         confirms = (tx.blockHeight == TX_UNCONFIRMED) ? 0 : (height - tx.blockHeight) + 1;
                NSUInteger peerCount = [[BRPeerManager sharedInstance] peerCount],
                           relayCount = [[BRPeerManager sharedInstance] relayCountForTransaction:tx.txHash];

                sentLabel.hidden = YES;
                unconfirmedLabel.hidden = NO;
                detailTextLabel.text = [self dateForTx:tx];
                balanceLabel.text = [m stringForAmount:balance];
                localBalanceLabel.text = [NSString stringWithFormat:@"(%@)", [m localCurrencyStringForAmount:balance]];

                if (confirms == 0 && ! [m.wallet transactionIsValid:tx]) {
                    unconfirmedLabel.text = NSLocalizedString(@"INVALID", nil);
                    unconfirmedLabel.backgroundColor = [UIColor redColor];
                }
                else if (confirms == 0 && [m.wallet transactionIsPostdated:tx atBlockHeight:height]) {
                    unconfirmedLabel.text = NSLocalizedString(@"post-dated", nil);
                    unconfirmedLabel.backgroundColor = [UIColor redColor];
                }
                else if (confirms == 0 && (peerCount == 0 || relayCount < peerCount)) {
                    unconfirmedLabel.text = NSLocalizedString(@"unverified", nil);
                }
                else if (confirms < 6) {
                    unconfirmedLabel.text = (confirms == 1) ? NSLocalizedString(@"1 confirmation", nil) :
                                            [NSString stringWithFormat:NSLocalizedString(@"%d confirmations", nil),
                                             (int)confirms];
                }
                else {
                    unconfirmedLabel.text = nil;
                    unconfirmedLabel.hidden = YES;
                    sentLabel.hidden = NO;
                }
                
                if (! [m.wallet addressForTransaction:tx] && sent > 0) {
                    textLabel.text = [m stringForAmount:sent];
                    localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                               [m localCurrencyStringForAmount:sent]];
                    sentLabel.text = NSLocalizedString(@"moved", nil);
                    sentLabel.textColor = [UIColor blackColor];
                }
                else if (sent > 0) {
                    textLabel.text = [m stringForAmount:received - sent];
                    localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                               [m localCurrencyStringForAmount:received - sent]];
                    sentLabel.text = NSLocalizedString(@"sent", nil);
                    sentLabel.textColor = [UIColor colorWithRed:1.0 green:0.33 blue:0.33 alpha:1.0];
                }
                else {
                    textLabel.text = [m stringForAmount:received];
                    localCurrencyLabel.text = [NSString stringWithFormat:@"(%@)",
                                               [m localCurrencyStringForAmount:received]];
                    sentLabel.text = NSLocalizedString(@"received", nil);
                    sentLabel.textColor = [UIColor colorWithRed:0.0 green:0.75 blue:0.0 alpha:1.0];
                }

                if (! unconfirmedLabel.hidden) {
                    unconfirmedLabel.layer.cornerRadius = 3.0;
                    unconfirmedLabel.backgroundColor = [UIColor lightGrayColor];
                    unconfirmedLabel.text = [unconfirmedLabel.text stringByAppendingString:@"  "];
                }
                else {
                    sentLabel.layer.cornerRadius = 3.0;
                    sentLabel.layer.borderWidth = 0.5;
                    sentLabel.text = [sentLabel.text stringByAppendingString:@"  "];
                    sentLabel.layer.borderColor = sentLabel.textColor.CGColor;
                    sentLabel.highlightedTextColor = sentLabel.textColor;
                }
            }
            else cell = [tableView dequeueReusableCellWithIdentifier:noTxIdent];
            
            break;

        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:disclosureIdent];

            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"about", nil);
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"backup phrase", nil);
                    break;

                default:
                    NSAssert(FALSE, @"%s:%d %s: unkown indexPath.row %d", __FILE__, __LINE__,  __func__,
                             (int)indexPath.row);
            }

            break;

        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:actionIdent];

            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = NSLocalizedString(@"change pin", nil);
                    cell.imageView.image = [UIImage imageNamed:@"pin"];
                    cell.imageView.alpha = 0.75;
                    break;

                case 1:
                    cell.textLabel.text = NSLocalizedString(@"import private key", nil);
                    cell.imageView.image = [UIImage imageNamed:@"cameraguide-blue-small"];
                    cell.imageView.alpha = 1.0;
                    break;

                case 2:
                    cell.textLabel.text = NSLocalizedString(@"rescan blockchain", nil);
                    cell.imageView.image = [UIImage imageNamed:@"rescan"];
                    cell.imageView.alpha = 0.75;
                    break;

                default:
                    NSAssert(FALSE, @"%s:%d %s: unkown indexPath.row %d", __FILE__, __LINE__,  __func__,
                             (int)indexPath.row);
            }
            
            break;

        case 3:
            switch (indexPath.row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:selectorIdent];
                    cell.detailTextLabel.text = m.localCurrencyCode;
                    break;

                case 1:
                    cell = [tableView dequeueReusableCellWithIdentifier:toggleIdent];
                    toggleLabel = (id)[cell viewWithTag:2];
                    toggleSwitch = (id)[cell viewWithTag:3];
                    toggleSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:SETTINGS_SKIP_FEE_KEY];
                    toggleLabel.hidden = (toggleSwitch.on) ? NO : YES;
                    break;

                default:
                    NSAssert(FALSE, @"%s:%d %s: unkown indexPath.row %d", __FILE__, __LINE__,  __func__,
                             (int)indexPath.row);
            }

            break;

        case 4:
            cell = [tableView dequeueReusableCellWithIdentifier:restoreIdent];
            break;

        default:
            NSAssert(FALSE, @"%s:%d %s: unkown indexPath.section %d", __FILE__, __LINE__,  __func__,
                     (int)indexPath.section);
    }
    
    [self setBackgroundForCell:cell tableView:tableView indexPath:indexPath];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.selectorController.tableView) return nil;

    switch (section) {
        case 0:
            return nil;

        case 1:
            return nil;
            
        case 2:
            return nil;

        case 3:
            return NSLocalizedString(@"rescan blockchain if you think you may have missing transactions, "
                                     "or are having trouble sending (rescaning can take several minutes)", nil);

        case 4:
            return NSLocalizedString(@"bitcoin network fees are only optional for high priority transactions "
                                     "(removal may cause delays)", nil);

        default:
            NSAssert(FALSE, @"%s:%d %s: unkown section %d", __FILE__, __LINE__,  __func__, (int)section);
    }
    
    return nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.selectorController.tableView) return 44.0;

    switch (indexPath.section) {
        case 0: return (indexPath.row == 0 || indexPath.row < self.transactions.count) ? TRANSACTION_CELL_HEIGHT : 44.0;
        case 1: return 44.0;
        case 2: return 44.0;
        case 3: return 44.0;
        case 4: return 44.0;
        default: NSAssert(FALSE, @"%s:%d %s: unkown section %d", __FILE__, __LINE__,  __func__, (int)indexPath.section);
    }
    
    return 44.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *s = [self tableView:tableView titleForHeaderInSection:section];

    if (s.length == 0) return 22.0;

    CGRect r = [s boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 20.0, CGFLOAT_MAX)
                options:NSStringDrawingUsesLineFragmentOrigin
                attributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:13]} context:nil];
    
    return r.size.height + 22.0 + 10.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                                         [self tableView:tableView heightForHeaderInSection:section])];
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 0.0, v.frame.size.width - 20.0,
                                                           v.frame.size.height - 22.0)];
    
    l.text = [self tableView:tableView titleForHeaderInSection:section];
    l.backgroundColor = [UIColor clearColor];
    l.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    l.textColor = [UIColor grayColor];
    l.shadowColor = [UIColor whiteColor];
    l.shadowOffset = CGSizeMake(0.0, 1.0);
    l.numberOfLines = 0;
    v.backgroundColor = [UIColor clearColor];
    [v addSubview:l];

    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return (section + 1 == [self numberOfSectionsInTableView:tableView]) ? 22.0 : 0.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width,
                                                         [self tableView:tableView heightForFooterInSection:section])];
    v.backgroundColor = [UIColor clearColor];
    return v;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //TODO: include an option to generate a new wallet and sweep old balance if backup may have been compromized
    UIViewController *c = nil;
    UILabel *l = nil;
//    NSUInteger i = 0;
//    UITableViewCell *cell = nil;
    NSMutableAttributedString *s = nil;
    NSMutableArray *a;
    BRWalletManager *m = [BRWalletManager sharedInstance];

    if (tableView == self.selectorController.tableView) {
        self.selectedOption = self.selectorOptions[indexPath.row];
        m.localCurrencyCode = self.selectedOption;

        [tableView reloadData];
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView reloadData];
        return;
    }

    switch (indexPath.section) {
        case 0: // transaction
            if (indexPath.row > 0 && indexPath.row >= self.transactions.count) {
                [tableView beginUpdates];
                self.transactions = [NSArray arrayWithArray:m.wallet.recentTransactions];
                self.moreTx = NO;
                [tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0]]
                 withRowAnimation:UITableViewRowAnimationFade];
                a = [NSMutableArray arrayWithCapacity:self.transactions.count - 5];
                
                for (NSUInteger i = 5; i < self.transactions.count; i++) {
                    [a addObject:[NSIndexPath indexPathForRow:i inSection:0]];
                }
                
                [tableView insertRowsAtIndexPaths:a withRowAnimation:UITableViewRowAnimationTop];
                [tableView endUpdates];
            }
            else if (self.transactions.count > 0) {
                c = [self.storyboard instantiateViewControllerWithIdentifier:@"TxDetailViewController"];
                [(id)c setTransaction:self.transactions[indexPath.row]];
                [(id)c setTxDateString:[self dateForTx:self.transactions[indexPath.row]]];
                [self.navigationController pushViewController:c animated:YES];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }

            break;

        case 1:
            switch (indexPath.row) {
                case 0: // about
                    c = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
                    l = (id)[c.view viewWithTag:411];
                    s = [[NSMutableAttributedString alloc] initWithAttributedString:l.attributedText];
#if BITCOIN_TESTNET
                    [s replaceCharactersInRange:[s.string rangeOfString:@"%net%"] withString:@"%net% (testnet)"];
#endif
                    [s replaceCharactersInRange:[s.string rangeOfString:@"%ver%"]
                     withString:NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"]];
                    [s replaceCharactersInRange:[s.string rangeOfString:@"%net%"] withString:@""];
                    l.attributedText = s;
                    [l.superview.gestureRecognizers.firstObject addTarget:self action:@selector(about:)];
                    
#ifdef DEBUG
                    [(UITextView *)[c.view viewWithTag:412]
                     setText:[[[NSUserDefaults standardUserDefaults] objectForKey:@"debug_backgroundfetch"]
                              description]];
#endif
                    
                    [self.navigationController pushViewController:c animated:YES];
                    break;
                    
                case 1: // backup phrase
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", nil)
                      message:NSLocalizedString(@"\nDO NOT let anyone see your backup phrase or they can spend your "
                                                "bitcoins.\n\nDO NOT take a screenshot. Screenshots are visible to "
                                                "other apps and devices.\n", nil) delegate:self
                      cancelButtonTitle:NSLocalizedString(@"cancel", nil)
                      otherButtonTitles:NSLocalizedString(@"show", nil), nil] show];
                    break;

                default:
                    NSAssert(FALSE, @"%s:%d %s: unkown indexPath.row %d", __FILE__, __LINE__,  __func__,
                             (int)indexPath.row);
            }

            break;

        case 2:
            switch (indexPath.row) {
                case 0: // change pin
                    self.pinNav = [self.storyboard instantiateViewControllerWithIdentifier:@"PINNav"];
                    [self.pinNav.viewControllers.firstObject setCancelable:YES];
                    [self.pinNav.viewControllers.firstObject setChangePin:YES];
                    self.pinNav.transitioningDelegate = self;
                    [self.navigationController presentViewController:self.pinNav animated:YES completion:nil];
                    [self.pinNav.viewControllers.firstObject setAppeared:YES];
                    break;

                case 1: // import private key
                    [self scanQR:nil];
                    break;

                case 2: // rescan blockchain
                    [[BRPeerManager sharedInstance] rescan];
                    [self done:nil];
                    break;

                default:
                    NSAssert(FALSE, @"%s:%d %s: unkown indexPath.row %d", __FILE__, __LINE__,  __func__,
                             (int)indexPath.row);
            }

            break;

        case 3:
            switch (indexPath.row) {
                case 0: // local currency
                    self.selectorOptions = [m.currencyCodes
                                            sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                    self.selectedOption = m.localCurrencyCode;
                    self.selectorController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
                    self.selectorController.transitioningDelegate = self;
                    self.selectorController.tableView.dataSource = self;
                    self.selectorController.tableView.delegate = self;
                    self.selectorController.tableView.backgroundColor = [UIColor clearColor];
                    self.selectorController.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                    self.selectorController.title = NSLocalizedString(@"local currency", nil);
                    [self.navigationController pushViewController:self.selectorController animated:YES];

                    NSUInteger i = [self.selectorOptions indexOfObject:self.selectedOption];

                    if (i != NSNotFound) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.selectorController.tableView
                             scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]
                             atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                        });
                    }

                    break;

                case 1: // remove standard fees
                    break;
            }

            break;

        case 4: // start/restore another wallet (handled by storyboard)
            break;

        default:
            NSAssert(FALSE, @"%s:%d %s: unkown indexPath.section %d", __FILE__, __LINE__,  __func__,
                     (int)indexPath.section);
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
        return;
    }

    self.pinNav = [self.storyboard instantiateViewControllerWithIdentifier:@"PINNav"];
    [self.pinNav.viewControllers.firstObject setAppeared:YES];
    [self.pinNav.viewControllers.firstObject setCancelable:YES];
    self.pinNav.transitioningDelegate = self;
    [self.navigationController presentViewController:self.pinNav animated:YES completion:nil];
}

#pragma mark - UIViewControllerAnimatedTransitioning

// This is used for percent driven interactive transitions, as well as for container controllers that have companion
// animations that might need to synchronize with the main animation.
- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.35;
}

// This method can only be a nop if the transition is interactive and not a percentDriven interactive transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIView *v = transitionContext.containerView;
    UIViewController *to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey],
                     *from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    BOOL pop = (to == self || to == self.navigationController) ? YES : NO;

    if (from == self.pinNav && ! [self.pinNav.viewControllers.firstObject changePin] &&
        [self.pinNav.viewControllers.firstObject success]) {
        [self.navigationController
         pushViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SeedViewController"]
         animated:NO];
        [self.pinNav.viewControllers.firstObject animateTransition:transitionContext];
    }
    else {
        if (self.wallpaper.superview != v) [v insertSubview:self.wallpaper belowSubview:from.view];
        to.view.center = CGPointMake(v.frame.size.width*(pop ? -1 : 3)/2, to.view.center.y);
        [v addSubview:to.view];

        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0.0 usingSpringWithDamping:0.8
        initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            to.view.center = from.view.center;
            from.view.center = CGPointMake(v.frame.size.width*(pop ? 3 : -1)/2, from.view.center.y);
            self.wallpaper.center = CGPointMake(self.wallpaper.frame.size.width/2 -
                                                v.frame.size.width*(pop ? 0 : 1)*PARALAX_RATIO,
                                                self.wallpaper.center.y);
        } completion:^(BOOL finished) {
            if (pop) [from.view removeFromSuperview];
            [transitionContext completeTransition:finished];
        }];
    }
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC
toViewController:(UIViewController *)toVC
{
    return self;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

@end
