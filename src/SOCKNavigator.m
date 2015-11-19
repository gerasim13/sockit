//
//  SOCKNavigator.m
//  SOCKit
//
//  Created by Павел Литвиненко on 15.01.15.
//  Copyright (c) 2015 Jeff Verkoeyen. All rights reserved.
//

//______________________________________________________________________________________________________________________

#import "SOCKNavigator.h"
#import "SOCKit.h"

//______________________________________________________________________________________________________________________

@interface SOCKNavigationRoute ()

@property (nonatomic, copy  ) SOCKNavigationMapBlock block;
@property (nonatomic, assign) SEL                    aSelector;
@property (nonatomic, assign) Class                  aClass;
@property (nonatomic, strong) SOCPattern            *pattern;
@property (nonatomic, strong) SOCKNavigationRoute   *parentRoute;
@property (nonatomic, strong) NSString              *parentPath;
@property (nonatomic, weak  ) NSObject              *object;

- (instancetype)initWithPatternString:(NSString*)string
                               object:(NSObject*)obj
                                class:(Class)cls
                             selector:(SEL)sel
                                block:(SOCKNavigationMapBlock)blk;

@end

//______________________________________________________________________________________________________________________

@interface SOCKNavigationMap ()
{
  NSMutableSet *_routes;
}

- (SOCKNavigationRoute*)routeMatchedToString:(NSString*)string;

@end

//______________________________________________________________________________________________________________________

@implementation SOCKNavigationRoute

- (instancetype)initWithPatternString:(NSString*)string
                               object:(NSObject*)obj
                                class:(Class)cls
                             selector:(SEL)sel
                                block:(SOCKNavigationMapBlock)blk
{
  if (self = [super init])
  {
    self.pattern   = [SOCPattern patternWithString:string];
    self.aSelector = sel;
    self.aClass    = cls;
    self.object    = obj;
    self.block     = blk;
  }
  return self;
}

- (id<SOCKNavigatorMappable>)performRoute:(id)parameter
{
  if (self.block)
  {
    return self.block(parameter);
  }
  else if (self.object)
  {
    if ([self.object respondsToSelector:self.aSelector])
    {
      IMP impl = [self.object methodForSelector:self.aSelector];
      return ((id<SOCKNavigatorMappable> (*)(id, SEL, id))impl)(self.object, self.aSelector, parameter);
    }
  }
  else if (self.aClass)
  {
    if ([self.aClass respondsToSelector:self.aSelector])
    {
      IMP impl = [self.aClass methodForSelector:self.aSelector];
      return ((id<SOCKNavigatorMappable> (*)(id, SEL, id))impl)(self.aClass, self.aSelector, parameter);
    }
  }
  return nil;
}

@end

//______________________________________________________________________________________________________________________

@implementation SOCKNavigationMap

#pragma mark - SOCKNavigationMap Lifecycle

- (instancetype)init
{
  if (self = [super init])
  {
    _routes = [NSMutableSet set];
  }
  return self;
}

#pragma mark - SOCKNavigationMap Private Methods

- (SOCKNavigationRoute*)routeMatchedToString:(NSString*)string
{
  for (SOCKNavigationRoute *route in _routes)
  {
    if ([route.pattern stringMatches:string])
    {
      return route;
    }
  }
  return nil;
}

#pragma mark - SOCKNavigationMap Public Methods

- (void)from:(NSString*)from toClass:(Class)to selector:(SEL)sel
{
  SOCKNavigationRoute *route = [[SOCKNavigationRoute alloc] initWithPatternString:from object:nil class:to selector:sel block:nil];
  [_routes addObject:route];
}

- (void)from:(NSString*)from toObject:(NSObject*)to selector:(SEL)sel
{
  SOCKNavigationRoute *route = [[SOCKNavigationRoute alloc] initWithPatternString:from object:to class:nil selector:sel block:nil];
  [_routes addObject:route];
}

- (void)from:(NSString*)from toBlock:(SOCKNavigationMapBlock)blk
{
  SOCKNavigationRoute *route = [[SOCKNavigationRoute alloc] initWithPatternString:from object:nil class:nil selector:nil block:blk];
  [_routes addObject:route];
}

- (void)from:(NSString*)from parent:(NSString*)parent toClass:(Class)to selector:(SEL)sel
{
  SOCKNavigationRoute *route = [[SOCKNavigationRoute alloc] initWithPatternString:from object:nil class:to selector:sel block:nil];
  route.parentRoute          = [self routeMatchedToString:parent];
  route.parentPath           = from;
  [_routes addObject:route];
}

- (void)from:(NSString*)from parent:(NSString*)parent toObject:(NSObject*)to selector:(SEL)sel
{
  SOCKNavigationRoute *route = [[SOCKNavigationRoute alloc] initWithPatternString:from object:to class:nil selector:sel block:nil];
  route.parentRoute          = [self routeMatchedToString:parent];
  route.parentPath           = from;
  [_routes addObject:route];
}

- (void)from:(NSString*)from parent:(NSString*)parent toBlock:(SOCKNavigationMapBlock)block
{
  SOCKNavigationRoute *route = [[SOCKNavigationRoute alloc] initWithPatternString:from object:nil class:nil selector:nil block:block];
  route.parentRoute          = [self routeMatchedToString:parent];
  route.parentPath           = from;
  [_routes addObject:route];
}

@end

//______________________________________________________________________________________________________________________

@implementation SOCKNavigator
@synthesize navigationMap = _navigationMap;

//______________________________________________________________________________________________________________________

#pragma mark - SOCKNavigator Lifecycle

+ (instancetype)sharedNavigator
{
  static SOCKNavigator *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  return sharedInstance;
}

- (instancetype)init
{
  if (self = [super init])
  {
    _navigationMap = [SOCKNavigationMap new];
  }
  return self;
}

#pragma mark - SOCKNavigator Public Methods

- (void)navigateToPath:(NSString*)path
{
  [self navigateToPath:path withQuery:nil];
}

- (void)navigateToPath:(NSString*)path withQuery:(NSDictionary*)query
{
  SOCKNavigationRoute *route = [_navigationMap routeMatchedToString:path];
  [self navigateToRoute:route withPath:path query:query];
}

- (void)navigateToRoute:(SOCKNavigationRoute*)route withPath:(NSString*)path query:(NSDictionary*)query
{
  // Navigate to parent
  if (route.parentRoute)
  {
    NSParameterAssert(route.parentPath);
    [self navigateToRoute:route.parentRoute withPath:route.parentPath query:query];
  }
  // Perform route
  if ([route respondsToSelector:@selector(performRoute:)])
  {
    id<SOCKNavigatorMappable> mappable = [route.pattern performSelector:@selector(performRoute:)
                                                               onObject:route
                                                           sourceString:path];
    // Apply query
    if ([mappable respondsToSelector:@selector(applyQuery:)])
    {
      [mappable applyQuery:query];
    }
  }
}

@end

//______________________________________________________________________________________________________________________
