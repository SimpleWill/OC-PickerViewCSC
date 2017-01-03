//
//  ViewController.m
//  YPPickerDemo
//
//  Created by BiuKia on 17/1/3.
//  Copyright © 2017年 personal. All rights reserved.
//

#import "ViewController.h"
#import "PickerView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem * right = [[UIBarButtonItem alloc]initWithTitle:@"options" style:UIBarButtonItemStylePlain target:self action:@selector(showOptions)];
    self.navigationItem.rightBarButtonItem = right;
}


-(void)showOptions{
    PickerView * picker1 = [PickerView showPickerAddTo:self.view withDataSource:@"city_json" dataType:0 fileSuffix:@"txt"];
    [picker1 show:^(NSDictionary *result) {
        NSLog(@"返回结果：%@",result);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
