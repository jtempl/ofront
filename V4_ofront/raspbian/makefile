# makefile for ofront command line version and IDE based on libOberonV4
#
# environment variable for setting C compiler options: CCOPT

VERSION = raspbian-Pi3
RELEASE = 1.4
RELEASEDIR = ofront_$(RELEASE)
LIBRARY = libOberonV4.so
V4_ofront = V4_ofront
CONFIG = Configuration.Mod
TARDIR = /tmp/$(RELEASEDIR)
TARFILE = /tmp/ofront-$(RELEASE)_$(VERSION).tar

SETPATH = OBERON=.:../share
OFRONT = $(SETPATH) ofront -s

CC = cc $(CCOPT) -c
CL = cc $(CCOPT)
LD = cc $(CCOPT) -shared -o $(LIBRARY) -ldl -lm -L. -lX11

ARCHIVE = ar rc libOberonV4.a
RANLIB = 
CLOBERONOPTS = -L. -lOberonV4 -lX11 -ldl -lm
OCL = ocl.bash

OCAT = $(SETPATH) ocat
ZIP = gzip -f



all:    clean cmds  lib obrn wiring gpio rpi tarversion

clean:
	mv SYSTEM.h SYSTEM.h.save
	rm -f libOberonV4.so oberon showdef ocat ofront
	rm -f *.c *.o *.sym *.s *.h a.out core
	mv SYSTEM.h.save SYSTEM.h

cmds:   ofcmds cccmds lnkcmds

ofcmds:
	$(OFRONT) SYSTEM.Mod -iapx Args.Mod Console.Mod ../share/Modules.Mod Unix.Mod Kernel.Mod Files.Mod -x \
		Reals.Mod CmdlnTexts.Mod OfrontOPM.cmdln.Mod OfrontOPS.Mod -x OfrontOPT.Mod\
		OfrontOPC.Mod OfrontOPV.Mod OfrontOPB.Mod OfrontOPP.Mod \
		OfrontCmd.Mod -m BrowserCmd.Mod -m OCatCmd.Mod -m

cccmds:
	$(CC) \
		SYSTEM.c Args.c Console.c Modules.c Unix.c Kernel.c Files.c Reals.c CmdlnTexts.c \
		OfrontOPM.c OfrontOPS.c OfrontOPT.c OfrontOPC.c OfrontOPV.c OfrontOPB.c OfrontOPP.c

lnkcmds:
	$(CL) \
		OfrontCmd.c -o ofront \
		SYSTEM.o Args.o Console.o Modules.o Unix.o Kernel.o Files.o Reals.o CmdlnTexts.o \
		OfrontOPM.o OfrontOPS.o OfrontOPT.o OfrontOPC.o OfrontOPV.o OfrontOPB.o OfrontOPP.o
	$(CL) \
		BrowserCmd.c -o showdef \
		SYSTEM.o Args.o Console.o Modules.o Unix.o Kernel.o Files.o Reals.o CmdlnTexts.o \
		OfrontOPM.o OfrontOPS.o OfrontOPT.o OfrontOPV.o OfrontOPC.o
	$(CL) \
		OCatCmd.c -o ocat \
		SYSTEM.o Args.o Console.o Modules.o Unix.o Kernel.o Files.o Reals.o CmdlnTexts.o
	$(OFRONT) \
		OfrontOPC.Mod

lib:    oflib  cclib   lnklib

oflib:
	$(OFRONT) \
		Modules.Mod X11.Mod Display.Mod Strings.Mod \
		Input.Mod Math.Mod MathL.Mod MathLX.Mod Fonts.Mod Viewers.Mod \
		Texts.Mod Oberon.Mod MenuViewers.Mod TextFrames.Mod \
		In.Mod Out.Mod Printer.Mod TextPrinter.Mod ParcElems.Mod \
		System.Mod Edit.Mod EdiT.Mod EditTools.Mod MenuElems.Mod IconElems.Mod \
		ClockElems.Mod TextPFrames.Mod TextPreview.Mod \
		TableElems.Mod  StyleElems.Mod FoldElems.Mod Folds.Mod ErrorElems.Mod \
		ChartElems.Mod LineElems.Mod PopupElems.Mod StampElems.Mod \
		AsciiCoder.Mod Miscellaneous.Mod FKeys.Mod \
		Colors.Mod FontToBDF.Mod \
		Types.Mod Display1.Mod KeplerPorts.Mod KeplerGraphs.Mod \
		KeplerFrames.Mod Kepler.Mod Kepler1.Mod Kepler2.Mod Kepler4.Mod \
		Kepler5.Mod Kepler6.Mod Kepler7.Mod Kepler8.Mod Kepler9.Mod \
		KeplerElems.Mod Mailer.Mod Dates.Mod \
		Graphics.Mod GraphicFrames.Mod GraphicElems.Mod GraphicOps.Mod Draw.Mod \
		Rectangles.Mod Curves.Mod Splines.Mod

cclib:
	$(CC) \
		Modules.c X11.c Display.c Strings.c \
		Input.c Math.c MathL.c MathLX.c Fonts.c Viewers.c \
		Texts.c Oberon.c MenuViewers.c TextFrames.c \
		In.c Out.c Printer.c TextPrinter.c ParcElems.c System.c  \
		Edit.c EdiT.c EditTools.c MenuElems.c IconElems.c ClockElems.c \
		TableElems.c StyleElems.c FoldElems.c Folds.c ErrorElems.c \
		ChartElems.c LineElems.c PopupElems.c StampElems.c\
		AsciiCoder.c Miscellaneous.c FKeys.c \
		TextPFrames.c TextPreview.c Colors.c FontToBDF.c \
		Types.c Display1.c KeplerPorts.c KeplerGraphs.c \
		KeplerFrames.c Kepler.c Kepler1.c Kepler2.c Kepler4.c \
		Kepler5.c Kepler6.c Kepler7.c Kepler8.c Kepler9.c KeplerElems.c Mailer.c \
		Dates.c Graphics.c GraphicFrames.c GraphicElems.c GraphicOps.c Draw.c \
		Rectangles.c Curves.c Splines.c

lnklib:
	$(LD) \
		SYSTEM.o Args.o Console.o Modules.o \
		Unix.o Kernel.o Files.o X11.o Display.o Strings.o Dates.o \
		Input.o Math.o MathL.o MathLX.o Fonts.o Viewers.o Reals.o\
		Texts.o CmdlnTexts.o Oberon.o MenuViewers.o TextFrames.o \
		In.o Out.o Printer.o TextPrinter.o ParcElems.o System.o\
		Edit.o EdiT.o EditTools.o MenuElems.o IconElems.o ClockElems.o\
		TableElems.o  StyleElems.o FoldElems.o Folds.o ErrorElems.o\
		ChartElems.o LineElems.o PopupElems.o StampElems.o\
		AsciiCoder.o Miscellaneous.o FKeys.o \
		TextPFrames.o TextPreview.o Colors.o FontToBDF.o\
		Types.o Display1.o KeplerPorts.o KeplerGraphs.o\
		KeplerFrames.o Kepler.o Kepler1.o Kepler2.o Kepler4.o\
		Kepler5.o Kepler6.o Kepler7.o Kepler8.o Kepler9.o KeplerElems.o Mailer.o \
		Graphics.o GraphicFrames.o GraphicElems.o GraphicOps.o Draw.o \
		Rectangles.o Curves.o Splines.o

	$(ARCHIVE) \
		SYSTEM.o Args.o Console.o Modules.o \
		Unix.o Kernel.o Files.o X11.o Display.o Strings.o Dates.o \
		Input.o Math.o MathL.o MathLX.o Fonts.o Viewers.o Reals.o\
		Texts.o CmdlnTexts.o Oberon.o MenuViewers.o TextFrames.o \
		In.o Out.o Printer.o TextPrinter.o ParcElems.o System.o\
		Edit.o EdiT.o EditTools.o MenuElems.o IconElems.o ClockElems.o\
		TableElems.o  StyleElems.o FoldElems.o Folds.o ErrorElems.o\
		ChartElems.o LineElems.o PopupElems.o StampElems.o\
		AsciiCoder.o Miscellaneous.o FKeys.o \
		TextPFrames.o TextPreview.o Colors.o FontToBDF.o\
		Types.o Display1.o KeplerPorts.o KeplerGraphs.o\
		KeplerFrames.o Kepler.o Kepler1.o Kepler2.o Kepler4.o\
		Kepler5.o Kepler6.o Kepler7.o Kepler8.o Kepler9.o KeplerElems.o Mailer.o \
		Graphics.o GraphicFrames.o GraphicElems.o GraphicOps.o Draw.o \
		Rectangles.o Curves.o Splines.o

	$(RANLIB)

obrn:
	$(OFRONT) \
		OfrontOPM.Mod OfrontOPC.Mod Ofront.Mod Browser.Mod $(CONFIG) -m
	$(CC) \
		Ofront.c OfrontOPM.c Browser.c 
	$(CL) Configuration.c OfrontOPC.c -o oberon \
		Ofront.o OfrontOPM.o Browser.o OfrontOPS.o OfrontOPT.o OfrontOPV.o OfrontOPB.o OfrontOPP.o \
		$(CLOBERONOPTS)

wiring:
	$(OFRONT) WiringPi.Mod
	$(CL) -shared -o libWiringPi.so WiringPi.c -lwiringPi

gpio:
	$(OFRONT) GPIO.Mod
	$(CL) -shared -o libGPIO.so GPIO.c

rpi:
	$(OFRONT) RPI.Mod
	$(CL) -shared -o libRPI.so RPI.c

tarversion: prepversion tar

prepversion:
	cp oberon /tmp/oberon
	cp ofront /tmp/ofront

tar:
	rm -fr $(TARDIR)
	mkdir $(TARDIR)
	mkdir $(TARDIR)/bin
	mkdir $(TARDIR)/lib
	mkdir $(TARDIR)/$(V4_ofront)
	cp $(OCL) oberon.bash $(TARDIR)
	chmod -R a+rx $(TARDIR)
	cp showdef ocat $(TARDIR)/bin
	cp /tmp/ofront $(TARDIR)/bin/ofront
	cp /tmp/oberon $(TARDIR)/bin/oberon
	cp $(LIBRARY) $(TARDIR)/lib
	cp libOberonV4.a $(TARDIR)/lib
	cp Args.h             Folds.h            KeplerFrames.h     Printer.sym \
		Args.sym           Folds.sym          KeplerFrames.sym   Reals.h \
		AsciiCoder.h       FontToBDF.h        KeplerGraphs.h     Reals.sym \
		AsciiCoder.sym     FontToBDF.sym      KeplerGraphs.sym   SYSTEM.h \
		Browser.h          Fonts.h            KeplerPorts.h      StampElems.h \
		Browser.sym        Fonts.sym          KeplerPorts.sym    StampElems.sym \
		ChartElems.h       IconElems.h        Kernel.h           StyleElems.h \
		ChartElems.sym     IconElems.sym      Kernel.sym         StyleElems.sym \
		ClockElems.h       In.h               LineElems.h        System.h \
		ClockElems.sym     In.sym             LineElems.sym      System.sym \
		Colors.h           Input.h            Math.h             TableElems.h \
		Colors.sym         Input.sym          Math.sym           TableElems.sym \
		Console.h          Kepler.h           MathL.h            TextFrames.h \
		Console.sym        Kepler.sym         MathL.sym          TextFrames.sym \
		Display.h          Kepler1.h          MenuElems.h        TextPFrames.h \
		Display.sym        Kepler1.sym        MenuElems.sym      TextPFrames.sym \
		Display1.h         Kepler2.h          MenuViewers.h      TextPreview.h \
		Display1.sym       Kepler2.sym        MenuViewers.sym    TextPreview.sym \
		EdiT.h             Kepler4.h          Miscellaneous.h    TextPrinter.h \
		EdiT.sym           Kepler4.sym        Miscellaneous.sym  TextPrinter.sym \
		Edit.h             Kepler5.h          Texts.h     CmdlnTexts.sym     CmdlnTexts.h \
		Edit.sym           Kepler5.sym        Modules.h          Texts.sym \
		EditTools.h        Kepler6.h          Modules.sym        Types.h \
		EditTools.sym      Kepler6.sym        Oberon.h           Types.sym \
		ErrorElems.h       Kepler7.h          Oberon.sym         Unix.h \
		ErrorElems.sym     Kepler7.sym        Out.h              Unix.sym \
		FKeys.h            Kepler8.h          Out.sym            Viewers.h \
		FKeys.sym          Kepler8.sym        ParcElems.h        Viewers.sym \
		Files.h            Kepler9.h          ParcElems.sym      X11.h \
		Files.sym          Kepler9.sym        PopupElems.h       X11.sym \
		FoldElems.h        KeplerElems.h      PopupElems.sym \
		FoldElems.sym      KeplerElems.sym    Printer.h \
		Mailer.h	Mailer.sym	Strings.h	Strings.sym \
		WiringPi.h	WiringPi.sym	MathLX.h	MathLX.sym \
		Dates.h	Dates.sym	CallMarkStack.c0 \
		Graphics.h GraphicFrames.h GraphicElems.h GraphicOps.h Draw.h \
		Graphics.sym GraphicFrames.sym GraphicElems.sym GraphicOps.sym Draw.sym \
		Rectangles.h Curves.h Splines.h \
		Rectangles.sym Curves.sym Splines.sym \
		$(TARDIR)/$(V4_ofront)
	cp ../share/$(CONFIG) $(TARDIR)/$(V4_ofront)/Configuration.Mod
	cp Ofront.par  Modules.Mod  Kernel.Mod  Reals.Mod  Unix.Mod \
		Syntax10.Scn.Fnt $(TARDIR)/$(V4_ofront)
	cp libWiringPi.so  libGPIO.so  libRPI.so  $(TARDIR)/lib
	cp WiringPi.Mod GPIO.Mod GPIO.c0 RPI.Mod RPI.c0 \
		My.Tool TestPi.Mod TestPiMain.Mod $(TARDIR)/$(V4_ofront)
	chmod -R a+x $(TARDIR)/bin $(TARDIR)/lib $(TARDIR)/oberon.bash
	chmod -R a-w $(TARDIR)/*/*
	chmod -R a+r $(TARDIR)
	rm -f /tmp/ofront /tmp/oberon
	cd $(TARDIR)/..; tar cf $(TARFILE) $(RELEASEDIR)
	$(ZIP) $(TARFILE)
	echo "created file" $(TARFILE).gz
