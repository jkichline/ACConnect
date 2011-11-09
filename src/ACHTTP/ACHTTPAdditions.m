//
//  ACHTTPAdditions.m
//  ACConnect
//
//  Created by Jason Kichline on 9/3/11.
//  Copyright (c) 2011 andCulture. All rights reserved.
//

#import "ACHTTPAdditions.h"

@implementation NSString (ACHTTPAdditions)

-(NSString*)xmlString {
	NSString* copy = self;
	copy = [copy stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
	copy = [copy stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
	copy = [copy stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
	copy = [copy stringByReplacingOccurrencesOfString:@"<" withString:@"lt;"];
    return copy;
}

@end

@implementation NSNumber (ACHTTPAdditions)

-(NSString*)xmlString {
	return [self stringValue];
}

@end

@implementation NSDate (ACHTTPAdditions)

-(NSString*)xmlString {
	static NSDateFormatter* df = nil;
	if(df == nil) {
		df = [[NSDateFormatter alloc] init];
		df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
	}
	return [df stringFromDate:self];
}

@end

@implementation NSDictionary (ACHTTPAdditions)

-(NSString*)xmlDocument {
	if([self allKeys].count > 0) {
		id key = [[self allKeys] objectAtIndex:0];
		return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n%@", [[NSDictionary dictionaryWithObject:[self objectForKey:key] forKey:key] xmlString]];
	}
	return nil;
}

-(NSString*)xmlString {
	NSMutableString* o = [NSMutableString string];
	for(id key in [(NSDictionary*)self allKeys]) {
		[o appendFormat:@"<%@>%@</%@>", 
		 [[NSString stringWithFormat:@"%@", key] xmlString], 
		 [[(NSDictionary*)self objectForKey:key] xmlString], 
		 [[NSString stringWithFormat:@"%@", key] xmlString]];
	}
	return o;
}

@end

@implementation NSArray (ACHTTPAdditions)

-(NSString*)xmlString {
	NSMutableString* o = [NSMutableString string];
	for(id value in self) {
		[o appendFormat:@"<Item>%@</Item>", [value xmlString]];
	}
	return o;
}

@end

@implementation NSData (ACHTTPAdditions)

-(NSString*)xmlString {
	//Point to start of the data and set buffer sizes
	int inLength = [self length];
	int outLength = ((((inLength * 4)/3)/4)*4) + (((inLength * 4)/3)%4 ? 4 : 0);
	const char *inputBuffer = [self bytes];
	char *outputBuffer = malloc(outLength);
	outputBuffer[outLength] = 0;
	
	//64 digit code
	static char Encode[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	
	//start the count
	int cycle = 0;
	int inpos = 0;
	int outpos = 0;
	char temp;
	
	//Pad the last to bytes, the outbuffer must always be a multiple of 4
	outputBuffer[outLength-1] = '=';
	outputBuffer[outLength-2] = '=';
	
	while (inpos < inLength){
		switch (cycle) {
			case 0:
				outputBuffer[outpos++] = Encode[(inputBuffer[inpos]&0xFC)>>2];
				cycle = 1;
				break;
			case 1:
				temp = (inputBuffer[inpos++]&0x03)<<4;
				outputBuffer[outpos] = Encode[temp];
				cycle = 2;
				break;
			case 2:
				outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xF0)>> 4];
				temp = (inputBuffer[inpos++]&0x0F)<<2;
				outputBuffer[outpos] = Encode[temp];
				cycle = 3;                  
				break;
			case 3:
				outputBuffer[outpos++] = Encode[temp|(inputBuffer[inpos]&0xC0)>>6];
				cycle = 4;
				break;
			case 4:
				outputBuffer[outpos++] = Encode[inputBuffer[inpos++]&0x3f];
				cycle = 0;
				break;                          
			default:
				cycle = 0;
				break;
		}
	}
	NSString *o = [NSString stringWithUTF8String:outputBuffer];
	free(outputBuffer); 
	return o;
}

@end
