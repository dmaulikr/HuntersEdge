//
//  HELoginViewController.m
//  Hunter's Edge
//
//  Created by James Forkey on 2/1/12.
//  Copyright (c) 2013 HF Development. All rights reserved.
//

#import "HELoginViewController.h"

#import "HEAppDelegate.h"
#import <Parse/Parse.h>
#import "HEActivityView.h"
#import "HEWallViewController.h"

@interface HELoginViewController ()

- (void)processFieldEntries;
- (void)textInputChanged:(NSNotification *)note;
- (BOOL)shouldEnableDoneButton;

@end

@implementation HELoginViewController

@synthesize doneButton;
@synthesize facebookButton;
@synthesize usernameField;
@synthesize passwordField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:usernameField];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputChanged:) name:UITextFieldTextDidChangeNotification object:passwordField];

	doneButton.enabled = NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
	[usernameField becomeFirstResponder];
	[super viewWillAppear:animated];
}

-  (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:usernameField];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:passwordField];
}

#pragma mark - IBActions

- (IBAction)cancel:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];

	[self processFieldEntries];
}

#pragma mark - UITextField text field change notifications and helper methods

- (BOOL)shouldEnableDoneButton {
	BOOL enableDoneButton = NO;
	if (usernameField.text != nil &&
		usernameField.text.length > 0 &&
		passwordField.text != nil &&
		passwordField.text.length > 0) {
		enableDoneButton = YES;
	}
	return enableDoneButton;
}

- (void)textInputChanged:(NSNotification *)note {
	doneButton.enabled = [self shouldEnableDoneButton];
}

#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == usernameField) {
		[passwordField becomeFirstResponder];
	}
	if (textField == passwordField) {
		[passwordField resignFirstResponder];
		[self processFieldEntries];
	}

	return YES;
}

// the following two functions are responsible for making sure the keyboard
// disappears if the background is touched
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self.view endEditing:YES];
}

- (IBAction)backgroundTouch:(id)sender {
	[usernameField resignFirstResponder];
	[passwordField resignFirstResponder];
}

#pragma mark - Private methods:

#pragma mark Field validation

- (void)processFieldEntries {
	// Get the username text, store it in the app delegate for now
	NSString *username = usernameField.text;
	NSString *password = passwordField.text;
	NSString *noUsernameText = @"username";
	NSString *noPasswordText = @"password";
	NSString *errorText = @"No ";
	NSString *errorTextJoin = @" or ";
	NSString *errorTextEnding = @" entered";
	BOOL textError = NO;

	// Messaging nil will return 0, so these checks implicitly check for nil text.
	if (username.length == 0 || password.length == 0) {
		textError = YES;

		// Set up the keyboard for the first field missing input:
		if (password.length == 0) {
			[passwordField becomeFirstResponder];
		}
		if (username.length == 0) {
			[usernameField becomeFirstResponder];
		}
	}

	if (username.length == 0) {
		textError = YES;
		errorText = [errorText stringByAppendingString:noUsernameText];
	}

	if (password.length == 0) {
		textError = YES;
		if (username.length == 0) {
			errorText = [errorText stringByAppendingString:errorTextJoin];
		}
		errorText = [errorText stringByAppendingString:noPasswordText];
	}

	if (textError) {
		errorText = [errorText stringByAppendingString:errorTextEnding];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorText message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
		[alertView show];
		return;
	}

	// Everything looks good; try to log in.
	// Disable the done button for now.
	doneButton.enabled = NO;

	HEActivityView *activityView = [[HEActivityView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.view.frame.size.width, self.view.frame.size.height)];
	UILabel *label = activityView.label;
	label.text = @"Logging in";
	label.font = [UIFont boldSystemFontOfSize:20.f];
	[activityView.activityIndicator startAnimating];
	[activityView layoutSubviews];

	[self.view addSubview:activityView];

	[PFUser logInWithUsernameInBackground:username password:password block:^(PFUser *user, NSError *error) {
		// Tear down the activity view in all cases.
		[activityView.activityIndicator stopAnimating];
		[activityView removeFromSuperview];

		if (user) {
			HEWallViewController *wallViewController = [[HEWallViewController alloc] initWithNibName:nil bundle:nil];
			[(UINavigationController *)self.presentingViewController pushViewController:wallViewController animated:NO];
			[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
			
			// associate user with facebook account
			if (![PFFacebookUtils isLinkedWithUser:user]) {
				[PFFacebookUtils linkUser:user permissions:nil block:^(BOOL succeeded, NSError *error) {
					if (succeeded) {
						NSLog(@"Woohoo, user logged in with Facebook!");
					}
				}];
			}
			
		} else {
			// Didn't get a user.
			NSLog(@"%s didn't get a user!", __PRETTY_FUNCTION__);

			// Re-enable the done button if we're tossing them back into the form.
			doneButton.enabled = [self shouldEnableDoneButton];
			UIAlertView *alertView = nil;

			if (error == nil) {
				// the username or password is probably wrong.
				alertView = [[UIAlertView alloc] initWithTitle:@"Couldn’t log in:\nThe username or password were wrong." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			} else {
				// Something else went horribly wrong:
				alertView = [[UIAlertView alloc] initWithTitle:[[error userInfo] objectForKey:@"error"] message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
			}
			[alertView show];
			// Bring the keyboard back up, because they'll probably need to change something.
			[usernameField becomeFirstResponder];
		}
	}];
}

- (IBAction)signInWithFacebook:(id)sender {
	@synchronized(self) {
		NSArray *permissionsArray = [NSArray arrayWithObjects:@"user_about_me", @"user_location", @"offline_access", nil];
		
		[PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error){
			//Logged in successfully
			// Tear down the activity view in all cases.
			HELoginViewController *wallViewController = [[HELoginViewController alloc] initWithNibName:nil bundle:nil];
			[(UINavigationController *)self.presentingViewController pushViewController:wallViewController animated:NO];
			[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
		 }];
	}
}

@end
