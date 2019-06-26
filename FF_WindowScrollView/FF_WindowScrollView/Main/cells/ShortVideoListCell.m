//
//  ShortVideoListCell.m
//  111
//
//  Created by mac on 2019/5/28.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import "ShortVideoListCell.h"
#import <Masonry.h>
#import <UIImageView+WebCache.h>

@implementation ShortVideoListCell

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        self.backgroundColor = [UIColor whiteColor];
        
        [self.contentView addSubview:self.coverIcon];
        [self.contentView addSubview:self.titleLabel];
        
        [self.coverIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView).insets(UIEdgeInsetsZero);
        }];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.contentView);
            make.right.equalTo(self.contentView.mas_right);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-10);
        }];
        
    }
    return self;
}

-(void)setModel:(ShortVideoModel *)model{
    _model = model;
    self.titleLabel.text = model.title ?: @"";
    [self.coverIcon sd_setImageWithURL:[NSURL URLWithString:model.thumbnail_url]];
}


-(UILabel *)titleLabel{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 2;
    }
    return _titleLabel;
}

-(UIImageView *)coverIcon{
    if (_coverIcon == nil) {
        _coverIcon = [[UIImageView alloc] init];
        _coverIcon.backgroundColor = [UIColor lightGrayColor];
    }
    return _coverIcon;
}

@end
