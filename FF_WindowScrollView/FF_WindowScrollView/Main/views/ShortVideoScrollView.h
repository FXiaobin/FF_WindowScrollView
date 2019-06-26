//
//  ShortVideoScrollView.h
//  FF_WindowScrollView
//
//  Created by mac on 2019/6/21.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShortPlayerView.h"
#import "ShortVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

/*
 *  以UIView子类为载体的短视频滚动播放
 */


@interface ShortVideoScrollView : UIView

///第一次弹出滚动视图时的数据数组
- (void)makeUIWithVideos:(NSArray *)videos;



@property (nonatomic,strong) ShortVideoModel *model;

@property (nonatomic,strong) UIImageView *coverIcon;

//当前页面视图
@property (nonatomic,strong) ShortPlayerView *currentPlayerView;

// 控制播放的索引，不完全等于当前播放内容的索引
@property (nonatomic,assign) NSInteger index;

// 当前播放内容是h索引
@property (nonatomic, assign) NSInteger                 currentPlayIndex;

// 记录播放内容
@property (nonatomic, copy) NSString                    *currentPlayId;

@property (nonatomic,assign) NSInteger currentPage;

///上下滑到显示的时候是否需要请求后面的数据 默认不需要请求
@property (nonatomic,assign) BOOL isNeedLoadMore;

@property (nonatomic,copy) void (^dismissBlock) (ShortVideoScrollView *aView,ShortVideoModel *currentModel);


-(void)removeVideo;

+(void)showScrollViewInShowViewController:(UIViewController *)showViewController visibleCells:(NSArray *)visibleCells currentCell:(UIView *)currentCell currentCellModel:(ShortVideoModel *)model cellSuperView:(UIView *)cellSuperView currentIndex:(NSInteger)index currentPage:(NSInteger)currentPage videos:(NSArray *)videos isNeedLoadMore:(BOOL)isNeedLoadMore;

@end

NS_ASSUME_NONNULL_END
