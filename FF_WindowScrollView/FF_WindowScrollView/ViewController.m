//
//  ViewController.m
//  FF_WindowScrollView
//
//  Created by mac on 2019/6/21.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import "ViewController.h"

#import "ShortVideoListViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = @"短视频";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:nil action:nil];
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 30)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:btn];
    
    
}

-(void)btnAction{
    
    ShortVideoListViewController *vc = [ShortVideoListViewController new];
    [self.navigationController pushViewController:vc animated:YES];
    
}

@end
