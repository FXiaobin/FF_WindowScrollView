//
//  ShortVideoScrollView.m
//  FF_WindowScrollView
//
//  Created by mac on 2019/6/21.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import "ShortVideoScrollView.h"
#import "ShortPlayerView.h"
#import "ShortVideoModel.h"
#import <PLPlayerKit/PLPlayerKit.h>

#import "ShortVideoListCell.h"

@interface ShortVideoScrollView ()<UIScrollViewDelegate,PLPlayerDelegate>

@property (nonatomic,strong) UIScrollView *scrollView;

@property (nonatomic,strong) UIButton *closeBtn;

@property (nonatomic,strong) NSMutableArray *videos;

@property (nonatomic, strong) ShortPlayerView      *topView;   // 顶部视图
@property (nonatomic, strong) ShortPlayerView      *ctrView;   // 中间视图
@property (nonatomic, strong) ShortPlayerView      *btmView;   // 底部视图

@property (nonatomic,strong) PLPlayer *player;
//暂停/播放图片
@property (nonatomic,strong) UIImageView *playStatuIcon;
@property (nonatomic,assign) BOOL isLoadSuccess;

@end

@implementation ShortVideoScrollView

-(void)queryData{
    
    NSString *fileName = [NSString stringWithFormat:@"video%zd", self.currentPage];
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    
    NSData *jsonData = [NSData dataWithContentsOfFile:videoPath];
    
    if (!jsonData) {
        [self.scrollView.mj_header endRefreshing];
        [self.scrollView.mj_footer endRefreshing];
        [self.scrollView.mj_footer endRefreshingWithNoMoreData];
        
        //如果加载不到数据就播放最后一个
        [self updateModels:@[] index:self.currentPlayIndex];
        
        return;
    }
    
    if (self.currentPage == 1) {
        [self.videos removeAllObjects];
    }
    
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    NSArray *videoList = dic[@"data"][@"video_list"];
    
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *dict in videoList) {
        ShortVideoModel *model = [ShortVideoModel mj_objectWithKeyValues:dict];
        [array addObject:model];
    }
    
    if (array.count == 0) {
        [self.scrollView.mj_footer endRefreshingWithNoMoreData];
    }else{
        self.currentPage++;
    }
    
    [self showHUD];
    self.isLoadSuccess = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isLoadSuccess = YES;
        
        //倒数第一个时加载
        ///这里只是获取数据 不播放数据 数据会在滚动的时候播放
        if (self.videos.count == 0) {   //第一页

        }else {
            [self updateModels:array index:self.currentPlayIndex];
        }

        [self.scrollView.mj_header endRefreshing];
        [self.scrollView.mj_footer endRefreshing];
        [self hiddenHUD];
    });
    
}

-(instancetype)init{
    if (self = [super init]) {
        self.frame = [UIScreen mainScreen].bounds;
        ///self.backgroundColor = [UIColor blackColor];
        
        [self addSubview:self.scrollView];
        [self addSubview:self.closeBtn];
        [self addSubview:self.coverIcon];
        
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsZero);
        }];
        
//        __weak typeof(self) weakSelf = self;
//        self.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//            weakSelf.currentPage = 1;
//
//            [weakSelf queryData];
//        }];
       
        self.isLoadSuccess = YES;
       
     
    }
    return self;
}

- (void)makeUIWithVideos:(NSArray *)videos{
    
    if (videos.count == 1) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame), kHeight );
    }else if (videos.count == 2) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame), kHeight * 2);
    }else if (videos.count > 2) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame), kHeight * 3);
    }
    
    for (int i = 0; i < 3; i++) {
        
        if ( i == 0) {
            self.topView.frame = CGRectMake(0, 0, kWidth, kHeight);
            self.topView.backgroundColor = [UIColor purpleColor];
            [self.scrollView addSubview:self.topView];
            
        }else if (i == 1){
            self.ctrView.frame = CGRectMake(0, kHeight, kWidth, kHeight);
            self.ctrView.backgroundColor = [UIColor yellowColor];
            [self.scrollView addSubview:self.ctrView];
            
        }else if (i == 2){
            self.btmView.frame = CGRectMake(0, kHeight * 2, kWidth, kHeight);
            self.btmView.backgroundColor = [UIColor cyanColor];
            [self.scrollView addSubview:self.btmView];
        }
    }
    
    [self setModels:videos index:self.index];
}

#pragma mark - Btn Action
-(void)closeBtnAction:(UIButton *)sender{
    
   // [self removeFromSuperview];
    
    if (self.dismissBlock) {
        self.dismissBlock(self, self.currentPlayerView.model);
    }
}

-(void)dismissViewController:(UIButton *)sender{
    [self removeVideo];
    if (self.dismissBlock) {
        self.dismissBlock(self,self.currentPlayerView.model);
    }
}

-(void)playOrPausePlayerTap:(UITapGestureRecognizer *)ges{
    
    if (self.player.status == PLPlayerStatusPaused) {
        [self.player resume];
        self.playStatuIcon.hidden = YES;
        
    }else{
        [self.player pause];
        self.playStatuIcon.hidden = NO;
    }
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
//    if (self.currentPlayIndex == 0 && scrollView.contentOffset.y < 0) {
//        self.scrollView.contentOffset = CGPointZero;
//    }
    
    // 小于等于三个，不用处理
    if (self.videos.count <= 3) return;
    
    // 上滑到第一个
    if (self.index == 0 && scrollView.contentOffset.y <= kHeight) {
        return;
    }
    
    // 下滑到最后一个
    if (self.index == self.videos.count - 1 && scrollView.contentOffset.y > kHeight) {
        return;
    }
    
    // 判断是从中间视图上滑还是下滑
    if (scrollView.contentOffset.y >= 2 * kHeight) {  // 上滑
        [self removeVideo];  // 在这里移除播放，解决闪动的bug
        
        if (self.index == 0) {
            self.index += 2;
            
            scrollView.contentOffset = CGPointMake(0, kHeight);
            self.topView.model = self.ctrView.model;
            self.ctrView.model = self.btmView.model;
            
        }else {
            self.index += 1;
            
            if (self.index == self.videos.count - 1) {
                self.ctrView.model = self.videos[self.index - 1];
                
                if (self.isNeedLoadMore) {
                    ///用来加载下一页数据 不用底部刷新控件了 滑到最后一个时就开始加载下一页数据
                    // 当播放索引为最后一个时才会触发下拉刷新
                    //[self removeVideo];
                    
                    self.currentPlayIndex = self.videos.count - 1;
                    [self queryData];
                }
                
            }else {
                scrollView.contentOffset = CGPointMake(0, kHeight);
                
                self.topView.model = self.ctrView.model;
                self.ctrView.model = self.btmView.model;
                
            }
        }
        
        if (self.index < self.videos.count - 1) {
            self.btmView.model = self.videos[self.index+1];
        }
        
    }else if (scrollView.contentOffset.y <= 0) { // 下滑
        [self removeVideo];  // 在这里移除播放，解决闪动的bug
        if (self.index == 1) {
            
            self.topView.model = self.videos[self.index-1];
            self.ctrView.model = self.videos[self.index];
            self.btmView.model = self.videos[self.index+1];
            
            self.index -= 1;
            
        }else {
            
            if (self.index == self.videos.count - 1) {
                self.index -= 2;
                
            }else {
                self.index -= 1;
            }
            
            scrollView.contentOffset = CGPointMake(0, kHeight);
            
            self.btmView.model = self.ctrView.model;
            self.ctrView.model = self.topView.model;
            
            if (self.index > 0) {
                self.topView.model = self.videos[self.index-1];
            }
        }
    }
    
}

// 结束滚动后开始播放
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if (scrollView.contentOffset.y == 0) {
        if (self.currentPlayId == self.topView.model.post_id) return;
        
        [self playPlayerWithCurrentView:self.topView];
        
    }else if (scrollView.contentOffset.y == kHeight) {
        if (self.currentPlayId == self.ctrView.model.post_id) return;
        
        [self playPlayerWithCurrentView:self.ctrView];
        
    }else if (scrollView.contentOffset.y == 2 * kHeight) {
        if (self.currentPlayId == self.btmView.model.post_id) return;
        
        ///预加载处理 最后一个的时候先不播放 等请求到下页数据后再播放当前的
        if (!self.isLoadSuccess) {
            [self removeVideo];
            return;
        }

        [self playPlayerWithCurrentView:self.btmView];
    }
}

-(void)removeVideo{
    [self.player stop];
    [self.player.playerView removeFromSuperview];
    ///因为在视频播放的时候会隐藏当前的封面 所以在滑动播放上一个或者下一个视频的时候 需要把当前这个视频的封面再显示出来 然后去播放其他的视频
    self.currentPlayerView.coverImgView.hidden = NO;
    self.player.delegate = nil;
    self.player = nil;
    [self progressShow:NO];
}

-(void)playPlayerWithCurrentView:(ShortPlayerView *)playerView{
    [self showHUD];
    
    ShortVideoModel *model = playerView.model;
    
    ///从其他视图上c移除后重新添加到新的视图上
    [self removeVideo];
    
    [playerView addSubview: self.player.playerView];
    [playerView insertSubview:self.player.playerView atIndex:0];
    
    [self.player.playerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(playerView).insets(UIEdgeInsetsZero);
    }];
    
    [self.player.launchView sd_setImageWithURL:[NSURL URLWithString:model.thumbnail_url]];
    [self.coverIcon sd_setImageWithURL:[NSURL URLWithString:model.thumbnail_url]];
    
    //预加载
    BOOL isOpen = [self.player openPlayerWithURL:[NSURL URLWithString:model.video_url]];
    playerView.coverImgView.hidden = isOpen;
    
    [self.player playWithURL:[NSURL URLWithString:model.video_url] sameSource:NO];
    ///NSLog(@" ---- ret = %d -- ",ret);
    [self.player play];
    
    
    self.currentPlayId = playerView.model.post_id;
    self.currentPlayIndex = [self indexOfModel:playerView.model];
    self.currentPlayerView = playerView;
    
    [self progressShow:YES];
}

#pragma mark - Public Methods
- (void)progressShow:(BOOL)show{
    self.currentPlayerView.progressView.hidden = !show;
    self.currentPlayerView.playProgress.hidden = !show;
}

// 获取当前播放内容的索引
- (NSInteger)indexOfModel:(ShortVideoModel *)model {
    __block NSInteger index = 0;
    [self.videos enumerateObjectsUsingBlock:^(ShortVideoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.post_id isEqualToString:obj.post_id]) {
            index = idx;
        }
    }];
    return index;
}

///点击cell 第一次进入滚动页面 只调用这个一次 后面的用下面的更新方法
- (void)setModels:(NSArray *)models index:(NSInteger)index {
    
    [self.videos addObjectsFromArray:models];
    
    self.index = index;
    self.currentPlayIndex = index;
    
    if (models.count == 0) return;
    
    if (self.videos.count == 1) {
        [self.ctrView removeFromSuperview];
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, kHeight);
        
        self.topView.hidden = NO;
        self.topView.model = self.videos.firstObject;
        ///[self playVideoFrom:self.topView];
        
        [self playPlayerWithCurrentView:self.topView];
        
    }else if (self.videos.count == 2) {
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, kHeight * 2);
        
        self.topView.hidden = NO;
        self.ctrView.hidden = NO;
        self.topView.model  = self.videos.firstObject;
        self.ctrView.model  = self.videos.lastObject;
        
        if (index == 1) {
            self.scrollView.contentOffset = CGPointMake(0, kHeight);
            [self playPlayerWithCurrentView:self.ctrView];
            
        }else {
            [self playPlayerWithCurrentView:self.topView];
        }
    }else {
        self.topView.hidden = NO;
        self.ctrView.hidden = NO;
        self.btmView.hidden = NO;
        
        if (index == 0) {   // 如果是第一个，则显示上视图，且预加载中下视图
            self.topView.model = self.videos[index];
            self.ctrView.model = self.videos[index + 1];
            self.btmView.model = self.videos[index + 2];
            
            // 播放第一个
            [self playPlayerWithCurrentView:self.topView];
            
            ///index == models.count - 1
        }else if (index == self.videos.count - 1) { // 如果是最后一个，则显示最后视图，且预加载前两个
            self.btmView.model = self.videos[index];
            self.ctrView.model = self.videos[index - 1];
            self.topView.model = self.videos[index - 2];
            
            // 显示最后一个
            self.scrollView.contentOffset = CGPointMake(0, kHeight * 2);
            // 播放最后一个
            ///[self playVideoFrom:self.btmView];
            [self playPlayerWithCurrentView:self.btmView];
            
        }else { // 显示中间，播放中间，预加载上下
            self.ctrView.model = self.videos[index];
            self.topView.model = self.videos[index - 1];
            self.btmView.model = self.videos[index + 1];
            
            // 显示中间
            self.scrollView.contentOffset = CGPointMake(0, kHeight);
            // 播放中间
            ///[self playVideoFrom:self.ctrView];
            [self playPlayerWithCurrentView:self.ctrView];
        }
        
        if (index == self.videos.count - 1 && self.isNeedLoadMore) {
            //说明点击的是最后一个 那么就需要就加载下一页了
            [self removeVideo];
            self.btmView.model = self.videos[index];
            [self queryData];
        }
    }
}

///请求数据后更新播放当前短视频
- (void)updateModels:(NSArray *)models index:(NSInteger)index {
    
    [self.videos addObjectsFromArray:models];
    
    self.index = index;
    self.currentPlayIndex = index;
    
    if (self.videos.count == 0) return;
    
    if (self.videos.count == 1) {
        [self.ctrView removeFromSuperview];
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, kHeight);
        
        self.topView.hidden = NO;
        self.topView.model = self.videos.firstObject;
        ///[self playVideoFrom:self.topView];
        
        [self playPlayerWithCurrentView:self.topView];
        
    }else if (self.videos.count == 2) {
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, kHeight * 2);
        
        self.topView.hidden = NO;
        self.ctrView.hidden = NO;
        self.topView.model  = self.videos.firstObject;
        self.ctrView.model  = self.videos.lastObject;
        
        if (index == 1) {
            self.scrollView.contentOffset = CGPointMake(0, kHeight);
            [self playPlayerWithCurrentView:self.ctrView];
            
        }else {
            [self playPlayerWithCurrentView:self.topView];
        }
    }else {
        self.topView.hidden = NO;
        self.ctrView.hidden = NO;
        self.btmView.hidden = NO;
        
        if (index == 0) {   // 如果是第一个，则显示上视图，且预加载中下视图
            self.topView.model = self.videos[index];
            self.ctrView.model = self.videos[index + 1];
            self.btmView.model = self.videos[index + 2];
            
            // 播放第一个
            [self playPlayerWithCurrentView:self.topView];
            
        }else if (index == self.videos.count - 1) { // 如果是最后一个，则显示最后视图，且预加载前两个
            self.btmView.model = self.videos[index];
            self.ctrView.model = self.videos[index - 1];
            self.topView.model = self.videos[index - 2];
            
            // 显示最后一个
            self.scrollView.contentOffset = CGPointMake(0, kHeight * 2);
            // 播放最后一个
            [self playPlayerWithCurrentView:self.btmView];
            
        }else { // 显示中间，播放中间，预加载上下
            self.ctrView.model = self.videos[index];
            self.topView.model = self.videos[index - 1];
            self.btmView.model = self.videos[index + 1];
            
            // 显示中间
            self.scrollView.contentOffset = CGPointMake(0, kHeight);
            // 播放中间
            [self playPlayerWithCurrentView:self.ctrView];
        }
        
    }
}


#pragma mark - <PLPlayerDelegate>
// 计算缓冲进度
- (void)player:(nonnull PLPlayer *)player loadedTimeRange:(CMTime)timeRange{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        float startSeconds = 0;
        float durationSeconds = CMTimeGetSeconds(timeRange);
        CGFloat totalDuration = CMTimeGetSeconds(self.player.totalDuration);
        CGFloat progress = (durationSeconds - startSeconds) / totalDuration;
        
        self.currentPlayerView.progressView.progress = progress;
    });
    
}

- (void)player:(nonnull PLPlayer *)player statusDidChange:(PLPlayerStatus)state{
    self.playStatuIcon.hidden = YES;
    
    if (state == PLPlayerStatusPlaying && self.isLoadSuccess) {
        [self hiddenHUD];
    }else if (state == PLPlayerStatusCaching || state == PLPlayerStatusStopped){
        [self showHUD];
    }else if (state == PLPlayerStatusPaused){
        self.playStatuIcon.hidden = NO;
    }
}

- (void)player:(nonnull PLPlayer *)player willRenderFrame:(nullable CVPixelBufferRef)frame pts:(int64_t)pts sarNumerator:(int)sarNumerator sarDenominator:(int)sarDenominator{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat currentTime = CMTimeGetSeconds(player.currentTime) + 0.55;
        float totalDuration = CMTimeGetSeconds(player.totalDuration);
        
        if (totalDuration <= 0.0) { //分母不能为0
            return ;
        }
        float rate = currentTime / totalDuration * 1.0;
        
        CGFloat w = rate * [UIScreen mainScreen].bounds.size.width;
        
        [self.currentPlayerView.playProgress mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(w);
        }];
        
        [UIView animateWithDuration:0.2 animations:^{
            [self.currentPlayerView layoutIfNeeded];
        }];
        
    });
    
}

-(NSString *)timeGetWithSecond:(NSInteger)second{
    NSInteger h = 0, m = 0, s = 0;
    h = second / 3600;
    m = (second % 3600) / 60;
    s = second  % 60;
    
    NSString *text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld",(long)h,(long)m,(long)s];
    
    return text;
}

#pragma mark - show

-(void)showHUD{
    [self hiddenHUD];
    [MBProgressHUD showHUDAddedTo:self animated:YES];
}

-(void)hiddenHUD{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self];
    [hud hideAnimated:YES];
    //[MBProgressHUD hideHUDForView:self animated:YES];
}

+(void)showScrollViewInShowViewController:(UIViewController *)showViewController visibleCells:(NSArray *)visibleCells currentCell:(UIView *)currentCell currentCellModel:(ShortVideoModel *)model cellSuperView:(UIView *)cellSuperView currentIndex:(NSInteger)index currentPage:(NSInteger)currentPage videos:(NSArray *)videos isNeedLoadMore:(BOOL)isNeedLoadMore{
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGRect itemRect = [cellSuperView convertRect:currentCell.frame toView:window];
    CGRect screenRect = [UIScreen mainScreen].bounds;
    
    ///可见cell对应坐标位置
    NSMutableArray *rects = [NSMutableArray new];
    for (ShortVideoListCell *cell in visibleCells) {
        CGRect rect = [cellSuperView convertRect:cell.frame toView:window];
        NSValue *rectValue = [NSValue valueWithCGRect:rect];
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:rectValue forKey:cell.model.post_id];
        [rects addObject:dic];
    }

    
    ShortVideoScrollView *showView = [ShortVideoScrollView new];
    showView.isNeedLoadMore = isNeedLoadMore;
    showView.model = model;
    showView.index = index;
    showView.currentPage = currentPage;
    showView.currentPlayId = model.post_id;
    showView.currentPlayIndex = index;
    //showView.coverIcon.image = cell.coverIcon.image;
    [showView.coverIcon sd_setImageWithURL:[NSURL URLWithString:model.thumbnail_url]];
    
    [showView makeUIWithVideos:videos];
   
    [window addSubview:showView];
    
    
    showView.coverIcon.frame = itemRect;
    showView.scrollView.hidden = YES;
    showView.coverIcon.hidden = NO;
    
    ///弹性动画
//    [UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//        showView.coverIcon.frame = screenRect;
//
//    } completion:^(BOOL finished) {
//        showView.coverIcon.hidden = YES;
//        showView.scrollView.hidden = NO;
//    }];
    
    ///非弹性动画
    [UIView animateWithDuration:0.25 animations:^{
        showView.coverIcon.frame = screenRect;

    } completion:^(BOOL finished) {
        showView.coverIcon.hidden = YES;
        showView.scrollView.hidden = NO;
         //做完动画以后将背景颜色换为黑色 因为当滑到第一个和最后一个的时候再滑到屏幕外面的时候如果没有黑色背景就会看到下面的列表
        showView.backgroundColor = [UIColor blackColor];
    }];
    
     //__weak typeof(self) weakSelf = self;
    showView.dismissBlock = ^(ShortVideoScrollView *aView,ShortVideoModel *currentModel) {
        //消失的时候再重置为透明色
        aView.backgroundColor = [UIColor clearColor];
        
        CGRect currentItemRect = itemRect;
        
        ///查找当前播放视频cell对应的坐标 找到就结束找到的做动画消失 找不到直接消失
        BOOL isCanFindCell = NO;
        for (NSDictionary *d in rects) {
            
            if (d[currentModel.post_id]) {
                NSValue *rectV = d[currentModel.post_id];
                currentItemRect = rectV.CGRectValue;
                isCanFindCell = YES;
                break;  //找到以后就可以结束了
            }else{
                isCanFindCell = NO;
            }
        }
        
       [aView removeVideo];
    
        aView.coverIcon.hidden = NO;
        aView.coverIcon.frame = screenRect;
        aView.currentPlayerView.alpha = 0.0;
        aView.coverIcon.alpha = 1.0;
        
        //找到 - 动画， 没找到 - 直接隐藏
        //        if (isCanFindCell) {
        //            [UIView animateWithDuration:0.3 animations:^{
        //                aVC.coverIcon.frame = currentItemRect;
        //                //aVC.coverIcon.alpha = 0.0; //这句不要
        //
        //            } completion:^(BOOL finished) {
        //                aVC.coverIcon.hidden = YES;
        //                [aVC.view removeFromSuperview];
        //            }];
        //
        //        }else{
        //            aVC.coverIcon.hidden = YES;
        //            [aVC.view removeFromSuperview];
        //        }
        
        
        //没找到默认让它移动到屏幕外面的左下角
        if (!isCanFindCell) {
            currentItemRect = CGRectMake(0, CGRectGetHeight([UIScreen mainScreen].bounds), CGRectGetWidth(currentItemRect), CGRectGetHeight(currentItemRect));
        }
        
        ///弹性动画
//        [UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseInOut animations:^{
//            aView.coverIcon.frame = currentItemRect;
//
//        } completion:^(BOOL finished) {
//            aView.coverIcon.hidden = YES;
//            [aView removeVideo];
//            [aView removeFromSuperview];
//        }];
        
        ///非弹性动画
        [UIView animateWithDuration:0.3 animations:^{
            aView.coverIcon.frame = currentItemRect;
            //aVC.coverIcon.alpha = 0.0; //这句不要

        } completion:^(BOOL finished) {
            aView.coverIcon.hidden = YES;
            [aView removeVideo];
            [aView removeFromSuperview];
        }];
        
    };
    
}

#pragma mark - Lazy
-(UIScrollView *)scrollView{
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _scrollView.pagingEnabled = YES;
        _scrollView.delegate = self;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }
    }
    return _scrollView;
}

-(UIButton *)closeBtn{
    if (_closeBtn == nil) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, 20, 40, 40)];
        [_closeBtn setImage:[UIImage imageNamed:@"ShortVideo_06"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(closeBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

- (ShortPlayerView *)topView {
    if (!_topView) {
        _topView = [[ShortPlayerView alloc] initWithFrame:CGRectZero];
        //_topView.hidden = YES;
    }
    return _topView;
}

- (ShortPlayerView *)ctrView {
    if (!_ctrView) {
        _ctrView = [[ShortPlayerView alloc] initWithFrame:CGRectZero];
        //_ctrView.hidden = YES;
    }
    return _ctrView;
}

- (ShortPlayerView *)btmView {
    if (!_btmView) {
        _btmView = [[ShortPlayerView alloc] initWithFrame:CGRectZero];
        //_btmView.hidden = YES;
    }
    return _btmView;
}

-(PLPlayer *)player{
    if (_player == nil) {
        _player = [PLPlayer playerWithURL:nil option:nil];
        _player.autoReconnectEnable = YES;  //开启重连
        _player.loopPlay = YES; //循环播放
        _player.delegate = self;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playOrPausePlayerTap:)];
        _player.playerView.userInteractionEnabled = YES;
        [_player.playerView addGestureRecognizer:tap];
        
        [_player.playerView addSubview:self.playStatuIcon];
        [self.playStatuIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self->_player.playerView);
            make.width.and.height.mas_equalTo(60.0);
        }];
    }
    return _player;
}

-(UIImageView *)playStatuIcon{
    if (_playStatuIcon == nil) {
        _playStatuIcon = [UIImageView new];
        _playStatuIcon.image = [UIImage imageNamed:@"playBtnActionImage"];
        _playStatuIcon.hidden = YES;
    }
    return _playStatuIcon;
}

-(UIImageView *)coverIcon{
    if (_coverIcon == nil) {
        _coverIcon = [UIImageView new];
        _coverIcon.hidden = YES;
    }
    return _coverIcon;
}

- (NSMutableArray *)videos {
    if (!_videos) {
        _videos = [NSMutableArray new];
    }
    return _videos;
}

@end
