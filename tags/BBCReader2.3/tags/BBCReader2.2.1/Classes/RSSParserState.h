//
//  RSSParserState.h
//  NYTReader
//
//  Created by Jae Han on 6/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSSParser;
@class RSSParserState;
@class RSSTitleState;
@class RSSLinkState;
@class RSSGUIDState;
@class WebLink;

//static RSSParserState *singletonParserState=nil;

@interface RSSParserState : NSObject {
	//NSString *text;
	//WebLink *currentLink;
	
	@protected
	RSSParser* parserDelegate;
	//RSSParserState *state;
	NSMutableString *text;
	BOOL elementEnded;
}

//@property (nonatomic, retain) NSString* text;
//@property (nonatomic, retain) WebLink* currentLink;

+(RSSParserState*) getInstance:(RSSParser*)delegate;
//-(void) setParseAtElementName:(NSString*)name;
-(void) addCharactersInText:(NSString*)string;
-(id) initWithDelegate:(RSSParser*)delegate;
-(BOOL) startElement;
-(void) endElement:(NSString*)name;

@end

@interface RSSChannelState : RSSParserState {
}

@end

@interface RSSTitleState : RSSParserState {
}

@end


@interface RSSLinkState : RSSParserState {
}


@end


@interface RSSGUIDState : RSSParserState {
}

@end

@interface RSSDescriptionState : RSSParserState {
}

@end

@interface RSSBuildDateState : RSSParserState {

}

@end

@interface RSSTTLState : RSSParserState {
}


@end




