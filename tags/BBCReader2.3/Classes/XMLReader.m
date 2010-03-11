//
//  XMLReader.m
//  NYTReader
//
//  Created by Jae Han on 6/21/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "XMLReader.h"
#import "RSSParser.h"
#import "RSSParserState.h"

@implementation XMLReader

- (id)init 
{
	if ((self = [super init])) {
		// class specific initialization
		rssParser = [[RSSParser alloc] init];
	}
	return self;
}

- (void)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error withIndex:(NSInteger)index
{	
	[rssParser setCurrentFeedIndex:index];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:URL];
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
    // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
    }
    
    [parser release];
}

-(void)parseXMLData:(NSData*) data parseError:(NSError**)error withIndex:(NSIndexPath*)indexPath shouldNotify:(BOOL)notify
{
	[rssParser setCurrentFeedIndex:indexPath.section];
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	
	[parser setDelegate:self];
    // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
    }
	else if (notify == YES) {
		[(id)[[UIApplication sharedApplication] delegate] performSelectorOnMainThread:@selector(addNewArticle:) withObject:nil	waitUntilDone:YES];
	}
    
    [parser release];
	
}

// TODO: Construct event handler so that it can push the data to UITableView.
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	//NSLog(@"didStartElement: %@", elementName);
	
	[rssParser setParserAtElementName:elementName];
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{    
	//NSLog(@"didEndElement: %@", elementName);
	
	[rssParser endElement:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	//NSLog(@"foundCharacters: %@", string);
	
	[rssParser addCharactersInText:string];
}

@end
