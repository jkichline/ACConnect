//
//  ACOAuthLoginScreen.m
//  ACOAuth
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 andCulture. All rights reserved.
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
	
	// Authorize if we haven't yet
	[self authorize];
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
//	[webView sizeToFit];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark Toolbar Methods

-(void)close {
	[self dismissModalViewControllerAnimated:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Load the Authorization

-(BOOL)authorize {
	
	// Validate that we can authorize
	if(self.configuration == nil || self.configuration.authorizationURL == nil || self.configuration.token == nil) {
		return NO;
	}
	
	// Create a new URL
	NSMutableString* url = [NSMutableString stringWithString:[self.configuration.authorizationURL absoluteString]];
	
	// Append to the query string
	if([url rangeOfString:@"?"].length > 0) {
		[url appendString:@"&"];
	} else {
		[url appendString:@"?"];
	}
	[url appendFormat:@"oauth_token=%@&oauth_callback=%@", [ACOAuthUtility webEncode:self.configuration.token], [ACOAuthUtility webEncode:@"close:"]];
	
	// Load the request
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
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
	return YES;
}

-(void)webViewDidStartLoad:(UIWebView*)webView {
	[spinner startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView*)webView {
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
