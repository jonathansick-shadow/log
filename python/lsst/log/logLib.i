// -*- lsst-c++ -*-
%define log_DOCSTRING
"
Access to the classes from the log library
"
%enddef

%feature("autodoc", "1");
%module(package="lsst.log", docstring=log_DOCSTRING) logLib

%naturalvar;
%include "std_string.i"

%{
#include "lsst/log/logInterface.h"
%}

%{
// Wrapper for Python callable object to make sure that we have GIL
// when we call Python. Note that we are leaking Python callable,
// as C++ callables may be (and actually are in our particular case) 
// outliving Python interpreter and attempt to delete Python object
// will result in crash.
class callable_wrapper {
public:
    callable_wrapper(PyObject* callable) : _callable(callable) {
        Py_XINCREF(_callable);
    }
    void operator()() {
        // make sure we own GIL before doing Python call
        auto state = PyGILState_Ensure();
        PyObject_CallObject(_callable, nullptr);
        PyGILState_Release(state);
    }
private:
    PyObject* _callable;
};
%}

// this should be for std::function<void()> but I can't convince SWIG
// to understand that syntax. Because we only have one type of function
// we can use more general std::function
%typemap(in) std::function {
    if (!PyCallable_Check($input)) {
        PyErr_SetString(PyExc_TypeError, "argument is not a callable");
        SWIG_fail;
    }
    $1 = std::function<void()>(callable_wrapper($input));
}

%include "lsst/log/logInterface.h"
