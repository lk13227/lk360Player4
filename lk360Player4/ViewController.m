//
//  ViewController.m
//  lk360Player4
//
//  Created by 888 on 16/9/2.
//  Copyright © 2016年 lk. All rights reserved.
//

#import "ViewController.h"

#import "VideoPlayerViewController.h"

@interface ViewController ()

//网址输入框
@property (weak, nonatomic) IBOutlet UITextField *urlTestField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
}

- (void)launchAsVideo:(NSURL*)url {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"VideoPlayer" bundle:nil];
    PlayerViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"VideoPlayerViewController"];
    
    [self presentViewController:vc animated:NO completion:^{
        [vc initParams:url];
    }];
}

#pragma mark - 播放本地视频
- (IBAction)playerLocalViedo:(UIButton *)sender
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"m4v"];
    // NSURL* url = [NSURL URLWithString:@"http://192.168.5.106/vr/stereo.mp4"];
    [self launchAsVideo:[NSURL fileURLWithPath:path]];
}

#pragma  mark - 播放网络视频
- (IBAction)playerSeverVideo:(UIButton *)sender
{
    NSString* url = self.urlTestField.text;
    [self launchAsVideo:[NSURL URLWithString:url]];
}



@end
