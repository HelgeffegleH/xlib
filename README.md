### Note

This is an example branch, consider this branch and the entire repo in _alpha_ stage. This branch features one example function.

## Documentation

### `xDllCall`

Asynchronously calls a function in memory or inside a DLL, such as a standard Windows API function.

```autohotkey
xDllCall(callback, function, Type1, Arg1, Type2, Arg2, ..., ReturnType)
```

### Parameters

* `Callback`, a function object which will be called when the asynchronous exectution of `function` completes. This function must accept one parameter, see below. This parameter is optional.

The remaining parameters are the same as for the built-in function [`DllCall`](https://lexikos.github.io/v2/docs/commands/DllCall.htm) with the following differences,

* Suffix `*` or `p` is not supported for the types `astr/wstr/str`.
* At most `14` parameters are supported. 
* To call a variadic function on __64-bit__  build, specify `...`, (three dots) for the `ReturnType`, in addition to the (optional) calling convention and return type. The `...` is ignored on __32-bit__ build.

### The callback function

The callback function is called with one parameter, which is an object, holding the result from the execution of `function`. To retrieve the value of parameter `i`, access member `i` of the result object. I.e, `param_i := result_object[i]`. The return value is stored at `i := 0`. Example,

```autohotkey
callback := (result_object) => msgbox( 'The function returned: ' . result_object[0] . '.')
xDllCall callback, 'msvcrt.dll\atan2', 'double', 2.0, 'double', 3.0, 'cdecl double'
```