//
//  BFKeychainManager.h
//  BlackFire
//
//	Created by Mark Douma
//

#import <Cocoa/Cocoa.h>


@interface BFKeychainManager : NSObject {

}
+ (BFKeychainManager *)defaultManager;
- (NSString *)passwordForServiceName:(NSString *)aServiceName accountName:(NSString *)anAccountName;
- (BOOL)addPassword:(NSString *)aPassword serviceName:(NSString *)aServiceName accountName:(NSString *)anAccountName;
- (BOOL)replacePassword:(NSString *)newPassword serviceName:(NSString *)aServiceName accountName:(NSString *)anAccountName;
- (BOOL)removePassword:(NSString *)aPassword serviceName:(NSString *)aServiceName accountName:(NSString *)anAccountName;
@end
