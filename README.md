Lacqit
======

Lacqit [1] is an Objective-C library that provides both UI and model classes.

Lacqit has dependencies on the Lacefx and LacqJS libraries, also available under the same MPLv2 license.

Lacefx is a C library, so some of the classes provided in Lacqit are Obj-C convenience wrappers for Lacefx objects and concepts. These are identified by the "LQLX" prefix (e.g. "LQLXSurface").

At one point there was a Windows+Linux port of Lacqit that used GTK+ for its GUI implementation. Some of the class hierarchies in Lacqit are explained by this history: for example the view controllers had both AppKit and GTK+ implementations. This is why you'll see the "_cocoa" suffix on some classes.

There are also Win32-specific classes included, for example the LQLacefxView class has separate implementations for both Cocoa OpenGL and Windows Direct3D.


[1] The name of the library is an awkward amalgamation of "Lacquer Kit".
