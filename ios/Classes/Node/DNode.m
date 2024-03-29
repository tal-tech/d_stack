//
//  DNode.m
//  
//
//  Created by TAL on 2020/1/16.
//

#import "DNode.h"

@interface DNode () <NSCopying, NSMutableCopying>

@end

@implementation DNode

- (instancetype)init
{
    self = [super init];
    if (self) {
        _target = @"";
    }
    return self;
}

- (NSString *)pageTypeString
{
    NSString *type = @"";
    if (_pageType == DNodePageTypeFlutter) {
        type = @"Flutter";
    } else if (_pageType == DNodePageTypeNative) {
        type = @"Native";
    }
    return type;
}

- (NSString *)pageString
{
    NSString *type = @"";
    if (_pageType == DNodePageTypeFlutter) {
        type = @"flutter";
    } else if (_pageType == DNodePageTypeNative) {
        type = @"native";
    }
    return type;
}

- (NSString *)actionTypeString
{
    NSString *action = @"";
    switch (_action) {
        case DNodeActionTypePush:{action = @"push";break;}
        case DNodeActionTypePresent:{action = @"present";break;}
        case DNodeActionTypePop:{action = @"pop";break;}
        case DNodeActionTypePopTo:{action = @"popTo";break;}
        case DNodeActionTypePopToRoot:{action = @"popToRoot";break;}
        case DNodeActionTypePopSkip:{action = @"popSkip";break;}
        case DNodeActionTypeGesture:{action = @"gesture";break;}
        case DNodeActionTypeDismiss:{action = @"dismiss";break;}
        case DNodeActionTypeReplace:{action = @"replace";break;}
        case DNodeActionTypeDidPop:{action = @"didPop";break;}
        case DNodeActionTypePushAndRemoveUntil:{action = @"pushAndRemoveUntil";break;}
        default:break;
    }
    return action;
}

- (void)copyWithNode:(DNode *)node
{
    self.action = node.action;
    self.pageType = node.pageType;
    self.target = node.target;
    self.params = node.params;
    self.identifier = node.identifier;
}

+ (DNodePageType)pageTypeWithString:(NSString *)string
{
    if (!string || [string isEqual:NSNull.null]  || !string.length) {
        return DNodePageTypeUnknow;
    }
    NSString *_pageType = string;
    DNodePageType pageType = DNodePageTypeUnknow;
    if ([_pageType isEqualToString:@"native"]) {
        pageType = DNodePageTypeNative;
    } else if ([_pageType isEqualToString:@"flutter"]) {
        pageType = DNodePageTypeFlutter;
    }
    return pageType;
}

+ (DNodeActionType)actionTypeWithString:(NSString *)string
{
    if (!string || [string isEqual:NSNull.null]  || !string.length) {
        return DNodeActionTypeUnknow;
    }
    NSString *_actionType = string;
    DNodeActionType actionType = DNodeActionTypeUnknow;
    if ([_actionType isEqualToString:@"push"]) {
        actionType = DNodeActionTypePush;
    } else if ([_actionType isEqualToString:@"present"]) {
        actionType = DNodeActionTypePresent;
    } else if ([_actionType isEqualToString:@"pop"]) {
        actionType = DNodeActionTypePop;
    } else if ([_actionType isEqualToString:@"popTo"]) {
        actionType = DNodeActionTypePopTo;
    } else if ([_actionType isEqualToString:@"popSkip"]) {
        actionType = DNodeActionTypePopSkip;
    } else if ([_actionType isEqualToString:@"popToRoot"]) {
        actionType = DNodeActionTypePopToRoot;
    } else if ([_actionType isEqualToString:@"dismiss"]) {
        actionType = DNodeActionTypeDismiss;
    } else if ([_actionType isEqualToString:@"gesture"]) {
        actionType = DNodeActionTypeGesture;
    } else if ([_actionType isEqualToString:@"replace"]) {
        actionType = DNodeActionTypeReplace;
    } else if ([_actionType isEqualToString:@"didPop"]) {
        actionType = DNodeActionTypeDidPop;
    } else if ([_actionType isEqualToString:@"pushAndRemoveUntil"]) {
        actionType = DNodeActionTypePushAndRemoveUntil;
    }
    return actionType;
}

- (NSString *)target
{
    if (_target && [_target isKindOfClass:NSString.class]) {
        return _target;
    }
    return @"";
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[class:%@ %p][action:%@][pageType:%@][target:%@][params:%@][identifier:%@]",
            NSStringFromClass(self.class),
            self,
            self.actionTypeString,
            self.pageTypeString,
            _target,
            _params,
            _identifier];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self nodeWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return [self nodeWithZone:zone];
}

- (id)nodeWithZone:(NSZone *)zone
{
    DNode *node = [[DNode allocWithZone:zone] init];
    node.fromFlutter = _fromFlutter;
    node.canRemoveNode = _canRemoveNode;
    node.isFlutterHomePage = _isFlutterHomePage;
    node.animated = _animated;
    node.boundary = _boundary;
    node.isRootPage = _isRootPage;
    node.action = _action;
    node.pageType = _pageType;
    node.params = _params;
    node.target = _target;
    node.identifier = _identifier;
    return node;
}

@end
