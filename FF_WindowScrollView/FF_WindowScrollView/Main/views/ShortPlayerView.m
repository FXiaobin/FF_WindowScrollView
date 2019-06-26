//
//  ShortPlayerView.m
//  111
//
//  Created by mac on 2019/5/27.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import "ShortPlayerView.h"
#import <Masonry.h>
#import <UIImageView+WebCache.h>
#import <UIButton+WebCache.h>

@interface ShortPlayerView ()


@property (nonatomic,strong) UIButton *headerBtn;


@property (nonatomic,strong) UIButton *commentBtn;


@property (nonatomic,strong) UIButton *shareBtn;


@end

@implementation ShortPlayerView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)setShareCount:(NSString *)shareCount{
    [self.shareBtn setTitle:shareCount forState:UIControlStateNormal];
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        [self addSubview:self.titleLabel];
        [self addSubview:self.progressView];
        [self addSubview:self.playProgress];
        [self addSubview:self.headerBtn];
        [self addSubview:self.commentBtn];
        [self addSubview:self.shareBtn];
        [self addSubview:self.coverImgView];
        
        [self.coverImgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).insets(UIEdgeInsetsZero);
        }];
        
        
        CGFloat bottom = kSCALE(60.0) + kSafeAreaBottomHeight;
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.right.equalTo(self.mas_right);
            make.bottom.equalTo(self.mas_bottom).offset(-bottom);
            make.height.mas_equalTo(0.5);
        }];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(15.0);
            make.bottom.equalTo(self.progressView.mas_top).offset(kSCALE(-50.0));
            make.width.mas_lessThanOrEqualTo(kSCALE(560.0));
        }];
    
        [self.playProgress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.centerY.equalTo(self.progressView);
            make.height.mas_equalTo(1.0);
            make.width.mas_equalTo(0.0);
        }];
        
        [self.shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.mas_right).offset(kSCALE(-30.0));
            make.bottom.equalTo(self.progressView.mas_top).offset(kSCALE(-50.0));
            make.width.and.height.mas_equalTo(kSCALE(120.0));
        }];
        
        [self.commentBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.shareBtn);
            make.bottom.equalTo(self.shareBtn.mas_top).offset(kSCALE(-50.0));
            make.width.and.height.mas_equalTo(kSCALE(120.0));
        }];
        
        [self.headerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.commentBtn);
            make.bottom.equalTo(self.commentBtn.mas_top).offset(kSCALE(-50.0));
            make.width.and.height.mas_equalTo(kSCALE(120.0));
        }];
        
    }
    return self;
}

-(void)btnAction:(UIButton *)sender{
    NSInteger index = sender.tag - 400;
    
    if (self.btnActionBlock) {
        self.btnActionBlock(self.model, index, sender);
    }
    
}

-(instancetype)init{
    if (self = [super init]) {
        [self addSubview:self.titleLabel];
        
    }
    return self;
}





-(void)setModel:(ShortVideoModel *)model{
    _model = model;
    NSString *text = [NSString stringWithFormat:@"@%@\n%@",model.author.user_name ?: @"",model.title ?: @""];
    self.titleLabel.text = text;
    [_coverImgView sd_setImageWithURL:[NSURL URLWithString:model.thumbnail_url]];
    _coverImgView.hidden = NO;

    if ([model.author.portrait hasPrefix:@"http"]) {
       [self.headerBtn sd_setImageWithURL:[NSURL URLWithString:model.author.portrait] forState:UIControlStateNormal];
    }else{
        [self.headerBtn setImage:[UIImage imageNamed:@"userImage_home"] forState:UIControlStateNormal];
    }
    
    [self.commentBtn setTitle:[NSString stringWithFormat:@"%@",model.comment_num ?: @"0"] forState:UIControlStateNormal];
    [self.shareBtn setTitle:[NSString stringWithFormat:@"%@",model.share_num ?: @"0"] forState:UIControlStateNormal];

    [self.commentBtn setImagePositionWithType:SSImagePositionTypeTop spacing:kSCALE(10.0)];
    [self.shareBtn setImagePositionWithType:SSImagePositionTypeTop spacing:kSCALE(10.0)];
}


-(UILabel *)titleLabel{
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc] init];
        //_titleLabel.backgroundColor = [UIColor redColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 3;
    }
    return _titleLabel;
}

-(UIImageView *)coverImgView{
    if (_coverImgView == nil) {
        _coverImgView = [[UIImageView alloc] init];
    }
    return _coverImgView;
}

-(UIProgressView *)progressView{
    if (_progressView == nil) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.trackTintColor = [UIColor grayColor];
        _progressView.progressTintColor = [UIColor grayColor];
        _progressView.hidden = YES;
    }
    return _progressView;
}

-(UIView *)playProgress{
    if (_playProgress == nil) {
        _playProgress = [UIView new];
        _playProgress.backgroundColor = [UIColor whiteColor];
        _playProgress.hidden = YES;
    }
    return _playProgress;
}

    
-(UIButton *)headerBtn{
    if (_headerBtn == nil) {
        _headerBtn = [[UIButton alloc] init];
        [_headerBtn setImage:[UIImage imageNamed:@"userImage_home"] forState:UIControlStateNormal];
        [_headerBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _headerBtn.tag = 400;
        _headerBtn.clipsToBounds = YES;
        _headerBtn.layer.cornerRadius = kSCALE(60.0);
        _headerBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        _headerBtn.layer.borderWidth = kSCALE(5.0);
    }
    return _headerBtn;
}

-(UIButton *)commentBtn{
    if (_commentBtn == nil) {
        _commentBtn = [[UIButton alloc] init];
        [_commentBtn setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
        _commentBtn.titleLabel.font = kFont(kSCALE(26.0));
        [_commentBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _commentBtn.tag = 401;
        [_commentBtn setImage:[UIImage imageNamed:@"ShortVideo_01"] forState:UIControlStateNormal];
    }
    return _commentBtn;
}

-(UIButton *)shareBtn{
    if (_shareBtn == nil) {
        _shareBtn = [[UIButton alloc] init];
        _shareBtn.titleLabel.font = kFont(kSCALE(26.0));
        [_shareBtn setImage:[UIImage imageNamed:@"ShortVideo_02"] forState:UIControlStateNormal];
        [_shareBtn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
        _shareBtn.tag = 402;
    }
    return _shareBtn;
}

@end
