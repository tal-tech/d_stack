//
//  DNodeManager.m
//  
//
//  Created by TAL on 2020/1/16.
//

#import "DNodeManager.h"
#import "DActionManager.h"
#import "DStackPlugin.h"
#import "DStack.h"

@interface DNodeManager ()

@property (nonatomic, copy) NSString *logPath;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, copy) NSString *debugLogPath;
@property (nonatomic, strong) dispatch_queue_t logQueue;
@property (nonatomic, strong) NSMutableArray <DNode *>*nodeList;

@end

@implementation DNodeManager

+ (instancetype)sharedInstance
{
    static DNodeManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.pageCount = 0;
    });
    return manager;
}

- (NSArray<DNode *> *)checkNode:(DNode *)node
{
    if (!node) { return @[];}
    NSArray *subArray = [self subArrayWithNode:node];
    // 这里要调用DActionManager去处理跳转
    [DActionManager handlerActionWithNodeList:subArray node:node];
    [self removeNodesWithNodeArray:subArray node:node];
    return subArray;
}

- (NSArray *)subArrayWithNode:(DNode *)node
{
    NSArray *subArray = @[];
    if (node.action == DNodeActionTypeUnknow || !node) {
        return subArray;
    }
    
    if (node.action == DNodeActionTypePush ||
        node.action == DNodeActionTypePresent) {
        // 入栈管理
        if (node.fromFlutter) {
            if (node.pageType == DNodePageTypeFlutter) {
                // 页面是flutter，直接入栈
                subArray = [self inStackWithNode:node];
            }
        } else {
            // native自己调用 push or Present 过来的节点，这时候才加入节点列表
            subArray = [self inStackWithNode:node];
        }
    } else if (node.action == DNodeActionTypeReplace) {
        //Replace 操作，删除最后一个节点，再新增当前节点
        if (node.fromFlutter) {
            // 从flutter过来的节点
            if (node.pageType == DNodePageTypeFlutter) {
                // 下一个页面是flutter，直接入栈
                DNode *lastNode = self.nodeList.lastObject;
                if (lastNode) {
                    DStackLog(@"被Replace的节点 === %@", self.nodeList.lastObject);
                    [lastNode copyWithNode:node];
                    self.pageCount = self.nodeList.count;
                    [self dStackDelegateSafeWithSEL:@selector(dStack:inStack:) exe:^(DStack *stack) {
                        DStackNode *stackNode = [DActionManager stackNodeFromNode:node];
                        [stack.delegate dStack:stack inStack:@[stackNode]];
                    }];
                    DStackLog(@"Replace的完成之后 === %@", self.nodeList);
                }
                
            }
        }
    } else {
        // 出栈管理
        if (node.action == DNodeActionTypePop ||
            node.action == DNodeActionTypeDismiss ||
            node.action == DNodeActionTypeGesture ||
            node.action == DNodeActionTypeDidPop) {
            if (!node.canRemoveNode) {
                DNode *lastNode = self.nodeList.lastObject;
                if (lastNode) {
                    if (node.action == DNodeActionTypePop ||
                        node.action == DNodeActionTypeDismiss) {
                        if (node.fromFlutter) {
                            subArray = @[lastNode];
                        } else {
                            if ([lastNode.target isEqualToString:node.target]) {
                                subArray = @[lastNode];
                            }
                        }
                    } else {
                        subArray = @[lastNode];
                    }
                }
            } else {
                if (node.target) {
                    DNode *targetNode = [self nodeWithTarget:node.target];
                    if (targetNode) {
                        subArray = @[targetNode];
                    }
                }
            }
        } else if (node.action == DNodeActionTypePopSkip) {
            // popSkip，最后面开始往前找skip的字段，直到没到为止
            NSMutableArray *skipArray = [[NSMutableArray alloc] init];
            [self.nodeList enumerateObjectsWithOptions:NSEnumerationReverse
                                            usingBlock:^(DNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj.target containsString:node.target]) {
                    [skipArray insertObject:obj atIndex:0];
                } else {
                    *stop = YES;
                }
            }];
            subArray = [skipArray copy];
        } else {
            // popTo 或者 popToRoot
            __block DNode *targetNode = nil;
            // 从栈底开始遍历出需要移除的节点
            if (!(!node.target || [node.target isEqual:NSNull.null])) {
                [self.nodeList enumerateObjectsWithOptions:NSEnumerationReverse
                                                usingBlock:^(DNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if ([obj.target isEqualToString:node.target]) {
                        targetNode = obj;
                        *stop = YES;
                    }
                }];
            }
            if (targetNode) {
                NSUInteger targetNodeIndex = [self.nodeList indexOfObject:targetNode];
                if (node.action == DNodeActionTypePopTo) {
                    targetNodeIndex += 1;
                }
                if (self.nodeList.count >= targetNodeIndex) {
                    NSInteger length = self.nodeList.count - targetNodeIndex;
                    subArray = [self.nodeList subarrayWithRange:NSMakeRange(targetNodeIndex, length)];
                }
            } else if (!targetNode && node.action == DNodeActionTypePopToRoot) {
                // 没有找到targetNode，又是回到root，说明targetNode为根节点，直接移除所有节点
                subArray = [self.nodeList copy];
            }
        }
    }
    
    if (node.action == DNodeActionTypePopTo) {
        // 目的页在栈里面不存在，直接返回
        if (![[DNodeManager sharedInstance] nodeWithTarget:node.target]) {
            DStackError(@"target %@ 不存在于栈中", node.target);
            return subArray;
        }
    }
    return subArray;
}

- (void)removeNodesWithNodeArray:(NSArray *)subArray node:(DNode *)node
{
    if (!node.fromFlutter) {
        // 原生自己的直接出栈
        if (!(node.action == DNodeActionTypePush || node.action == DNodeActionTypePresent)) {
            // 先执行跳转，再出栈管理
            [self outStackWithNode:node nodeArray:subArray];
        }
    } else {
        if (node.action == DNodeActionTypeDidPop) {
            // 收到flutter的确认出栈信息才执行出栈
            if (node.canRemoveNode && subArray.count) {
                [self outStackWithNode:node nodeArray:subArray];
            }
        } else {
            if ((node.action == DNodeActionTypePopTo ||
                 node.action == DNodeActionTypePopSkip ||
                 node.action == DNodeActionTypePopToRoot ||
                 node.action == DNodeActionTypeGesture)) {
                // 先执行跳转，再出栈管理
                [self outStackWithNode:node nodeArray:subArray];
            } else if (node.action == DNodeActionTypePop ||
                       node.action == DNodeActionTypeDismiss) {
                if (subArray.count == 1) {
                    DNode *first = subArray.firstObject;
                    if (first.isFlutterHomePage) {
                        [self outStackWithNode:node nodeArray:subArray];
                    }
                }
            }
        }
    }
}

- (NSArray *)inStackWithNode:(DNode *)node
{
    NSArray *subArray = @[node];
    [self.nodeList addObject:node];
    for (DNode *node in self.nodeList) {
        if (node.pageType == DNodePageTypeFlutter) {
            node.isFlutterHomePage = YES; break;
        }
    }
    self.pageCount = self.nodeList.count;
    [self dStackDelegateSafeWithSEL:@selector(dStack:inStack:) exe:^(DStack *stack) {
        DStackNode *stackNode = [DActionManager stackNodeFromNode:node];
        [stack.delegate dStack:stack inStack:@[stackNode]];
    }];
    [self sendPageLifeCicleToFlutterWithAppearNode:node
                                     disappearNode:self.preNode
                                            isPush:YES];
    DStackLog(@"来自【%@】的【%@】消息，入栈节点为 == %@, 入栈后的节点列表 == %@", [self _page:node], node.actionTypeString, subArray, self.nodeList);
    [self writeLogWithNode:node];
    return subArray;
}

- (void)outStackWithNode:(DNode *)node nodeArray:(NSArray *)subArray
{
    if (!subArray.count) { return;}
    [self.nodeList removeObjectsInArray:subArray];
    self.removedNodes = [subArray copy];
    self.pageCount = self.pageCount - subArray.count;
    [self dStackDelegateSafeWithSEL:@selector(dStack:outStack:) exe:^(DStack *stack) {
        NSMutableArray *nodes = [[NSMutableArray alloc] init];
        for (DNode *x in subArray) {
            DStackNode *_node = [DActionManager stackNodeFromNode:x];
            [nodes addObject:_node];
        }
        [stack.delegate dStack:stack outStack:[nodes copy]];
    }];
    [self sendPageLifeCicleToFlutterWithAppearNode:self.currentNode
                                     disappearNode:subArray.lastObject
                                            isPush:NO];
    [self writeLogWithNode:node];
    if ([[DStack sharedInstance] debugMode]) {
        // 加入节点检查
        if (self.nodeList.count != self.pageCount) {
            // 节点出现异常，没有清理干净
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"警告"
                                                                           message:@"节点异常，请及时排查"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *sure = [UIAlertAction actionWithTitle:@"好的"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
            [alert addAction:sure];
            [[DActionManager rootController] presentViewController:alert animated:YES completion:nil];
        }
    }
    DStackLog(@"来自【%@】的【%@】消息，出栈节点为 == %@, 出栈后的节点列表 == %@", [self _page:node], node.actionTypeString, subArray, self.nodeList);
}


- (void)sendAppliccationLifeCicleToFlutter:(DStackApplicationState)state
{
    DStack *stack = [DStack sharedInstance];
    DNode *node = [[DNodeManager sharedInstance] currentNode];
    DStackNode *stackNode = [DActionManager stackNodeFromNode:node];
    if (stack.delegate && [stack.delegate respondsToSelector:@selector(dStack:applicationState:visibleNode:)]) {
        [stack.delegate dStack:stack applicationState:state visibleNode:stackNode];
    }
    NSString *currentRoute = @"";
    if (!self.nodeList.count) {
        // 节点列表里面没用记录根页面的路由，/代表根页面
        currentRoute = @"/";
    } else {
        currentRoute = stackNode.route ? stackNode.route : @"";
    }
    NSDictionary *params = @{
        @"application": @{
                @"currentRoute": currentRoute,
                @"pageType": node.pageString ? node.pageString : @"",
                @"state": @(state)
        }
    };
    [[DStackPlugin sharedInstance] invokeMethod:DStackMethodChannelSendLifeCircle
                                      arguments:params
                                         result:nil];
}

- (void)sendPageLifeCicleToFlutterWithAppearNode:(DNode *)appear
                                   disappearNode:(DNode *)disappear
                                          isPush:(BOOL)isPush
{
    DStack *stack = [DStack sharedInstance];
    DStackNode *stackAppearNode = [DActionManager stackNodeFromNode:appear];
    DStackNode *stackDisappearNode = [DActionManager stackNodeFromNode:disappear];
    if (stack.delegate && [stack.delegate respondsToSelector:@selector(dStack:appear:disappear:)]) {
        [stack.delegate dStack:stack appear:stackAppearNode disappear:stackDisappearNode];
    }
    NSString *appearRoute = stackAppearNode.route ? stackAppearNode.route : @"";
    NSString *disappearRoute = stackDisappearNode.route ? stackDisappearNode.route : @"";
    if (isPush) {
        // 节点列表里面没用记录根页面的路由，/代表根页面
        if (!self.preNode) {
            disappearRoute = @"/";
        }
    } else {
        if (!self.nodeList.count) {
            appearRoute = @"/";
        }
    }
    
    NSDictionary *params = @{
        @"page": @{
                @"actionType": isPush ? @"push" : @"pop",
                @"appearRoute": appearRoute,
                @"disappearRoute": disappearRoute,
                @"appearPageType": appear.pageString ? appear.pageString : @"",
                @"disappearPageType": disappear.pageString ? disappear.pageString : @""
        },
    };
    [[DStackPlugin sharedInstance] invokeMethod:DStackMethodChannelSendLifeCircle
                                      arguments:params
                                         result:nil];
}

#pragma mark -- private

- (DNode *)nodeWithTarget:(NSString *)target
{
    DNode *targetNode = nil;
    for (NSInteger i = self.nodeList.count - 1; i >= 0; i --) {
        DNode *node = self.nodeList[i];
        if ([node.target isEqualToString:target]) {
            targetNode = node; break;
        }
    }
    return targetNode;
}

- (BOOL)nativePopGestureCanReponse
{
    if (self.nodeList.count == 0) {
        return YES;
    } else if (self.nodeList.count == 1) {
        return ![DActionManager rootControllerIsFlutterController];
    } else {
        // self.nodeList.count - 2 是要查看当前页面前一个页面的页面类型
        DNode *node = [self.nodeList objectAtIndex:self.nodeList.count - 2];
        return node.pageType == DNodePageTypeNative;
    }
}

- (DNode *)nextPageScheme:(NSString *)scheme
                 pageType:(DNodePageType)pageType
                   action:(DNodeActionType)actionType
                   params:(NSDictionary *)params
{
    DNode *node = [[DNode alloc] init];
    node.pageType = pageType;
    node.action = actionType;
    node.target = scheme;
    node.params = params;
    return node;
}

- (void)dStackDelegateSafeWithSEL:(SEL)selector exe:(void(^)(DStack *stack))exe
{
    DStack *stack = [DStack sharedInstance];
    if (stack.delegate && [stack.delegate respondsToSelector:selector]) {
        if (exe) {
            exe(stack);
        }
    }
}


#pragma mark - 日志记录

- (void)configLogFileWithDebugMode:(BOOL)debugMode
{
    NSString *logFilePath = [self logFileDirectoryPath];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:logFilePath]) {
        [manager createDirectoryAtPath:logFilePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString *date = [formatter stringFromDate:[NSDate date]];
    NSString *logName = [NSString stringWithFormat:@"%@.txt", date];
    if (debugMode) {
        NSString *debugName = [NSString stringWithFormat:@"%@-debug.txt", date];
        self.debugLogPath = [NSString stringWithFormat:@"%@/%@", logFilePath, debugName];
    }
    self.logPath = [NSString stringWithFormat:@"%@/%@", logFilePath, logName];
}

- (void)cleanLogFile
{
    self.logPath = nil;
    self.debugLogPath = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[self logFileDirectoryPath]
                                               error:nil];
    [self configLogFileWithDebugMode:[[DStack sharedInstance] debugMode]];
}

- (void)writeLogWithNode:(DNode *)node
{
    dispatch_async(self.logQueue, ^{
        if (!self.logPath || !node) { return;}
        NSString *target = node.target;
        if (!node.target || [node.target isEqual:NSNull.null] || !node.target.length) {
            target = @"";
        }
        NSDictionary *info = @{
            @"action": [node actionTypeString],
            @"pagaType" : [node pageTypeString],
            @"tagret": target,
            @"time": @([[NSDate date] timeIntervalSince1970] * 1000),
            @"params": (node.params != nil) ? node.params : @{}
        };
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.logPath]) {
            [self _writeWithItems:@[info] node:node existsLog:NO];
        } else {
            NSString *localString = [NSString stringWithContentsOfFile:self.logPath
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
            NSData *jsonData = [localString dataUsingEncoding:NSUTF8StringEncoding];
            if (!jsonData) {return;}
            NSArray *items = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:NSJSONReadingFragmentsAllowed
                                                               error:nil];
            if (!items) {return;}
            NSMutableArray *mutableItems = [NSMutableArray arrayWithArray:items];
            [mutableItems addObject:info];
            [self _writeWithItems:mutableItems node:node existsLog:YES];
        }
    });
}

- (void)_writeWithItems:(NSArray *)items
                   node:(DNode *)node
              existsLog:(BOOL)exists
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:items
                                                       options:NSJSONWritingFragmentsAllowed
                                                         error:nil];
    if (jsonData) {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        if (jsonString) {
        [jsonString writeToFile:self.logPath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:nil];
        }
        
        if (self.debugLogPath) {
            NSString *debugString = [NSString stringWithFormat:@"来自【%@】的【%@】消息，当前节点列表为 == %@\n", [self _page:node], node.actionTypeString, self.nodeList];
            if (exists) {
                NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:self.debugLogPath];
                [handle seekToEndOfFile];
                NSData *data = [debugString dataUsingEncoding:NSUTF8StringEncoding];
                [handle writeData:data];
                [handle closeFile];
            } else {
                [debugString writeToFile:self.debugLogPath
                              atomically:YES
                                encoding:NSUTF8StringEncoding
                                   error:nil];
            }
        }
    }
}

- (void)resetHomePage
{
    if (self.removedNodes && self.removedNodes.count == 1) {
        DNode *first = self.removedNodes.firstObject;
        if (first.isFlutterHomePage) {
            [[DStackPlugin sharedInstance] invokeMethod:DStackMethodChannelSendResetHomePage arguments:nil result:nil];
        }
        self.removedNodes = nil;
    }
}


#pragma mark -- getter

- (NSMutableArray<DNode *> *)nodeList
{
    if (!_nodeList) {
        _nodeList = [[NSMutableArray alloc] init];
    }
    return _nodeList;
}

- (NSArray<DNode *> *)currentNodeList
{
    return [self.nodeList copy];
}

- (DNode *)currentNode
{
    return [self.nodeList lastObject];
}

- (DNode *)preNode
{
    if (self.nodeList.count > 1) {
        return [self.nodeList objectAtIndex:self.nodeList.count - 2];
    }
    return nil;
}

- (NSString *)_page:(DNode *)node
{
    NSString *string = [node pageTypeString];
    if (!string.length) {
        if (node.fromFlutter) {
            string = @"Flutter";
        } else {
            string = @"Native";
        }
    }
    return string;
}

- (dispatch_queue_t)logQueue
{
    if (!_logQueue) {
        _logQueue = dispatch_queue_create("com.tal.dstack.log.queue", DISPATCH_QUEUE_SERIAL);
    }
    return _logQueue;;
}

- (NSString *)timeString
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    return [formatter stringFromDate:[NSDate date]];
}

- (NSString *)logFileDirectoryPath
{
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/DStack"];
}

@end
