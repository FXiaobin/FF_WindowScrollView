//
//  VideoScrollViewController.h
//  FF_WindowScrollView
//
//  Created by mac on 2019/6/24.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShortVideoModel.h"
#import "ShortPlayerView.h"

/*
 *  以控制器为载体的短视频f滚动播放
 */

NS_ASSUME_NONNULL_BEGIN

@interface VideoScrollViewController : UIViewController

@property (nonatomic,strong) UIScrollView *scrollView;

@property (nonatomic,strong) ShortVideoModel *model;


@property (nonatomic,strong) NSArray *videosArr;


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

@property (nonatomic,copy) void (^dismissBlock) (VideoScrollViewController *aVC,ShortVideoModel *currentModel);


-(void)removeVideo;


/*
 *  showViewController :    要显示在哪个控制器上面
 *  visibleCells :          需要定位坐标的cell视图数组
 *  currentCell ：           当前点击的这个cell
 *  model ：                 当前点击的这个cell对应的model
 *  cellSuperView ：         当前点击的这个cell的父视图
 *  index   ：               当前点击的这个cell的索引
 *  currentPage ：           showViewController拉取数据的当前页数
 *  videos ：                showViewController拉取数据的所有数据
 *  isNeedLoadMore ：        滚动是否需要再加载之后的数据 为NO时 currentPage不会使用 可默认传1
 *
 */

+(void)showScrollViewInShowViewController:(UIViewController *)showViewController visibleCells:(NSArray *)visibleCells currentCell:(UIView *)currentCell currentCellModel:(ShortVideoModel *)model cellSuperView:(UIView *)cellSuperView currentIndex:(NSInteger)index currentPage:(NSInteger)currentPage videos:(NSArray *)videos isNeedLoadMore:(BOOL)isNeedLoadMore dismissCompleteBlock:(void(^)(void))block;

@end

NS_ASSUME_NONNULL_END
