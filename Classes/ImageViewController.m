//
//  FirstViewController.m
//  NYTReader
//
//  Created by Jae Han on 6/19/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//
#include "MReader_Defs.h"
#import "ImageViewController.h"
#import "ArticleStorage.h"
#import "WebLink.h"
#import "ArticleImageView.h"

/*
#define BLOCK_SIZE	1024
static NSMutableData *fileBuffer = nil;
static unsigned char temp_file_storage[BLOCK_SIZE];

NSMutableData *getImageFileBuffer()
{
	if (fileBuffer == nil) {
		fileBuffer = [[NSMutableData alloc]initWithCapacity:BLOCK_SIZE];
	}
	
	return fileBuffer;
}

(NSData*)readFromFile(NSString* file)
{
	int fd = open([file UTF8String], O_RDONLY);
	if (fd == -1) {
		NSLog(@"%s: %@, %s", __func__, file, strerror(errno));
		return nil;
	}
	
	int size = 0;
	int totalLength = 0;
	//NSMutableData *data = [[NSMutableData alloc] initWithCapacity:BLOCK_SIZE];
	NSMutableData *data = getImageFileBuffer();
	[data setLength:0];
	
	do {
		size = read(fd, temp_file_storage, BLOCK_SIZE);
		if (size > 0) {
			[data appendBytes:temp_file_storage length:size];
		}
		else if (size < 0) {
			NSLog(@"%s: %@, %s", __func__, file, strerror(errno));
			//[data release];
			close(fd);
			return nil;
		}
		totalLength += size;
	} while (size > 0);
	
	close(fd);
	return data;
}
*/

@implementation ImageViewController

@synthesize webLink;
@synthesize articleImageView;
@synthesize articleTitle;
@synthesize articleDescription;

- (id)initWithNibName:(NSString *)nibNameOrNil withPage:(NSInteger)page {
	if (self = [super initWithNibName:nibNameOrNil bundle:nil]) {
		// Initialization code
		pageNum = page;
		webLink = nil;
	}
	return self;
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
 - (void)loadView {
 }
 */

- (void)viewDidLoad 
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getArticleAtPage:pageNum];
	webLink = link;
	if (link != nil) {
		NSData *data = [[NSData alloc] initWithContentsOfFile:link.imageLink];
		UIImage *image = [[UIImage alloc] initWithData:data];
		articleImageView.image = image;
		articleDescription.text = link.description;
		articleDescription.font = [UIFont systemFontOfSize:15.0];
		articleDescription.textColor = [UIColor whiteColor]; 
		articleTitle.text = link.text;
		[image release];
		[data release];
		//[articleImageView addSubview:image];
	}
}

- (void)reDrawWithPage:(NSInteger)page
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getArticleAtPage:page];
	webLink = link;
	pageNum = page;
	if (link != nil) {
		NSData *data = [[NSData alloc] initWithContentsOfFile:link.imageLink];
		UIImage *image = [[UIImage alloc] initWithData:data];
		
		articleImageView.image = image;
		articleDescription.text = link.description;
		//articleDescription.font = [UIFont systemFontOfSize:15.0];
		//articleDescription.textColor = [UIColor whiteColor]; 
		articleTitle.text = link.text;
		[image release];
		[data release];
		//[articleImageView addSubview:image];
		//TRACE("%s, %s\n", __func__, [link.text UTF8String]);
		//[self.view drawRect:self.view.frame];
	}
	
}

- (void)showPrevImage
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getPrevArticle];
	if (link != nil) {
		//UIImage *image = [[UIImage alloc] initWithContentsOfFile:link.imageLink];
		NSData *data = [[NSData alloc] initWithContentsOfFile:link.imageLink];
		UIImage *image = [[UIImage alloc] initWithData:data];
		
		//if (articleImageView.image != nil)
		//	[articleImageView.image release];
		articleImageView.image = image;
		articleDescription.text = link.description;
		//articleDescription.font = [UIFont systemFontOfSize:15.0];
		//articleDescription.textColor = [UIColor whiteColor]; 
		articleTitle.text = link.text;
		[image release];
		[data release];
		//[articleImageView addSubview:image];
	}
}

- (void)showNextImage
{
	ArticleStorage *storage = [ArticleStorage sharedArticleStorageInstance];
	
	WebLink *link = [storage getNextArticle];
	webLink = link;
	if (link != nil) {
		//UIImage *image = [[UIImage alloc] initWithContentsOfFile:link.imageLink];
		NSData *data = [[NSData alloc] initWithContentsOfFile:link.imageLink];
		UIImage *image = [[UIImage alloc] initWithData:data];
		
		//if (articleImageView.image != nil) {
		//	prev = articleImageView.image;
		//}
		articleImageView.image = image;
		articleDescription.text = link.description;
		//articleDescription.font = [UIFont systemFontOfSize:15.0];
		//articleDescription.textColor = [UIColor whiteColor]; 
		articleTitle.text = link.text;
		[image release];
		[data release];
		//[articleImageView addSubview:image];
	}
}

- (void)showNextImage:(NSTimer*)timer
{
	[self showNextImage];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	NSLog(@"%s", __func__);
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)viewDidUnload
{
	TRACE("%s\n", __func__);
	self.articleTitle = nil;
	self.articleDescription = nil;
	self.articleImageView = nil;
	
}

- (void)dealloc {
	//TRACE("%s, %d\n", __func__, [articleImageView.image retainCount]);
	
	[articleTitle release];
	[articleDescription release];
	[articleImageView release];
	
	[super dealloc];
}

@end
