/*
 Copyright (c) 2012, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SFSDKInfoPlugin.h"
#import "CDVPlugin+SFAdditions.h"
#import "SFContainerAppDelegate.h"

// Keys in sdk info map
NSString * const kSDKVersionKey = @"sdkVersion";
NSString * const kAppNameKey = @"appName";
NSString * const kAppVersionKey = @"appVersion";
NSString * const kForcePluginsAvailableKey = @"forcePluginsAvailable";

// Other constants
NSString * const kCordova = @"Cordova";
NSString * const kPlugins = @"Plugins";
NSString * const kForcePluginPrefix = @"com.salesforce.";

// Static member
NSArray * forcePlugins = nil;

@implementation SFSDKInfoPlugin


/**
 This is Cordova's default initializer for plugins.
 */
- (CDVPlugin*) initWithWebView:(UIWebView*)theWebView
{
    return [super initWithWebView:theWebView];
}

#pragma mark - Methods to get force plugins

+ (NSArray*) getForcePlugins
{
    if (!forcePlugins) {
        forcePlugins = [SFSDKInfoPlugin getForcePluginsFromPList];
    }
    return forcePlugins;
}

+ (NSArray*)getForcePluginsFromPList
{
    NSMutableArray* services = [NSMutableArray array];

    NSDictionary* cordovaPlist = [SFSDKInfoPlugin getBundlePlist:kCordova];
    if (cordovaPlist) {
        NSDictionary* pluginsDict = [cordovaPlist objectForKey:kPlugins];
        if (pluginsDict) {
            for (NSString* key in [pluginsDict allKeys]) {
                key = [key lowercaseString];
                if ([key hasPrefix:kForcePluginPrefix]) {
                    [services addObject:key];
                }
            }
        }
    }
    
    return services;
}

+ (NSDictionary*)getBundlePlist:(NSString *)plistName
{
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format errorDescription:&errorDesc];
    return temp;
}

#pragma mark - Plugin methods called from js

- (void)getInfo:(NSMutableArray*)arguments withDict:(NSDictionary*)options
{
    NSString *callbackId = [arguments pop];
    /* NSString* jsVersionStr = */[self popVersion:@"getInfo" withArguments:arguments];

    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];

    NSDictionary *sdkInfo = [[[NSDictionary alloc] initWithObjectsAndKeys:
                             kSFMobileSDKVersion, kSDKVersionKey,
                             appName, kAppNameKey,
                             appVersion, kAppVersionKey,
                             [SFSDKInfoPlugin getForcePlugins], kForcePluginsAvailableKey,
                             nil] autorelease];
    
    [self writeSuccessDictToJsRealm:sdkInfo callbackId:callbackId];
}



@end
