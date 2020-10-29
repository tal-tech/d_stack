//
//  DNode.m
//  
//
//  Created by TAL on 2020/1/16.
//

#import "DNode.h"

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
        case DNodeActionTypePush:
        {
            action = @"push";
            break;
        }
        case DNodeActionTypePresent:
        {
            action = @"present";
            break;
        }
        case DNodeActionTypePop:
        {
            action = @"pop";
            break;
        }
        case DNodeActionTypePopTo:
        {
            action = @"popTo";
            break;
        }
        case DNodeActionTypePopToRoot:
        {
            if (_fromFlutter) {
                action = @"popToNativeRoot";
            } else {
                action = @"popToRoot";
            }
            break;
        }
        case DNodeActionTypePopSkip:
        {
            action = @"popSkip";
            break;
        }
        case DNodeActionTypeGesture:
        {
            action = @"gesture";
            break;
        }
        case DNodeActionTypeDismiss:
        {
            action = @"dismiss";
            break;
        }
        case DNodeActionTypeReplace:
        {
            action = @"replace";
            break;
        }
        case DNodeActionTypeDidPop:
        {
            action = @"didPop";
            break;
        }
        default:
            break;
    }
    return action;
}

- (void)copyWithNode:(DNode *)node
{
    self.action = node.action;
    self.pageType = node.pageType;
    self.target = node.target;
    self.params = node.params;
    self.fromFlutter = node.fromFlutter;
    self.canRemoveNode = node.canRemoveNode;
    self.isFlutterHomePage = node.isFlutterHomePage; 
    self.animated = node.animated;
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
    } else if ([_actionType isEqualToString:@"popToNativeRoot"]) {
        actionType = DNodeActionTypePopToRoot;
    } else if ([_actionType isEqualToString:@"dismiss"]) {
        actionType = DNodeActionTypeDismiss;
    } else if ([_actionType isEqualToString:@"gesture"]) {
        actionType = DNodeActionTypeGesture;
    } else if ([_actionType isEqualToString:@"replace"]) {
        actionType = DNodeActionTypeReplace;
    } else if ([_actionType isEqualToString:@"didPop"]) {
        actionType = DNodeActionTypeDidPop;
    }
    return actionType;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[class:%@ %p] [action:%@] [pageType:%@] [target:%@] [params:%@]",
            NSStringFromClass(self.class),
            self,
            self.actionTypeString,
            self.pageTypeString,
            _target,
            _params];
}

@end
