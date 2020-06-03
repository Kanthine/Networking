//
//  ItemListTableController.m
//  Networking
//
//  Created by 苏沫离 on 2020/6/2.
//  Copyright © 2020 苏沫离. All rights reserved.
//
#define CellIdentifer @"UITableViewCell"

#import "ItemListTableController.h"
#import "URLSessionManager.h"

@interface ItemListTableController ()
@property (nonatomic ,strong) NSArray<NSString *> *titleArray;
@end

@implementation ItemListTableController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.sectionFooterHeight = 0.01f;
    self.tableView.sectionHeaderHeight = 30.0f;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifer];
    [self.tableView registerClass:[UITableViewHeaderFooterView class] forHeaderFooterViewReuseIdentifier:@"UITableViewHeaderFooterView"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0){
        return 10;
    }else if (section == 1){
        return 2;
    }else if (section == 2){
        return 2;
    }
    return self.titleArray.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"UITableViewHeaderFooterView"];
    if (section == 0){
        headerView.textLabel.text = @"session Block回调";
    }else if (section == 1){
        headerView.textLabel.text = @"session 代理";
    }else if (section == 2){
        headerView.textLabel.text = @"session 上传下载";
    }
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifer forIndexPath:indexPath];
    if (indexPath.section == 0){
        if (indexPath.row == 0){
            cell.textLabel.text = @"创建alloc Session获取get请求";
        }else if (indexPath.row == 1){
            cell.textLabel.text = @"创建sharedSession获取get请求";
        }else if (indexPath.row == 2){
            cell.textLabel.text = @"创建Configuration获取get请求";
        }else if (indexPath.row == 3){
            cell.textLabel.text = @"创建DelegateQueue获取get请求";
        }else if (indexPath.row == 4){
            cell.textLabel.text = @"创建alloc Session获取post请求";
        }else if (indexPath.row == 5){
            cell.textLabel.text = @"创建sharedSession获取post请求";
        }else if (indexPath.row == 6){
            cell.textLabel.text = @"创建Configuration获取post请求";
        }else if (indexPath.row == 7){
            cell.textLabel.text = @"创建DelegateQueue获取post请求";
        }else if (indexPath.row == 8){
            cell.textLabel.text = @"post请求 上传图片";
        }else if (indexPath.row == 9){
            cell.textLabel.text = @"get请求 下载图片";
        }
    }else if (indexPath.section == 1){
        if (indexPath.row == 0){
            cell.textLabel.text = @"get delegate";
        }else if (indexPath.row == 1){
            cell.textLabel.text = @"post delegate";
        }
    }else if (indexPath.section == 2){
        if (indexPath.row == 0){
            cell.textLabel.text = @"上传";
        }else if (indexPath.row == 1){
            cell.textLabel.text = @"下载";
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0){
        if (indexPath.row == 0)
        {
            [URLSessionManager getBlockByAlloc];
        }else if (indexPath.row == 1){
            [URLSessionManager getBlockBySharedSession];
        }else if (indexPath.row == 2){
            [URLSessionManager getBlockByConfiguration];
        }else if (indexPath.row == 3){
            [URLSessionManager getBlockByDelegateQueue];
        }else if (indexPath.row == 4)
        {
            [URLSessionManager postBlockByAlloc];
        }else if (indexPath.row == 5){
            [URLSessionManager postBlockBySharedSession];
        }else if (indexPath.row == 6){
            [URLSessionManager postBlockByConfiguration];
        }else if (indexPath.row == 7){
            [URLSessionManager postBlockByDelegateQueue];
        }else if (indexPath.row == 8){
            [URLSessionManager postBlockUpload];
        }else if (indexPath.row == 9){
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, CGRectGetWidth(UIScreen.mainScreen.bounds), CGRectGetWidth(UIScreen.mainScreen.bounds))];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            [URLSessionManager getBlockDownLoadFile:^(NSString * _Nonnull filePath) {
                
                NSData *data = [NSData dataWithContentsOfFile:filePath];
                imageView.image = [UIImage imageWithData:data];
                [self.view addSubview:imageView];
                [self performSelector:@selector(removeImageView:) withObject:imageView afterDelay:2.5];
            }];
        }
    }else if (indexPath.section == 1){
        if (indexPath.row == 0){
            [URLSessionManager getDelegateMethod];
        }else if (indexPath.row == 1){
            [URLSessionManager postDelegateMethod];
        }
    }else if (indexPath.section == 2){
        
    }
}

- (void)removeImageView:(UIImageView *)imageView{
    [imageView removeFromSuperview];
    imageView = nil;
}

#pragma mark - Getters And Setters

- (NSArray<NSString *> *)titleArray{
    if (_titleArray == nil){
        _titleArray = @[@"GET Block",@"POST Block",@"GET Delegate",@"POST Delegate",@"Upload",@"download"];
    }
    return _titleArray;
}


@end

