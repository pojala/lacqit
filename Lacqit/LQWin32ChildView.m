//
//  LQWin32ChildView.m
//  Lacqit
//
//  Created by Pauli Ojala on 4.6.2010.
//  Copyright 2010 Lacquer oy/ltd. All rights reserved.
//

#import "LQWin32ChildView.h"
#import <windows.h>
#include <Lacefx/LXStringUtils.h>


//#define DEBUGLOG(format, args...)
#define DEBUGLOG(format, args...)          NSLog(format , ## args);



@interface NSObject (CocotronWin32WindowMethods) 
+ (id)windowWithWindowNumber:(int)windowNumber;
- (HWND)windowHandle;
- (CGRect)frame;
@end


@implementation LQWin32ChildView

static LRESULT CALLBACK lqChildWindowProcedure(HWND handle,UINT message,WPARAM wParam,LPARAM lParam)
{
   if (message == WM_PAINT){    
    ValidateRect(handle, NULL);
    return 1;
   }
   
   if (message == WM_MOUSEACTIVATE)
    return MA_NOACTIVATE;

   if (message == WM_ACTIVATE)
    return 1;

   if (message == WM_ERASEBKGND)
    return 1;
        
   return DefWindowProc(handle,message,wParam,lParam);
}

+ (const char *)win32WindowClassName
{
    const char *s = "LQWin32ChildViewWindow";
    return s;
}

static void initWin32State()
{
    static BOOL registerWindowClass = NO;
    if ( !registerWindowClass) {
        static WNDCLASSEX windowClass;
                
        windowClass.cbSize=sizeof(WNDCLASSEX);
        windowClass.style=CS_HREDRAW|CS_VREDRAW|CS_OWNDC|CS_DBLCLKS;
        windowClass.lpfnWndProc=lqChildWindowProcedure;
        windowClass.cbClsExtra=0;
        windowClass.cbWndExtra=0;
        windowClass.hInstance=NULL;
        windowClass.hIcon=NULL;
        windowClass.hCursor=LoadCursor(NULL,IDC_ARROW);
        windowClass.hbrBackground=NULL;
        windowClass.lpszMenuName=NULL;
        windowClass.lpszClassName=[LQWin32ChildView win32WindowClassName];
        windowClass.hIconSm=NULL;
        
        DEBUGLOG(@"registering '%s'", windowClass.lpszClassName);
        
        if(RegisterClassEx(&windowClass)==0)
            NSLog(@"** %s: RegisterClass failed", __func__);
        
        registerWindowClass = TRUE;
   }
}

- (void)_createChildWindow
{
    DEBUGLOG(@"%s, %@", __func__, self);
    initWin32State();

    HWND child = CreateWindowEx(0, [LQWin32ChildView win32WindowClassName], "",
                                  WS_POPUP,  //|WS_CLIPCHILDREN|WS_CLIPSIBLINGS,
                                  0, 0 ,1, 1, NULL, NULL,
                                  GetModuleHandle(NULL), NULL);
    if ( !child) {
        int error = GetLastError();
        NSLog(@"*** %s (%p): could not create child window: error %i", __func__, self, error);
    }
    DEBUGLOG(@"... child window created");
    
    SetWindowPos(child, HWND_TOP, 0, 0, 0, 0, 
                SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE);  //|SWP_SHOWWINDOW);
                
    _childWindow = child;
    
    DEBUGLOG(@"%s, %@ -- child window is %p", __func__, self, _childWindow);
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    
    return self;
}

- (void)dealloc
{
    DestroyWindow((HWND)_childWindow);
    _childWindow = NULL;
    
    [super dealloc];
}

-(void)viewDidMoveToSuperview
{
    //NSLog(@"%s", __func__);
    if ( !_childWindow)
        [self _createChildWindow];

    [self update];
}

-(void)viewDidMoveToWindow
{
    //NSLog(@"%s", __func__);
    if ( !_childWindow)
        [self _createChildWindow];
    
    [self update];
}

- (void)awakeFromNib
{
    //NSLog(@"%s", __func__);
    //[self viewDidMoveToSuperview];
}

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
    //NSLog(@"%s, %@", __func__, NSStringFromRect(frame));
    if (_childWindow) {
        [self update];
    }
}

- (void *)nativeChildWindow {
    return _childWindow;
}

- (void)getChildWindowWidth:(int *)outW height:(int *)outH
{
    if ( !_childWindow) {
        if (outW) *outW = 0;
        if (outH) *outH = 0;
        return;
    }

	RECT wndRect;
	GetClientRect((HWND)_childWindow, &wndRect);
    
    if (outW)  *outW = wndRect.right - wndRect.left;
    if (outH)  *outH = wndRect.bottom - wndRect.top;
}
    

// private function in Cocotron
extern void CGNativeBorderFrameWidthsForStyle(unsigned styleMask,CGFloat *top,CGFloat *left,CGFloat *bottom,CGFloat *right);


static void adjustFrameInParent(id parentWindow, CGFloat *x,CGFloat *y,CGFloat *w,CGFloat *h)
{
   if (parentWindow) {
    CGFloat top,left,bottom,right;

    CGNativeBorderFrameWidthsForStyle([parentWindow styleMask],&top,&left,&bottom,&right);

    *y=[parentWindow frame].size.height-(*y+*h);

    *y-=top;
    *x-=left;
   }
}

- (void)update
{
    if ( !_childWindow) {
        NSLog(@"** %s: no child window yet", __func__);
        return;
    }

    if ( ![self window]) {
        NSLog(@"** %s: can't update, no window yet", __func__);
        return;
    }
    
    NSRect rectInWindow = [self convertRect:[self bounds] toView:nil];
    NSSize windowSize = [[[self window] contentView] bounds].size;
    
    CGFloat w = rectInWindow.size.width;
    CGFloat h = rectInWindow.size.height;
    CGFloat x = rectInWindow.origin.x;
    CGFloat y = rectInWindow.origin.y;  //windowSize.height - 1 - rectInWindow.origin.y - h;
    
    // the native Win32 window for this view.
    // this is fetched through Cocotron's private Win32Window class
    long windowNumber = [[self window] windowNumber];
    id parentWindow = [NSClassFromString(@"Win32Window") windowWithWindowNumber:windowNumber];
    HWND parentHandle = [parentWindow windowHandle];
    
    HWND child = (HWND)_childWindow;
    
    if ( !_childVisible) {
        SetProp(child, "self", parentWindow);
        SetParent(child, parentHandle);
        ShowWindow(child, SW_SHOWNOACTIVATE);
        _childVisible = YES;
    }
    
    adjustFrameInParent(parentWindow, &x, &y, &w, &h);

    DEBUGLOG(@"%s, %@ -- parent hwnd %p -- child hwnd %p -- bounds in window: %@ (win32 coords: %i, %i - %i * %i)", __func__, self,
                parentHandle, _childWindow, NSStringFromRect(rectInWindow),
                (int)x, (int)y, (int)w, (int)h);
    
    MoveWindow(child, x, y, w, h, NO);
}

- (void)_testPaintUsingGDI
{
    NSRect bounds = [self bounds];

    HDC dc = GetDC((HWND)_childWindow);
    
    ///NSLog(@"%s -- bounds %@ -- childwindow %p", __func__, NSStringFromRect(bounds), _childWindow);
    
    HBRUSH brush = CreateSolidBrush(RGB(255, 200, 0));
    SelectObject(dc, brush);
    Rectangle(dc, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);    
    DeleteObject(brush);
    
    HPEN pen = CreatePen(PS_SOLID, 2, RGB(255, 255, 255));
    SelectObject(dc, pen);
    MoveToEx(dc, bounds.origin.x + 10, bounds.origin.y + 10, NULL);
    LineTo(dc, bounds.origin.x + bounds.size.width - 20, bounds.origin.y + bounds.size.height - 20);
    DeleteObject(pen);
    
    ReleaseDC((HWND)_childWindow, dc);
}

- (void)drawRect:(NSRect)rect
{
    if ( !_childWindow) {
        [self _createChildWindow];
        if ( !_childWindow) return; // --
        
        [self update];
    }
    
    //[self _testPaintUsingGDI];
}

@end
