//
//  RepositoryContentTableVC.m
//  MrCode
//
//  Created by hao on 9/6/15.
//  Copyright (c) 2015 hao. All rights reserved.
//

#import "RepositoryContentTableVC.h"
#import "GITRepository.h"
#import "RepositoryContentTableViewCell.h"
#import "WebViewController.h"

@interface RepositoryContentTableVC ()

@property (nonatomic, strong) NSArray *contents;

@end

@implementation RepositoryContentTableVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = _repo.name;
    
    _contents = [NSArray array];
    
    [self.tableView registerClass:[RepositoryContentTableViewCell class]
           forCellReuseIdentifier:NSStringFromClass([RepositoryContentTableViewCell class])];
    
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = NSStringFromClass([RepositoryContentTableViewCell class]);
    RepositoryContentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    [cell configWithGitContent:_contents[indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GITRepositoryContent *content = _contents[indexPath.row];
    if ([content.type isEqualToString:@"dir"]) {

        // 方法1，在 IB 中看弹出自身 VC 的 segue 连线很晦涩隐秘，不算好办法
        [self performSegueWithIdentifier:@"ReposContent2Self" sender:content];
        
        // 方法2，单独创建的 VC 不是从 SB 中获取，没有 segue 可以拿到下一个 VC
//        RepositoryContentTableVC *controller = [[RepositoryContentTableVC alloc] init];
        
        // 方法3，而下面试图从 SB 中取得 VC 却报错，最终还是用
//        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        RepositoryContentTableVC *controller = [sb instantiateViewControllerWithIdentifier:@"ReposDetail2ReposContentTableVC"];
//        controller.repo = self.repo;
//        controller.path = [content apiPath];
//        controller.title = content.name;
//        [self.navigationController pushViewController:controller animated:YES];

    }
    else if ([content.type isEqualToString:@"file"]) {
        if ([content.name hasSuffix:@".md"]) {
            [self performSegueWithIdentifier:@"ReposContent2WebView" sender:content];
        }
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    NSLog(@"identifier=%@", identifier);
    
    // 因为这个 push 到自身 controller 是在 IB 拖 cell 连上的，所以不会触发 didSelectRowAtIndexPath，
    // 也就无法设置 sender，此时 sender 是被点击的 UITableViewCell，但因为在 IB 设置 segue 的是 BasicCell，
    // 而不是自定义的子类，所以 IB 中对 cell 设置的 selection 跳转没有生效，下面知识利用了 ReposContent2Self 这个 segue 标识
    // FIXME: 这种方式在 IB 那个连线太晦涩，改用 pushViewController 更直观。
    GITRepositoryContent *content = sender;
    if ([identifier isEqualToString:@"ReposContent2Self"]) {
        RepositoryContentTableVC *controller = (RepositoryContentTableVC *)segue.destinationViewController;
        controller.repo = self.repo;
        controller.path = [content apiPath];
        controller.title = content.name;
        NSLog(@"ReposContent2Self");
    }
    else if ([identifier isEqualToString:@"ReposContent2WebView"]) {
        GITRepositoryContent *content = sender;
        NSLog(@"begin load file data");
        [content fileOfPath:content.apiPath needRefresh:NO success:^(NSString *html) {
            WebViewController *controller = (WebViewController *)segue.destinationViewController;
            controller.htmlString = html;
            controller.title = content.name;
            [controller reloadWebView];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"error\n%@", error);
        }];
    }
}

- (void)loadData
{
    [_repo contentsOfPath:_path success:^(NSArray *array) {
        _contents = [array copy];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
}

@end
