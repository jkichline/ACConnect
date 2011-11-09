//
//  ACOAuthLoginScreen.m
//  ACOAuth
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 Jason Kichline. All rights reserved.
//

#import "ACOAuthLoginScreen.h"
#import "ACOAuthUtility.h"
#import "ACOAuthSession.h"

@implementation ACOAuthLoginScreen

@synthesize configuration;

#pragma mark -
#pragma mark Initialization

-(id)initWithConfiguration:(ACOAuthConfiguration*)_configuration {
	self = [self init];
	if(self) {
		self.configuration = _configuration;
	}
	return self;
}

#pragma mark -
#pragma mark Properties

-(void)setConfiguration:(ACOAuthConfiguration *)value {
	if(value != configuration) {
		[value retain];
		[configuration release];
		configuration = value;
	}
	if(webView != nil) {
		[self authorize];
	}
}

#pragma mark -
#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Create an activity spinner
	UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleWhite;
	UIColor* color = self.navigationController.navigationBar.tintColor;
	if(color == nil) {
		if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
			style = UIActivityIndicatorViewStyleGray;
		}
	}
	
	spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
	
	// Setup navigation
	self.navigationItem.title = NSLocalizedString(@"Authorizing", @"");
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(close)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:spinner] autorelease];

	// Add the web view
	CGRect r = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	webView = [[UIWebView alloc] initWithFrame:r];
	webView.delegate = self;
	webView.scalesPageToFit = YES;
	webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:webView];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self authorize];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Toolbar Methods

-(void)close {
	if(self.navigationController) {
		[self.navigationController popViewControllerAnimated:YES];
	} else {
		[self dismissModalViewControllerAnimated:YES];
	}
}

#pragma mark -
#pragma mark Load the Authorization

-(BOOL)authorize {
	
	// Validate that we can authorize
	if(self.configuration == nil || self.configuration.authorizationURL == nil || self.configuration.token == nil) {
		return NO;
	}
	
	// Create a new URL
	NSString* qs = [NSString stringWithFormat:@"oauth_token=%@&oauth_callback=%@", [ACOAuthUtility webEncode:self.configuration.token], [ACOAuthUtility webEncode:@"close:"]];
	NSURL* url = self.configuration.authorizationURL;
	if(![self.configuration.authorizationMethod isEqualToString:@"POST"]) {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@", self.configuration.authorizationURL.absoluteString, ([self.configuration.authorizationURL.absoluteString rangeOfString:@"?"].length > 0) ? @"&" : @"?", qs]];
	}
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	if([self.configuration.authorizationMethod isEqualToString:@"POST"]) {
		request.HTTPBody = [qs dataUsingEncoding:NSUTF8StringEncoding];
	}
	
	// Load the request
	NSLog(@"Authorize URL: %@", url);
	[webView loadRequest:request];
	return YES;
}

#pragma mark -
#pragma mark Web View Delegate Methods

-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	NSDictionary* parameters = [ACOAuthUtility dictionaryFromQueryString:[[request URL] query]];
	if([parameters objectForKey:@"oauth_verifier"] != nil) {
		self.configuration.verifier = [parameters objectForKey:@"oauth_verifier"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ACOAuthSessionAuthorizationVerified object:self userInfo:[NSDictionary dictionaryWithObject:self.configuration forKey:@"configuration"]];
		[self close];
	}
	if([[parameters objectForKey:@"close"] boolValue] || [request.URL.absoluteString hasPrefix:@"close:"]) {
		[self close];
	}
	return YES;
}

-(void)webViewDidStartLoad:(UIWebView*)webView {
	[spinner startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView*)wv {
	NSMutableString* js = [NSMutableString string];
	if(configuration.css != nil) {
		[js appendFormat:@"var head = document.getElementsByTagName('head')[0]; var style = document.createElement('style'); var rules = document.createTextNode('%@'); style.type = 'text/css'; if(style.styleSheet) { style.styleSheet.cssText = rules.nodeValue; } else { style.appendChild(rules); } head.appendChild(style);", configuration.css];
	}
	if(configuration.javascript != nil) {
		[js appendString:configuration.javascript];
	}
	if(js.length > 0) {
		[wv stringByEvaluatingJavaScriptFromString:js];
	}
	[spinner stopAnimating];
}

-(void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
	NSLog(@"ACOAuthLoginScreen Error: %@", error);
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
	spinner = nil;
	webView = nil;
}

- (void)dealloc {
	[spinner release];
	[webView release];
    [super dealloc];
}

@end
