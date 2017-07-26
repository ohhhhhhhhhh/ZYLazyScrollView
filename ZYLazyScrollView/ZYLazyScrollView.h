//
//  ZYLazyScrollView.h
//  ZYLazyScrollView
//
//  Created by zy on 2017/7/24.
//  Copyright © 2017年 zy. All rights reserved.
//

#import <UIKit/UIKit.h>

#define ZYDEFAULT_REUSE_IDENTIFIER @"reuseIdentifier"

@protocol ZYLazyScrollViewCellProtocol <NSObject>

@optional
- (void)zy_prepareForReuse;

- (void)zy_didEnterWithTimes:(NSUInteger)times;

- (void)zy_afterGetView;

@end


@interface UIView(ZYLazy)

@property (nonatomic, copy, nonnull) NSString * muiID;

@property (nonatomic, copy, nullable) NSString * reuseIdentifier;

- (nonnull instancetype)initWithFrame:(CGRect)frame
                      reuseIdentifier:(nullable NSString *)reuseIdentifier;

@end


@interface ZYRectModel : NSObject

@property (nonatomic, assign) CGRect absoluteRect;

@property (nonatomic, copy, nonnull) NSString * muiID;

@end


@class ZYLazyScrollView;
@protocol ZYLazyScrollViewDataSource <NSObject>

@required
// 0 default
- (NSInteger)numberOfItemInScrollView:(nonnull ZYLazyScrollView *)scrollView;

- (nonnull ZYRectModel *)scrollView:(nonnull ZYLazyScrollView *)scrollView
                   rectModelAtIndex:(NSUInteger)index;

- (nullable UIView *)scrollView:(nonnull ZYLazyScrollView *)scrollView
                       itemByID:(nonnull NSString *)muiID;

@end

@protocol ZYLazyScrollViewDelegate <NSObject,UIScrollViewDelegate>

@end

@interface ZYLazyScrollView : UIScrollView<NSCoding>

@property (nonatomic, weak, nullable) id<ZYLazyScrollViewDataSource> dataSource;

- (void)reloadData;

- (nullable UIView *)dequeReusableItemWithIdentifier:(nonnull NSString *)reuseIdentifier;

- (void)removeAllLayouts;

- (void)resetViewEnterTimes;

@end
