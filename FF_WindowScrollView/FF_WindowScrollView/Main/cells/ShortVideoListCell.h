//
//  ShortVideoListCell.h
//  111
//
//  Created by mac on 2019/5/28.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShortVideoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShortVideoListCell : UICollectionViewCell


@property (nonatomic,strong) UIImageView *coverIcon;


@property (nonatomic,strong) UILabel *titleLabel;


@property (nonatomic,strong) ShortVideoModel *model;


@end

NS_ASSUME_NONNULL_END
