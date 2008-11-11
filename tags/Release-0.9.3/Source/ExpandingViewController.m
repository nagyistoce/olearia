//
//  ExpandingViewController.m
//  Olearia
//
//  Created by Kieren Eaton on 4/05/08.
//  Copyright 2008 BrainBender Software. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "ExpandingViewController.h"

@implementation ExpandingViewController

- (void) awakeFromNib 
{
	// get thw windows content view 
    NSView *contentView = [[toolsBoxView window] contentView];
   
	// add our subview
    [contentView addSubview:toolsBoxView];
	[toolsBoxView setContentView:soundView];
	//[toolsBoxView setTitle:@"Sound"];
	
	isExpanded = NO;
	
}

- (IBAction)displaySoundView:(id)sender
{
	CGFloat windowDelta = 0;
	
	
	// get the current window frame
    NSRect newWindowFrame = [[toolsBoxView window] frame];
	
	if(isExpanded)
	{
		if([toolsBoxView contentView] == soundView)
		{
			windowDelta -= [toolsBoxView convertSize:[toolsBoxView frame].size toView:nil].height;
		}
	}
	else
		windowDelta += [toolsBoxView convertSize:[toolsBoxView frame].size toView:nil].height;

		//[toolsBoxView setHidden:NO];
	//[[NSAnimationContext currentContext] setDuration:0.5];
	[NSAnimationContext beginGrouping];
	
	//if([toolsBoxView frame].size.height > [soundView frame].size.height)
	//	vie
	
	//[[toolsBoxView animator] setTitle:@"Sound"];
	[[toolsBoxView animator] setContentView:soundView];
	
	
    // change the window height by the delta we computed above
    newWindowFrame.size.height += windowDelta;
    // keep the upper left of the window in the same place, by moving the lower left by the same delta
    newWindowFrame.origin.y -= windowDelta;
   
	[[[toolsBoxView window] animator] setFrame:newWindowFrame display:YES animate:YES];
	
	[NSAnimationContext endGrouping];
	
	isExpanded = !isExpanded;
	/*
	if (windowDelta > 0) {
        // before we start resizing the window, make sure the new size will fit onscreen
        NSRect constrainedWindowFrame = [docWindow constrainFrameRect:newWindowFrame toScreen:[docWindow screen]];
        if (!(NSEqualRects(constrainedWindowFrame, newWindowFrame))) {
            // adjust window frame so it can grow by windowDelta height 
            NSRect adjustedWindowFrame = constrainedWindowFrame;
            adjustedWindowFrame.size.height -=  windowDelta;
            adjustedWindowFrame.origin.y += windowDelta;
            [docWindow setFrame:adjustedWindowFrame display:YES animate:YES];
            newWindowFrame = constrainedWindowFrame;
        }
    }
	*/
	
}

/*
// updateView is invoked to change hide/show the detail view, or to change which detail view is shown
- (void)updateView 
{
    NSWindow *appWindow = [toolsBox window];
    NSView *newView;
   
    NSRect newViewFrame = NSZeroRect;
    NSRect currentViewFrame = NSZeroRect;
    NSMutableArray *viewAnimations = [NSMutableArray array];
    
    // figure out which view we want to show, or if we want to hide the detail view
    if (!_expanded) {
        // hide the detail view
        newView = nil;
    } else if ([self showingStockTransaction]) {
        // show the stock transaction detail view
        newView = _stockTransactionView;
    } else {
        // show the bank transaction detail view
        newView = _bankTransactionView;
    }
    // if there is no change from what we are already showing, we're done
    if (newView == _currentView) return;
 
    // make sure any previous animation has stopped
    if (_animation) {
        // set progress to 1.0 so that animation will display its last frame (eg. to get correct window height)
        [_animation setCurrentProgress:1.0f];
        [_animation stopAnimation];
    }

    if (newView != nil) {
        // the window should grow by the size of the new view, in window coordinates
        newViewFrame = [newView frame];
        windowDelta += [newView convertSize:newViewFrame.size toView:nil].height;
    }
    
    if (_currentView != nil) {
        // the window should shrink by the size of the current view, in window coordinates
        currentViewFrame = [_currentView frame];
        windowDelta -= [_currentView convertSize:currentViewFrame.size toView:nil].height;
    }

    // calculate new window frame
    NSRect newWindowFrame = [docWindow frame];
    // change the window height by the delta we computed above
    newWindowFrame.size.height += windowDelta;
    // keep the upper left of the window in the same place, by moving the lower left by the same delta
    newWindowFrame.origin.y -= windowDelta;
    if (windowDelta > 0) {
        // before we start resizing the window, make sure the new size will fit onscreen
        NSRect constrainedWindowFrame = [docWindow constrainFrameRect:newWindowFrame toScreen:[docWindow screen]];
        if (!(NSEqualRects(constrainedWindowFrame, newWindowFrame))) {
            // adjust window frame so it can grow by windowDelta height 
            NSRect adjustedWindowFrame = constrainedWindowFrame;
            adjustedWindowFrame.size.height -=  windowDelta;
            adjustedWindowFrame.origin.y += windowDelta;
            [docWindow setFrame:adjustedWindowFrame display:YES animate:YES];
            newWindowFrame = constrainedWindowFrame;
        }
    }
    
    // temporarily pin the existing views to the top of  the window, so that they don't resize or move during the window resize below
    [_upperTableScrollView setAutoresizingMask:NSViewMinYMargin];
    [_middleBoxView setAutoresizingMask:NSViewMinYMargin];
        
    // hide old view, if any
    if (_currentView != nil) {
        NSRect endFrame = newViewFrame;
        endFrame.size.width = NSWidth(currentViewFrame);                // same width
        if (currentViewFrame.size.height < newViewFrame.size.height) {
            // if new view is taller than current view, set end frame for current view to be appropriate offset from bottom of window
            endFrame.origin.y = NSHeight(newViewFrame) - NSHeight(currentViewFrame);
            endFrame.size.height = NSHeight(currentViewFrame);
        }
        NSDictionary *animateOutDict = [NSDictionary dictionaryWithObjectsAndKeys:
            _currentView, NSViewAnimationTargetKey,
            NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
            [NSValue valueWithRect:endFrame], NSViewAnimationEndFrameKey,
            nil];
        [viewAnimations addObject:animateOutDict];
    }

    // resize window
    NSDictionary *windowSizeDict = [NSDictionary dictionaryWithObjectsAndKeys:docWindow, NSViewAnimationTargetKey, [NSValue valueWithRect:newWindowFrame], NSViewAnimationEndFrameKey, nil];
    [viewAnimations addObject:windowSizeDict];
    
    // show new view, if any
    if (newView != nil) {
        NSRect startFrame = currentViewFrame;
        startFrame.size.width = NSWidth(newViewFrame);                                  // same width
        if (newViewFrame.size.height < currentViewFrame.size.height) {                  
            // if new view is shorter than old view, animate into appropriate offset from bottom of window
            startFrame.origin.y = NSHeight(currentViewFrame) - NSHeight(newViewFrame);
            startFrame.size.height = NSHeight(newViewFrame);
        }
        NSDictionary *animateInDict = [NSDictionary dictionaryWithObjectsAndKeys:
            newView, NSViewAnimationTargetKey, 
            NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, 
            [NSValue valueWithRect:startFrame], NSViewAnimationStartFrameKey,
            [NSValue valueWithRect:newViewFrame], NSViewAnimationEndFrameKey,
            nil];
        
        [viewAnimations addObject:animateInDict];
    }

    _currentView = newView;
    
    _animation = [[NSViewAnimation alloc] initWithViewAnimations:viewAnimations];
    [_animation setDelegate:self];
    [_animation startAnimation];
}

- (void)animationDidStop:(NSAnimation*)animation {
    [self animationDidEnd:animation];
}

- (void)animationDidEnd:(NSAnimation*)animation {
    // since we may have adjusted the origin during animation, restore the correct origins.  This is important for the view that has been hidden
    [_stockTransactionView setFrameOrigin:NSZeroPoint];
    [_bankTransactionView  setFrameOrigin:NSZeroPoint];
    [_animation release];
    _animation = nil;
    
    // restore the resizing masks on the scrollView and middleBoxView.  
    // the scrollView should resize when the window resizes - NSViewHeightSizable|NSViewWidthSizable
    [_upperTableScrollView setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
    // the middleBoxView should preserve its size and position relative to lower left - NSViewNotSizable
    [_middleBoxView setAutoresizingMask:NSViewNotSizable];
}

// key value observing
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // if we have changed whether a transaction is a stock or bank transaction, update which detail view we show
    if ([keyPath isEqualToString:@"selection.stockTransaction"]) {
        [self updateView];
    }
}

- (IBAction)disclosureToggle:(id)sender 
{
    // the user has toggled the disclosure triangle to hide or show the detail view
    _expanded = ([sender state] == NSOnState);
    if (_expanded) {
        // while the detail view is shown, we need to be notified of any changes to the type of transaction (bank or stock)
        [_transactionController addObserver:self forKeyPath:@"selection.stockTransaction" options:0 context:NULL];    
    } else {
        // while the detail view is hidden, we do not need to be notified of changes to the type of transaction
        [_transactionController removeObserver:self forKeyPath:@"selection.stockTransaction"];
    }
    // hide or show the detail view
    [self updateView];
}
*/
@end
