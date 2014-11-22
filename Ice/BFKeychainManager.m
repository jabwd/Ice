//
//  BFKeychainManager.m
//  BlackFire
//
//  Created by Mark Douma
//

#import "BFKeychainManager.h"
#import <Security/Security.h>

static BFKeychainManager *sharedManager = nil;
@implementation BFKeychainManager
+ (BFKeychainManager *)defaultManager {
	if (sharedManager == nil) {
		sharedManager = [[self alloc] init]; // assignment not done here;
	}
	return sharedManager;
}


+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (sharedManager == nil) {
			sharedManager = [super allocWithZone:zone];
			return sharedManager;	// assignment and return on first allocation
		}
	}
	return nil; //on subsequent allocation attempts return nil
}

- (void)dealloc
{
	sharedManager = nil;
	[super dealloc];
}


- (NSString *)passwordForServiceName:(NSString *)aServiceName accountName:(NSString *)anAccountName {
	OSStatus status = noErr;
	
	NSString *password = nil;
	
	void *passwordData = NULL;
	
	UInt32 passwordLength = 0;
	
	status = SecKeychainFindGenericPassword(NULL, (UInt32)strlen([aServiceName UTF8String]), [aServiceName UTF8String], (UInt32)strlen([anAccountName UTF8String]), [anAccountName UTF8String], &passwordLength, &passwordData, NULL);
	
	if (status == noErr) {
		password = [[NSString alloc] initWithBytes:(const void*)passwordData length:passwordLength encoding:NSUTF8StringEncoding];
		
		if (password) {
			//NSLog(@"[MDKeychain passwordForServiceName:accountName:] password == %@", password);
		}
		
		//status = SecKeychainItemFreeContent(NULL, passwordData);
		SecKeychainItemFreeContent(NULL, passwordData);
		
	} else if (status == errSecItemNotFound) {
		//	NSLog(@"[MDKeychain passwordForServiceName:accountName:] keyhain item was not found.");
		NSLog(@"Keychain item was not found!");
		
	} else {
		/*NSLog(@"[MDKeychain passwordForServiceName:accountName:] SecKeychainFindGenericPassword() returned %u, %@", status, [(NSString *)SecCopyErrorMessageString(status, NULL) autorelease]); */
		NSLog(@"some error");
	}
	
	return [password autorelease];
}



- (BOOL)addPassword:(NSString *)aPassword serviceName:(NSString *)aServiceName accountName:(NSString *)anAccountName {
	
	if (aPassword && [aPassword length] && aServiceName && [aServiceName length] && anAccountName && [anAccountName length]) {
		OSStatus status = noErr;
		
		BOOL success = NO;
		
		status = SecKeychainAddGenericPassword(NULL, (UInt32)strlen([aServiceName UTF8String]), [aServiceName UTF8String],
											   (UInt32)strlen([anAccountName UTF8String]), [anAccountName UTF8String],
											   (UInt32)strlen([aPassword UTF8String]), (void *)[aPassword UTF8String], NULL);
		
		if (status == noErr) {
			success = YES;
		} else {
			
			/*NSLog(@"[MDKeychain addPassword:serviceName:accountName:] SecKeychainAddGenericPassword() returned %ld, %@", status, [(NSString *)SecCopyErrorMessageString(status, NULL) autorelease]);*/
			
		}
		
		return success;
		
	}
	
	return NO;
}



- (BOOL)replacePassword:(NSString *)newPassword serviceName:(NSString *)aServiceName accountName:(NSString *)anAccountName {
	if (newPassword && [newPassword length] && aServiceName && [aServiceName length] && anAccountName && [anAccountName length]) {
		OSStatus status = noErr;
		
		BOOL success = NO;
		
		SecKeychainItemRef item = NULL;
		
		status = SecKeychainFindGenericPassword(NULL, (UInt32)strlen([aServiceName UTF8String]), [aServiceName UTF8String],
												(UInt32)strlen([anAccountName UTF8String]), [anAccountName UTF8String],
												NULL, NULL, &item);
		
		if (status == noErr && item) {
			
			status = SecKeychainItemModifyAttributesAndData(item, NULL, (UInt32)strlen([newPassword UTF8String]), (const void *)[newPassword UTF8String]);
			
			if (status == noErr) {
				success = YES;
			}
			
			CFRelease(item);
			
		} else {
			/*NSLog(@"[MDKeychain replacePassword:serviceName:accountName:] SecKeychainFindGenericPassword() returned %u, %@", status, [(NSString *)SecCopyErrorMessageString(status, NULL) autorelease]);*/
			
		}
		
		
		return success;
	}
	return NO;
}



- (BOOL)removePassword:(NSString *)aPassword serviceName:(NSString *)aServiceName accountName:(NSString *)anAccountName {
	if (aPassword && [aPassword length] && aServiceName && [aServiceName length] && anAccountName && [anAccountName length]) {
		OSStatus status = noErr;
		
		BOOL success = NO;
		
		SecKeychainItemRef item = NULL;
		
		status = SecKeychainFindGenericPassword(NULL, (UInt32)strlen([aServiceName UTF8String]), [aServiceName UTF8String],
												(UInt32)strlen([anAccountName UTF8String]), [anAccountName UTF8String],
												NULL, NULL, &item);
		
		if (status == noErr && item) {
			status = SecKeychainItemDelete(item);
			
			if (status == noErr) {
				success = YES;
			}
			
			CFRelease(item);
			
		} else {
			/*NSLog(@"[MDKeychain replacePassword:serviceName:accountName:] SecKeychainFindGenericPassword() returned %u, %@", status, [(NSString *)SecCopyErrorMessageString(status, NULL) autorelease]);*/
		}
		return success;
	}
	return NO;
}
@end
