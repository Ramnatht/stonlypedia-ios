//
//  ViewController.m
//  Wikipedia-iOS
//
//  Created by Brion on 10/27/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
//

#import "ViewController.h"

#import "CommunicationBridge.h"

@interface ViewController ()

@end

@implementation ViewController {
    CommunicationBridge *bridge;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    bridge = [[CommunicationBridge alloc] initWithWebView:self.webView];
    [bridge addListener:@"DOMLoaded" withBlock:^(NSString *messageType, NSDictionary *payload) {
        NSLog(@"QQQ HEY DOMLoaded!");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self navigateToPage:textField.text];
    [textField resignFirstResponder];
    return NO;
}

#pragma mark action methods

- (IBAction)backButtonPushed:(id)sender {
    [self.webView goBack];
}

- (IBAction)forwardButtonPushed:(id)sender {
    [self.webView goForward];
}

- (IBAction)languageButtonPushed:(id)sender {
}

- (IBAction)actionButtonPushed:(id)sender {
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]
                                                        initWithActivityItems:@[self.webView.request.URL]
                                                        applicationActivities:@[]];
    [self presentViewController:activityViewController animated:YES completion:^{
        // Whee!
    }];
}

- (IBAction)bookmarkButtonPushed:(id)sender {
}

- (IBAction)menuButtonPushed:(id)sender {
}

#pragma mark local methods

/**
 * this is a temporary hack for demo!
 */
- (void)navigateToPage:(NSString *)pageTitle
{
    NSString *underscoreForm = [pageTitle stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *encTitle = [underscoreForm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    // First we need the base URL
    NSString *baseUrlStr = [NSString stringWithFormat:@"https://en.m.wikipedia.org/wiki/%@", encTitle];
    NSURL *baseUrl = [NSURL URLWithString:baseUrlStr];

    // Now we need to fetch from API
    NSString *apiUrlStr = [NSString stringWithFormat:@"https://en.m.wikipedia.org/w/api.php?format=json&action=mobileview&page=%@&prop=sections%%7Ctext&sections=all", encTitle];
    NSURL *apiUrl = [NSURL URLWithString:apiUrlStr];
    NSURLRequest *apiReq = [NSURLRequest requestWithURL:apiUrl];
    
    [NSURLConnection sendAsynchronousRequest:apiReq queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

        if (connectionError) {
            NSLog(@"Failed to fetch page data: %@", connectionError);
            exit(1);
        }

        NSError *err;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (err) {
            NSLog(@"Failed to decode JSON: %@", err);
            exit(1);
        }

        NSMutableString *str = [[NSMutableString alloc] init];
        for (NSDictionary *section in dict[@"mobileview"][@"sections"]) {
            [str appendString:section[@"text"]];
        }
        NSString *htmlStr = [NSString stringWithString:str];

        //[self.webView loadHTMLString:htmlStr baseURL:baseUrl];
        [bridge sendMessage:@"displayLeadSection" withPayload:@{@"leadSectionHTML": htmlStr}];
    }];
    
}
@end
