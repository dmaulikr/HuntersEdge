//
//  HEWallPostCreateViewController.m
//  Hunter's Edge
//
//  Created by James Forkey on 1/31/12.
//  Copyright (c) 2013 HF Development. All rights reserved.
//

#import "HEWallPostCreateViewController.h"

#import "HEAppDelegate.h"
#import <Parse/Parse.h>

@interface HEWallPostCreateViewController ()

- (void)updateCharacterCount:(UITextView *)aTextView;
- (BOOL)checkCharacterCount:(UITextView *)aTextView;
- (void)textInputChanged:(NSNotification *)note;

@end

@implementation HEWallPostCreateViewController

@synthesize textView;
@synthesize characterCount;
@synthesize postButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	// Do any additional setup after loading the view from its nib.
	
	self.characterCount = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 154.0f, 21.0f)];
	self.characterCount.backgroundColor = [UIColor clearColor];
	self.characterCount.textColor = [UIColor whiteColor];
	self.characterCount.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.7f];
	self.characterCount.shadowOffset = CGSizeMake(0.0f, -1.0f);
	self.characterCount.text = @"0/140";

	[self.textView setInputAccessoryView:self.characterCount];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextViewTextDidChangeNotification object:textView];
	[self updateCharacterCount:textView];
	[self checkCharacterCount:textView];

	// Show the keyboard/accept input.
	[textView becomeFirstResponder];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:textView];
}

#pragma mark UINavigationBar-based actions

- (IBAction)cancelPost:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
//	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)postPost:(id)sender {
	// Resign first responder to dismiss the keyboard and capture in-flight autocorrect suggestions
	[textView resignFirstResponder];

	// Capture current text field contents:
	[self updateCharacterCount:textView];
	BOOL isAcceptableAfterAutocorrect = [self checkCharacterCount:textView];

	if (!isAcceptableAfterAutocorrect) {
		[textView becomeFirstResponder];
		return;
	}

	// Data prep:
	
	HEAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	CLLocationCoordinate2D currentCoordinate = appDelegate.pinDropLocation.coordinate;
	PFGeoPoint *currentPoint = [PFGeoPoint geoPointWithLatitude:currentCoordinate.latitude longitude:currentCoordinate.longitude];
	PFUser *user = [PFUser currentUser];

	// Stitch together a postObject and send this async to Parse
	PFObject *postObject = [PFObject objectWithClassName:kHEParsePostsClassKey];
	[postObject setObject:textView.text forKey:kHEParseTextKey];
	[postObject setObject:user forKey:kHEParseUserKey];
	[postObject setObject:currentPoint forKey:kHEParseLocationKey];
	// Use PFACL to restrict future modifications to this object.
	PFACL *readOnlyACL = [PFACL ACL];
	[readOnlyACL setPublicReadAccess:YES];
	[readOnlyACL setPublicWriteAccess:NO];
	[postObject setACL:readOnlyACL];
	[postObject saveEventually:^(BOOL succeeded, NSError *error) {
		if (error) {
			NSLog(@"Couldn't save!");
			NSLog(@"%@", error);
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			[alertView show];
			return;
		}
		if (succeeded) {
			NSLog(@"Successfully saved!");
			NSLog(@"%@", postObject);
			dispatch_async(dispatch_get_main_queue(), ^{
				[[NSNotificationCenter defaultCenter] postNotificationName:kHEPostCreatedNotification object:nil];
			});
		} else {
			NSLog(@"Failed to save.");
		}
	}];
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITextView notification methods

- (void)textInputChanged:(NSNotification *)note {
	// Listen to the current text field and count characters.
	UITextView *localTextView = [note object];
	[self updateCharacterCount:localTextView];
	[self checkCharacterCount:localTextView];
}

#pragma mark Private helper methods

- (void)updateCharacterCount:(UITextView *)aTextView {
	NSUInteger count = aTextView.text.length;
	self.characterCount.text = [NSString stringWithFormat:@"%i/140", count];
	if (count > kHEWallPostMaximumCharacterCount || count == 0) {
		self.characterCount.font = [UIFont boldSystemFontOfSize:self.characterCount.font.pointSize];
	} else {
		self.characterCount.font = [UIFont systemFontOfSize:self.characterCount.font.pointSize];
	}
}

- (BOOL)checkCharacterCount:(UITextView *)aTextView {
	NSUInteger count = aTextView.text.length;
	if (count > kHEWallPostMaximumCharacterCount || count == 0) {
		postButton.enabled = NO;
		return NO;
	} else {
		postButton.enabled = YES;
		return YES;
	}
}

@end
