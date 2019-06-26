//
//  ShortPlayerView.h
//  111
//
//  Created by mac on 2019/5/27.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShortVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShortPlayerView : UIView

@property (nonatomic,copy) NSString *shareCount;


@property (nonatomic,strong) UIImageView *coverImgView;

@property (nonatomic,strong) UILabel *titleLabel;
//缓冲进度
@property (nonatomic,strong) UIProgressView *progressView;
//播放进度
@property (nonatomic,strong) UIView *playProgress;


@property (nonatomic,strong) ShortVideoModel *model;

@property (nonatomic,copy) void (^btnActionBlock) (ShortVideoModel *model, NSInteger tag, UIButton *sender);

@end

NS_ASSUME_NONNULL_END
