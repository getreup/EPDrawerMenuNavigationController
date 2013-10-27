//
//  EPDrawerMenuNavigationController.m
//  EPDrawerMenuNavigationController
//
//  Created by Kelsey Regan on 2013-10-23.
//  Copyright (c) 2013 Elevated Pixels Software. All rights reserved.
//

#import "EPDrawerMenuNavigationController.h"

#define DRAWERVIEW_TOUCHBUFFER 20
#define DRAWERVIEW_MAXDISMISSBUTTONALPHA .2

//------------------------------------------------------------------------------------
// EPDrawerView
@class EPDrawerView;
@protocol DrawerViewProtocol <NSObject>
@optional
-(void)drawerView:(EPDrawerView*)drawerView didChangeIsShown:(bool)isShown;
@end

// Public
@interface EPDrawerView : UIView <UIScrollViewDelegate>
-(void)setIsShown:(bool)isShown animated:(bool)animated;
@property(strong, nonatomic) UIView* contentView;
@property(weak, nonatomic) id<DrawerViewProtocol> delegate;
@property(nonatomic) bool isShown;
@end

// Private
@interface EPDrawerView()
@property(strong, nonatomic) UIScrollView* scrollView;
@property(strong, nonatomic) UIButton* dismissButton;
@property(nonatomic) CGFloat visibleWidth;
@end

@implementation EPDrawerView

+(instancetype)drawerViewWithVisibleWidth:(CGFloat)visibleWidth
{
    EPDrawerView* drawerView = [[EPDrawerView alloc] init];
    drawerView.visibleWidth = visibleWidth;
    return drawerView;
}

-(id)init
{
    self = [super init];
    if( self ) [self initialize];
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if( self ) [self initialize];
    return self;
}

-(void)initialize
{
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    const CGRect bufferRect = CGRectMake(0, 0, DRAWERVIEW_TOUCHBUFFER, self.frame.size.height);
    return CGRectContainsPoint(bufferRect, point) || [self.contentView pointInside:[self convertPoint:point toView:self.contentView] withEvent:event];
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.scrollView.frame = CGRectMake(0, 0, self.visibleWidth, frame.size.height);
    self.contentView.frame = CGRectMake(0, 0, self.visibleWidth, frame.size.height);
    self.scrollView.contentSize = CGSizeMake( self.scrollView.frame.size.width*2, self.frame.size.height );
}

#pragma mark Properties

-(bool)isShown
{
    return self.scrollView.contentOffset.x != self.scrollView.frame.size.width;
}

-(void)setIsShown:(bool)isShown
{
    [self setIsShown:isShown animated:YES];
}

-(void)setIsShown:(bool)isShown animated:(bool)animated
{
    if( isShown )
    {
        [self.scrollView setContentOffset:CGPointMake( 0, 0 ) animated:animated];
    }
    else
    {
        [self.scrollView setContentOffset:CGPointMake( self.scrollView.frame.size.width, 0 ) animated:animated];
    }
}

-(void)setVisibleWidth:(CGFloat)visibleWidth
{
    _visibleWidth = visibleWidth;
    [_scrollView removeFromSuperview], _scrollView = nil;
    [_contentView removeFromSuperview], _contentView = nil;
    [self initialize];
}

-(UIScrollView *)scrollView
{
    if( !_scrollView )
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.visibleWidth, self.frame.size.height)];
        _scrollView.autoresizingMask |= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.contentSize = CGSizeMake( _scrollView.frame.size.width*2, _scrollView.frame.size.height );
        _scrollView.contentOffset = CGPointMake( self.scrollView.frame.size.width, 0 );
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.bounces = NO;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

-(UIView*)contentView
{
    if( !_contentView )
    {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.visibleWidth, self.frame.size.height)];
        _contentView.autoresizingMask |= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _contentView.backgroundColor = [UIColor whiteColor];
    }
    return _contentView;
}

#pragma mark Utilities

-(void)hide
{
    self.isShown = NO;
}

#pragma mark UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if( self.isShown )
    {
        if( !self.dismissButton )
        {
            self.dismissButton = [[UIButton alloc] initWithFrame:self.superview.bounds];
            self.dismissButton.backgroundColor = [UIColor blackColor];
            [self.dismissButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchDown];
            [self.superview addSubview:self.dismissButton];
            [self.superview bringSubviewToFront:self];
        }
        self.dismissButton.alpha = DRAWERVIEW_MAXDISMISSBUTTONALPHA * (self.scrollView.frame.size.width - scrollView.contentOffset.x ) / self.scrollView.frame.size.width;
    }
    else if( self.dismissButton )
    {
        [self.dismissButton removeFromSuperview], self.dismissButton = nil;
    }
    
    static bool oldIsShown = NO;
    if( oldIsShown != self.isShown )
    {
        if( [self.delegate respondsToSelector:@selector(drawerView:didChangeIsShown:)] )[self.delegate drawerView:self didChangeIsShown:self.isShown];
        oldIsShown = self.isShown;
    }
}

@end


//------------------------------------------------------------------------------------
// EPDrawerMenuNavigationController
@interface EPDrawerMenuNavigationController () <DrawerViewProtocol, UINavigationControllerDelegate>
@property(strong, nonatomic) EPDrawerView* drawerView;
@property(strong, nonatomic) UIBarButtonItem* openDrawerBarButton;
@end

@implementation EPDrawerMenuNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) self.interactivePopGestureRecognizer.enabled = NO;
    
    self.drawerView = [EPDrawerView drawerViewWithVisibleWidth:280];
    self.drawerContentView = self.drawerView.contentView;
    self.drawerView.delegate = self;
}

#pragma mark Utilities

-(void)toggleDrawer
{
    self.drawerView.isShown ^= YES;
}

-(void)addDrawerToViewController:(UIViewController*)viewController
{
    if( viewController )
    {
        self.drawerView.frame = viewController.view.bounds;
        [viewController.view addSubview:self.drawerView];
    }
    [self.drawerView setIsShown:NO animated:NO];
}

#pragma mark Properties

-(UIBarButtonItem *)openDrawerBarButton
{
    if( !_openDrawerBarButton )
    {
        _openDrawerBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"button_nav.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleDrawer)];
    }
    return _openDrawerBarButton;
}

-(id<UINavigationControllerDelegate>)delegate
{
    return self;
}

#pragma mark DrawerViewProtocol

-(void)drawerView:(EPDrawerView *)drawerView didChangeIsShown:(bool)isShown
{
}

#pragma mark UINavigationControllerDelegate

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self addDrawerToViewController:viewController];
    if( viewController == navigationController.viewControllers[0] )
    {
        viewController.navigationItem.leftBarButtonItem = self.openDrawerBarButton;
    }
}

@end
