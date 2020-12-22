//
//  HomeViewController.m
//  Runner
//
//  Created by TAL on 2020/2/11.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

#import "HomeViewController.h"

@interface HomeViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UILabel *titleView;

@end

@implementation HomeViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.titleView];
    [self.view addSubview:self.tableView];
    [self setNavigationTitle];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self dataSource] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.textColor = [UIColor blackColor];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.backgroundColor = [UIColor whiteColor];
    NSDictionary *data = self.dataSource[indexPath.row];
    cell.textLabel.text = data[@"text"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *data = self.dataSource[indexPath.row];
    void (^block)(UIViewController *) = data[@"clicked"];
    if (block) {
        block(self);
    }
}

- (void)setNavigationTitle
{
    self.titleView.text = NSStringFromClass(self.class);
}

- (NSArray *)dataSource
{
    return self.testCase.homeTestCases;
}


- (UITableView *)tableView
{
    if (!_tableView) {
        CGFloat bottom = self.titleView.frame.size.height;
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, bottom, self.view.frame.size.width, self.view.frame.size.height - bottom)];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 60;
        _tableView.backgroundColor = [UIColor whiteColor];
    }
    return _tableView;
}

- (UILabel *)titleView
{
    if (!_titleView) {
        CGFloat height = [UIApplication sharedApplication].statusBarFrame.size.height + 44;
        _titleView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, height)];
        _titleView.textAlignment = NSTextAlignmentCenter;
        _titleView.backgroundColor = [UIColor orangeColor];
    }
    return _titleView;
}

- (DStackTestCase *)testCase
{
    if (!_testCase) {
        _testCase = [[DStackTestCase alloc] init];
    }
    return _testCase;
}

- (void)dealloc
{
    NSLog(@"dealloc ==> %@", NSStringFromClass(self.class));
}
    
@end
