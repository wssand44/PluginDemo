//
//  RootViewController.m
//  PluginDemo
//
//  Created by 王 松 on 14-2-13.
//
//

#import "RootViewController.h"
#import "MainViewController.h"

#import "AFNetworking.h"

#import "ZipArchive.h"

#import "MBProgressHUD.h"

#import <Cordova/PluginManager.h>

@interface RootViewController ()

@property (nonatomic, assign) NSInteger pluginCount;

@end

@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Plugin";
    
    self.pluginCount = 2;
    
    [self syncPluginCount];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashPlugins)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.pluginCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Plugin%d", indexPath.row + 1];
    
    return cell;
}

- (void)trashPlugins
{
    NSString *doc = [PluginManager pluginPath];
    
    [[NSFileManager defaultManager] removeItemAtPath:doc error:nil];
}

- (void)syncPluginCount
{
    AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
    
    AFHTTPRequestOperation *operation = [operationManager HTTPRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://song4you.sinaapp.com/plugin/"]] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *aStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        self.pluginCount = [aStr integerValue];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [[operationManager operationQueue] addOperation:operation];
}

- (void)downloadPluginsWithName:(NSString *)name atURL:(NSString *)url
{
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES].labelText = @"正在下载...";
    
    NSURL *serverURL = [NSURL URLWithString:url];
    
    NSString *resourcePath = [PluginManager pluginPath];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *nameWithSubfix = [NSString stringWithFormat:@"%@.zip", name];
    
    nameWithSubfix = [resourcePath stringByAppendingPathComponent:nameWithSubfix];
    
    AFHTTPRequestOperationManager *operationManager = [AFHTTPRequestOperationManager manager];
    
    AFHTTPRequestOperation *operation = [operationManager HTTPRequestOperationWithRequest:[NSURLRequest requestWithURL:serverURL] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        ZipArchive *zip = [[ZipArchive alloc] initWithFileManager:manager];
        zip.progressBlock = ^(int percentage, int filesProcessed, int numFiles) {
            if (percentage >= 100) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                    [manager removeItemAtPath:nameWithSubfix error:nil];
                    [self openPluginsWithName:name];
                });
            }
        };
        [zip UnzipOpenFile:nameWithSubfix];
        [zip UnzipFileTo:resourcePath overWrite:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
    }];
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:nameWithSubfix append:YES];
    
    [[operationManager operationQueue] addOperation:operation];
}

- (void)openPluginsWithName:(NSString *)name
{
    MainViewController *detailViewController = [[MainViewController alloc] init];
    detailViewController.title = name;
    detailViewController.wwwFolderName = name;
    [self.navigationController pushViewController:detailViewController animated:YES];
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *pluginName = [NSString stringWithFormat:@"plugin%d",indexPath.row + 1];
    
    NSString *resourcePath = [NSString stringWithUTF8String:[PluginManager pluginPathWithModule:pluginName]];
    
    if (![manager fileExistsAtPath:resourcePath]) {
        [self downloadPluginsWithName:pluginName atURL:[NSString stringWithFormat:@"http://song4you.sinaapp.com/?file=%@.zip", pluginName]];
    }else {
        [self openPluginsWithName:pluginName];
    }

}

@end
