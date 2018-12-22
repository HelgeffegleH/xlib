; Basic msgbox example, press f1 to show messageboxes, script thread continues to run.

#include xdllcall.ahk

cb := (r) => msgbox( 'You clicked button: ' . r[] . '.')
ctr := 0

loop
	tooltip(a_index), sleep(25)

f1::xdllcall cb, 'MessageBox', 'ptr', 0, 'str', 'Hello from parallel thread: ' . ++ctr . '.', 'str', 'Title', 'uint', [0x1,0x22,0x33,0x44][random(1,4)], 'uint'
esc::exitapp