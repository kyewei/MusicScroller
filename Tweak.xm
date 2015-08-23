
/*@interface NSAttributedString
- (NSString *)string;
@end*/

@interface SKUIAttributedStringIndexBarEntry : NSObject
@property (nonatomic, readonly, copy) NSAttributedString *attributedString;
- (NSAttributedString *)attributedString;
@end

@interface UITouchesEvent : NSObject
@end

@class SKUIIndexBarControl;


@protocol SKUIIndexBarControlDelegate <NSObject>
@optional
- (void)indexBarControl:(SKUIIndexBarControl *)arg1 didSelectEntryAtIndexPath:(NSIndexPath *)arg2;
//-(void)indexBarControlDidSelectBeyondBottom:(id)arg1;
//-(void)indexBarControlDidSelectBeyondTop:(id)arg1;

@end

@protocol SKUIIndexBarControlDataSource <NSObject>
//@optional
//-(id)combinedEntryForIndexBarControl:(id)arg1;
//-(long long)numberOfSectionsInIndexBarControl:(id)arg1;

@required
//-(long long)indexBarControl:(id)arg1 numberOfEntriesInSection:(long long)arg2;
//-(id)indexBarControl:(id)arg1 entryAtIndexPath:(id)arg2;
- (SKUIAttributedStringIndexBarEntry *)indexBarControl:(SKUIIndexBarControl *)arg1 entryAtIndexPath:(NSIndexPath *)arg2;
@end




@interface SKUIIndexBarControl : UIControl
- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (NSObject<SKUIIndexBarControlDataSource> *)dataSource;
//- (id)defaultTextAttributes;
- (NSObject<SKUIIndexBarControlDelegate> *)delegate;
- (void)setDelegate:(NSObject<SKUIIndexBarControlDelegate> *)arg1;

- (void) updateLetterView:(UIView*)view withText:(NSString *) text;
- (void) createLetterView;

- (NSString *)scrollSelection;
- (void)setScrollSelection:(NSString *)selection;

- (UIView *)letterView;
- (void)setLetterView:(UIView *)view;

@end


@interface MusicLibraryViewController : NSObject <SKUIIndexBarControlDelegate,SKUIIndexBarControlDataSource>
- (id) view;
//- (SKUIAttributedStringIndexBarEntry *)indexBarControl:(SKUIIndexBarControl *)arg1 entryAtIndexPath:(NSIndexPath *)arg2; from protocol
//- (void)indexBarControl:(SKUIIndexBarControl *)arg1 didSelectEntryAtIndexPath:(NSIndexPath *)arg2; in protocol
//- (void)indexBarControlDidSelectBeyondBottom:(id)arg1;
//- (void)indexBarControlDidSelectBeyondTop:(id)arg1;


@end






//Why does hooking protocols not work? SIGH. Use MSHookMessageEx down in setDelegate.
//%hook SKUIIndexBarControlDelegate
void *(*oldIndexBarControlDidSelectEntryAtIndexPath)(id self, SEL _cmd, SKUIIndexBarControl *arg1, NSIndexPath *arg2);

void newIndexBarControlDidSelectEntryAtIndexPath(id self, SEL _cmd, SKUIIndexBarControl *arg1, NSIndexPath *arg2) {
    (*oldIndexBarControlDidSelectEntryAtIndexPath)(self, _cmd, arg1, arg2);

    [arg1 createLetterView];
    [arg1.letterView setHidden:NO];
    SKUIAttributedStringIndexBarEntry *entry = [arg1.dataSource indexBarControl: arg1 entryAtIndexPath:arg2];
    if (![NSStringFromClass([entry class]) isEqualToString:@"SKUIAttributedStringIndexBarEntry"] )
        return;

    [arg1 setScrollSelection:[[entry attributedString] string]];
    [arg1 updateLetterView: [arg1 letterView] withText: [arg1 scrollSelection]];
}


%hook SKUIIndexBarControl

%new
- (NSString *)scrollSelection {
    NSString * _selection = objc_getAssociatedObject(self, @selector(scrollSelection));
    return _selection;
}

%new
- (void)setScrollSelection:(NSString *)selection {
    %log;
    objc_setAssociatedObject(self, @selector(scrollSelection), selection, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new
- (UIView *)letterView {
    UIView * view = objc_getAssociatedObject(self, @selector(letterView));
    return view;
}

%new
- (void)setLetterView:(UITextView *)view {
    %log;
    objc_setAssociatedObject(self, @selector(letterView), view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


%new
- (void) updateLetterView:(UIView*)view withText:(NSString *) text{
    if (!view)
        return;
    if ([view isHidden])
        return;
    if ([view.subviews count]<1)
        return;
    if (!text) {
        [view setHidden:YES];
        return;
    }

    UILabel *label = [view.subviews objectAtIndex:0];
    label.text= [NSString stringWithFormat: @"%@", text];
}


%new
- (void) createLetterView {
    UIView *parent = [self superview];
    CGFloat width = 100;
    UIView *letterView=nil;

    if (![self letterView]) {
        NSLog(@"%f %f %f %f",parent.frame.origin.x,parent.frame.origin.y,parent.frame.size.width,parent.frame.size.height);
        letterView = [[UIView alloc]
            initWithFrame:CGRectMake(parent.frame.size.width/2-width/2,
                                    parent.frame.size.height/2-width/2,
                                    width, width)];
        [self setLetterView: letterView];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(width/4,width/4,width/2,width/2)];

        [letterView addSubview:label];
        label.text=nil;
        [label setTextAlignment:NSTextAlignmentCenter];//
        label.numberOfLines = 1;
        label.font = [UIFont boldSystemFontOfSize:width/2];
        //label.minimumScaleFactor=0.5;
        label.minimumScaleFactor=0.25;
        label.adjustsFontSizeToFitWidth = YES;
        label.textColor=[UIColor whiteColor];

        [parent addSubview: letterView];
        NSLayoutConstraint *myConstraint = [NSLayoutConstraint constraintWithItem:letterView
                        attribute:NSLayoutAttributeCenterY
                        relatedBy:NSLayoutRelationEqual
                        toItem:parent
                        attribute:NSLayoutAttributeCenterY
                        multiplier:1.0
                        constant:0];
        [parent addConstraint:myConstraint];
        myConstraint =[NSLayoutConstraint constraintWithItem:letterView
                        attribute:NSLayoutAttributeCenterX
                        relatedBy:NSLayoutRelationEqual
                        toItem:parent
                        attribute:NSLayoutAttributeCenterX
                        multiplier:1.0
                        constant:0];
        [parent addConstraint:myConstraint];
        myConstraint = [NSLayoutConstraint constraintWithItem:letterView
                        attribute:NSLayoutAttributeHeight
                        relatedBy:NSLayoutRelationEqual
                        toItem:nil
                        attribute:NSLayoutAttributeNotAnAttribute
                        multiplier:1
                        constant:width];
        [parent addConstraint:myConstraint];

        myConstraint = [NSLayoutConstraint constraintWithItem:letterView
                        attribute:NSLayoutAttributeWidth
                        relatedBy:NSLayoutRelationEqual
                        toItem:nil
                        attribute:NSLayoutAttributeNotAnAttribute
                        multiplier:1
                        constant:width];
        [parent addConstraint: myConstraint];
        letterView.translatesAutoresizingMaskIntoConstraints = NO;

        [letterView setHidden:YES];
        letterView.opaque = NO;
        letterView.layer.cornerRadius = width/10;
        letterView.layer.masksToBounds = YES;
        letterView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    }
}

- (void)setDelegate:(NSObject<SKUIIndexBarControlDelegate> *)arg1 {
    %orig;
    // couldn't override <SKUIIndexBarControlDelegate>'s
    //   @selector(indexBarControl:didSelectEntryAtIndexPath:) so....

    MSHookMessageEx([arg1 class],
                    @selector(indexBarControl:didSelectEntryAtIndexPath:),
                    (IMP)&newIndexBarControlDidSelectEntryAtIndexPath,
                    (IMP *)&oldIndexBarControlDidSelectEntryAtIndexPath);
}


- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    BOOL result = %orig;
    //%log;
    //MusicLibraryViewController *d = [self delegate];
    //NSString *string = [d scrollSelection];
    //NSLog(@"%@",string);
    [self createLetterView];
    //UIView * view = [[self delegate] letterView];

    [[self letterView] setHidden:NO];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];

    return result;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    BOOL result = %orig;
    //%log;
    //MusicLibraryViewController *d = [self delegate];
    //NSString *string = [d scrollSelection];
    //NSLog(@"%@",string);
    [self createLetterView];

    [self updateLetterView: [self letterView] withText:[self scrollSelection]];

    return result;
}
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    %orig;

    //%log;
    //MusicLibraryViewController *d = [self delegate];
    //NSString *string = [d scrollSelection];
    //NSLog(@"%@",string);
    [self createLetterView];

    [self setScrollSelection:nil];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];
    [[self letterView] setHidden:YES];


}

%end
