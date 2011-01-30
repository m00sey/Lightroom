//
//  LightroomViewController.h
//  Lightroom
//
//  Created by Kevin Griffin on 1/29/11.
//  Copyright 2011 Chariot Solutions LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

//Going to have to be dynamic

#define TILE_ROWS    8
#define TILE_COLUMNS 6
#define TILE_COUNT   (TILE_ROWS * TILE_COLUMNS)

#define DEFAULT_PORTRAIT_ROWS 8
#define DEFAULT_LANDSCASPE_ROWS 6
#define DEFAULT_PORTRAIT_COLS 6 
#define DEFAULT_LANDSCASPE_COLS 8
#define DEFAULT_TILE_COUNT (DEFAULT_PORTRAIT_COLS * DEFAULT_PORTRAIT_ROWS)

@class Tile;

@interface LightroomViewController : UIViewController {
@private
    CGRect   tileFrame[DEFAULT_TILE_COUNT];
    Tile    *tileForFrame[DEFAULT_TILE_COUNT];
    
    Tile    *heldTile;
    int      heldFrameIndex;
    CGPoint  heldStartPosition;
    CGPoint  touchStartLocation;
	
	int		 rows;
	int      cols;
}

@end

