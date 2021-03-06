//
//  ELCAssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"
#import "ELCConsole.h"

#define kELCImagePickerDefaultIconWidth 28.0f
#define kELCImagePickerDefaultBorderWith 0.65f

static NSInteger const kELCAssetTablePickerColumns = 4;
static CGFloat const kELCAssetCellPadding = 2.0f;
static CGFloat const kELCAssetDefaultItemWidth = 80.0f;

@interface ELCAssetTablePicker ()

@property (nonatomic, assign) int columns;
@property(readonly) UIImage *defaultSelectionIcon;

@end

@implementation ELCAssetTablePicker

//Using auto synthesizers

- (instancetype)init {
    self = [super init];
    if(self) {
        self.selectionIcon = self.defaultOverlayImage;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Sets a reasonable default bigger then 0 for columns
    //So that we don't have a divide by 0 scenario
    self.columns = kELCAssetTablePickerColumns;
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	[self.tableView setAllowsSelection:NO];
    
    //Ensure that the the table has the same padding above the first row and below the last row
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, kELCAssetCellPadding)];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
	
    if (self.immediateReturn) {
        
    } else {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:NSLocalizedString(@"Loading...", nil)];
    }

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
    
    // Register for notifications when the photo library has changed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preparePhotos) name:ALAssetsLibraryChangedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.columns = self.view.bounds.size.width / kELCAssetDefaultItemWidth;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[ELCConsole mainConsole] removeAllIndex];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.columns = self.view.bounds.size.width / kELCAssetDefaultItemWidth;
    [self.tableView reloadData];
}

- (void)preparePhotos
{
    @autoreleasepool {
        
        [self.elcAssets removeAllObjects];
        [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            if (result == nil) {
                return;
            }
            
            ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
            [elcAsset setParent:self];
            
            BOOL isAssetFiltered = NO;
            if (self.assetPickerFilterDelegate &&
               [self.assetPickerFilterDelegate respondsToSelector:@selector(assetTablePicker:isAssetFilteredOut:)])
            {
                isAssetFiltered = [self.assetPickerFilterDelegate assetTablePicker:self isAssetFilteredOut:(ELCAsset*)elcAsset];
            }

            if (!isAssetFiltered) {
                [self.elcAssets addObject:elcAsset];
            }

         }];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            // scroll to bottom
            long section = [self numberOfSectionsInTableView:self.tableView] - 1;
            long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
            if (section >= 0 && row >= 0) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                     inSection:section];
                        [self.tableView scrollToRowAtIndexPath:ip
                                              atScrollPosition:UITableViewScrollPositionBottom
                                                      animated:NO];
            }
            
            [self.navigationItem setTitle:self.singleSelection ? NSLocalizedString(@"Pick Photo", nil) : NSLocalizedString(@"Pick Photos", nil)];
        });
    }
}


- (void)doneAction:(id)sender
{	
    NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
	    
	for (ELCAsset *elcAsset in self.elcAssets) {
		if ([elcAsset selected]) {
			[selectedAssetsImages addObject:elcAsset];
		}
	}
    if ([[ELCConsole mainConsole] onOrder]) {
        [selectedAssetsImages sortUsingSelector:@selector(compareWithIndex:)];
    }
    [self.parent selectedAssets:selectedAssetsImages];
}


- (BOOL)shouldSelectAsset:(ELCAsset *)asset
{
    NSUInteger selectionCount = 0;
    for (ELCAsset *elcAsset in self.elcAssets) {
        if (elcAsset.selected) selectionCount++;
    }
    BOOL shouldSelect = YES;
    if ([self.parent respondsToSelector:@selector(shouldSelectAsset:previousCount:)]) {
        shouldSelect = [self.parent shouldSelectAsset:asset previousCount:selectionCount];
    }
    return shouldSelect;
}

- (void)assetSelected:(ELCAsset *)asset
{
    if (self.singleSelection) {

        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
}

- (BOOL)shouldDeselectAsset:(ELCAsset *)asset
{
    if (self.immediateReturn){
        return NO;
    }
    return YES;
}

- (void)assetDeselected:(ELCAsset *)asset
{
    if (self.singleSelection) {
        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }

    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset.asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
    
    int numOfSelectedElements = [[ELCConsole mainConsole] numOfSelectedElements];
    if (asset.index < numOfSelectedElements - 1) {
        NSMutableArray *arrayOfCellsToReload = [[NSMutableArray alloc] initWithCapacity:1];
        
        for (int i = 0; i < [self.elcAssets count]; i++) {
            ELCAsset *assetInArray = [self.elcAssets objectAtIndex:i];
            if (assetInArray.selected && (assetInArray.index > asset.index)) {
                assetInArray.index -= 1;
                
                int row = i / self.columns;
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                BOOL indexExistsInArray = NO;
                for (NSIndexPath *indexInArray in arrayOfCellsToReload) {
                    if (indexInArray.row == indexPath.row) {
                        indexExistsInArray = YES;
                        break;
                    }
                }
                if (!indexExistsInArray) {
                    [arrayOfCellsToReload addObject:indexPath];
                }
            }
        }
        [self.tableView reloadRowsAtIndexPaths:arrayOfCellsToReload withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.columns <= 0) { //Sometimes called before we know how many columns we have
        self.columns = kELCAssetTablePickerColumns;
    }
    return ceil([self.elcAssets count] / (float)self.columns);
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    long index = path.row * self.columns;
    long length = MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {		        
        cell = [[ELCAssetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.itemPadding = kELCAssetCellPadding;
    cell.numberOfColumns = self.columns;
    cell.selectionIcon = self.selectionIcon;
    
    [cell setAssets:[self assetsForIndexPath:indexPath]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = ceilf((tableView.frame.size.width - (self.columns+1) * kELCAssetCellPadding) / self.columns + kELCAssetCellPadding);
    return height;
}

- (int)totalSelectedAssets
{
    int count = 0;
    
    for (ELCAsset *asset in self.elcAssets) {
		if (asset.selected) {
            count++;	
		}
	}
    
    return count;
}

#pragma mark Lazy Getter

// Draws an iOS 7 style checkbubble
- (UIImage *)defaultOverlayImage {
    static UIImage *defaultSelectionIcon;
    if(!defaultSelectionIcon) {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(kELCImagePickerDefaultIconWidth, kELCImagePickerDefaultIconWidth), NO, 0.0f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Color Declarations
        UIColor* backgroundColor = [UIColor colorWithRed:0.078 green:0.43 blue:0.87 alpha:1];
        UIColor* foregroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        
        // Shadow Declarations
        UIColor* dropShadowColor = [UIColor.blackColor colorWithAlphaComponent:0.2];
        CGSize dropShadowOffset = CGSizeMake(0.1, 1.1);
        CGFloat dropShadowBlurRadius = 1;
        
        // Glow Declarations
        UIColor* glowColor = [UIColor.blackColor colorWithAlphaComponent:0.5];
        CGSize glowOffset = CGSizeMake(0.1, 0.1);
        CGFloat glowBlurRadius = 3;
        
        // Calculate scale factor & offset
        CGFloat drawScale = 1.0 / 18.0 * kELCImagePickerDefaultIconWidth;
        CGFloat offset = round(kELCImagePickerDefaultIconWidth / 2.0);
        
        UIBezierPath* baseOvalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(-7, -7, 14, 14)];
        baseOvalPath.lineWidth = kELCImagePickerDefaultBorderWith;
        
        // Begin Drawing
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, offset, offset);
        CGContextScaleCTM(context, drawScale, drawScale);

        // Draw background glow
        CGContextSetShadowWithColor(context, glowOffset, glowBlurRadius, [glowColor CGColor]);
        CGContextBeginTransparencyLayer(context, NULL);
        [dropShadowColor setFill];
        [baseOvalPath fill];
        [dropShadowColor setStroke];
        [baseOvalPath stroke];
        CGContextEndTransparencyLayer(context);

        // Draw icon with dropshadow
        CGContextSetShadowWithColor(context, dropShadowOffset, dropShadowBlurRadius, [dropShadowColor CGColor]);
        CGContextBeginTransparencyLayer(context, NULL);
        // Draw the round base
        [backgroundColor setFill];
        [baseOvalPath fill];
        [foregroundColor setStroke];
        [baseOvalPath stroke];
        
        // Draw the right line of the checkmark
        UIBezierPath* checkRightPath = UIBezierPath.bezierPath;
        [checkRightPath moveToPoint: CGPointMake(3.5, -2.5)];
        [checkRightPath addLineToPoint: CGPointMake(-1.5, 2.5)];
        [checkRightPath addLineToPoint: CGPointMake(3.5, -2.5)];
        [checkRightPath closePath];
        checkRightPath.miterLimit = 4;
        checkRightPath.lineCapStyle = kCGLineCapSquare;
        checkRightPath.lineJoinStyle = kCGLineJoinMiter;
        checkRightPath.usesEvenOddFillRule = YES;
        [foregroundColor setStroke];
        checkRightPath.lineWidth = kELCImagePickerDefaultBorderWith;
        [checkRightPath stroke];
        
        // Draw the left line of the checkmark
        UIBezierPath* checkLeftPath = UIBezierPath.bezierPath;
        [checkLeftPath moveToPoint: CGPointMake(-1.5, 2.5)];
        [checkLeftPath addLineToPoint: CGPointMake(-3.5, 0.5)];
        [checkLeftPath addLineToPoint: CGPointMake(-1.5, 2.5)];
        [checkLeftPath closePath];
        checkLeftPath.miterLimit = 4;
        checkLeftPath.lineCapStyle = kCGLineCapSquare;
        checkLeftPath.lineJoinStyle = kCGLineJoinMiter;
        checkLeftPath.usesEvenOddFillRule = YES;
        [foregroundColor setStroke];
        checkLeftPath.lineWidth = kELCImagePickerDefaultBorderWith;
        [checkLeftPath stroke];
        CGContextEndTransparencyLayer(context);
        CGContextRestoreGState(context);
        
        defaultSelectionIcon = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return defaultSelectionIcon;
}

@end
