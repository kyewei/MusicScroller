
/*@interface NSAttributedString
- (NSString *)string;
@end*/

@interface SKUIAttributedStringIndexBarEntry : NSObject
@property (nonatomic, readonly, copy) NSAttributedString *attributedString;
- (NSAttributedString *)attributedString;
@end

@interface UITouchesEvent : NSObject
@end

@interface SKUIIndexBarControl : NSObject
- (id)delegate;
- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2;


- (void) updateLetterView:(UIView*)view withText:(NSString *) text;
@end


@interface MusicLibraryViewController : NSObject
- (id) view;
- (SKUIAttributedStringIndexBarEntry *)indexBarControl:(SKUIIndexBarControl *)arg1 entryAtIndexPath:(NSIndexPath *)arg2;
- (void)indexBarControl:(SKUIIndexBarControl *)arg1 didSelectEntryAtIndexPath:(NSIndexPath *)arg2;
//- (void)indexBarControlDidSelectBeyondBottom:(id)arg1;
//- (void)indexBarControlDidSelectBeyondTop:(id)arg1;

- (NSString *)scrollSelection;
- (void)setScrollSelection:(NSString *)selection;

- (UIView *)letterView;
- (void)setLetterView:(UIView *)view;
@end


void createLetterView(MusicLibraryViewController *c) {
    UIView *parent = [c view];
    CGFloat width = 100;
    if (![c letterView]) {
        NSLog(@"%f %f %f %f",parent.frame.origin.x,parent.frame.origin.y,parent.frame.size.width,parent.frame.size.height);
        UIView *letterView = [[UIView alloc]
            initWithFrame:CGRectMake(parent.frame.origin.x+parent.frame.size.width/2-width/2,
                                    parent.frame.origin.y+parent.frame.size.height/2-width/2,
                                    width, width)];
        [c setLetterView: letterView];
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
        //[label sizeToFit];


        [parent addSubview: letterView];
        [letterView setHidden:YES];
        letterView.opaque = NO;
        letterView.layer.cornerRadius = width/10;
        letterView.layer.masksToBounds = YES;
        letterView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        //[letterView setBackgroundColor: [UIColor colorWithWhite:1.0 alpha:0.5]];
        //[letterView setAlpha:0.5];
    }


}

%hook MusicLibraryViewController



%new
- (NSString *)scrollSelection {
    NSString * _selection = objc_getAssociatedObject(self, @selector(scrollSelection));
    return _selection;
}

%new
- (void)setScrollSelection:(NSString *)selection {
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

- (void)indexBarControl:(SKUIIndexBarControl *)arg1 didSelectEntryAtIndexPath:(NSIndexPath *)arg2 {
    //%log;
    %orig;
    [self.letterView setHidden:NO];
    createLetterView(self);
    SKUIAttributedStringIndexBarEntry *entry = [self indexBarControl: arg1 entryAtIndexPath:arg2];
    if (![NSStringFromClass([entry class]) isEqualToString:@"SKUIAttributedStringIndexBarEntry"] )
        return;

    [self setScrollSelection:[[entry attributedString] string]];
    [arg1 updateLetterView: [self letterView] withText: [self scrollSelection]];

}

- (void)viewDidLayoutSubviews {
    %orig;
    if ([self letterView]) {
        UIView *view = [self letterView];
        view.frame = CGRectMake(view.superview.frame.origin.x+view.superview.frame.size.width/2-view.frame.size.width/2,
                                    view.superview.frame.origin.y+view.superview.frame.size.height/2-view.frame.size.width/2,
                                    view.frame.size.width, view.frame.size.width);
    }
}




/*- (void)indexBarControl:(id)arg1 didSelectEntryAtIndexPath:(id)arg2{ %log; %orig; }
- (id)indexBarControl:(id)arg1 entryAtIndexPath:(id)arg2{ %log; return %orig; }
- (int)indexBarControl:(id)arg1 numberOfEntriesInSection:(int)arg2{ %log; return %orig; }
- (void)indexBarControlDidSelectBeyondBottom:(id)arg1{ %log; %orig; }
- (void)indexBarControlDidSelectBeyondTop:(id)arg1{ %log; %orig; }*/
%end


%hook SKUIIndexBarControl

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


- (BOOL)beginTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    //%log;
    MusicLibraryViewController *d = [self delegate];
    //NSString *string = [d scrollSelection];
    //NSLog(@"%@",string);
    createLetterView(d);
    UIView * view = [[self delegate] letterView];
    [view setHidden:NO];
    [self updateLetterView: view withText:[[self delegate] scrollSelection]];

    return %orig;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    //%log;
    MusicLibraryViewController *d = [self delegate];
    //NSString *string = [d scrollSelection];
    //NSLog(@"%@",string);
    createLetterView(d);
    UIView * view = [[self delegate] letterView];
    [self updateLetterView: view withText:[[self delegate] scrollSelection]];

    return %orig;
}
- (void)endTrackingWithTouch:(UITouch *)arg1 withEvent:(UITouchesEvent *)arg2 {
    //%log;
    MusicLibraryViewController *d = [self delegate];
    //NSString *string = [d scrollSelection];
    //NSLog(@"%@",string);
    createLetterView(d);

    UIView * view = [[self delegate] letterView];

    [[self delegate] setScrollSelection:nil];
    [self updateLetterView: view withText:[[self delegate] scrollSelection]];
    [view setHidden:YES];

    %orig;
}

%end


/*
%hook SKUIIndexBarControl
- (id)_allEntries { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)_allRequiredEntries { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)_combinedEntry { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (void)_configureNewEntry:(id)arg1 { %log; %orig; }
//- (id)_displayEntries { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)_displayEntriesThatFitInViewForGroupedEntries { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)_entryAtIndexPath:(id)arg1 { %log; id r = %orig; NSLog(@" = %@", r); return r; }
//- (void)_enumerateEntryIndexPathsUsingBlock:(id)arg1 { %log; %orig; }
- (void)_invalidateDisplayEntries { %log; %orig; }
- (void)_invalidateForChangedLayoutProperties { %log; %orig; }
- (int)_numberOfEntriesInSection:(int)arg1 { %log; int r = %orig; NSLog(@" = %d", r); return r; }
- (int)_numberOfSections { %log; int r = %orig; NSLog(@" = %d", r); return r; }
- (BOOL)_reloadLineSpacing { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
//- (void)_sendSelectionForTouch:(id)arg1 withEvent:(id)arg2 { %log; %orig; }
- (CGSize)_sizeForEntries:(id)arg1 { %log; CGSize r = %orig; NSLog(@" = {%g, %g}", r.width, r.height); return r; }
- (CGSize)_sizeForEntryAtIndexPath:(id)arg1 { %log; CGSize r = %orig; NSLog(@" = {%g, %g}", r.width, r.height); return r; }
- (int)_totalEntryCount { %log; int r = %orig; NSLog(@" = %d", r); return r; }
- (CGSize)_totalSize { %log; CGSize r = %orig; NSLog(@" = {%g, %g}", r.width, r.height); return r; }
- (CGRect)_visibleBounds { %log; CGRect r = %orig; NSLog(@" = {{%g, %g}, {%g, %g}}", r.origin.x, r.origin.y, r.size.width, r.size.height); return r; }
- (BOOL)beginTrackingWithTouch:(id)arg1 withEvent:(id)arg2 { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
- (void)cancelTrackingWithEvent:(id)arg1 { %log; %orig; }
- (UIEdgeInsets)contentEdgeInsets { %log; UIEdgeInsets r = %orig;  return r; }
- (BOOL)continueTrackingWithTouch:(id)arg1 withEvent:(id)arg2 { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
- (id)dataSource { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)defaultTextAttributes { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)delegate { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (void)drawRect:(CGRect)arg1 { %log; %orig; }
- (void)endTrackingWithTouch:(id)arg1 withEvent:(id)arg2 { %log; %orig; }
- (UIEdgeInsets)hitTestEdgeInsets { %log; UIEdgeInsets r = %orig;  return r; }
- (id)initWithCoder:(id)arg1 { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (id)initWithFrame:(CGRect)arg1 { %log; id r = %orig; NSLog(@" = %@", r); return r; }
- (int)numberOfEntriesInSection:(int)arg1 { %log; int r = %orig; NSLog(@" = %d", r); return r; }
- (int)numberOfSections { %log; int r = %orig; NSLog(@" = %d", r); return r; }
- (BOOL)pointInside:(CGPoint)arg1 withEvent:(id)arg2 { %log; BOOL r = %orig; NSLog(@" = %d", r); return r; }
- (void)reloadCombinedEntry { %log; %orig; }
- (void)reloadData { %log; %orig; }
- (void)reloadEntryAtIndexPath:(id)arg1 { %log; %orig; }
- (void)reloadSections:(id)arg1 { %log; %orig; }
- (void)setBounds:(CGRect)arg1 { %log; %orig; }
//- (void)setContentEdgeInsets:(UIEdgeInsets)arg1 { %log; %orig; }
- (void)setDataSource:(id)arg1 { %log; %orig; }
- (void)setDefaultTextAttributes:(id)arg1 { %log; %orig; }
- (void)setDelegate:(id)arg1 { %log; %orig; }
- (void)setFrame:(CGRect)arg1 { %log; %orig; }
//- (void)setHitTestEdgeInsets:(UIEdgeInsets)arg1 { %log; %orig; }
- (void)setTransform:(CGAffineTransform)arg1 { %log; %orig; }
- (CGSize)sizeThatFits:(CGSize)arg1 { %log; CGSize r = %orig; NSLog(@" = {%g, %g}", r.width, r.height); return r; }
- (void)tintColorDidChange { %log; %orig; }
- (void)traitCollectionDidChange:(id)arg1 { %log; %orig; }
%end*/
