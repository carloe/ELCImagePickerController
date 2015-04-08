//
//  AssetCell.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ELCAssetCell : UITableViewCell

@property (nonatomic, assign) BOOL alignmentLeft;
@property (nonatomic, assign) CGFloat itemPadding;
@property (nonatomic, assign) NSInteger numberOfColumns;
@property (nonatomic, retain) UIImage *selectionIcon;
@property (nonatomic, assign) BOOL showSelectionCounter;

- (void)setAssets:(NSArray *)assets;

@end
