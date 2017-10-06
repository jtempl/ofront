ofront is an Oberon-2 to C translator written in Oberon-2. 
It supports both ANSI and K&R style C and supports cross 
translation to arbitrary target platforms. ofront includes 
a runtime system including an automatic garbage collector 
for Linux, the Oberon V4 system, and a set of command-line tools.

Download ofront 1.4 for Linux/i386 or Raspbian from http://www.software-templ.com/shareware.html.

The directory structure of the project ofront is as follows:

fonts
    A set of bitmap fonts for the Oberon system.
    This directory is not required for building ofront.

man1
    A set of section 1 manual pages.
    This directory is not required for building ofront.

V4
    A set of example modules and resource files for the original Oberon V4 system.
    This directory is not required for building ofront.

V4_ofront
    The files that are required for building ofront.

    share
        A set of source files not specific for any particular ofront version.

    linux386
        The set of files specifically adapted for the linux-386 version of ofront.
        This includes adapted low level modules as well as 
        the 'makefile' and the parameter file 'Ofront.par'.

    raspbian
        The set of files specifically adapted for the raspbian version of ofront.
        This includes adapted low level modules as well as 
        the 'makefile' and the parameter file 'Ofront.par'.
        This version is in many aspects similar to linux386.
        One difference is the added module WiringPi, which provides an interface to
        the popular libwiringPi.so for the Raspberry Pi.

