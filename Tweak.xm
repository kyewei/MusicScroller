
/*@interface NSAttributedString
- (NSString *)string;
@end*/

@interface SKUIAttributedStringIndexBarEntry : NSObject
@property (nonatomic, readonly, copy) NSAttributedString *attributedString;
- (NSAttributedString *)attributedString;
@end

@interface UITouchesEvent : NSObject
@end

@interface SKUIIndexBarControl : UIControl
- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (void)_sendSelectionForTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (SKUIAttributedStringIndexBarEntry *)_entryAtIndexPath:(NSIndexPath *)arg1;

- (void) updateLetterView:(UIView*)view withText:(NSString *) text;
- (void) createLetterView;

- (NSString *)scrollSelection;
- (void)setScrollSelection:(NSString *)selection;

- (UIView *)letterView;
- (void)setLetterView:(UIView *)view;

@end


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

- (void)_sendSelectionForTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    %orig;
    //%log;
    [self createLetterView];
    [[self letterView] setHidden:NO];
    NSIndexPath *_lastSelectedIndexPath = MSHookIvar<NSIndexPath*>(self, "_lastSelectedIndexPath");
    SKUIAttributedStringIndexBarEntry *entry = _lastSelectedIndexPath? [self _entryAtIndexPath:_lastSelectedIndexPath] : nil;
    if (![NSStringFromClass([entry class]) isEqualToString:@"SKUIAttributedStringIndexBarEntry"] )
        return;
    [self setScrollSelection:[[entry attributedString] string]];

    [self updateLetterView: [self letterView] withText:[self scrollSelection]];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    BOOL result = %orig;
    [self createLetterView];

    [[self letterView] setHidden:NO];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];

    return result;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    BOOL result = %orig;
    [self createLetterView];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];

    return result;
}
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    %orig;

    [self createLetterView];
    [self setScrollSelection:nil];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];
    [[self letterView] setHidden:YES];
}

%end


@interface UITableViewIndex : UIControl
- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (NSString *)selectedSectionTitle;
- (void)_selectSectionForTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (SKUIAttributedStringIndexBarEntry *)_entryAtIndexPath:(NSIndexPath *)arg1;

- (void) updateLetterView:(UIView*)view withText:(NSString *) text;
- (void) createLetterView;

- (NSString *)scrollSelection;
- (void)setScrollSelection:(NSString *)selection;

- (UIView *)letterView;
- (void)setLetterView:(UIView *)view;

@end


%hook UITableViewIndex

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
    UIView *parent = [[self superview] superview];
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




- (void)_selectSectionForTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    %orig;
    //%log;
    [self createLetterView];
    [[self letterView] setHidden:NO];
    [self setScrollSelection:[self selectedSectionTitle]];

    [self updateLetterView: [self letterView] withText:[self scrollSelection]];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    BOOL result = %orig;
    [self createLetterView];

    [[self letterView] setHidden:NO];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];

    return result;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    BOOL result = %orig;
    [self createLetterView];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];

    return result;
}
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    %orig;

    [self createLetterView];
    [self setScrollSelection:nil];
    [self updateLetterView: [self letterView] withText:[self scrollSelection]];
    [[self letterView] setHidden:YES];
}

%end


