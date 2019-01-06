#include "common.h"
#define ASSERT_NOT_NULL(a, label) if ((a) == 0) {p.hbm = NULL; goto cleanup_##label; }

void __stdcall cBitmap(ppar pp){
	
	params p = *pp;			// for convenience
	gdiLib lib = *p.gdi; 	// -- "" --
	
	pp->hbm = 0;				// Set this now to indicate error in case of early return.
	bool success = false;		// indicates wheter to delete return bitmap or not
	// init structs
	BITMAPINFO bmi;
	BITMAPINFOHEADER bih;
	bih.biSize = sizeof (BITMAPINFOHEADER);
	bih.biWidth = p.w;
	bih.biHeight = p.h * p.dir;			// see dir in params struct.
	bih.biPlanes = 1;
	bih.biBitCount = 32;
	bih.biCompression = BI_RGB;
	bih.biSizeImage = p.w * p.h * 4;
	bih.biClrUsed = 0;
	bih.biClrImportant = 0;
	bmi.bmiHeader = bih;
	
	// Create bitmap
	HDC hdc;
	if(p.sHwnd != NULL)
		hdc = lib.GetDCEx (p.sHwnd, p.hrgnClip, p.flags);	// window specified
	else 
		hdc = lib.GetDC (NULL);								// all screen
	
	ASSERT_NOT_NULL( hdc, 0 )
	
	HDC hdcComp = lib.CreateCompatibleDC ( hdc );
	ASSERT_NOT_NULL( hdcComp, 1 )
	
	HBITMAP hBitmapDIB = lib.CreateDIBSection ( hdcComp, &bmi, DIB_RGB_COLORS, &pp->ppvBits, NULL, 0 );
	ASSERT_NOT_NULL( hBitmapDIB, 2 )
	HBITMAP hBitmapSelect = (HBITMAP) lib.SelectObject ( hdcComp, hBitmapDIB );
	ASSERT_NOT_NULL( hBitmapSelect, 2 )
	ASSERT_NOT_NULL( lib.BitBlt( hdcComp, 0, 0, p.w, p.h, hdc, p.x, p.y, SRCCOPY ), 3)
	hBitmapDIB = lib.SelectObject ( hdcComp, hBitmapSelect );
	
	// Save resulting handle
	pp->hbm = hBitmapDIB;					// caller must delete this when done with ppvBits.
	success = true;							// indicates that hBitmapDIB should not be deleted below, caller is responsible for deleting it.
	// Clean up
	cleanup_3:
	lib.DeleteObject ( hBitmapSelect );
	cleanup_2:
	lib.DeleteDC ( hdcComp );
	cleanup_1:
	lib.ReleaseDC ( p.sHwnd, hdc );
	if ( (!success) && hBitmapDIB )
		lib.DeleteObject ( hBitmapDIB );
	cleanup_0:
	return;
}