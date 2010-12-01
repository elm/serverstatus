//
//  AutostartManager.m
//  ServerStatus
//
//  Created by Florian Mutter on 01.12.10.
//  Copyright 2010 skweez.net. All rights reserved.
//

#import "AutostartManager.h"
#import "SynthesizeSingleton.h"


@implementation AutostartManager
SYNTHESIZE_SINGLETON_FOR_CLASS(AutostartManager)


#pragma mark -
#pragma mark Public
- (NSInteger)isStartingAtLogin {
	return [self getApplicationsLoginItem] != NULL;
}

- (void)startAtLogin:(BOOL)enabled {
	/* Get list of users login items */
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
	
	LSSharedFileListItemRef itemRef = [self getApplicationsLoginItem];
	
	if (enabled && itemRef == NULL) {
		/* Add App to login item list with icon */
		
		NSURL *url = [[NSBundle mainBundle] bundleURL];
		
		IconRef icon = [[NSApp applicationIconImage] iconRefRepresentation];
		
		LSSharedFileListInsertItemURL(loginItems,
									  kLSSharedFileListItemLast,
									  NULL /*displayName*/,
									  icon,
									  url,
									  NULL /*propertiesToSet*/, 
									  NULL /*propertiesToClear*/);
	} else if (!enabled && itemRef != NULL) {
		/* Remove App from login item list */
		LSSharedFileListItemRemove(loginItems, itemRef);
	}
}


#pragma mark -
#pragma mark Private
- (LSSharedFileListItemRef)getApplicationsLoginItem {
	/* Get url to app bundle */
	NSURL *url = [[NSBundle mainBundle] bundleURL];
	
	/* Get list of users login items */
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
	
	if ( !loginItems ) {
		DLog(@"Could not retrieve loginItems.");
		return;
	}
	
	LSSharedFileListItemRef existingItem = NULL;
	UInt32 seedValue;
	/* Search for the login itme to delete it from the list */
	NSArray  *loginItemsArray = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seedValue)) autorelease];
	for(id itemObject in loginItemsArray){
		LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)itemObject;
		
		UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
		CFURLRef itemUrl = NULL;
		/* Resolve the item with URL */
		if (LSSharedFileListItemResolve(itemRef, resolutionFlags, &itemUrl, NULL) == noErr) {
			if ( CFEqual(url, itemUrl) ) {
				existingItem = itemRef;
			}
		}
		CFRelease(itemUrl);
		
	}

	return existingItem;
}

- (void)registerForLogin:(id)sender {
	/* Get url to app bundle */
	NSURL *url = [[NSBundle mainBundle] bundleURL];
	
	/* Get list of users login items */
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL,kLSSharedFileListSessionLoginItems, NULL);
	
	if ( !loginItems ) {
		DLog(@"Could not retrieve loginItems.");
		return;
	}
	
	if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"startAtLogin"] ) {
		
		/* Add app to login items list */
		LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
		
	} else {
		
		UInt32 seedValue;
        /* Search for the login itme to delete it from the list */
		NSArray  *loginItemsArray = (NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
		CFURLRef itemUrl = NULL;
		int i = 0;
		for(i; i < [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (LSSharedFileListItemRef)[loginItemsArray
																		objectAtIndex:i];
			/* Resolve the item with URL */
			if (LSSharedFileListItemResolve(itemRef, 0, &itemUrl, NULL) == noErr) {
				if ( [url isEqual:itemUrl] ) {
					LSSharedFileListItemRemove(loginItems, itemRef);
				}
			}
			CFRelease(itemUrl);
			
		}
		[loginItemsArray release];
		
	}
	CFRelease(loginItems);
	
}

@end