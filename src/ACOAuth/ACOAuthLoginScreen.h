//
//  ACOAuthLoginScreen.h
//  ACOAuth
//
//  Created by Jason Kichline on 7/29/11.
//  Copyright 2011 andCulture. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACOAuthConfiguration.h"

@interface ACOAuthLoginScreen : UIViewController <UIWebViewDelegate> {
	UIWebView* webView;
	UIActivityIndicatorView* spinner;
	ACOAuthConfiguration* configuration;
}

@property (nonatomic, retain) ACOAuthConfiguration* configuration;

-(void)close;
-(BOOL)authorize;
-(id)initWithConfiguration:(ACOAuthConfiguration*)configuration;

@end
