//
//  ParserHandler.h
//  NYTReader
//
//  Created by Jae Han on 7/30/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTMLParser;

@interface ParserHandler : NSObject {
	int currentLevel;
	@protected
	HTMLParser *theParser;
}

@property (nonatomic) int currentLevel;

- (id)initWithParser:(HTMLParser*)parser;
- (void)OnElementAction:(int)level;
- (void)OnFilterAction:(NSString*)local byURL:(NSString*)url;
- (void)OnPageAction;

@end

@interface TitleElementHandler : ParserHandler {
}

@end


@interface ImgElementHandler : ParserHandler {
}

@end

@interface TDElementHandler : ParserHandler {
}

@end

@interface TableEndElementHandler : ParserHandler {
}

@end

@interface LinkElementHandler : ParserHandler {
}


@end


@interface ScriptElementHandler : ParserHandler {
}

@end


@interface StyleElementHandler : ParserHandler {
}

@end

@interface DivElementHandler : ParserHandler {
}

@end

@interface IFrameElementHandler : ParserHandler {
}

@end

@interface AnchorHrefHandler : ParserHandler
{

}


@end

@interface AnchorElementHandler : ParserHandler {
}

@end


@interface FormElementHandler : ParserHandler {
}

- (void)actionTypeHandler:(int)level;

@end


@interface HrefAttrHandler : ParserHandler {
}

@end


@interface SrcAttrHandler : ParserHandler {
}

@end


@interface TypeAttrHandler : ParserHandler {
}

@end

@interface StyleImportHandler : ParserHandler {
}

@end

@interface CssUrlHandler : ParserHandler {
}

@end

@interface DivStyleAttrHandler : ParserHandler {
}

@end

@interface ClassAttrHandler : ParserHandler {
}

@end

@interface DivEndElementHandler : ParserHandler {
}

@end

@interface AnchorEndElementHandler : ParserHandler {

}

@end

@interface MetaElementHandler : ParserHandler {
}

@end

@interface MetaNameAttrHandler : ParserHandler {
}


@end

@interface MetaContentAttrHandler : ParserHandler {
}


@end


