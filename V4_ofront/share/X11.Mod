MODULE X11;	(* RC 12.10.92, JT 13.12.94 *)
(* Oberon interface to X Window System Version 11 *)

	IMPORT S := SYSTEM, Kernel, Console, Args;
	
	CONST
		WinNameStr = "ETH-Oberon (TM)";
		CopyrightStr = "  -  Copyright (c) 1991-95, ETH Zurich.";
		IconNameStr = "oberon";

		BackgroundCol = 0;
		ForegroundCol = 15;
		WhiteCol = BackgroundCol;
		BlackCol = ForegroundCol;

		(* drawing modes *)
		replace* = 0; paint* = 1; invert* = 2;
		(* color classes *)
		monochrome* = 0; grayscale* = 1; color* = 2;

	TYPE
		Pixmap* = LONGINT;

		Pattern* = LONGINT (* = PatternPtr *);
		PatternPtr* = POINTER TO PatternDesc;
		PatternDesc* = RECORD
			x*, y*: LONGINT;
			w*, h*: INTEGER;
			pixmap*: Pixmap
		END ;

		MetricDesc* = RECORD
			dx*, x*, y*, filler: INTEGER;
			p*: PatternDesc
		END ;

		Font* = POINTER TO Bytes;
		Bytes* = RECORD
			metrics*: ARRAY 256 OF MetricDesc;
			xid*: LONGINT
		END ;

		(* X types *)
		Display* = LONGINT;
		Window* = LONGINT;
		Drawable* = LONGINT;
		GC* = LONGINT;
		Bool* = LONGINT;
		Colormap* = LONGINT;
		Time* = LONGINT;
		Atom* = LONGINT;

		VisualID* = LONGINT;
		Visual* = RECORD
			extData*: LONGINT;
			visualid*: VisualID;
			class*: LONGINT;
			redMask*, greenMask*, blueMask*: LONGINT;
			bitsPerRgb*, mapEntries*: LONGINT
		END ;
		VisualPtr* = POINTER TO Visual;
		VisualInfo* = RECORD
			visual*: (*VisualPtr*) LONGINT;
			visualID*: VisualID;
			screen*, depth*, class*: LONGINT;
			redmask*, greenmask*, bluemask*: LONGINT;
			colomapsize*, bitsperrgb*: LONGINT
		END ;
		Color* = RECORD
			pixel*: LONGINT;
			red*, green*, blue*: INTEGER;
			flags*, pad*: CHAR
		END ;
		Point* = RECORD x*, y*: INTEGER END ;
		Rectangle* = RECORD x*, y*, w*, h*: INTEGER END ;
		Cursor* = LONGINT;
		KeySym* = LONGINT;
		KeyCode* = LONGINT;
		Event* = RECORD
			type*, serial*: LONGINT;
			sendEvent*: Bool;
			display*: Display;
			window*, root*, subwindow*: Window;
			time*, x*, y*, xRoot*, yRoot*, state*, button*: LONGINT;
			sameScreen*, focus*: Bool;
			state2*: LONGINT;
			pad*: ARRAY 32 OF LONGINT
		END ;
		SelectionEvent* = RECORD
			type*, serial*: LONGINT;
			sendEvent*: Bool;
			display*: Display;
			requestor*: Window;
			selection*, target*, property*: Atom;
			time*: Time
		END ;
		SelectionRequestEvent* = RECORD
			type*, serial*: LONGINT;
			sendEvent*: Bool;
			display*: Display;
			owner*, requestor*: Window;
			selection*, target*, property*: Atom;
			time*: Time
		END ;
		Image* = LONGINT;
		ImagePtr* = POINTER TO ImageDesc;
		ImageDesc* = RECORD
			width*, height*: LONGINT;
			xoffset*, format*, data*: LONGINT;
			byteOrder*, bitmapUnit*, bitmapBitOrder*: LONGINT;
			bitmapPad*, depth*, bytesPerLine*, bitsPerPixel*: LONGINT;
			redmask*, greenmask*, bluemask*: LONGINT;
			obdata*, createImage*, destroyImage*, getPixel*, putPixel*, subImage*, addPixel*: LONGINT
		END ;
		ErrorEvent* = RECORD
			type*: LONGINT;
			display*: Display;
			resourceid*, serial*: LONGINT;
			errorCode*, requestCode*, minorCode*: CHAR
		END ;
		ErrorEventPtr* = POINTER TO ErrorEvent;
		ErrorHandler* = PROCEDURE(display: Display; err: ErrorEventPtr): LONGINT;
		IOErrorHandler = PROCEDURE(display: Display): LONGINT;

		Modlist* = ARRAY 8, 32 OF CHAR;

	CONST (* X constants: <X11/X.h> *)
		False* = 0; True* = 1; None* = 0;
	(* line styles: *)
		LineSolid* = 0;
		LineOnOffDash* = 1;
		LineDoubleDash* = 2;
	(* cap styles: *)
		CapNotLast* = 0;
		CapButt* = 1;
		CapRound* = 2;
		CapProjecting* = 3;
	(* join styles: *)
		JoinMiter* = 0;
		JoinRound* = 1;
		JoinBevel* = 2;
	(* fill styles: *)
		FillSolid* = 0;
		FillTiled* = 1;
		FillStippled* = 2;
		FillOpaqueStippled* = 3;
	(* functions: *)
		GXand* = 1;
		GXcopy* = 3;
		GXxor* = 6;
		GXor* = 7;
		GXequiv* = 9;
	(* color flags: *)
		DoRed* = 1;
		DoGreen* = 2;
		DoBlue* = 4;
		DoAll* = DoRed + DoGreen + DoBlue;
	(* for CreateColormap : *)
		AllocNone* = 0;
		AllocAll* = 1;
	(* QueryBestSize Class: *)
		CursorShape* = 0;
		TileShape* = 1;
		StippleShape* = 2;
	(* visual classes: *)
		StaticGray* = 0;
		GrayScale* = 1;
		StaticColor* = 2;
		PseudoColor* = 3;
		TrueColor* = 4;
		DirectColor* = 5;
	(* arc modes: *)
		ArcChord* = 0;
		ArcPieSlice* = 1;
	(* polygone shape: *)
		Complex* = 0;
		Nonconvex* = 1;
		Convex* = 2;
	(* clip odering and origin: *)
		CoordModeOrigin* = 0;
		CoordModePrevious* = 1;
		Unsorted* = 0;
		YSorted* = 1;
		YXSorted* = 2;
		YXBanded* = 3;
	(* property modes: *)
		PropModeReplace* = 0;
	(* events types: *)
		KeyPress* = 2;
		ButtonPress* = 4;
		ButtonRelease* = 5;
		MotionNotify* = 6;
		FocusIn* = 9;
		FocusOut* = 10;
		Expose* = 12;
		GraphicsExpose* = 13;
		NoExpose* = 14;
		UnmapNotify* = 18;
		MapNotify* = 19;
		PropertyNotify* = 28;
		SelectionClear* = 29;
		SelectionRequest* = 30;
		SelectionNotify* = 31;
		ClientMessage* = 33;
		MappingNotify* = 34;
	(* event masks: *)
		KeyPressMask* = 1H;
		ButtonPressMask* = 4H;
		ButtonReleaseMask* = 8H;
		PointerMotionMask* = 40H;
		PointerMotionHintMask* = 80H;
		ButtonMotionMask* = 2000H;
		ExposureMask* = 8000H;
		StructureNotifyMask* = 20000H;
		FocusChangeMask* = 200000H;
		PropertyChangeMask* = 400000H;
		OwnerGrabButtonMask* = 1000000H;
	(* event modes:  <X11/Xlib.h> *)
		QueuedAlready* = 0;
		QueuedAfterReading* = 1;
		QueuedAfterFlush* = 2;
	(* focus revert modes: <X11/X.h> *)
		RevertToParent* = 2;
	(* buttons: *)
		Button1* = 1;
		Button2* = 2;
		Button3* = 3;
		Button1Mask* = 100H;
		Button2Mask* = 200H;
		Button3Mask* = 400H;
	(* image format: *)
		XYBitmap* = 0;
		XYPixmap* = 1;
		ZPixmap* = 2;
	(* special keys: <X11/keysymdef.h> *)
	(* cursor shapes: <X11/cursorfont.h> *)
		XCleftptr* = 132;
	(* atoms: <X11/Xatom.h> *)
		XAPRIMARY* = 1;
		XASTRING* = 31;

	(* line cache *)
		LcLen* = 256;

	VAR
		WinName*, IconName*, Copyright*, WinNameCopyright*: ARRAY 128 OF CHAR;
		display*: Display;
		primary*, secondary*, root*: Window;
		basePixel*, foreground*, background*: LONGINT;
		backgroundCol*, foregroundCol*: INTEGER;
		screen*, screenw*, screenh*, screenhmm*: LONGINT;
		cells*, planes*: LONGINT;
		visualptr*, defvisualptr*: LONGINT;
		cmap*, defcmap*: Colormap;
		Width*, Height*, Bottom*, UBottom*, ColLeft*, depth*: INTEGER;
		pixelValues*: ARRAY 256 OF LONGINT;
		function*: ARRAY 3 OF LONGINT;
		planesMask*: LONGINT;
		colorClass*: SHORTINT; (* monochrome, grayscale or color *)
		nofcol*: LONGINT;
		arrow*, noCursor*: Cursor;
		ErrorText*: ARRAY 80 OF CHAR;
		ErrorFlag*: BOOLEAN;
		lastEventTime*: Time;

	(* character cache *)
		ccp*: Pattern;
		ccf*: Font;
		ccch*: CHAR;
		ccdx*, ccx*, ccy*: INTEGER;

		lcache*: ARRAY LcLen OF CHAR;
		lcf*: Font;
		lcx0*, lcy0*, lcx*, lccol*, lcmode*, lclen*: INTEGER;

	(* cut and paste *)
		SendSelection*: PROCEDURE(VAR event: SelectionRequestEvent);
		ReceiveSelection*: PROCEDURE(VAR event: SelectionEvent);
		ClearSelection*: PROCEDURE;

		arrowSource, arrowMask, noCursorSource, noCursorMask: Pattern;
		RGB: ARRAY 257 OF RECORD r, g, b: INTEGER END;

		Gc: GC;	(* general purpose GC *)
		lastcol, lastmode: INTEGER;
		lastfont: Font;


	PROCEDURE -OpenDisplay*(name: ARRAY OF CHAR): LONGINT
			"(long)XOpenDisplay(name)";

	PROCEDURE -DefaultScreen*(display: Display): LONGINT
			"(long)XDefaultScreen(display)";

	PROCEDURE -DisplayWidth*(display: Display; screen: LONGINT): LONGINT
			"(long)XDisplayWidth(display, screen)";

	PROCEDURE -DisplayHeight*(display: Display; screen: LONGINT): LONGINT
			"(long)XDisplayHeight(display, screen)";

	PROCEDURE -DisplayHeightMM*(display: Display; screen: LONGINT): LONGINT
			"(long)XDisplayHeightMM(display, screen)";

	PROCEDURE -DefaultDepth*(display: Display; screen: LONGINT): LONGINT
			"(long)XDefaultDepth(display, screen)";

	PROCEDURE -DisplayCells*(display: Display; screen: LONGINT): LONGINT
			"(long)XDisplayCells(display, screen)";

	PROCEDURE -DisplayPlanes*(display: Display; screen: LONGINT): LONGINT
			"(long)XDisplayPlanes(display, screen)";

	PROCEDURE -BlackPixel*(display: Display; screen: LONGINT): LONGINT
			"(long)XBlackPixel(display, screen)";

	PROCEDURE -WhitePixel*(display: Display; screen: LONGINT): LONGINT
			"(long)XWhitePixel(display, screen)";

	PROCEDURE -DefaultVisual*(display: Display; screen: LONGINT): LONGINT
			"(long)XDefaultVisual(display, screen)";

	PROCEDURE -DefaultColormap*(display: Display; screen: LONGINT): Colormap
			"(long)XDefaultColormap(display, screen)";

	PROCEDURE -DefaultRootWindow*(display: Display): Window
			"(long)XDefaultRootWindow(display)";

	PROCEDURE -CreateSimpleWindow*(display: Display; parent: Window;
															x, y, width, height, borderWidth, border, background: LONGINT): Window
			"(long)XCreateSimpleWindow(display, parent, x, y, width, height, borderWidth, border, background)";

	PROCEDURE -TranslateCoordinates*(display: Display; sw, dw: Window; srcx, srcy: LONGINT;
															VAR dstx, dsty: LONGINT; VAR child: Window)
			"XTranslateCoordinates(display, sw, dw, srcx, srcy, dstx, dsty, child)";

	PROCEDURE -MoveResizeWindow*(display: Display; window: Window; x, y, width, height: LONGINT)
			"XMoveResizeWindow(display, window, x, y, width, height)";

	PROCEDURE -StoreName*(display: Display; window: Window; name: LONGINT)
			"XStoreName(display, window, name)";

	PROCEDURE -SetIconName*(display: Display; window: Window; name: LONGINT)
			"XSetIconName(display, window, name)";

	PROCEDURE -SetCommand*(display: Display; window: Window; argv, argc: LONGINT)
			"XSetCommand(display, window, argv, argc)";

	PROCEDURE -Geometry*(display: Display; screen: LONGINT; user, default: ARRAY OF CHAR;
											bwidth, fw, fh, xpad, ypad: LONGINT; VAR x, y, w, h: LONGINT): LONGINT
			"(long)XGeometry(display, screen, user, default, bwidth, fw, fh, xpad, ypad, x, y, w, h)";

	PROCEDURE -MapRaised*(display: Display; window: Window)
			"XMapRaised(display, window)";

	PROCEDURE -LowerWindow*(display: Display; window: Window)
			"XLowerWindow(display, window)";

	PROCEDURE -ClearWindow*(display: Display; window: Window)
			"XClearWindow(display, window)";

	PROCEDURE -Sync*(display: Display; discard: LONGINT)
			"XSync(display, discard)";

	PROCEDURE -Flush*(display: Display)
			"XFlush(display)";

	PROCEDURE -StoreColor*(display: Display; cmap: Colormap; color: LONGINT)
			"XStoreColor(display, cmap, color)";

	PROCEDURE -CreateBitmapFromData*(display: Display; drawable: Drawable;
															data: LONGINT; width, height: LONGINT): Pixmap
			"(long)XCreateBitmapFromData(display, drawable, data, width, height)";

	PROCEDURE -CopyArea*(display: Display; src, dest: Drawable; gc: GC; srcX, srcY, width, height, destX, destY: LONGINT)
			"XCopyArea(display, src, dest, gc, srcX, srcY, width, height, destX, destY)";

	PROCEDURE -CopyPlane*(display: Display; src, dest: Drawable; gc: GC;
										srcX, srcY, width, height, destX, destY, plane: LONGINT)
			"XCopyPlane(display, src, dest, gc, srcX, srcY, width, height, destX, destY, plane)";

	PROCEDURE -SetStipple*(display: Display; gc: GC; stipple: Pixmap)
			"XSetStipple(display, gc, stipple)";

	PROCEDURE -SetTSOrigin*(display: Display; gc: GC; tsxorigin, tsyorigin: LONGINT)
			"XSetTSOrigin(display, gc, tsxorigin, tsyorigin)";

	PROCEDURE -DrawPoint*(display: Display; window: Drawable; gc: GC; x, y: LONGINT)
			"XDrawPoint(display, window, gc, x, y)";

	PROCEDURE -FillRectangle*(display: Display; window: Drawable; gc: GC; x, y, width, height: LONGINT)
			"XFillRectangle(display, window, gc, x, y, width, height)";

	PROCEDURE -DrawString*(display: Display; window: Drawable; gc: GC; x, y, width, height: LONGINT)
			"XDrawString(display, window, gc, x, y, width, height)";

	PROCEDURE -CreateGC*(display: Display; drawable: Drawable; valueMask, values: LONGINT): GC
			"(long)XCreateGC(display, drawable, valueMask, values)";

	PROCEDURE -SetForeground*(display: Display; gc: GC; arg: LONGINT)
			"XSetForeground(display, gc, arg)";

	PROCEDURE -SetBackground*(display: Display; gc: GC; arg: LONGINT)
			"XSetBackground(display, gc, arg)";

	PROCEDURE -SetFunction*(display: Display; gc: GC; arg: LONGINT)
			"XSetFunction(display, gc, arg)";

	PROCEDURE -SetFont*(display: Display; gc: GC; arg: LONGINT)
			"XSetFont(display, gc, arg)";

	PROCEDURE -SetFillStyle*(display: Display; gc: GC; arg: LONGINT)
			"XSetFillStyle(display, gc, arg)";

	PROCEDURE -SetPlaneMask*(display: Display; gc: GC; mask: LONGINT)
			"XSetPlaneMask(display, gc, mask)";

	PROCEDURE -SetGraphicsExposures*(display: Display; gc: GC; graphicsExposures: Bool)
			"XSetGraphicsExposures(display,gc, graphicsExposures )";

	PROCEDURE -SetLineAttributes*(display: Display; gc: GC; lineWidth, lineStyle, capStyle, joinStyle: LONGINT)
			"XSetLineAttributes(display, gc, lineWidth, lineStyle, capStyle, joinStyle)";

	PROCEDURE -AllocColorCells*(display: Display; cmap: Colormap; contig: Bool;
												planeMasks, nplanes, pixels, ncolors: LONGINT): LONGINT
			"(long)XAllocColorCells(display, cmap, contig, planeMasks, nplanes, pixels, ncolors)";

	PROCEDURE -SetWindowBackground*(display: Display; window: Window; pixel: LONGINT)
			"XSetWindowBackground(display, window, pixel)";

	PROCEDURE -CreateFontCursor*(display: Display; shape: LONGINT): Cursor
			"(long)XCreateFontCursor(display, shape)";

	PROCEDURE -CreatePixmapCursor*(display: Display; csource, cmask: Pixmap;
														cfore, cback, xhot, yhot: LONGINT): Cursor
			"(long)XCreatePixmapCursor(display, csource, cmask, cfore, cback, xhot, yhot)";

	PROCEDURE -RecolorCursor*(display: Display; curs: Cursor; cfore, cback: LONGINT)
			"XRecolorCursor(display, curs, cfore, cback)";

	PROCEDURE -DefineCursor*(display: Display; window: Window; curs: Cursor)
			"XDefineCursor(display, window, curs)";

	PROCEDURE -DrawLine*(display: Display; window: Window; gc: GC; x1, y1, x2, y2: LONGINT)
			"XDrawLine(display, window, gc, x1, y1, x2, y2)";

	PROCEDURE -SetArcMode*(display: Display; gc: GC; arcmode: LONGINT)
			"XSetArcMode(display, gc, arcmode)";

	PROCEDURE -DrawArc*(display: Display; window: Window; gc: GC; x, y, width, height, angle1, angle2: LONGINT)
			"XDrawArc(display, window, gc, x, y, width, height, angle1, angle2)";

	PROCEDURE -FillArc*(display: Display; window: Window; gc: GC; x, y, width, height, angle1, angle2: LONGINT)
			"XFillArc(display, window, gc, x, y, width, height, angle1, angle2)";

	PROCEDURE -FillPolygon*(display: Display; window: Window; gc: GC; points, npoints, shape, mode: LONGINT)
			"XFillPolygon(display, window, gc, points, npoints, shape, mode)";

	PROCEDURE -SetClipMask*(display: Display; gc: GC; clipMask: Pixmap)
			"XSetClipMask(display, gc, clipMask)";

	PROCEDURE -SetClipRectangles*(display: Display; gc: GC; clipxorigin, clipyorigin, rectangles, n, ordering: LONGINT)
			"XSetClipRectangles(display, gc, clipxorigin, clipyorigin, rectangles, n, ordering)";

	PROCEDURE -ListFonts*(display: Display; pattern, maxnames: LONGINT; VAR count: LONGINT): LONGINT
			"(long)XListFonts(display, pattern, maxnames, count)";

	PROCEDURE -FreeFontNames*(list: LONGINT)
			"XFreeFontNames(list)";

	PROCEDURE -LoadFont*(display: Display; name: LONGINT): LONGINT
			"(long)XLoadFont(display, name)";

	PROCEDURE -SelectInput*(display: Display; window: Window; eventMask: LONGINT)
			"XSelectInput(display, window, eventMask)";

	PROCEDURE -NextEvent*(display: Display; event: LONGINT)
			"XNextEvent(display, event)";

	PROCEDURE -EventsQueued*(display: Display; mode: LONGINT): LONGINT
			"(long)XEventsQueued(display, mode)";

	PROCEDURE -SetInputFocus*(display: Display; focus: Window; revertTo: LONGINT; time: LONGINT)
			"XSetInputFocus(display, focus, revertTo, time)";

	PROCEDURE -LookupString*(event, buffer, bufsize: LONGINT;
												VAR keysym: KeySym; compstatus: LONGINT): LONGINT
			"(long)XLookupString(event, buffer, bufsize, keysym, compstatus)";

	PROCEDURE -QueryPointer*(display: Display; window: Window; VAR rw, cw: Window;
												VAR xr, yr, xw, yw, keysButtons: LONGINT)
			"XQueryPointer(display, window, rw, cw, xr, yr, xw, yw, keysButtons)";

	PROCEDURE -RefreshKeyboardMapping*(event: LONGINT)
			"XRefreshKeyboardMapping(event)";

	PROCEDURE -Bell*(display: Display; percent: LONGINT)
			"XBell(display, percent)";

	PROCEDURE -RebindKeysym*(display: Display; reboundsym: KeySym; modlist: LONGINT; modlength: LONGINT;
												newstring: LONGINT; newlength: LONGINT)
			"XRebindKeysym(display, reboundsym, modlist, modlength, newstring, newlength)";

	PROCEDURE -StringToKeysym*(string: LONGINT): KeySym
			"(long)XStringToKeysym(string)";

	PROCEDURE -CopyColormapAndFree*(display: Display; cmap: Colormap): Colormap
			"(long)XCopyColormapAndFree(display, cmap)";

	PROCEDURE -CreateColormap*(display: Display; window: Window; vis, alloc: LONGINT): Colormap
			"(long)XCreateColormap(display, window, vis, alloc)";

	PROCEDURE -MatchVisualInfo*(display: Display; screen, depth, class, vinforet: LONGINT): LONGINT
			"(long)XMatchVisualInfo(display, screen, depth, class, vinforet)";

	PROCEDURE -SetWindowColormap*(display: Display; window: Window; cmap: Colormap)
			"XSetWindowColormap(display, window, cmap)";

	PROCEDURE -QueryBestSize*(display: Display; class: LONGINT; screen: Drawable;
												width, height: LONGINT; VAR w, h: LONGINT)
			"XQueryBestSize(display, class, screen, width, height, w, h)";

	PROCEDURE -CreatePixmap*(display: Display; drawable: Drawable; width, height, depth: LONGINT): Pixmap
			"(long)XCreatePixmap(display,drawable, width, height, depth)";

	PROCEDURE -FreePixmap*(display: Display; pixmap: Pixmap)
			"XFreePixmap(display, pixmap)";

	PROCEDURE -CreateImage*(display: Display; visual: LONGINT; depth, format, offset, data, 
												width, height, bitmapPad, bytesPerLine: LONGINT): Image
			"(long)XCreateImage(display, visual, depth, format, offset, data, width, height, bitmapPad, bytesPerLine)";

	PROCEDURE -DestroyImage*(image: Image)
			"XDestroyImage(image)";

	PROCEDURE -SubImage*(image: Image; x, y, width, height: LONGINT): Image
			"(long)XSubImage(image, x, y, width, height)";

	PROCEDURE -GetImage*(display: Display; drawable: Drawable; x, y, 
										width, height, planeMask, format: LONGINT): Image
			"(long)XGetImage(display, drawable, x, y, width, height, planeMask, format)";

	PROCEDURE -GetSubImage*(display: Display; drawable: Drawable; x, y, width, height, planeMask, format: LONGINT;
												dstImage: Image; dstX, dstY: LONGINT): Image
			"(long)XGetSubImage(display, drawable, x, y, width, height, planeMask, format, dstImage, dstX, dstY)";

	PROCEDURE -PutImage*(display: Display; drawable: Drawable; gc: GC; image: Image; 
											srcX, srcY, dstX, dstY, width, height: LONGINT)
			"XPutImage(display, drawable, gc, image, srcX, srcY, dstX, dstY, width, height)";

	PROCEDURE -PutPixel*(image: Image; x, y, pixel: LONGINT): LONGINT
			"(long)XPutPixel(image, x, y, pixel)";

	PROCEDURE -GetPixel*(image: Image; x, y: LONGINT): LONGINT
			"(long)XGetPixel(image, x, y)";

	PROCEDURE -AddPixel*(image: Image; value: LONGINT)
			"XAddPixel(image, value)";

	PROCEDURE -Free*(data: LONGINT)
			"XFree(data)";

	PROCEDURE -SetErrorHandler*(handler: ErrorHandler)
			"XSetErrorHandler(handler)";

	PROCEDURE -GetErrorText*(display: Display; code, buffer, length: LONGINT)
			"XGetErrorText(display, code, buffer, length)";

	PROCEDURE -StoreBytes*(display: Display; bytes, nbytes: LONGINT)
			"XStoreBytes(display, bytes, nbytes)";

	PROCEDURE -FetchBytes*(display: Display; VAR nbytes: LONGINT): LONGINT
			"(long)XFetchBytes(display, nbytes)";

	PROCEDURE -SetSelectionOwner*(display: Display; selection: Atom; owner: Window; time: Time)
			"XSetSelectionOwner(display, selection, owner, time)";

	PROCEDURE -GetSelectionOwner*(display: Display; selection: Atom): Window
			"(long)XGetSelectionOwner(display, selection)";

	PROCEDURE -InternAtom*(display: Display; name: LONGINT; onlyifexists: Bool): Atom
			"(long)XInternAtom(display, name, onlyifexists)";

	PROCEDURE -SendEvent*(display: Display; window: Window; propagate: Bool; eventmask, event: LONGINT)
			"XSendEvent(display, window, propagate, eventmask, event)";

	PROCEDURE -ConvertSelection*(display: Display; selection, target, property: Atom; 
													requestor: Window; timestamp: Time)
			"XConvertSelection(display, selection, target, property, requestor, timestamp)";

	PROCEDURE -ChangeProperty*(display: Display; window: Window; property, type: Atom; 
													format, mode, data, nelements: LONGINT)
			"XChangeProperty(display, window, property, type, format, mode, data, nelements)";

	PROCEDURE -GetWindowProperty*(display: Display; window: Window; property: Atom; offset, length: LONGINT;
									delete: Bool; reqtype: Atom; VAR type: Atom; VAR format, nitems, bytesafter, prop: LONGINT)
			"XGetWindowProperty(display, window, property, offset, length, delete, reqtype, type, format, nitems, bytesafter, prop)";

	PROCEDURE -DeleteProperty*(display: Display; window: Window; property: Atom)
			"XDeleteProperty(display, window, property)";

	PROCEDURE -WarpPointer*(display: Display; srcwin, dstwin: Window; srcx, srcy, srcw, srch, dstx, dsty: LONGINT)
			"XWarpPointer(display, srcwin, dstwin, srcx, srcy, srcw, srch, dstx, dsty)";

	PROCEDURE -InstallColormap*(display: Display; cmap: Colormap)
			"XInstallColormap(display, cmap)";

	PROCEDURE -GetGeometry*(display: Display; drawable: Drawable;
												VAR root, x, y, width, height, orderWidth, Depth: LONGINT)
			"XGetGeometry(display, drawable, root, x, y, width, height, orderWidth, Depth)";

	PROCEDURE -ResizeWindow*(display: Display; window: Window; x, y: LONGINT)
			"XResizeWindow(display, window, x, y)";

	PROCEDURE -SetIOErrorHandler*(handler: IOErrorHandler)
			"XSetIOErrorHandler(handler)";


	PROCEDURE NewPattern*(VAR image: ARRAY OF SET; class: LONGINT; width, height: INTEGER): Pattern;
		VAR pixmap: Pixmap; pat: PatternPtr; w, h, i, j, b, dest, srcw, destb, srci, desti: LONGINT;
			data: ARRAY 256*32 OF CHAR; (* 256*256 bits *)
	BEGIN i := 0;
		WHILE i < LEN(data) DO data[i] := 0X; INC(i) END ;
		(*QueryBestSize(display, class, primary, width, height, w, h);*)
		(*WHILE w < width DO w := w*2 END ;*)
		(*WHILE h < height DO h := h*2 END ;*)
		w := width; h := height;
		srcw := (width+31) DIV 32; (* number of words in source line *)
		destb := (w+7) DIV 8; (* number of bytes in dest line *)
		srci := (height-1)*srcw; desti := 0;
		WHILE srci >= 0 DO
			i := 0; j := 0; b := 0; dest := 0;
			LOOP
				dest := dest DIV 2;
				IF b IN image[srci+j+1] THEN INC(dest, 80H) END;
				INC(b);
				IF b MOD 8 = 0 THEN
					data[desti+i] := CHR(dest); INC(i); dest := 0;
					IF i >= destb THEN EXIT END
				END;
				IF b = 32 THEN b := 0; INC(j);
					IF j >= srcw THEN
						WHILE i < destb DO data[desti+i] := 0X; INC(i) END;
						EXIT
					END
				END
			END;
			INC(desti, destb); DEC(srci, srcw)
		END;
		Kernel.Lock();
		pixmap := CreateBitmapFromData(display, primary, S.ADR(data[0]), w, h);
		Kernel.Unlock();
		IF pixmap = 0 THEN HALT(99) END ;
		pat := S.VAL(PatternPtr, Kernel.malloc(SIZE(PatternDesc)));
		pat.x := 0; pat.y := 0; pat.w := width; pat.h := height; pat.pixmap := pixmap;
		RETURN S.VAL(LONGINT, pat)
	END NewPattern;

	PROCEDURE RasterToPixmap*(base, width, height: LONGINT): LONGINT;
		VAR pixmap: Pixmap;
	BEGIN
		Kernel.Lock();
		pixmap := CreateBitmapFromData(display, primary, base, width, height);
		Kernel.Unlock();
		IF pixmap = 0 THEN HALT(99) END ;
		RETURN pixmap
	END RasterToPixmap;

	PROCEDURE SetColor*(col, red, green, blue: INTEGER);	(* 0 <= col, red, green, blue < 256 *)
		VAR xcol, cfore, cback: Color;
			error: ARRAY 15 OF CHAR;
	BEGIN
		Kernel.Lock();
		IF depth = 24 (* hack to support TrueColor displays *) THEN  
			pixelValues[col] := ASH(red, 16) + ASH(green, 8) + ASH(blue, 0)
		ELSIF depth = 16 (* e.g. Raspberry Pi default setting *) THEN
			pixelValues[col] := ASH(ASH(red, -3), 11) + ASH(ASH(green, -2), 5) + ASH(ASH(blue, -3), 0)
		END ;
		IF colorClass =  grayscale THEN green := red; blue := red END ;
		RGB[col+1].r := red; RGB[col+1].g := green; RGB[col+1].b := blue;
		IF (colorClass # monochrome) & (col >= 0) THEN
			xcol.red := 256*red; xcol.green := 256*green; xcol.blue := 256*blue;
			xcol.flags := CHR(DoAll);
			xcol.pixel := pixelValues[col];
			IF col < nofcol THEN
				StoreColor(display, cmap, S.ADR(xcol))
			ELSE Console.String("out of colors; try option -c"); Console.Ln; (*HALT(99)*)
			END ;
			IF ((col = BackgroundCol) OR (col = ForegroundCol)) & (arrow # 0) THEN
				cfore.red := 256*RGB[ForegroundCol+1].r;
				cfore.green := 256*RGB[ForegroundCol+1].g;
				cfore.blue := 256*RGB[ForegroundCol+1].b;
				cback.red := 256*RGB[BackgroundCol+1].r;
				cback.green := 256*RGB[BackgroundCol+1].g;
				cback.blue := 256*RGB[BackgroundCol+1].b;
				RecolorCursor(display, arrow, S.ADR(cfore), S.ADR(cback))
			END
		END ;
		Kernel.Unlock();
	END SetColor;

	PROCEDURE GetColor*(col: INTEGER; VAR red, green, blue: INTEGER);
	BEGIN red := RGB[col+1].r; green := RGB[col+1].g; blue := RGB[col+1].b
	END GetColor;

	PROCEDURE FlushLCache*;
		VAR gc: GC; window: Window;
	BEGIN
		Kernel.Lock();
		gc := Gc;
		IF lcmode = paint THEN lcmode := replace END ;
		(* DrawString modifies only foreground pixels, replace and paint modes work as Oberon paint mode *)
		IF lcmode # lastmode THEN SetFunction(display, gc, function[lcmode]); lastmode := lcmode END ;
		IF lccol # lastcol THEN SetForeground(display, gc, pixelValues[lccol]); lastcol := lccol END ;
		IF lcf # lastfont THEN SetFont(display, gc, lcf.xid); lastfont := lcf  END ;
		IF lcy0 >= 0 THEN window := primary ELSE window := secondary; DEC(lcy0, UBottom) END ;
		DrawString(display, window, gc, lcx0, Height-lcy0, S.ADR(lcache), lclen);
		lclen := 0;
		Kernel.Unlock()
	END FlushLCache;

	PROCEDURE DoSync*;
	BEGIN
		IF lclen > 0 THEN FlushLCache END ;
		Kernel.Lock(); Sync(display, 0); Kernel.Unlock()
	END DoSync;

	PROCEDURE DoFlush*;
	BEGIN
		IF lclen > 0 THEN FlushLCache END ;
		Kernel.Lock(); Flush(display); Kernel.Unlock()
	END DoFlush;

	PROCEDURE Rebind*(keyString: ARRAY OF CHAR; VAR modifierStrings: Modlist; nofmod: LONGINT;
									to: ARRAY OF CHAR; nofchar: LONGINT);
		VAR modlist: ARRAY 8 OF LONGINT; i: LONGINT;
	BEGIN i := 0;
		WHILE i < nofmod DO modlist[i] := StringToKeysym(S.ADR(modifierStrings[i])); INC(i) END ;
		RebindKeysym(display, StringToKeysym(S.ADR(keyString)), S.ADR(modlist), nofmod, S.ADR(to), nofchar)
	END Rebind;

	PROCEDURE InitNames;
		VAR i, j: INTEGER;
	BEGIN
		WinName := WinNameStr;
		Args.Get(Args.Pos("-title") + 1, WinName);
		IconName := IconNameStr;
		Args.Get(Args.Pos("-title") + 1, IconName);
		Copyright := CopyrightStr;
		WinNameCopyright := WinNameStr;
		i := 0; WHILE WinNameCopyright[i] # 0X DO INC(i) END ;
		j := 0; REPEAT WinNameCopyright[i] := Copyright[j]; INC(i); INC(j) UNTIL Copyright[j-1] = 0X
	END InitNames;

	PROCEDURE OpenDisp;
		VAR child: Window; flagmask, fd: LONGINT; event: Event;
			gRoot, gX, gY, gW, gH, gBW, gD, offset: LONGINT;
			defgeo: ARRAY 64 OF CHAR; i: INTEGER;
			displayArg, geometryArg: ARRAY 256 OF CHAR;
			coption: BOOLEAN;

		PROCEDURE Int(n: LONGINT);
			VAR j: INTEGER;
		BEGIN j := 64;
			WHILE n > 0 DO DEC(j); defgeo[j] := CHR(n MOD 10 + 48); n := n DIV 10 END ;
			WHILE j < 64 DO defgeo[i] := defgeo[j]; INC(i); INC(j) END
		END Int;
			
	BEGIN
		displayArg := ""; geometryArg := "";
		Args.Get(Args.Pos("-d") + 1, displayArg);
		Args.Get(Args.Pos("-g") + 1, geometryArg);
		display := OpenDisplay(displayArg);
		IF display = 0 THEN Console.String("Cannot open display"); Console.Ln; Kernel.Exit(1) END ;
		S.GET(display+8, fd);
		INCL(Kernel.readSet[0], fd);
		screen := DefaultScreen(display);
		screenw := DisplayWidth(display, screen);
		screenh := DisplayHeight(display, screen);
		screenhmm := DisplayHeightMM(display, screen);
		depth := SHORT(DefaultDepth(display, screen));
		visualptr := DefaultVisual(display, screen); defvisualptr := visualptr;
		cmap := DefaultColormap(display, screen); defcmap := cmap;
		cells := DisplayCells(display, screen);
		planes := DisplayPlanes(display, screen);
		IF ForegroundCol = BlackCol THEN
			foreground := BlackPixel(display, screen);
			background := WhitePixel(display, screen)
		ELSE
			foreground := WhitePixel(display, screen);
			background := BlackPixel(display, screen)
		END ;
		root := DefaultRootWindow(display);
		i := 0; Int(screenw - 2*4); defgeo[i] := "x"; INC(i);
		Int(screenh - 23 - 4); defgeo[i] := "+"; INC(i);
		Int(4); defgeo[i] := "+"; INC(i); Int(23); defgeo[i] := 0X;
		flagmask := Geometry(display, screen, geometryArg, defgeo, 0, 1, 1, 0, 0, gX, gY, gW, gH);
		primary := CreateSimpleWindow(display, root, gX, gY, gW, gH, 0, foreground, background);
		StoreName(display, primary, S.ADR(WinNameCopyright));
		SetIconName(display, primary, S.ADR(IconName));
		SetCommand(display, primary, Args.argv, Args.argc);
		SelectInput(display, primary, ExposureMask);
		MapRaised(display, primary);
		REPEAT NextEvent(display, S.ADR(event)) UNTIL (event.type = Expose) & (event.window = primary);

		(* adjust to physical window size *)
		GetGeometry(display, primary, gRoot, gX, gY, gW, gH, gBW, gD);
		IF gW MOD 8 # 0 THEN
			DEC (gW, gW MOD 8);
			ResizeWindow (display, primary, gW, gH);
		END;
		Width := SHORT(gW);
		Height := SHORT(gH);
		Bottom := 0;
		UBottom := -Height;

		(* pixmap cannot be larger than screen: *)
		IF gW > screenw THEN gW := SHORT(screenw) END ;
		IF gH > screenh THEN gH := SHORT(screenh) END ;
		(* very slow if wider than 1024: not on a SUN *)
(*		IF gW > 1024 THEN gW := 1024 END ;	*)
		secondary := CreatePixmap(display, primary, gW, gH, depth)
	END OpenDisp;

	PROCEDURE CreateColors;
		VAR col: INTEGER;
			planeMasks: ARRAY 8 OF LONGINT;
			visualInfo: VisualInfo;
			vis: VisualPtr; coption: BOOLEAN;
	BEGIN
		coption := Args.Pos("-c") < Args.argc;
		col := 0; WHILE col < 256 DO pixelValues[col] := col; INC(col) END ;
		IF ~coption & (depth <= 4) THEN colorClass := monochrome
		ELSIF MatchVisualInfo(display, screen, depth, PseudoColor, S.ADR(visualInfo)) = 1 THEN
			colorClass := color; visualptr := visualInfo.visual
		ELSIF MatchVisualInfo(display, screen, depth, GrayScale, S.ADR(visualInfo)) = 1 THEN
			colorClass := grayscale; visualptr := visualInfo.visual
		ELSE colorClass := monochrome
		END ;
		IF colorClass = monochrome THEN
			ColLeft := Width;
			nofcol := 2;
			basePixel := S.VAL(LONGINT, S.VAL(SET, foreground) * S.VAL(SET, background));
			planesMask := S.VAL(LONGINT, S.VAL(SET, foreground) / S.VAL(SET, background));
			colorClass := monochrome;
			pixelValues[BackgroundCol] := background;
			pixelValues[ForegroundCol] := foreground;
			col := 1;
			WHILE col <= 14  DO
				pixelValues[col] := foreground;
				INC(col)
			END
		ELSE
			ColLeft := 0;
			vis := S.VAL(VisualPtr, visualptr);
			IF coption THEN
				nofcol := vis.mapEntries;
				cmap := CreateColormap(display, primary, visualptr, AllocAll);
				SetWindowColormap(display, primary, cmap);
				basePixel := 0;
				planesMask := ASH(1, depth) - 1
			ELSE
				nofcol := 16;
				IF AllocColorCells(display, cmap, False, S.ADR(planeMasks), 4, S.ADR(basePixel), 1) = 0 THEN
					Console.String("Not enough color cells"); Console.Ln; 
					Console.String("Try option -c to allocate a private colormap");
					Console.Ln; Kernel.Exit(1)
				END ;
				col := 0;
				planesMask := 0;
				WHILE col < 4 DO
					planesMask := planesMask + planeMasks[col]; INC(col)
				END ;
				col := 0;
				WHILE col < 16 DO
					pixelValues[col] := basePixel + (col MOD 2) * planeMasks[0] + (col DIV 2 MOD 2) * planeMasks[1] +
						(col DIV 4 MOD 2) * planeMasks[2] + (col DIV 8 MOD 2) * planeMasks[3];
					INC(col)
				END
			END ;
			foreground := pixelValues[ForegroundCol];
			background := pixelValues[BackgroundCol];
			SetWindowBackground(display, primary, background);
			ClearWindow(display, primary)
		END
	END CreateColors;

	PROCEDURE CreateGc;
	BEGIN
		function[replace] := GXcopy;
		function[paint] := GXor;	(* not used *)
		(* drawing in invert mode with BackgroundCol on BackgroundCol is a no-op: *)
		IF S.VAL(SET, background) * S.VAL(SET, planesMask) # {} THEN function[invert] := GXequiv
		ELSE function[invert] := GXxor
		END ;
		Gc := CreateGC(display, primary, 0, 0);
		IF Gc = 0 THEN Console.String("Cannot create X graphic context"); Console.Ln; Kernel.Exit(1) END ;
		SetPlaneMask(display, Gc, planesMask);
		SetGraphicsExposures(display, Gc, True);
		SetBackground(display, Gc, background);
		lastcol := -1;
		lastmode := -1;
		lastfont := NIL
	END CreateGc;

	PROCEDURE InitColors*;	(* like in Linz Obern V4 *)
		VAR col, colScale: INTEGER;
	BEGIN
		IF colorClass = grayscale THEN
			IF BlackCol < WhiteCol THEN
				col := BlackCol;
				WHILE col <= WhiteCol DO
					SetColor(col, 17*col, 0, 0); INC(col)
				END
			ELSE
				col := WhiteCol;
				WHILE col <= BlackCol DO
					SetColor(col, 255 - 17*col, 0, 0); INC(col)
				END
			END
		ELSE
			colScale := 1;
			SetColor(BlackCol, 0, 0, 0); (*black*)
			SetColor(WhiteCol, 255, 255, 255); (*white*)
			SetColor(1, 255 DIV colScale, 0 DIV colScale, 0 DIV colScale);
			SetColor( 2, 0 DIV colScale, 255 DIV colScale, 0 DIV colScale);
			SetColor(3, 0 DIV colScale,  0 DIV colScale,  255 DIV colScale);
			SetColor(4, 255 DIV colScale, 0 DIV colScale, 255 DIV colScale);
			SetColor(5,  255 DIV colScale, 255 DIV colScale,  0 DIV colScale);
			SetColor( 6, 0 DIV colScale,  255 DIV colScale,  255 DIV colScale);
			SetColor( 7, 128 DIV colScale, 0 DIV colScale, 0 DIV colScale);
			SetColor( 8, 0 DIV colScale, 128 DIV colScale, 0 DIV colScale);
			SetColor( 9, 0 DIV colScale,   0 DIV colScale, 128 DIV colScale);
			SetColor(10, 166 DIV colScale, 202 DIV colScale, 240 DIV colScale);
			SetColor(11, 0 DIV colScale, 128 DIV colScale, 128 DIV colScale);
			SetColor(12, 192 DIV colScale, 192 DIV colScale, 192 DIV colScale);
			SetColor(13, 160 DIV colScale, 160 DIV colScale, 160 DIV colScale);
			SetColor(14, 128 DIV colScale, 128 DIV colScale, 128 DIV colScale);
		END
	END InitColors;
	
	PROCEDURE CreatePatterns;
		VAR image: ARRAY 17 OF SET; i: INTEGER;
	BEGIN
		image[1] := {};
		image[2] := {13};
		image[3] := {12..14};
		image[4] := {11..13};
		image[5] := {10..12};
		image[6] := {9..11};
		image[7] := {8..10};
		image[8] := {1, 7..9};
		image[9] := {1, 2, 6..8};
		image[10] := {1..3, 5..7};
		image[11] := {1..6};
		image[12] := {1..5};
		image[13] := {1..6};
		image[14] := {1..7};
		image[15] := {1..8};
		image[16] := {};
		arrowSource := NewPattern(image, CursorShape, 16, 16);

		image[1] := {13};
		image[2] := {12..14};
		image[3] := {11..15};
		image[4] := {10..14};
		image[5] := {9..13};
		image[6] := {8..12};
		image[7] := {0..1, 7..11};
		image[8] := {0..2, 6..10};
		image[9] := {0..3, 5..9};
		image[10] := {0..8};
		image[11] := {0..7};
		image[12] := {0..6};
		image[13] := {0..7};
		image[14] := {0..8};
		image[15] := {0..9};
		image[16] := {0..9};
		arrowMask := NewPattern(image, CursorShape, 16, 16);

		i := 1; WHILE i < 17 DO image[i] := {}; INC(i) END ;
		noCursorSource := NewPattern(image, CursorShape, 16, 16);
		noCursorMask := NewPattern(image, CursorShape, 16, 16)
	END CreatePatterns;

	PROCEDURE InitCursors;
		VAR cfore, cback: Color; csource, cmask: PatternPtr;
	BEGIN
		cfore.red := 256*RGB[ForegroundCol+1].r; cfore.green := 256*RGB[ForegroundCol+1].g; cfore.blue := 256*RGB[ForegroundCol+1].b;
		cback.red := 256*RGB[BackgroundCol+1].r; cback.green := 256*RGB[BackgroundCol+1].g; cback.blue := 256*RGB[BackgroundCol+1].b;
		csource := S.VAL(PatternPtr, arrowSource);
		cmask := S.VAL(PatternPtr, arrowMask);
		arrow := CreatePixmapCursor(display, csource.pixmap, cmask.pixmap, S.ADR(cfore), S.ADR(cback), 1, 1);
		csource := S.VAL(PatternPtr, noCursorSource);
		cmask := S.VAL(PatternPtr, noCursorMask);
		noCursor := CreatePixmapCursor(display, csource.pixmap, cmask.pixmap, S.ADR(cfore), S.ADR(cback), 1, 1)
	END InitCursors;

	PROCEDURE MyErrorHandler*(display: Display; err: ErrorEventPtr): LONGINT;
	BEGIN
		ErrorFlag := TRUE;
		GetErrorText(display, ORD(err.errorCode), S.ADR(ErrorText), LEN(ErrorText));
		RETURN 0
	END MyErrorHandler;

	PROCEDURE MyIOErrorHandler(display: Display): LONGINT;
	BEGIN ErrorFlag := TRUE; Kernel.Exit(0)
	END MyIOErrorHandler;

BEGIN
	backgroundCol := BackgroundCol;
	foregroundCol := ForegroundCol;
	InitNames;
	OpenDisp;
	CreateColors;
	CreateGc;
	InitColors;
	CreatePatterns;
	InitCursors;
	DefineCursor(display, primary, arrow);
	lclen := 0;
	ErrorFlag := FALSE;
	(* SetErrorHandler(MyErrorHandler); *)
	SetIOErrorHandler(MyIOErrorHandler)
END X11.
