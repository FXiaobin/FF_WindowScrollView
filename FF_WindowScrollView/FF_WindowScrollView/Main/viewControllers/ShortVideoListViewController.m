//
//  ShortVideoListViewController.m
//  111
//
//  Created by mac on 2019/5/28.
//  Copyright © 2019 healifeGroup. All rights reserved.
//

#import "ShortVideoListViewController.h"
#import "ShortVideoModel.h"
#import "ShortVideoListCell.h"

#import <UIImageView+WebCache.h>
#import <MJRefresh.h>
#import <MJExtension/MJExtension.h>

///第1种方式
#import "ShortVideoScrollView.h"
///第2种方式
#import "VideoScrollViewController.h"

@interface ShortVideoListViewController ()<UICollectionViewDelegate,UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>


@property (nonatomic,strong) UICollectionView *collectionView;

@property (nonatomic,strong) NSMutableArray *videos;
@property (nonatomic,assign) NSInteger currentPage;

@end

@implementation ShortVideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"短视频";
    [self.view addSubview:self.collectionView];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.currentPage = 1;
    [self queryData];
    
}

-(void)queryData{
    
    NSString *fileName = [NSString stringWithFormat:@"video%zd", self.currentPage];
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"json"];
    
    NSData *jsonData = [NSData dataWithContentsOfFile:videoPath];
    
    if (!jsonData) {
        [self.collectionView.mj_header endRefreshing];
        [self.collectionView.mj_footer endRefreshing];
        [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        
        return;
    }
   
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    NSArray *videoList = dic[@"data"][@"video_list"];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (self.currentPage == 1) {
            [self.videos removeAllObjects];
        }
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSDictionary *dict in videoList) {
            ShortVideoModel *model = [ShortVideoModel mj_objectWithKeyValues:dict];
            [array addObject:model];
        }
        
        if (array.count == 0) {
            [self.collectionView.mj_footer endRefreshingWithNoMoreData];
        }else{
            self.currentPage++;
        }
        
        [self.videos addObjectsFromArray:array];
        
        [self.collectionView.mj_header endRefreshing];
        [self.collectionView.mj_footer endRefreshing];
        
        [self.collectionView reloadData];
    });

}



-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.videos.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ShortVideoListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ShortVideoListCell" forIndexPath:indexPath];
  
    ShortVideoModel *model = self.videos[indexPath.item];
    cell.model = model;
    
    
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    ShortVideoModel *model = self.videos[indexPath.item];
    CGFloat rate = model.thumbnail_height.floatValue / model.thumbnail_width.floatValue;
    CGFloat width = (CGRectGetWidth(self.view.bounds)-30) / 2.0;
    CGFloat height = width * rate;

    return CGSizeMake(width, height);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    ShortVideoModel *model = self.videos[indexPath.item];
    
    ShortVideoListCell *cell = (ShortVideoListCell *)[collectionView cellForItemAtIndexPath:indexPath];
   
    ///1. 以UIView为承载视图 添加到Window上 （不适用于点击某个按钮需要push或则present的操作）因为这个UIView是显示在window的最上层的
    //[ShortVideoScrollView showScrollViewInShowViewController:self visibleCells:collectionView.visibleCells currentCell:cell currentCellModel:model cellSuperView:collectionView currentIndex:indexPath.item currentPage:self.currentPage videos:self.videos isNeedLoadMore:YES];
    
    //2. 以UIViewController为承载 添加到当前视图所在的最底层的UIViewController的View上 可以进行push或则present的操作 但是要注意操作时导航条的隐藏和显示问题 （这种做法的会比上面的实现方法适用性更强 但比上面的方法会麻烦一点 要控制好导航条的隐藏和显示）
    [VideoScrollViewController showScrollViewInShowViewController:self visibleCells:collectionView.visibleCells currentCell:cell currentCellModel:model cellSuperView:collectionView currentIndex:indexPath.item currentPage:self.currentPage videos:self.videos isNeedLoadMore:YES dismissCompleteBlock:^{
        
    }];
}


-(UICollectionView *)collectionView{
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.minimumLineSpacing = 10;
        layout.minimumInteritemSpacing = 10;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
      
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.view.frame), [UIScreen mainScreen].bounds.size.height - 64) collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[ShortVideoListCell class] forCellWithReuseIdentifier:@"ShortVideoListCell"];
        
        __weak typeof(self) weakSelf = self;
        _collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
            weakSelf.currentPage = 1;
            [weakSelf queryData];
        }];
        
        
        MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
            [weakSelf queryData];
        }];
       // footer.stateLabel.hidden = YES;
        footer.refreshingTitleHidden = YES;
        footer.ignoredScrollViewContentInsetBottom = YES;
        
        _collectionView.mj_footer = footer;
        
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        
    }
    return _collectionView;
}

- (NSMutableArray *)videos {
    if (!_videos) {
        _videos = [NSMutableArray new];
    }
    return _videos;
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
