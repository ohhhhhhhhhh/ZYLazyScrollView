//
//  ViewController.m
//  ZYLazyScrollView
//
//  Created by zy on 2017/7/24.
//  Copyright © 2017年 zy. All rights reserved.
//

#import "ViewController.h"
#import "ZYLazyScrollView.h"


@interface ZYLazyScrollViewCustomView : UILabel<ZYLazyScrollViewCellProtocol>

@end

@implementation ZYLazyScrollViewCustomView

-(void)zy_prepareForReuse{
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@ - Prepare For Reuse",self.text]);
}

-(void)zy_afterGetView{
    
    NSLog(@"%@", [NSString stringWithFormat:@"%@ - AfterGetView",self.text]);
}

-(void)zy_didEnterWithTimes:(NSUInteger)times{
 
    NSLog(@"%@", [NSString stringWithFormat:@"%@ - Did Enter With Times - %lu",self.text,(unsigned long)times]);
}

@end



@interface ViewController ()<ZYLazyScrollViewDataSource>
{
    NSMutableArray * rectArray;
}


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self testMethod];
}


- (void)testMethod{
    
    ZYLazyScrollView *scrollview = [[ZYLazyScrollView alloc]init];
    scrollview.frame = self.view.bounds;
    scrollview.dataSource = self;
    
    [self.view addSubview:scrollview];
    
    
    //Here is frame array for test.
    //LazyScrollView must know every rect before rending.
    rectArray  = [[NSMutableArray alloc] init];
    
    //Create a single column layout with 5 elements;
//    for (int i = 0; i < 5 ; i++) {
//        [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(10, i *80 + 2 , self.view.bounds.size.width-20, 80-2)]];
//    }
//    //Create a double column layout with 10 elements;
//    for (int i = 0; i < 10 ; i++) {
//        [rectArray addObject:[NSValue valueWithCGRect:CGRectMake((i%2)*self.view.bounds.size.width/2 + 3, 410 + i/2 *80 + 2 , self.view.bounds.size.width/2 -3, 80 - 2)]];
//    }
//    //Create a trible column layout with 15 elements;
//    for (int i = 0; i < 15 ; i++) {
//        [rectArray addObject:[NSValue valueWithCGRect:CGRectMake((i%3)*self.view.bounds.size.width/3 + 1, 820 + i/3 *80 + 2 , self.view.bounds.size.width/3 -3, 80 - 2)]];
//    }

    
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(10, 0, self.view.bounds.size.width-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 82, self.view.bounds.size.width/2-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 82, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 124, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 164, self.view.bounds.size.width, 80)]];
    
    
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(10, 246, self.view.bounds.size.width-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 328, self.view.bounds.size.width/2-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 328, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 370, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 410, self.view.bounds.size.width, 80)]];

    
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(10, 492, self.view.bounds.size.width-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 574, self.view.bounds.size.width/2-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 574, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 616, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 658, self.view.bounds.size.width, 80)]];
    
    
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(10, 740, self.view.bounds.size.width-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 822, self.view.bounds.size.width/2-20, 80)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 822, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(self.view.bounds.size.width/2-10, 864, self.view.bounds.size.width/2-20, 40)]];
    [rectArray addObject:[NSValue valueWithCGRect:CGRectMake(0, 904, self.view.bounds.size.width, 80)]];
    
    
    scrollview.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), 1230);
    //STEP 3 reload LazyScrollView
    [scrollview reloadData];

}


//STEP 2 implement datasource delegate.
- (NSInteger)numberOfItemInScrollView:(ZYLazyScrollView *)scrollView
{
    return rectArray.count;
}

- (ZYRectModel *)scrollView:(ZYLazyScrollView *)scrollView rectModelAtIndex:(NSUInteger)index
{
    CGRect rect = [(NSValue *)[rectArray objectAtIndex:index]CGRectValue];
    ZYRectModel *rectModel = [[ZYRectModel alloc]init];
    rectModel.absoluteRect = rect;
    rectModel.muiID = [NSString stringWithFormat:@"%ld",index];
    return rectModel;
}

- (nullable UIView *)scrollView:(nonnull ZYLazyScrollView *)scrollView
                       itemByID:(nonnull NSString *)muiID
{
    //Find view that is reuseable first.
    ZYLazyScrollViewCustomView *label = (ZYLazyScrollViewCustomView *)[scrollView dequeReusableItemWithIdentifier:@"testView"];
    NSInteger index = [muiID integerValue];
    if (!label)
    {
        label = [[ZYLazyScrollViewCustomView alloc]initWithFrame:[(NSValue *)[rectArray objectAtIndex:index]CGRectValue]];
        label.textAlignment = NSTextAlignmentCenter;
        label.reuseIdentifier = @"testView";
    }
    label.frame = [(NSValue *)[rectArray objectAtIndex:index]CGRectValue];
    label.text = [NSString stringWithFormat:@"%lu",(unsigned long)index];
    label.backgroundColor = [self randomColor];
    [scrollView addSubview:label];
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(click:)]];
    return label;
}

#pragma mark - Private

- (UIColor *)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 ); //0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5; // 0.5 to 1.0,away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5; //0.5 to 1.0,away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    
}

- (void)click:(UIGestureRecognizer *)recognizer
{
    ZYLazyScrollViewCustomView *label = (ZYLazyScrollViewCustomView *)recognizer.view;
    
    NSLog(@"Click - %@",label.muiID);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
