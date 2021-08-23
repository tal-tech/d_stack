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
/// 列表第一个节点是根节点，只有一个 / 代表根
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
    if (node.action == DNodeActionTypePush ||
        node.action == DNodeActionTypePresent) {
        /// 判断一下是否在栈中已存在了相同的node
        DNode *checkNode = [[DNodeManager sharedInstance] nodeWithIdentifier:node.identifier];
        if (checkNode) {
            /// 节点已存在栈中，不在入栈
            DStackLog(@"【当前节点id】== %@，【已存在于栈中不再重复入栈，栈列表为】== %@", node.identifier, [DNodeManager sharedInstance].currentNodeList);
            return @[];
        }
    }
    NSArray *subArray = [self subArrayWithNode:node];
    // 这里要调用DActionManager去处理跳转
    [DActionManager handlerActionWithNodeList:subArray node:node];
    [self removeNodesWithNodeArray:subArray node:node];
    return subArray;
}

- (NSArray *)subArrayWithNode:(DNode *)node
{
    NSArray *subArray = @[];
    if (node.action == DNodeActionTypeUnknow || !node) {return subArray;}
    
    switch (node.action) {
        case DNodeActionTypePush:
        case DNodeActionTypePresent:
        {
            subArray = [self pushNodeToListWithNode:node];
            break;
        }
        case DNodeActionTypeReplace:
        {
            // replace最后一个节点，并且是flutter的页面时，replace只存在于flutter
            if (node.fromFlutter && node.pageType == DNodePageTypeFlutter) {
                DNode *lastNode = self.nodeList.lastObject;
                if (lastNode) {
                    DStackLog(@"被Replace的节点 === %@", lastNode);
                    [self sendPageLifeCicleToFlutterWithAppearNode:node
                                                     disappearNode:lastNode
                                                        actionType:node.actionTypeString];
                    [lastNode copyWithNode:node];
                    [self operationNode:lastNode];
                    self.pageCount = self.nodeList.count;
                    [self dStackDelegateSafeWithSEL:@selector(dStack:inStack:) exe:^(DStack *stack) {
                        DStackNode *stackNode = [DActionManager stackNodeFromNode:node];
                        [stack.delegate dStack:stack inStack:@[stackNode]];
                    }];
                    DStackLog(@"Replace的完成之后 === %@", self.nodeList);
                }
            }
            break;
        }
        case DNodeActionTypePopTo:
        {
            if (![[DNodeManager sharedInstance] nodeWithTarget:node.target]) {
                // 目的页在栈里面不存在
                DStackError(@"target %@ 不存在于栈中", node.target);
            } else {
                // 从栈底开始遍历出需要移除的节点
                if (!(!node.target || [node.target isEqual:NSNull.null])) {
                    NSMutableArray *removeArray = [[NSMutableArray alloc] init];
                    NSInteger count = self.nodeList.count;
                    for (NSInteger i = count - 1; i >= 0; i --) {
                        DNode *obj = self.nodeList[i];
                        /// flutter的popTo只能比较路由、native侧的popTo比较identifier
                        NSString *identifierA = obj.target;
                        NSString *identifierB = node.target;
                        if (node.pageType == DNodePageTypeNative && !node.fromFlutter) {
                            identifierA = obj.identifier;
                            identifierB = node.identifier;
                        }
                        if ([identifierA isEqualToString:identifierB]) {
                            break;
                        } else {
                            if (!obj.isRootPage) {
                                [removeArray insertObject:obj atIndex:0];
                            }
                        }
                    }
                    subArray = [removeArray copy];
                }
            }
            break;
        }
        case DNodeActionTypePopToRoot:
        {
            subArray = [self.nodeList subarrayWithRange:NSMakeRange(1, self.nodeList.count - 1)];
            break;
        }
        case DNodeActionTypePopSkip:
        {
            // popSkip，最后面开始往前找skip的字段，直到没到为止
            NSMutableArray *skipArray = [[NSMutableArray alloc] init];
            [self.nodeList enumerateObjectsWithOptions:NSEnumerationReverse
                                            usingBlock:^(DNode *obj, NSUInteger idx, BOOL *stop) {
                if ([obj.target containsString:node.target]) {
                    [skipArray insertObject:obj atIndex:0];
                } else {
                    *stop = YES;
                }
            }];
            subArray = [skipArray copy];
            break;
        }
        case DNodeActionTypePop:
        case DNodeActionTypeDismiss:
        {
            subArray = [self popNodeToListWithNode:node];
            break;
        }
        case DNodeActionTypeGesture:
        {
            if (!node.canRemoveNode) {
                DNode *lastNode = self.nodeList.lastObject;
                if (lastNode) {
                    subArray = [self checkRemovedNode:node needRemove:lastNode];
                }
            }
            break;
        }
        case DNodeActionTypeDidPop:
        {
            DNode *targetNode = [self nodeWithNode:node];
            if (targetNode) { subArray = @[targetNode]; }
            break;
        }
        case DNodeActionTypePushAndRemoveUntil:
        {
            if (node.fromFlutter && node.pageType == DNodePageTypeFlutter) {
                NSInteger count = self.nodeList.count;
                if (count > 1) {
                    subArray = [self.nodeList subarrayWithRange:NSMakeRange(1, count - 1)];
                }
                // 更新更节点
                DNode *rootNode = [self.nodeList firstObject];
                [self sendPageLifeCicleToFlutterWithAppearNode:node
                                                 disappearNode:rootNode
                                                    actionType:node.actionTypeString];
                [rootNode copyWithNode:node];
                [self operationNode:rootNode];
            }
            break;
        }
        default: {subArray = @[];}
    }
    return subArray;
}

- (NSArray *)pushNodeToListWithNode:(DNode *)node
{
    if (node.fromFlutter) {
        // 页面是flutter，直接入栈
        // flutter打开native页面会调用原生的push和present
        if (node.pageType == DNodePageTypeFlutter) {
            return [self inStackWithNode:node];
        }
    } else {
        // native自己调用 push or Present 过来的节点，这时候才加入节点列表
        return [self inStackWithNode:node];
    }
    return @[];
}

- (NSArray *)popNodeToListWithNode:(DNode *)node
{
    NSArray *subArray = @[];
    if (!node.canRemoveNode) {
        DNode *lastNode = self.nodeList.lastObject;
        if (lastNode) {
            if (node.fromFlutter) {
                lastNode.params = node.params;
                subArray = @[lastNode];
            } else {
                subArray = [self checkRemovedNode:node needRemove:lastNode];
            }
        }
    }
    return subArray;
}

/// 移除节点
/// @param subArray subArray
/// @param node node
- (void)removeNodesWithNodeArray:(NSArray *)subArray node:(DNode *)node
{
    if (!node.fromFlutter) {
        switch (node.action) {
            case DNodeActionTypePop:
            case DNodeActionTypePopTo:
            case DNodeActionTypePopToRoot:
            case DNodeActionTypePopSkip:
            case DNodeActionTypeGesture:
            case DNodeActionTypeDismiss:
            case DNodeActionTypeReplace:
            case DNodeActionTypeDidPop:
            {
                [self outStackWithNode:node nodeArray:subArray];
                break;
            }
            default:break;
        }
    } else {
        switch (node.action) {
            case DNodeActionTypeDidPop:
            {
                if (node.canRemoveNode) {
                    [self outStackWithNode:node nodeArray:subArray];
                }
                break;
            }
            case DNodeActionTypePopTo:
            case DNodeActionTypePopSkip:
            case DNodeActionTypePopToRoot:
            case DNodeActionTypeGesture:
            case DNodeActionTypePushAndRemoveUntil:
            {
                [self outStackWithNode:node nodeArray:subArray];
                break;
            }
            case DNodeActionTypePop:
            case DNodeActionTypeDismiss:
            {
                if (subArray.count == 1) {
                    DNode *first = subArray.firstObject;
                    if (first.isFlutterHomePage) {
                        [self outStackWithNode:node nodeArray:subArray];
                    }
                }
                break;
            }
            default:break;
        }
    }
}

/// 检查移除节点的准确性
/// @param removed 实际已经不在显示的节点页面
/// @param need 栈中最后一个节点，需要被移除的
- (NSArray *)checkRemovedNode:(DNode *)removed needRemove:(DNode *)need
{
    NSArray *subArray = @[];
    BOOL match = [need.identifier isEqualToString:removed.identifier];
    NSString *assert = [NSString stringWithFormat:@"已经不在屏幕节点的id：%@，栈中最后一个节点id：%@，两者不一致，请注意排查。", removed.identifier, need.identifier];
    if (removed.boundary && (removed.pageType == need.pageType) &&
        (removed.action == DNodeActionTypeGesture)) {
        match = YES;
    }
    NSAssert(match, assert);
    if (match) {
        subArray = @[need];
    }
    return subArray;
}

/// 进栈
/// @param node node
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
                                        actionType:node.actionTypeString];
    DStackLog(@"来自【%@】的【%@】消息，入栈节点为 == %@, 入栈后的节点列表 == %@", [self _page:node], node.actionTypeString, subArray, self.nodeList);
    [self writeLogWithNode:node];
    return subArray;
}

/// 出栈
/// @param node node
/// @param subArray 出栈列表
- (void)outStackWithNode:(DNode *)node nodeArray:(NSArray *)subArray
{
    // 根节点不能出出栈
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    for (DNode *x in subArray) {
        if (!x.isRootPage) {
            [tempArray addObject:x];
        }
    }
    subArray = [tempArray copy];
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
                                        actionType:node.actionTypeString];
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
            [[DActionManager currentController] presentViewController:alert animated:YES completion:nil];
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
    NSDictionary *params = @{
        @"application": @{
                @"currentRoute": stackNode.route ? stackNode.route : @"",
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
                                      actionType:(NSString *)actionType
{
    DStack *stack = [DStack sharedInstance];
    DStackNode *stackAppearNode = [DActionManager stackNodeFromNode:appear];
    DStackNode *stackDisappearNode = [DActionManager stackNodeFromNode:disappear];
    if (stack.delegate && [stack.delegate respondsToSelector:@selector(dStack:appear:disappear:)]) {
        [stack.delegate dStack:stack appear:stackAppearNode disappear:stackDisappearNode];
    }
    NSString *appearRoute = stackAppearNode.route ? stackAppearNode.route : @"";
    NSString *disappearRoute = stackDisappearNode.route ? stackDisappearNode.route : @"";
    NSDictionary *params = @{
        @"page": @{
                @"actionType": actionType,
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

- (void)updateBoundaryNode:(NSDictionary *)nodeInfo
{
    if (!nodeInfo) {return;}
    int index = (int)(self.nodeList.count - 1);
    for (int i = index; index >= 0; i --) {
        DNode *node = self.nodeList[index];
        if ([node.target isEqualToString:nodeInfo[@"target"]] &&
            [node.actionTypeString isEqualToString:nodeInfo[@"action"]] &&
            (node.boundary == [nodeInfo[@"boundary"] boolValue]) &&
            [node.pageString isEqualToString:nodeInfo[@"pageType"]]) {
            node.identifier = nodeInfo[@"identifier"];
            DStackLog(@"更新临界节点信息为%@, 更新后的节点列表 == %@", nodeInfo, self.nodeList);
            break;
        }
    }
}

- (BOOL)updateRootNode:(DNode *)node
{
    DNode *root = self.nodeList.firstObject;
    if ([root.target isEqualToString:node.target] &&
        root.pageType == node.pageType) {
        return NO;
    }
    root.target = node.target;
    root.pageType = node.pageType;
    root.action = node.action;
    DStackLog(@"更新根节点信息为%@, 更新后的节点列表 == %@", node, self.nodeList);
    return YES;
}

    
#pragma mark -- private

- (void)operationNode:(DNode *)node {
    
    // 发送给flutter侧
    NSDictionary *params;
    if (node.target) {
        params = @{
            @"action": node.actionTypeString != nil ? node.actionTypeString : @"unknown",
            @"pageType": node.pageTypeString!= nil ? node.pageTypeString : @"unknown",
            @"target": node.target != nil ? node.target : @"unknown",
            @"params": node.params != nil ? node.params : @{},
            @"homePage": @(node.isFlutterHomePage),
            @"boundary": @(node.boundary),
            @"animated": @(node.animated),
            @"identifier": node.identifier != nil ? node.identifier : @"unknown",
        };
    } else {
        params = @{};
    }
    
    [[DStackPlugin sharedInstance] invokeMethod:DStackMethodChannelSendOperationNodeToFlutter
                                      arguments:params
                                         result:nil];
    // 发送调给native侧
    [self dStackDelegateSafeWithSEL:@selector(operationNode:) exe:^(DStack *stack) {
        [stack.delegate operationNode:[node copy]];
    }];
}

- (DNode *)nodeWithTarget:(NSString *)target
{
    DNode *targetNode = nil;
    if (!target || [target isEqual:NSNull.null]) {return targetNode;}
    for (NSInteger i = self.nodeList.count - 1; i >= 0; i --) {
        DNode *node = self.nodeList[i];
        if ([node.target isEqualToString:target]) {
            targetNode = node; break;
        }
    }
    return targetNode;
}

- (DNode *)nodeWithIdentifier:(NSString *)identifier
{
    DNode *targetNode = nil;
    if (!identifier || [identifier isEqual:NSNull.null]) {return targetNode;}
    for (NSInteger i = self.nodeList.count - 1; i >= 0; i --) {
        DNode *node = self.nodeList[i];
        if ([node.identifier isEqualToString:identifier]) {
            targetNode = node; break;
        }
    }
    return targetNode;
}

- (DNode *)nodeWithNode:(DNode *)messageNode
{
    DNode *targetNode = nil;
    if (!messageNode.target || [messageNode.target isEqual:NSNull.null]) {return targetNode;}
    for (NSInteger i = self.nodeList.count - 1; i >= 0; i --) {
        DNode *node = self.nodeList[i];
        if ([node.target isEqualToString:messageNode.target] &&
            [node.identifier isEqualToString:messageNode.identifier]) {
            targetNode = node; break;
        }
    }
    return targetNode;
}

- (BOOL)nativePopGestureCanReponse
{
    if (self.nodeList.count <= 1) {
        return YES;
    } else if (self.nodeList.count == 2) {
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

- (nullable NSArray<NSString *> *)logFiles
{
    if ([[DStack sharedInstance] debugMode]) {
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *temps = [manager contentsOfDirectoryAtPath:self.logFileDirectoryPath
                                                      error:nil];
        NSMutableArray *files = [[NSMutableArray alloc] init];
        for (NSString *file in temps) {
            if ([file hasSuffix:@"-debug.txt"]) {
                NSString *path = [NSString stringWithFormat:@"%@/%@", self.logFileDirectoryPath, file];
                [files addObject:path];
            }
        }
        return files;
    }
    return nil;
}

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
    [self operationNode:node];
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


#pragma mark -- getter

- (NSMutableArray<DNode *> *)nodeList
{
    if (!_nodeList) {
        _nodeList = [[NSMutableArray alloc] init];
        DNode *rootNode = [[DNode alloc] init];
        rootNode.target = @"/";
        rootNode.pageType = DNodePageTypeUnknow;
        rootNode.isRootPage = YES;
        [_nodeList addObject:rootNode];
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
    return self.nodeList.firstObject;
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
