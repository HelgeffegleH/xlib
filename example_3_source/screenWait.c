#include "common.h"

typedef unsigned int __stdcall (*sleep)(unsigned int);
typedef DWORD  __stdcall (*getTickCount)(void);
typedef void __stdcall (*_cBitmap)(ppar);

int screenWait( _cBitmap cb, sleep psleep, getTickCount tic, HWND hwnd, pGdiLib gdi, int x, int y, int w, int h, HRGN hrgnClip, DWORD flags, int dir, unsigned int sleep_time, unsigned int timeout){
	// returns 0 if screen changed, 1 if timed out, negative if error when getting snapshot.
	params p1 = {hwnd, gdi, 0, 0, x, y, w, h, hrgnClip, flags, dir};
	params p2 = {hwnd, gdi, 0, 0, x, y, w, h, hrgnClip, flags, dir};
	
	// get first snapshot.
	cb ( &p1 );
	if ( !p1.hbm )
		return -1;	// error getting first snapshot
	int result = 1;
	size_t pixel_count = w * h;
	int i;	// loop index
	const unsigned int* old_bits;
	const unsigned int* new_bits;

	DWORD tick_1 = tic ();
	do {
		psleep ( sleep_time );
		cb ( &p2 );
		if ( !p2.hbm ) {
			result = -2;	// error getting snapshot
			break;
		}
		
		// compare the snapshots
		old_bits = (const unsigned int*) p1.ppvBits;
		new_bits = (const unsigned int*) p2.ppvBits;
		i = 0;
		while (i < pixel_count) {
			if (old_bits[ i ] != new_bits[ i ]) {
				result = 0; // screen changed
				break; // stop compairison
			}
			i++;
		}
		gdi->DeleteObject ( p2.hbm );
		
	} while (result && ( timeout == 0xffffffff || tic() - tick_1 < timeout ) );
	gdi->DeleteObject( p1.hbm );
	return result;
}

