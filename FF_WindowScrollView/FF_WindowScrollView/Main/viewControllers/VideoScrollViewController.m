//
//  VideoScrollViewController.m
//  FF_WindowScrollView
//
//  Created by mac on 2019/6/24.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import "VideoScrollViewController.h"

#import "ShortPlayerView.h"

#import "ShortVideoModel.h"
#import "ShortVideoListCell.h"

#import <Masonry.h>
#import <MJRefresh.h>
#import <MJExtension/MJExtension.h>
#import <MBProgressHUD.h>

#import <UIImageView+WebCache.h>
#import <PLPlayerKit/PLPlayerKit.h>

#define SCREEN_HEIGHT   [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width

@interface VideoScrollViewController ()<UIScrollViewDelegate,PLPlayerDelegate>


//暂停/播放图片
@property (nonatomic,strong) UIImageView *playStatuIcon;

@property (nonatomic,strong) NSMutableArray *videos;

@property (nonatomic, strong) ShortPlayerView      *topView;   // 顶部视图
@property (nonatomic, strong) ShortPlayerView      *ctrView;   // 中间视图
@property (nonatomic, strong) ShortPlayerView      *btmView;   // 底部视图



@property (nonatomic,strong) PLPlayer *player;


@property (nonatomic,strong) UIButton *closeBtn;

@property (nonatomic,assign) BOOL isLoadSuccess;


@property (nonatomic,strong) UIView *maskBg;


@end

@implementation VideoScrollViewController

-(void)queryData{
    
    NSString *fileName = [NSString stringWithFormat:@"video%zd", self.currentPage];
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    
    NSData *jsonData = [NSData dataWithContentsOfFile:videoPath];
    
    if (!jsonData) {
        [self.scrollView.mj_header endRefreshing];
        [self.scrollView.mj_footer endRefreshing];
        [self.scrollView.mj_footer endRefreshingWithNoMoreData];
        
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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.isLoadSuccess = YES;
        
        //倒数第一个时加载
        ///这里只是获取数据 不播放数据 数据会在滚动的时候播放
        if (self.videos.count == 0) {   //第一页
            //[self setModels:array index:0];
        }else {
            // [self resetModels:array];
            [self updateModels:array index:self.currentPlayIndex];
        }
        
        //倒数第二个去加载
        // [self resetModels:array];
        
        [self.scrollView.mj_header endRefreshing];
        [self.scrollView.mj_footer endRefreshing];
        [self hiddenHUD];
    });
    
    
    
}

#pragma mark - Public Methods

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
    
    if (self.videos.count == 0) return;
    
    if (self.videos.count == 1) {
        [self.ctrView removeFromSuperview];
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, SCREEN_HEIGHT);
        
        self.topView.hidden = NO;
        self.topView.model = self.videos.firstObject;
        ///[self playVideoFrom:self.topView];
        
        [self playPlayerWithCurrentView:self.topView];
        
    }else if (self.videos.count == 2) {
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, SCREEN_HEIGHT * 2);
        
        self.topView.hidden = NO;
        self.ctrView.hidden = NO;
        self.topView.model  = self.videos.firstObject;
        self.ctrView.model  = self.videos.lastObject;
        
        if (index == 1) {
            self.scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
            /// [self playVideoFrom:self.ctrView];
            [self playPlayerWithCurrentView:self.ctrView];
            
        }else {
            /// [self playVideoFrom:self.topView];
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
            /// [self playVideoFrom:self.topView];
            [self playPlayerWithCurrentView:self.topView];
            
            ///index == models.count - 1
        }else if (index == self.videos.count - 1) { // 如果是最后一个，则显示最后视图，且预加载前两个
            self.btmView.model = self.videos[index];
            self.ctrView.model = self.videos[index - 1];
            self.topView.model = self.videos[index - 2];
            
            // 显示最后一个
            self.scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT * 2);
            // 播放最后一个
            ///[self playVideoFrom:self.btmView];
            [self playPlayerWithCurrentView:self.btmView];
            
        }else { // 显示中间，播放中间，预加载上下
            self.ctrView.model = self.videos[index];
            self.topView.model = self.videos[index - 1];
            self.btmView.model = self.videos[index + 1];
            
            // 显示中间
            self.scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
            // 播放中间
            ///[self playVideoFrom:self.ctrView];
            [self playPlayerWithCurrentView:self.ctrView];
        }
        
        if (index == self.videos.count - 1 && self.isNeedLoadMore) {
            //说明点击的是最后一个 那么就需要就加载下一页了
            [self removeVideo];
            self.btmView.model = self.videos[index];
            [self queryData];
            //return;
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
        
        self.scrollView.contentSize = CGSizeMake(0, SCREEN_HEIGHT);
        
        self.topView.hidden = NO;
        self.topView.model = self.videos.firstObject;
        ///[self playVideoFrom:self.topView];
        
        [self playPlayerWithCurrentView:self.topView];
        
    }else if (self.videos.count == 2) {
        [self.btmView removeFromSuperview];
        
        self.scrollView.contentSize = CGSizeMake(0, SCREEN_HEIGHT * 2);
        
        self.topView.hidden = NO;
        self.ctrView.hidden = NO;
        self.topView.model  = self.videos.firstObject;
        self.ctrView.model  = self.videos.lastObject;
        
        if (index == 1) {
            self.scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
            
            /// [self playVideoFrom:self.ctrView];
            [self playPlayerWithCurrentView:self.ctrView];
            
        }else {
            /// [self playVideoFrom:self.topView];
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
            /// [self playVideoFrom:self.topView];
            [self playPlayerWithCurrentView:self.topView];
            
            ///index == models.count - 1
        }else if (index == self.videos.count - 1) { // 如果是最后一个，则显示最后视图，且预加载前两个
            self.btmView.model = self.videos[index];
            self.ctrView.model = self.videos[index - 1];
            self.topView.model = self.videos[index - 2];
            
            // 显示最后一个
            self.scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT * 2);
            // 播放最后一个
            ///[self playVideoFrom:self.btmView];
            [self playPlayerWithCurrentView:self.btmView];
            
        }else { // 显示中间，播放中间，预加载上下
            self.ctrView.model = self.videos[index];
            self.topView.model = self.videos[index - 1];
            self.btmView.model = self.videos[index + 1];
            
            // 显示中间
            self.scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
            // 播放中间
            ///[self playVideoFrom:self.ctrView];
            [self playPlayerWithCurrentView:self.ctrView];
        }
        
    }
}

- (void)resetModels:(NSArray *)models {
    [self.videos addObjectsFromArray:models];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    ///默认是yes
    self.isLoadSuccess = YES;
    ////self.currentPage = 1;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.pagingEnabled = YES;
    //self.scrollView.bounces = NO;
    self.scrollView.delegate = self;
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        // Fallback on earlier versions
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    [self.view addSubview:self.scrollView];
    
//    __weak typeof(self) weakSelf = self;
//    self.scrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
//        weakSelf.currentPage = 1;
//
//        [weakSelf queryData];
//    }];
    
    
    //    self.scrollView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
    //        // 当播放索引为最后一个时才会触发下拉刷新
    //        weakSelf.currentPlayIndex = weakSelf.videos.count - 1;
    //
    //        [weakSelf queryData];
    //    }];
    
    //    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
    //        // 当播放索引为最后一个时才会触发下拉刷新
    //        weakSelf.currentPlayIndex = weakSelf.videos.count - 1;
    //        [weakSelf queryData];
    //    }];
    //    // footer.stateLabel.hidden = YES;
    //    footer.refreshingTitleHidden = YES;
    //    footer.ignoredScrollViewContentInsetBottom = YES;
    //
    //    self.scrollView.mj_footer = footer;
    
    
    if (self.videos.count == 1) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), SCREEN_HEIGHT );
    }else if (self.videos.count == 2) {
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), SCREEN_HEIGHT * 2);
    }else{
        self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), SCREEN_HEIGHT * 3);
    }
    
    for (int i = 0; i < 3; i++) {
        
        if ( i == 0) {
            self.topView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.topView.backgroundColor = [UIColor purpleColor];
            [self.scrollView addSubview:self.topView];
            
        }else if (i == 1){
            self.ctrView.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.ctrView.backgroundColor = [UIColor yellowColor];
            [self.scrollView addSubview:self.ctrView];
            
        }else if (i == 2){
            self.btmView.frame = CGRectMake(0, SCREEN_HEIGHT * 2, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.btmView.backgroundColor = [UIColor cyanColor];
            [self.scrollView addSubview:self.btmView];
        }
    }
    
    //    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViewController:)];
    //    [self.view addGestureRecognizer:tap];
    
    [self setModels:self.videosArr index:self.index];
    
    [self.view addSubview:self.coverIcon];
    
    
    [self.view addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(30);
        make.left.equalTo(self.view).offset(20);
        make.width.and.height.mas_equalTo(40);
    }];
    
    
//    self.topView.btnActionBlock = ^(ShortVideoModel * _Nonnull model, NSInteger tag) {
//        if (tag == 0) {
//
//        }else if (tag == 1) {
//            CommentsViewController *vc = [[CommentsViewController alloc] init];
//            [weakSelf.parentViewController presentViewController:vc animated:NO completion:nil];
//
//        }else if (tag == 2) {
//
//
//        }
//    };
//
//
//    self.ctrView.btnActionBlock = ^(ShortVideoModel * _Nonnull model, NSInteger tag) {
//        if (tag == 0) {
//
//        }else if (tag == 1) {
//            CommentsViewController *vc = [[CommentsViewController alloc] init];
//            [weakSelf.parentViewController.navigationController presentViewController:vc animated:NO completion:nil];
//
//        }else if (tag == 2) {
//
//
//        }
//    };
//
//    self.btmView.btnActionBlock = ^(ShortVideoModel * _Nonnull model, NSInteger tag) {
//        if (tag == 0) {
//
//        }else if (tag == 1) {
//            CommentsViewController *vc = [[CommentsViewController alloc] init];
//            [weakSelf.parentViewController presentViewController:vc animated:NO completion:nil];
//
//        }else if (tag == 2) {
//
//
//        }
//    };
    
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    ///抖音刷新
    //    if (self.currentPlayIndex == 0 && scrollView.contentOffset.y < 0) {
    //        self.scrollView.contentOffset = CGPointZero;
    //    }
    
    // 小于等于三个，不用处理
    if (self.videos.count <= 3) return;
    
    // 上滑到第一个
    if (self.index == 0 && scrollView.contentOffset.y <= SCREEN_HEIGHT) {
        return;
    }
    
    // 下滑到最后一个
    if (self.index == self.videos.count - 1 && scrollView.contentOffset.y > SCREEN_HEIGHT) {
        return;
    }
    
    // 判断是从中间视图上滑还是下滑
    if (scrollView.contentOffset.y >= 2 * SCREEN_HEIGHT) {  // 上滑
        [self removeVideo];  // 在这里移除播放，解决闪动的bug
        
        if (self.index == 0) {
            self.index += 2;
            
            scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
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
                scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
                
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
            
            scrollView.contentOffset = CGPointMake(0, SCREEN_HEIGHT);
            
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
        
    }else if (scrollView.contentOffset.y == SCREEN_HEIGHT) {
        if (self.currentPlayId == self.ctrView.model.post_id) return;
        
        [self playPlayerWithCurrentView:self.ctrView];
        
    }else if (scrollView.contentOffset.y == 2 * SCREEN_HEIGHT) {
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

#pragma mark - show

-(void)showHUD{
    [self hiddenHUD];
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
}

-(void)hiddenHUD{
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    [hud hideAnimated:YES];
    //[MBProgressHUD hideHUDForView:self.view animated:YES];
}

+(void)showScrollViewInShowViewController:(UIViewController *)showViewController visibleCells:(NSArray *)visibleCells currentCell:(UIView *)currentCell currentCellModel:(ShortVideoModel *)model cellSuperView:(UIView *)cellSuperView currentIndex:(NSInteger)index currentPage:(NSInteger)currentPage videos:(NSArray *)videos isNeedLoadMore:(BOOL)isNeedLoadMore dismissCompleteBlock:(void(^)(void))block{
  
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
    
    VideoScrollViewController *vc = [VideoScrollViewController new];
    vc.isNeedLoadMore = isNeedLoadMore;
    vc.model = model;
    vc.index = index;
    vc.currentPage = currentPage;
    vc.currentPlayId = model.post_id;
    vc.currentPlayIndex = index;
    vc.videosArr = videos;
    //vc.coverIcon.image = cell.coverIcon.image;
    [vc.coverIcon sd_setImageWithURL:[NSURL URLWithString:model.thumbnail_url]];
    
    ///如果想要在弹出的时候是黑底 可景这个视图默认颜色设为黑色 并在消失的时候移除就行了
    //[showViewController.view addSubview:vc.maskBg];
    
    [showViewController addChildViewController:vc];
    [showViewController.view addSubview:vc.view];
    [showViewController.navigationController setNavigationBarHidden:YES animated:YES];
    
    vc.coverIcon.frame = itemRect;
    
    vc.scrollView.hidden = YES;
    vc.coverIcon.hidden = NO;
    vc.view.backgroundColor = [UIColor clearColor];
    
    [UIView animateWithDuration:0.3 animations:^{
        vc.coverIcon.frame = screenRect;
        
    } completion:^(BOOL finished) {
        vc.coverIcon.hidden = YES;
        vc.scrollView.hidden = NO;
        //做完动画以后将背景颜色换为黑色 因为当滑到第一个和最后一个的时候再滑到屏幕外面的时候如果没有黑色背景就会看到下面的列表
        vc.view.backgroundColor = [UIColor blackColor];
    }];
    
    vc.dismissBlock = ^(VideoScrollViewController *aVC,ShortVideoModel *currentModel) {
        
        aVC.view.backgroundColor = [UIColor clearColor];
        
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
        
        [showViewController.navigationController setNavigationBarHidden:NO animated:YES];
        
        [aVC removeVideo];
        
        aVC.coverIcon.hidden = NO;
        aVC.coverIcon.frame = screenRect;
        aVC.currentPlayerView.alpha = 0.0;
        
        aVC.coverIcon.alpha = 1.0;
        
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
        
        [UIView animateWithDuration:0.3 animations:^{
            aVC.coverIcon.frame = currentItemRect;
            //aVC.coverIcon.alpha = 0.0; //这句不要
            
        } completion:^(BOOL finished) {
            aVC.coverIcon.hidden = YES;
            [aVC removeVideo];
            [aVC.view removeFromSuperview];
        }];
        
        
        if (block) {
            block();
        }
        
    };
    
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

- (void)progressShow:(BOOL)show{
    self.currentPlayerView.progressView.hidden = !show;
    self.currentPlayerView.playProgress.hidden = !show;
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

- (NSMutableArray *)videos {
    if (!_videos) {
        _videos = [NSMutableArray new];
    }
    return _videos;
}

-(UIImageView *)coverIcon{
    if (_coverIcon == nil) {
        _coverIcon = [UIImageView new];
        _coverIcon.hidden = YES;
    }
    return _coverIcon;
}

-(UIView *)maskBg{
    if (_maskBg == nil) {
        _maskBg = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _maskBg.backgroundColor = [UIColor clearColor];
    }
    return _maskBg;
}

-(UIButton *)closeBtn{
    if (_closeBtn == nil) {
        _closeBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_closeBtn setImage:[UIImage imageNamed:@"ShortVideo_06"] forState:UIControlStateNormal];
        [_closeBtn addTarget:self action:@selector(dismissViewController:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
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


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
