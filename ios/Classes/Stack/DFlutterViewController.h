//
//  DFlutterViewController.h
//  
//
//  Created by TAL on 2020/1/16.
//

#import <UIKit/UIKit.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// 当需要打开一个Flutter页面时，必须是DFlutterViewController或者是它的子类
@interface DFlutterViewController : FlutterViewController

- (void)willUpdateView;
- (void)didUpdateView;
- (void)updateCurrentNode:(id)node;
- (id)currentNode;

@end

NS_ASSUME_NONNULL_END

