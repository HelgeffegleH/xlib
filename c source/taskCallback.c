#include <windef.h>

typedef void (*udFn)(void*);
typedef BOOL WINAPI (*_PostMessage)(HWND,UINT,WPARAM,LPARAM);
typedef struct udf	{					// User defined function and pointer to arguments
	udFn	pudFn;						// Function pointer of type udFn
	void* 	pParams;					// Pointer to arguments
} *pudf;

typedef struct params {
	pudf			userStruct;			// A struct on the form of udf 
	_PostMessage 	pPostMessage;		// For posting message to "calling thread".
	HWND 			hwnd;				// handle to the window which will recieve the msg.
	WPARAM 			wParam;				// "this" reference
	LPARAM 			lParam;				// callbackNumber
	unsigned int 	msg;				// message number
} *pPar;

void taskCallback(pPar par){
	par->userStruct->pudFn(par->userStruct->pParams);
	par->pPostMessage(par->hwnd,par->msg,par->wParam,par->lParam);
}