//
//  SOCKNavigator.h
//  SOCKit
//
//  Created by Павел Литвиненко on 15.01.15.
//  Copyright (c) 2015 Jeff Verkoeyen. All rights reserved.
//

//______________________________________________________________________________________________________________________

#import <Foundation/Foundation.h>

//______________________________________________________________________________________________________________________

@protocol SOCKNavigatorMappable <NSObject>
@optional
+ (void)applyQuery:(NSDictionary*)query;
- (void)applyQuery:(NSDictionary*)query;
@end

//______________________________________________________________________________________________________________________

typedef id<SOCKNavigatorMappable> (^SOCKNavigationMapBlock)(NSObject *object);

//______________________________________________________________________________________________________________________

@interface SOCKNavigationRoute : NSObject
- (id<SOCKNavigatorMappable>)performRoute:(id)parameter;
@end

//______________________________________________________________________________________________________________________

@interface SOCKNavigationMap : NSObject

- (void)from:(NSString*)from toClass :(Class    )to selector:(SEL)sel;
- (void)from:(NSString*)from toObject:(NSObject*)to selector:(SEL)sel;
- (void)from:(NSString*)from toBlock :(SOCKNavigationMapBlock)block;

- (void)from:(NSString*)from parent:(NSString*)parent toClass :(Class    )to selector:(SEL)sel;
- (void)from:(NSString*)from parent:(NSString*)parent toObject:(NSObject*)to selector:(SEL)sel;
- (void)from:(NSString*)from parent:(NSString*)parent toBlock :(SOCKNavigationMapBlock)block;

@end

//______________________________________________________________________________________________________________________

@interface SOCKNavigator : NSObject

@property (nonatomic, readonly) SOCKNavigationMap *navigationMap;
@property (nonatomic, readonly) NSString          *navigationPath;

+ (instancetype)sharedNavigator;
- (void)navigateToPath:(NSString*)path;
- (void)navigateToPath:(NSString*)path withQuery:(NSDictionary*)query;

@end

//______________________________________________________________________________________________________________________
