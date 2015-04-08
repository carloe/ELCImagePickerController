//
//  ELCOverlayImageView.m
//  ELCImagePickerDemo
//
//  Created by Seamus on 14-7-11.
//  Copyright (c) 2014年 ELC Technologies. All rights reserved.
//

#import "ELCOverlayImageView.h"
#import "ELCConsole.h"

#define kELCOverlayImageViewDefaultInset 2.0f

static CGSize const labelPadding = { 3.0f, 1.0f };

@interface ELCOverlayImageView ()

@property(nonatomic) UIView *overlayView;
@property(nonatomic) UIImageView *iconView;
@property(nonatomic) UILabel *indexLabel;

@end

@implementation ELCOverlayImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if(self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        if(image) {
            self.iconView.image = image;
        }
    }
    return self;
}

- (void)setSelectionIcon:(UIImage *)selectionIcon {
    self.iconView.image = selectionIcon;
}

- (UIImage *)selectionIcon {
    return self.iconView.image;
}

- (void)setShowSelectionCounter:(BOOL)showSelectionCounter {
    self.indexLabel.hidden = !showSelectionCounter;
}

- (BOOL)showSelectionCounter {
    return !self.indexLabel.hidden;
}


- (void)commonInit {
    self.contentInsets = UIEdgeInsetsMake(kELCOverlayImageViewDefaultInset, kELCOverlayImageViewDefaultInset , kELCOverlayImageViewDefaultInset, kELCOverlayImageViewDefaultInset);
    
    self.overlayView = [[UIView alloc] initWithFrame:CGRectZero];
    self.overlayView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    [self addSubview:self.overlayView];
    
    self.indexLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.indexLabel.backgroundColor = [UIColor redColor];
    self.indexLabel.clipsToBounds = YES;
    self.indexLabel.textAlignment = NSTextAlignmentCenter;
    self.indexLabel.textColor = [UIColor whiteColor];
    self.indexLabel.layer.shouldRasterize = YES;
    self.indexLabel.layer.borderWidth = 1.0f;
    self.indexLabel.layer.borderColor = [UIColor whiteColor].CGColor;
    self.indexLabel.font = [UIFont boldSystemFontOfSize:12];
    self.indexLabel.hidden = YES;
    [self addSubview:self.indexLabel];
    
    self.iconView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:self.iconView];
}

- (void)setIndex:(NSInteger)index
{
    _index = index;
    if(index>0 && self.showSelectionCounter) {
        self.indexLabel.text = [NSString stringWithFormat:@"%ld",(long)index];
        self.indexLabel.hidden = NO;
    }
    else {
        self.indexLabel.hidden = YES;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.overlayView.frame = self.bounds;
    
    [self.indexLabel sizeToFit];
    CGSize labelSize = self.indexLabel.frame.size;
    CGFloat largerDimension = (labelSize.width>labelSize.height) ? labelSize.width : labelSize.height;
    labelSize.width = (labelSize.width<labelSize.height) ? labelSize.height : labelSize.width;
    labelSize.width += labelPadding.width; // extra side padding
    labelSize.height += labelPadding.height;
    self.indexLabel.frame = CGRectMake(self.contentInsets.left, self.contentInsets.top, labelSize.width, labelSize.height);
    self.indexLabel.layer.cornerRadius = largerDimension/2.0;
    
    if(self.iconView.image) {
        CGSize iconSize = self.iconView.image.size;
        CGPoint iconViewOrigin;
        iconViewOrigin.x = self.frame.size.width - self.contentInsets.right - iconSize.width;
        iconViewOrigin.y = self.frame.size.height - self.contentInsets.bottom - iconSize.height;
        self.iconView.frame = CGRectMake(iconViewOrigin.x, iconViewOrigin.y, iconSize.width, iconSize.height);
    }
    
}



@end
