//
//  VideoPlayerViewController.m
//  MD360Player4iOS
//
//  Created by ashqal on 16/5/21.
//  Copyright © 2016年 ashqal. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import "MDVRLibrary.h"

@interface CustomDirectorFactory : NSObject<MD360DirectorFactory>
@end

@implementation CustomDirectorFactory

- (MD360Director*) createDirector:(int) index{
    MD360Director* director = [[MD360Director alloc]init];
    switch (index) {
        case 1:
            [director setEyeX:-2.0f];
            [director setLookX:-2.0f];
            break;
        default:
            break;
    }
    return director;
}

@end

@interface VideoPlayerViewController ()<VIMVideoPlayerDelegate>{
    BOOL _played;
    NSString *_totalTime;
    NSDateFormatter *_dateFormatter;
}
@property (nonatomic, strong) VIMVideoPlayer *player;
//@property (nonatomic, strong) AVPlayer* avplayer;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic ,weak) IBOutlet UIButton *stateButton;
@property (nonatomic ,weak) IBOutlet UISlider *videoSlider;
@property (nonatomic ,weak) IBOutlet UIProgressView *videoProgress;
@property (nonatomic ,strong) id playbackTimeObserver;

- (IBAction)stateButtonTouched:(UIButton *)sender forEvent:(UIEvent *)event;
- (IBAction)videoSlierChangeValue:(UISlider *)sender forEvent:(UIEvent *)event;
- (IBAction)videoSlierChangeValueEnd:(UISlider *)sender forEvent:(UIEvent *)event;

@end

@implementation VideoPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) onClosed{
    [self.player reset];
}

- (void) initPlayer{
    // video player
    
    
    self.player = [[VIMVideoPlayer alloc] init];

    
    self.playerItem = [AVPlayerItem playerItemWithURL:self.mURL];
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
    [self.player setPlayerItem:self.playerItem];
    
    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    
//    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:self.mURL];
//    [self.player setPlayerItem:playerItem];
//    self.player.delegate = self;
    
    /////////////////////////////////////////////////////// MDVRLibrary
    MDVRConfiguration* config = [MDVRLibrary createConfig];
    
    [config asVideo:self.playerItem];
    [config setContainer:self view:self.view];
    
    // optional
    [config projectionMode:MDModeProjectionStereoSphere];
    [config displayMode:MDModeDisplayNormal];
    [config interactiveMode:MDModeInteractiveTouch];
    [config pinchEnabled:true];
    [config setDirectorFactory:[[CustomDirectorFactory alloc]init]];
    
    self.vrLibrary = [config build];
    /////////////////////////////////////////////////////// MDVRLibrary
    
    
    //播放
    //[self.player play];
}

// KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
            self.stateButton.enabled = YES;
            CMTime duration = self.playerItem.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTime = [self convertTime:totalSecond];// 转换成播放时间
            [self customVideoSlider:duration];// 自定义UISlider外观
            NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
            [self monitoringPlayback:self.playerItem];// 监听播放状态
        } else if ([playerItem status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        NSLog(@"Time Interval:%f",timeInterval);
        CMTime duration = _playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.videoProgress setProgress:timeInterval / totalDuration animated:YES];
    }
}

// 监听播放状态
- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.player.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        [weakSelf.videoSlider setValue:currentSecond animated:YES];
    }];
}

// 计算缓冲进度
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[self.player.player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

// 自定义UISlider外观
- (void)customVideoSlider:(CMTime)duration {
    self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

// 转换成播放时间
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}
- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

//视频播放完成回调
- (void)moviePlayDidEnd:(NSNotification *)notification {
    NSLog(@"Play end");
    
    __weak typeof(self) weakSelf = self;
    [self.player.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.videoSlider setValue:0.0 animated:YES];
        [weakSelf.stateButton setTitle:@"Play" forState:UIControlStateNormal];
    }];
}

- (IBAction)stateButtonTouched:(UIButton *)sender forEvent:(UIEvent *)event
{
    if (!_played) {
        [self.player play];
        [self.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [self.player pause];
        [self.stateButton setTitle:@"Play" forState:UIControlStateNormal];
    }
    _played = !_played;
}

- (IBAction)videoSlierChangeValue:(UISlider *)sender forEvent:(UIEvent *)event
{
    UISlider *slider = (UISlider *)sender;
    NSLog(@"value change:%f",slider.value);
    
    if (slider.value == 0.000000) {
        __weak typeof(self) weakSelf = self;
        [self.player.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf.player play];
        }];
    }
}

- (IBAction)videoSlierChangeValueEnd:(UISlider *)sender forEvent:(UIEvent *)event
{
    UISlider *slider = (UISlider *)sender;
    NSLog(@"value end:%f",slider.value);
    CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
    
    __weak typeof(self) weakSelf = self;
    [self.player.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf.player play];
        [weakSelf.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
    }];
}

- (void)updateVideoSlider:(CGFloat)currentSecond {
    [self.videoSlider setValue:currentSecond animated:YES];
}

- (void)dealloc {
    [self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
    [self.player.player removeTimeObserver:self.playbackTimeObserver];
}

@end
