#include <windows.h>
#include <stdbool.h>

// typedef gdi lib.
typedef HDC 	WINAPI	( *_GetDC )( HWND );
typedef HDC 	WINAPI	( *_GetDCEx )( HWND, HRGN, DWORD );
typedef HDC 	WINAPI	( *_CreateCompatibleDC )( HDC );
typedef HBITMAP WINAPI	( *_CreateDIBSection )( HDC, BITMAPINFO*, UINT, VOID**, HANDLE, DWORD );
typedef HGDIOBJ WINAPI	( *_SelectObject )( HDC, HGDIOBJ );
typedef BOOL 	WINAPI	( *_BitBlt )( HDC, int, int, int, int, HDC, int, int, DWORD );
typedef int 	WINAPI	( *_ReleaseDC )( HWND, HDC );
typedef BOOL 	WINAPI	( *_DeleteDC )( HDC );
typedef BOOL 	WINAPI	( *_DeleteObject )( HGDIOBJ );

// gdi function struct
typedef struct gdiLib {
	_GetDC  				GetDC;
	_GetDCEx				GetDCEx;
	_CreateCompatibleDC 	CreateCompatibleDC;
	_CreateDIBSection  		CreateDIBSection;
	_SelectObject  			SelectObject;
	_BitBlt  				BitBlt;				// If the function succeeds, the return value is nonzero.
	_ReleaseDC  			ReleaseDC;			// If the DC was not released, the return value is zero.
	_DeleteDC				DeleteDC;			// If the function succeeds, the return value is nonzero
	_DeleteObject			DeleteObject;		// If the function succeeds, the return value is nonzero.
} gdiLib, *pGdiLib;



// params struct
typedef struct params {
	HWND sHwnd;		// source window, NULL -> screen.
	pGdiLib gdi;	// struct of function pointers to gdi functions.
	void* ppvBits;	// return - pixel data
	HBITMAP hbm;	// return - caller must delete when done with ppvBits
	int x;			// dimensions
	int y;
	int w;
	int h;
	HRGN  hrgnClip;	// GetDCEx params
	DWORD flags;	// ...
	int dir;		// Direction 1 or -1 (bottom->up, top->down)
} params, *ppar;

