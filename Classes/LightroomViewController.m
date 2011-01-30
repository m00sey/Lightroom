//
//  LightroomViewController.m
//  Lightroom
//
//  Created by Kevin Griffin on 1/29/11.
//  Copyright 2011 Chariot Solutions LLC. All rights reserved.
//

#import "LightroomViewController.h"
#import "Tile.h"
#import <QuartzCore/QuartzCore.h>

@interface LightroomViewController ()
- (void)createTiles;
- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (CALayer *)layerForTouch:(UITouch *)touch;
- (int)frameIndexForTileIndex:(int)tileIndex;
- (int)indexOfClosestFrameToPoint:(CGPoint)point;
- (void)moveHeldTileToPoint:(CGPoint)location;
- (void)moveUnheldTilesAwayFromPoint:(CGPoint)location;
- (void)startTilesWiggling;
- (void)stopTilesWiggling;
- (void)redrawTiles:(NSNotification *)notification;
@end

@implementation LightroomViewController


#define TILE_WIDTH  120
#define TILE_HEIGHT 120
#define TILE_MARGIN 6

- (void)viewDidLoad {
    [super viewDidLoad];
	rows = DEFAULT_PORTRAIT_ROWS;
	cols = DEFAULT_PORTRAIT_COLS;
	[self createTiles];
	//we need to re-draw the tiles on rotation change
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(redrawTiles:) 
												 name:UIDeviceOrientationDidChangeNotification 
											   object:nil];
	
	//load default from user defaults
	
}

- (void) viewWillAppear:(BOOL)animated {
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[self createTiles];
}

-(void) viewWillDisappear:(BOOL)animated {
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark -
#pragma mark redrawTiles
-(void) redrawTiles:(NSNotification *) notification {
	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	
	if (UIDeviceOrientationIsLandscape(orientation)) {
		NSLog(@"Landscape");
		rows = DEFAULT_LANDSCASPE_ROWS;
		cols = DEFAULT_LANDSCASPE_COLS;
	} else if (UIDeviceOrientationIsPortrait(orientation)) {
		//Portrait Values
		NSLog(@"Portrait");
		rows = DEFAULT_PORTRAIT_ROWS;
		cols = DEFAULT_PORTRAIT_COLS;
	}
	
	//kill old ones
	[[[self view] layer] setSublayers:nil];
	
	for (int row = 0; row < rows; ++row) {
        for (int col = 0; col < cols; ++col) {
            int index = (row * cols) + col;
			
			Tile *arse = tileForFrame[index];
			NSLog(@"redrawing tile %d from array position %d", [arse tileIndex], index);
			//remake frame
			CGRect frame = CGRectMake(TILE_MARGIN + col * (TILE_MARGIN + TILE_WIDTH),
									  TILE_MARGIN + row * (TILE_MARGIN + TILE_HEIGHT),
									  TILE_WIDTH, TILE_HEIGHT);
			[arse setFrame:frame];
			[self.view.layer addSublayer:arse];
			[arse setNeedsDisplay];
		}
	}
}

- (void)createTiles {
    UIColor *tileColors[] = {
        [UIColor blueColor],
        [UIColor brownColor],
        [UIColor grayColor],
        [UIColor greenColor],
        [UIColor orangeColor],
        [UIColor purpleColor],
        [UIColor redColor],
    };

    int tileColorCount = sizeof(tileColors) / sizeof(tileColors[0]);
	
	[[[self view] layer] setSublayers:nil];
	
    for (int row = 0; row < rows; ++row) {
        for (int col = 0; col < cols; ++col) {
            int index = (row * cols) + col;
			
            CGRect frame = CGRectMake(TILE_MARGIN + col * (TILE_MARGIN + TILE_WIDTH),
                                      TILE_MARGIN + row * (TILE_MARGIN + TILE_HEIGHT),
                                      TILE_WIDTH, TILE_HEIGHT);
            tileFrame[index] = frame;
            Tile *tile = [[Tile alloc] init];
            tile.tileIndex = index;
            tileForFrame[index] = tile;
			[tile setFrame: frame];
            tile.backgroundColor = tileColors[index % tileColorCount].CGColor;
            tile.cornerRadius = 8;
            tile.delegate = self;
            [self.view.layer addSublayer:tile];
            [tile setNeedsDisplay];
            [tile release];
        }
    }
}


- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    UIGraphicsPushContext(ctx);
    
    Tile *tile = (Tile *)layer;
    [tile draw];
    
    UIGraphicsPopContext();
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CALayer *hitLayer = [self layerForTouch:[touches anyObject]];
    if ([hitLayer isKindOfClass:[Tile class]]) {
        Tile *tile = (Tile*)hitLayer;
        heldTile = tile;
        
        touchStartLocation = [[touches anyObject] locationInView:self.view];
        heldStartPosition = tile.position;
        heldFrameIndex = [self frameIndexForTileIndex:tile.tileIndex];
        [tile moveToFront];
        [tile appearDraggable];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (heldTile) {
        UITouch *touch = [touches anyObject];
        UIView *view = self.view;
        CGPoint location = [touch locationInView:view];
        [self moveHeldTileToPoint:location];
        [self moveUnheldTilesAwayFromPoint:location];
    }
}


- (void)moveHeldTileToPoint:(CGPoint)location {
    float dx = location.x - touchStartLocation.x;
    float dy = location.y - touchStartLocation.y;
    CGPoint newPosition = CGPointMake(heldStartPosition.x + dx, heldStartPosition.y + dy);
    
    [CATransaction begin];
    [CATransaction setDisableActions:TRUE];
    heldTile.position = newPosition;
    [CATransaction commit];
}


- (void)moveUnheldTilesAwayFromPoint:(CGPoint)location {
	//bug!
    int frameIndex = [self indexOfClosestFrameToPoint:location];
	NSLog(@"frame index %d",frameIndex);
	NSLog(@"held frame index %d", heldFrameIndex);
    if (frameIndex != heldFrameIndex) {
        [CATransaction begin];
		
        if (frameIndex < heldFrameIndex) {
            for (int i = heldFrameIndex; i > frameIndex; --i) {
                Tile *movingTile = tileForFrame[i-1];
                movingTile.frame = tileFrame[i];
                tileForFrame[i] = movingTile;
            }
        }
        else if (heldFrameIndex < frameIndex) {
            for (int i = heldFrameIndex; i < frameIndex; ++i) {
                Tile *movingTile = tileForFrame[i+1];
                movingTile.frame = tileFrame[i];
                tileForFrame[i] = movingTile;
            }
        }
        heldFrameIndex = frameIndex;
        tileForFrame[heldFrameIndex] = heldTile;
        
        [CATransaction commit];
		//[self redrawTiles:nil];
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (heldTile) {
        [heldTile appearNormal];
        heldTile.frame = tileFrame[heldFrameIndex];
        heldTile = nil;
    }
    //[self stopTilesWiggling];
	[self redrawTiles:nil];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}


- (CALayer *)layerForTouch:(UITouch *)touch {
    UIView *view = self.view;
    
    CGPoint location = [touch locationInView:view];
    location = [view convertPoint:location toView:nil];
    
    CALayer *hitPresentationLayer = [view.layer.presentationLayer hitTest:location];
    if (hitPresentationLayer) {
        return hitPresentationLayer.modelLayer;
    }
    
    return nil;
}


- (int)frameIndexForTileIndex:(int)tileIndex {
    for (int i = 0; i < DEFAULT_TILE_COUNT; ++i) {
        if (tileForFrame[i].tileIndex == tileIndex) {
            return i;
        }
    }
    return 0;
}


- (int)indexOfClosestFrameToPoint:(CGPoint)point {
	//still on the bug trail
    int index = 0;
    float minDist = FLT_MAX;
    for (int i = 0; i < DEFAULT_TILE_COUNT; ++i) {
        CGRect frame = tileFrame[i];
        
        float dx = point.x - CGRectGetMidX(frame);
        float dy = point.y - CGRectGetMidY(frame);
        
        float dist = (dx * dx) + (dy * dy);
        if (dist < minDist) {
            index = i;
            minDist = dist;
        }
    }
    return index;
}


- (void)startTilesWiggling {
    for (int i = 0; i < DEFAULT_TILE_COUNT; ++i) {
        Tile *tile = tileForFrame[i];
        if (tile != heldTile) {
            [tile startWiggling];
        }
    }
}


- (void)stopTilesWiggling {
    for (int i = 0; i < DEFAULT_TILE_COUNT; ++i) {
        Tile *tile = tileForFrame[i];
        [tile stopWiggling];
    }
}


@end
