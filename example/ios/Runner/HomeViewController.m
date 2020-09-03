//
//  HomeViewController.m
//  Runner
//
//  Created by TAL on 2020/2/11.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "HomeViewController.h"
#import "SecondViewController.h"
#import <DStack.h>

@interface HomeViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray *testCases;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HomeViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.closeButton.hidden = !self.showCloseButton;
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.testCases = @[
        @"打开新的NATIVE页面",
        @"打开新的Flutter页面",
    ];
}

- (IBAction)close:(UIButton *)sender
{
    if (self.navigationController.viewControllers.count <= 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.testCases.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.textLabel.text = self.testCases[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 1:
        {
            [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
                                                               route:@"page1"];
            
//            [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
//                                                               route:@"page1"
//                                                              params:@{@"fromNative": @"来自原生"}];
            
//            [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
//                                                               route:@"page1"
//                                                              params:@{@"fromNative": @"来自原生"}
//                                                            animated:NO];
            
//            [[DStack sharedInstance] pushFlutterPageWithFlutterClass:DFlutterViewController.class
//                                                               route:@"page1"
//                                                              params:@{@"fromNative": @"来自原生"}
//                                                  controllerCallBack:^(DFlutterViewController *flutterViewController) {
//                NSLog(@"flutterViewController === %@", flutterViewController);
//            }
//                                                            animated:YES];
//
            break;
        }
        case 0:
        {
            SecondViewController *secondVC = [[SecondViewController alloc] init];
            [self.navigationController pushViewController:secondVC animated:YES];
            break;
        }
        default:
            break;
    }
}

    
@end
