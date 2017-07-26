//
//  ZYLazyScrollView.m
//  ZYLazyScrollView
//
//  Created by zy on 2017/7/24.
//  Copyright © 2017年 zy. All rights reserved.
//

#define ZYRENDER_BUFFER_WINDOW   20.f

#import "ZYLazyScrollView.h"
#import <objc/runtime.h>

@implementation ZYRectModel

@end



@implementation UIView(ZYLazy)

-(instancetype)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier{
    
    self = [self initWithFrame:frame];
    if (self) {
        self.reuseIdentifier = reuseIdentifier;
    }
    return self;
}

-(NSString *)reuseIdentifier{
    
    NSString * reuse = objc_getAssociatedObject(self, @"reuseIdentifier");
    return reuse;
}

-(void)setReuseIdentifier:(NSString *)reuseIdentifier{
    
    objc_setAssociatedObject(self, @"reuseIdentifier", reuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)muiID{
    
    NSString * muiId = objc_getAssociatedObject(self, @"muiID");
    return muiId;
}

-(void)setMuiID:(NSString *)muiID{
    
    objc_setAssociatedObject(self, @"muiID", muiID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end



//@interface ZYLazyScrollViewObserver : NSObject
//
//@property (nonatomic, weak) ZYLazyScrollView * lazyScrollView;
//
//@end



@interface ZYLazyScrollView() <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) NSMutableSet * visibleItems;

@property (nonatomic, strong) NSMutableDictionary * recycledIdentifierItemsDic;

@property (nonatomic, strong) NSMutableArray * itemsFrames;

@property (nonatomic,   weak) id<ZYLazyScrollViewDelegate> lazyScrollViewDelegate;

@property (nonatomic, strong) NSArray * modelsSortedByTop;

@property (nonatomic, strong) NSArray * modelsDortedByBottom;

@property (nonatomic, strong) NSMutableSet * firstSet;

@property (nonatomic, strong) NSMutableSet * secondSet;

@property (nonatomic, assign) CGPoint lastScrollOffset;

@property (nonatomic,   copy) NSString * currentVisibleItemMuiID;

@property (nonatomic, strong) NSMutableSet * shouldReloadItems;

@property (nonatomic, strong) NSSet * muiIDOfVisibleViews;

@property (nonatomic, strong) NSMutableDictionary * enterDict;

@property (nonatomic, strong) NSMutableSet * lastVisibleMuiID;

@property (nonatomic, strong) NSMutableSet * inScreenVisibleItems;

@end

@implementation ZYLazyScrollView

-(NSMutableDictionary *)enterDict{
    
    if (!_enterDict) {
        _enterDict = [NSMutableDictionary dictionary];
    }
    return _enterDict;
}

-(NSMutableSet *)inScreenVisibleItems{
    
    if (!_inScreenVisibleItems) {
        _inScreenVisibleItems = [NSMutableSet set];
    }
    return _inScreenVisibleItems;
}

-(NSMutableSet *)shouldReloadItems{
    
    if (!_shouldReloadItems) {
        _shouldReloadItems = [NSMutableSet set];
    }
    return _shouldReloadItems;
}

-(NSArray *)modelsSortedByTop{
    
    if (!_modelsSortedByTop) {
        _modelsSortedByTop = [NSArray array];
    }
    return _modelsSortedByTop;
}

-(NSArray *)modelsDortedByBottom{
    
    if (!_modelsDortedByBottom) {
        _modelsDortedByBottom = [NSArray array];
    }
    return _modelsDortedByBottom;
}

-(void)setFrame:(CGRect)frame{
    
    if (!CGRectEqualToRect(frame, self.frame)) {
        
        [super setFrame:frame];
    }
}

-(instancetype)initWithFrame:(CGRect)frame{
    
    if (self = [super initWithFrame:frame]) {
        
        self.clipsToBounds                  = YES;
        self.autoresizesSubviews            = NO;
        self.showsVerticalScrollIndicator   = NO;
        self.showsHorizontalScrollIndicator = NO;
        _recycledIdentifierItemsDic = [NSMutableDictionary dictionary];
        _visibleItems = [NSMutableSet set];
        _itemsFrames  = [NSMutableArray array];
        _firstSet     = [[NSMutableSet alloc]initWithCapacity:30];
        _secondSet    = [[NSMutableSet alloc]initWithCapacity:30];
//        self.delegate = self;
        super.delegate = self;
    }
    return self;
}

-(void)dealloc{
    
    _dataSource = nil;
    self.delegate = nil;
    
    [_recycledIdentifierItemsDic removeAllObjects];
    _recycledIdentifierItemsDic = nil;
    
    [_visibleItems removeAllObjects];
    _visibleItems = nil;
    
    [_itemsFrames removeAllObjects];
    _itemsFrames = nil;
    
    [_firstSet removeAllObjects];
    _firstSet = nil;
    
    [_secondSet removeAllObjects];
    _secondSet = nil;
    
    _modelsSortedByTop = nil;
    _modelsDortedByBottom = nil;
}

-(void)setDelegate:(id<ZYLazyScrollViewDelegate>)delegate{
    
    if (!delegate) {
        
        [super setDelegate:nil];
        _lazyScrollViewDelegate = nil;
    }else{
        
        [super setDelegate:self];
        _lazyScrollViewDelegate = delegate;
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    CGFloat currentY = scrollView.contentOffset.y;
    CGFloat buffer   = ZYRENDER_BUFFER_WINDOW/2;
    if (buffer < ABS(currentY - self.lastScrollOffset.y)) {
        self.lastScrollOffset = scrollView.contentOffset;
        [self assembleSubviews];
        [self findViewsInVisibleRect];
    }
   
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidScroll:self];
    }
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidZoom:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidZoom:self];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
        
        [self.lazyScrollViewDelegate scrollViewWillBeginDragging:self];
    }
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
        
        [self.lazyScrollViewDelegate scrollViewWillEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidEndDragging:self willDecelerate:decelerate];
    }
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginDecelerating:)]) {
        
        [self.lazyScrollViewDelegate scrollViewWillBeginDecelerating:self];
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidEndDecelerating:self];
    }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndScrollingAnimation:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidEndScrollingAnimation:self];
    }
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)]) {
        
        [self.lazyScrollViewDelegate viewForZoomingInScrollView:self];
    }
    return nil;
}

-(void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)]) {
        
        [self.lazyScrollViewDelegate scrollViewWillBeginZooming:self withView:view];
    }
}

-(void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidEndZooming:self withView:view atScale:scale];
    }
}

-(BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewShouldScrollToTop:)]) {
        
        [self.lazyScrollViewDelegate scrollViewShouldScrollToTop:self];
    }
    return self.scrollsToTop;
}

-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView{
    
    if (self.lazyScrollViewDelegate &&
        [self.lazyScrollViewDelegate conformsToProtocol:@protocol(UIScrollViewDelegate)] &&
        [self.lazyScrollViewDelegate respondsToSelector:@selector(scrollViewDidScrollToTop:)]) {
        
        [self.lazyScrollViewDelegate scrollViewDidScrollToTop:self];
    }
}

- (NSUInteger)binarySearchForIndex:(NSArray *)frameArray
                          baseLine:(CGFloat)baseLine
                         isFromTop:(BOOL)isFromTop{
    
    NSInteger min = 0;
    NSInteger max = frameArray.count-1;
    NSInteger mid = ceil((CGFloat)(min+max)/2.f);
    while (mid > min && mid < max) {
        
        CGRect rect = [(ZYRectModel *)[frameArray objectAtIndex:mid] absoluteRect];
        
        if (isFromTop) {
            
            CGFloat itemTop = CGRectGetMinY(rect);
            if (itemTop <= baseLine) {
                CGRect nextItemRect = [(ZYRectModel *)[frameArray objectAtIndex:mid+1] absoluteRect];
                CGFloat nextItemTop = CGRectGetMinY(nextItemRect);
                if (nextItemTop > baseLine) {
                    mid++;
                    break;
                }
                min = mid;
            }else{
                max = mid;
            }
        }else{
            
            CGFloat itemBottom = CGRectGetMaxY(rect);
            if (itemBottom >= baseLine) {
                CGRect nextItemRect = [(ZYRectModel *)[frameArray objectAtIndex:mid+1] absoluteRect];
                CGFloat nextItemBottom = CGRectGetMaxY(nextItemRect);
                if (nextItemBottom < baseLine) {
                    
                    mid++;
                    break;
                }
                min = mid;
            }else{
                max = mid;
            }
        }
        mid = ceil((CGFloat)(min+max)/2.f);
    }
    return mid;
}

- (NSSet *)showingItemIndexSetFrom:(CGFloat)startY to:(CGFloat)endY{
    
    if (!_modelsSortedByTop || !_modelsDortedByBottom) {
        [self createScrollViewIndex];
    }
    NSUInteger endBottomIndex = [self binarySearchForIndex:self.modelsDortedByBottom baseLine:startY isFromTop:NO];
    [self.firstSet removeAllObjects];
    if(self.modelsDortedByBottom && self.modelsDortedByBottom.count > 0){
    
        for (NSUInteger i = 0; i <= endBottomIndex; i++) {
            ZYRectModel * model = [self.modelsDortedByBottom objectAtIndex:i];
            if (model) {
                [self.firstSet addObject:model.muiID];
            }
        }
    }
    
    NSUInteger endTopIndex = [self binarySearchForIndex:self.modelsSortedByTop baseLine:endY isFromTop:YES];
    [self.secondSet removeAllObjects];
    if (self.modelsSortedByTop && self.modelsSortedByTop.count > 0) {
        
        for (NSUInteger i = 0; i <= endTopIndex; i++) {
            
            ZYRectModel * model = [self.modelsSortedByTop objectAtIndex:i];
            if (model) {
                [self.secondSet addObject:model.muiID];
            }
        }
    }
    [self.firstSet intersectSet:self.secondSet];
    return [self.firstSet copy];
}


- (void)createScrollViewIndex{
    
    NSUInteger count = 0;
    [self.itemsFrames removeAllObjects];
    if(self.dataSource &&
       [self.dataSource conformsToProtocol:@protocol(ZYLazyScrollViewDataSource)] &&
       [self.dataSource respondsToSelector:@selector(numberOfItemInScrollView:)]){
    
        count = [self.dataSource numberOfItemInScrollView:self];
    }
    
    for (NSUInteger i = 0; i < count; i++) {
        
        ZYRectModel * rectModel;
        
        if (self.dataSource &&
            [self.dataSource conformsToProtocol:@protocol(ZYLazyScrollViewDataSource)] &&
            [self.dataSource respondsToSelector:@selector(scrollView:rectModelAtIndex:)]) {
            
            rectModel = [self.dataSource scrollView:self rectModelAtIndex:i];
            
            if (rectModel.muiID.length == 0) {
                rectModel.muiID = [NSString stringWithFormat:@"%ld",i];
            }
        }
        [self.itemsFrames addObject:rectModel];
    }
    
    self.modelsSortedByTop = [self.itemsFrames sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        CGRect rectA = [(ZYRectModel *)obj1 absoluteRect];
        CGRect rectB = [(ZYRectModel *)obj2 absoluteRect];
        
        if (rectA.origin.y < rectB.origin.y) {
            return NSOrderedAscending;
        }else if(rectA.origin.y > rectB.origin.y){
            return NSOrderedDescending;
        }else{
            return NSOrderedSame;
        }
    }];
    
    self.modelsDortedByBottom = [self.itemsFrames sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
        CGRect rectA = [(ZYRectModel *)obj1 absoluteRect];
        CGRect rectB = [(ZYRectModel *)obj2 absoluteRect];
        
        CGFloat bottomA = CGRectGetMaxY(rectA);
        CGFloat bottomB = CGRectGetMaxY(rectB);
        
        if (bottomA < bottomB) {
            return NSOrderedAscending;
        }else if(bottomA > bottomB){
            return NSOrderedDescending;
        }else{
            return NSOrderedSame;
        }
    }];
}

- (void)findViewsInVisibleRect{
    
    NSMutableSet * itemViewSet = [self.muiIDOfVisibleViews mutableCopy];
    [itemViewSet minusSet:self.lastVisibleMuiID];
    for (UIView * view in self.visibleItems) {
        if (view && [itemViewSet containsObject:view.muiID]) {
            
            if ([view conformsToProtocol:@protocol(ZYLazyScrollViewCellProtocol)] &&
                [view respondsToSelector:@selector(zy_didEnterWithTimes:)]) {
                
                NSUInteger times = 0;
                if ([_enterDict objectForKey:view.muiID] != nil) {
                    times = [[self.enterDict objectForKey:view.muiID] unsignedIntegerValue] +1;
                }
                NSNumber * showTimes = [NSNumber numberWithUnsignedInteger:times];
                [self.enterDict setObject:showTimes forKey:view.muiID];
                
                [(UIView<ZYLazyScrollViewCellProtocol> *)view zy_didEnterWithTimes:times];
            }
        }
    }
    
    self.lastVisibleMuiID = [self.muiIDOfVisibleViews copy];
}

-(void)assembleSubviews{
    CGRect visibleBounds = self.bounds;
    CGFloat minY = CGRectGetMinY(visibleBounds) - ZYRENDER_BUFFER_WINDOW;
    CGFloat maxY = CGRectGetMaxY(visibleBounds) + ZYRENDER_BUFFER_WINDOW;
    [self assembleSubViewsForReload:NO minY:minY maxY:maxY];
}

- (void)assembleSubViewsForReload:(BOOL)isReload minY:(CGFloat)minY maxY:(CGFloat)maxY{
    
    NSSet * itemShouldShowSet = [self showingItemIndexSetFrom:minY to:maxY];
    self.muiIDOfVisibleViews  = [self showingItemIndexSetFrom:CGRectGetMinY(self.bounds) to:CGRectGetMaxY(self.bounds)];
    
    NSMutableSet * recycledItems = [NSMutableSet set];
    NSSet * visibles = [self.visibleItems copy];
    
    for (UIView * view in visibles) {
        
        BOOL isToShow = [itemShouldShowSet containsObject:view.muiID];
        if (!isToShow && view.reuseIdentifier.length > 0) {
            
            NSMutableSet * recycledIdentifierSet = [self recycledIdentifierSet:view.reuseIdentifier];
            [recycledIdentifierSet addObject:view];
            view.hidden = YES;
            [recycledItems addObject:view];
        }else if (isReload && view.muiID){
            
            [self.shouldReloadItems addObject:view.muiID];
        }
    }
    
    [self.visibleItems minusSet:recycledItems];
    [recycledItems removeAllObjects];

    for (NSString * muiID in itemShouldShowSet) {
     
        BOOL shouldReload = isReload || [self.shouldReloadItems containsObject:muiID];
        if (![self isCellVisible:muiID] || [self.shouldReloadItems containsObject:muiID]) {
            
            if (self.dataSource &&
                [self.dataSource conformsToProtocol:@protocol(ZYLazyScrollViewDataSource)] &&
                [self.dataSource respondsToSelector:@selector(scrollView:itemByID:)]) {
                
                if (shouldReload) {
                    self.currentVisibleItemMuiID = muiID;
                }else{
                    self.currentVisibleItemMuiID = nil;
                }
                
                UIView * viewToShow = [self.dataSource scrollView:self itemByID:muiID];
                
                if ([viewToShow conformsToProtocol:@protocol(ZYLazyScrollViewCellProtocol)] &&
                    [viewToShow respondsToSelector:@selector(zy_afterGetView)]) {
                    
                    [(UIView<ZYLazyScrollViewCellProtocol> *)viewToShow zy_afterGetView];
                }
                
                if (viewToShow) {
                    viewToShow.muiID = muiID;
                    viewToShow.hidden = NO;
                    if (![self.visibleItems containsObject:viewToShow]) {
                        [self.visibleItems addObject:viewToShow];
                    }
                }
            }
            
            [self.shouldReloadItems removeObject:muiID];
        }
    }
    
    [self.inScreenVisibleItems removeAllObjects];
    for (UIView * view in self.visibleItems) {
        
        if ([view isKindOfClass:[UIView class]] && view.superview) {
            
            CGRect absRect = [view.superview convertRect:view.frame toView:self];
            if ((absRect.origin.y + absRect.size.height >= CGRectGetMinY(self.bounds)) && (absRect.origin.y <= CGRectGetMaxY(self.bounds))) {
                [self.inScreenVisibleItems addObject:view];
            }
        }
    }
    
}

- (NSMutableSet *)recycledIdentifierSet:(NSString *)reuseIdentifier{
    
    if (reuseIdentifier.length == 0) {
        return nil;
    }
    NSMutableSet * result = [self.recycledIdentifierItemsDic objectForKey:reuseIdentifier];
    if (result == nil) {
        result = [NSMutableSet set];
        [self.recycledIdentifierItemsDic setObject:result forKey:reuseIdentifier];
    }
    return result;
}

- (void)reloadData{
    
    [self createScrollViewIndex];
    if (self.itemsFrames.count > 0) {
        
        CGRect visibleBounds = self.bounds;
        CGFloat minY = CGRectGetMinY(visibleBounds) - ZYRENDER_BUFFER_WINDOW;
        CGFloat maxY = CGRectGetMaxY(visibleBounds) + ZYRENDER_BUFFER_WINDOW;
        [self assembleSubViewsForReload:YES minY:minY maxY:maxY];
        [self findViewsInVisibleRect];
    }
}

- (nullable UIView *)dequeReusableItemWithIdentifier:(nonnull NSString *)reuseIdentifier{
    
    UIView * view = nil;
    
    if (self.currentVisibleItemMuiID) {
        NSSet * visibles = self.visibleItems;
        for (UIView * v in visibles) {
            if ([v.muiID isEqualToString:self.currentVisibleItemMuiID]) {
                view = v;
                break;
            }
        }
    }
    
    if (view == nil) {
        NSMutableSet * recycledIdentifierSet = [self recycledIdentifierSet:reuseIdentifier];
        view = [recycledIdentifierSet anyObject];
        if (view) {
            [recycledIdentifierSet removeObject:view];
            view.gestureRecognizers = nil;
        }
    }
    
    if ([view conformsToProtocol:@protocol(ZYLazyScrollViewCellProtocol)] &&
        [view respondsToSelector:@selector(zy_prepareForReuse)]) {
        [(UIView<ZYLazyScrollViewCellProtocol> *)view zy_prepareForReuse];
    }
    
    return view;
}


-(BOOL)isCellVisible: (NSString *)muiID {

    BOOL result = NO;
    
    NSSet * visibles = [self.visibleItems copy];
    for (UIView * view in visibles) {
        if ([view.muiID isEqualToString:muiID]) {
            result = YES;
            break;
        }
    }
    return result;
}

-(void)removeAllLayouts{
    
    NSSet * visibles = self.visibleItems;
    for (UIView * view in visibles) {
        
        NSMutableSet * recycledIdentifierSet = [self recycledIdentifierSet:view.reuseIdentifier];
        [recycledIdentifierSet addObject:view];
        view.hidden = YES;
    }
    [_visibleItems removeAllObjects];
    [_recycledIdentifierItemsDic removeAllObjects];
}

-(void)resetViewEnterTimes{
    
    [self.enterDict removeAllObjects];
    self.lastVisibleMuiID = nil;
}

@end
