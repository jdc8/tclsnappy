package require critcl 3

namespace eval ::snappy {
}

critcl::license {Jos Decoster} {LGPLv3 / BSD}
critcl::summary {A Tcl wrapper for the Google compression/decompression library}
critcl::description {
A Tcl wrapper for the Google compression/decompression library (http://code.google.com/p/snappy/)
}
critcl::subject {Snappy} {snappy}
critcl::subject {compression} {decompression}

critcl::meta origin https://github.com/jdc8/tclsnappy

critcl::userconfig define mode {choose mode of Crossroads I/O to build and link against.} {static dynamic}

if {[string match "win32*" [::critcl::targetplatform]]} {
    critcl::clibraries -llibsnappy -luuid -lws2_32 -lcomctl32 -lrpcrt4
    switch -exact -- [critcl::userconfig query mode] {
	static {
	    critcl::cflags /DDLL_EXPORT
	}
	dynamic {
	}
    }
} else {
    switch -exact -- [critcl::userconfig query mode] {
	static {
	    critcl::clibraries -l:libsnappy.a -lstdc++
	}
	dynamic {
	    critcl::clibraries -lsnappy
	}
    }

    critcl::clibraries -lpthread -lm

    if {[string match "macosx*" [::critcl::targetplatform]]} {
	critcl::clibraries -lgcc_eh
    } else {
	critcl::clibraries -lrt
    }
}

critcl::cflags -ansi -pedantic -Wall


# Get local build configuration
set cfgfnm [file dirname [info script]]/snappy_config.tcl
if {[file exists $cfgfnm]} {
    set fd [open $cfgfnm]
    eval [read $fd]
    close $fd
}

critcl::tcl 8.5
critcl::tsources snappy_helper.tcl

critcl::ccode {
#include "snappy-c.h"
}

critcl::ccommand ::snappy::compress {cd ip objc objv} {
    const char* input = 0;
    int input_length;
    size_t output_length = 0;
    char* output = 0;
    if (objc != 2) {
	Tcl_WrongNumArgs(ip, 1, objv, "string");
	return TCL_ERROR;
    }
    input = Tcl_GetStringFromObj(objv[1], &input_length);
    output_length = snappy_max_compressed_length(input_length);
    output = ckalloc(output_length);
    if (snappy_compress(input, input_length, output, &output_length) != SNAPPY_OK) {
	ckfree(output);
	Tcl_SetObjResult(ip, Tcl_NewStringObj("Snappy compression failed", -1));
	return TCL_ERROR;
    }
    Tcl_SetObjResult(ip, Tcl_NewStringObj(output, output_length));
    ckfree(output);
    return TCL_OK;
}

critcl::ccommand ::snappy::uncompress {cd ip objc objv} {
    const char* input = 0;
    int input_length;
    size_t output_length = 0;
    char* output = 0;
    if (objc != 2) {
	Tcl_WrongNumArgs(ip, 1, objv, "string");
	return TCL_ERROR;
    }
    input = Tcl_GetStringFromObj(objv[1], &input_length);
    if (snappy_uncompressed_length(input, input_length, &output_length) != SNAPPY_OK) {
	Tcl_SetObjResult(ip, Tcl_NewStringObj("Snappy uncompression failed", -1));
	return TCL_ERROR;
    }
    output = ckalloc(output_length);
    if (snappy_uncompress(input, input_length, output, &output_length) != SNAPPY_OK) {
	ckfree(output);
	Tcl_SetObjResult(ip, Tcl_NewStringObj("Snappy uncompression failed", -1));
	return TCL_ERROR;
    }
    Tcl_SetObjResult(ip, Tcl_NewStringObj(output, output_length));
    ckfree(output);
    return TCL_OK;
}

critcl::ccommand ::snappy::validate_compressed_buffer {cd ip objc objv} {
    const char* input = 0;
    int input_length;
    if (objc != 2) {
	Tcl_WrongNumArgs(ip, 1, objv, "string");
	return TCL_ERROR;
    }
    input = Tcl_GetStringFromObj(objv[1], &input_length);
    Tcl_SetObjResult(ip, Tcl_NewIntObj(snappy_validate_compressed_buffer(input, input_length) == SNAPPY_OK));
    return TCL_OK;
}

critcl::cinit {
} {
}

package provide snappy 1.0.0
