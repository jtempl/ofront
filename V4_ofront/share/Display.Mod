MODULE Display;	(* RC 23.12.92 *)
(* Based on X Window System Version 11 *)

	IMPORT X11, Kernel, Console, S := SYSTEM;
	
	CONST
		black* = (*X11.BackgroundCol*) 0;
		white* = (*X11.ForegroundCol*) 15;
		replace* = (*X11.replace*) 0;
		paint* = (*X11.paint*) 1;
		invert* = (*X11.invert*) 2;

	TYPE
		Frame* = POINTER TO FrameDesc;
		FrameMsg* = RECORD END ;
		Handler* = PROCEDURE (f: Frame; VAR msg: FrameMsg);
		FrameDesc* = RECORD
			dsc*, next*: Frame;
			X*, Y*, W*, H*: INTEGER;
			handle*: Handler;
		END ;

		Pattern* = (*X11.Pattern*) LONGINT (* for X11.PatternPtr *);

		Bytes* = (*X11.Bytes*) RECORD END ;
		Font* = (*X11.Font*) POINTER TO Bytes;

	VAR
		Bottom*, (* bottom of primary map *)
		Left*, (* left margin of black-and-white maps *)
		Width*, (* map width *)
		Height*, (* map height *)
		ColLeft*, (* left margin of color maps *)
		UBottom*: (* bottom of secondary map *)
			INTEGER;
		Unit*: LONGINT; (* RasterUnit = Unit/36000 mm *)
		primary*, secondary*,
		arrow*, cross*, star*, hook*, downArrow*: Pattern;
		grey0*, grey1*, grey2*, ticks*: Pattern;

	(* without clipping: *)
		Gc: X11.GC;
		lastcol, lastmode: INTEGER;

	(* with clipping: *)
		GcC: X11.GC;
		Window: X11.Window;
		lastcolC, lastmodeC, lastx, lasty, lastw, lasth: INTEGER;

	PROCEDURE NewPattern*(VAR image: ARRAY OF SET; w, h: INTEGER): X11.Pattern;
	(* Allocates a new pattern with width w and height h. The i-th pattern line from bottom (increasing y-value)
		corresponds to the image entries (i+1)*lineLen .. (i+2)*lineLen-1, where lineLen = (w+31) DIV 32.
		The set elements desribe the pixels from left to right (increasing x-value). *)
	BEGIN RETURN X11.NewPattern(image, X11.StippleShape, w, h)
	END NewPattern;

	PROCEDURE Secondary(F: Frame; col, mode: INTEGER): BOOLEAN;
		VAR cliprect: X11.Rectangle;
	BEGIN
		IF X11.lclen > 0 THEN X11.FlushLCache END ;
		Kernel.Lock();
		IF (F.X # lastx) OR (F.Y # lasty) OR (F.W # lastw) OR (F.H # lasth) THEN
			lastx := F.X; lasty := F.Y; lastw := F.W; lasth := F.H;
			cliprect.x := lastx; cliprect.y := X11.Height-lasty-lasth; cliprect.w := lastw; cliprect.h := lasth;
			IF lasty >= 0 THEN Window := X11.primary ELSE Window := X11.secondary; INC(cliprect.y, X11.UBottom) END ;
			IF (cliprect.x <= 0) & (cliprect.y <= 0) & (cliprect.w >= X11.Width) & (cliprect.h >= X11.Height) THEN (* no clipping *)
				X11.SetClipMask(X11.display, GcC, X11.None)
			ELSE
				X11.SetClipRectangles(X11.display, GcC, 0, 0, S.ADR(cliprect), 1, X11.YXBanded)
			END
		END ;
		IF mode = X11.paint THEN mode := X11.replace END ;
		IF mode # lastmodeC THEN X11.SetFunction(X11.display, GcC, X11.function[mode]); lastmodeC := mode END ;
		IF col # lastcolC THEN X11.SetForeground(X11.display, GcC, X11.pixelValues[col]); lastcolC := col END ;
		Kernel.Unlock();
		RETURN Window = X11.secondary
	END Secondary;

	PROCEDURE Map*(X, Y: INTEGER): LONGINT;
	BEGIN RETURN 0 (* map cannot be accessed directly *)
	END Map;

	PROCEDURE SetColor*(col, red, green, blue: INTEGER);	(* 0 <= col, red, green, blue < 256 *)
	BEGIN X11.SetColor(col, red, green, blue)
	END SetColor;

	PROCEDURE GetColor*(col: INTEGER; VAR red, green, blue: INTEGER);
	BEGIN X11.GetColor(col, red, green, blue)
	END GetColor;

	PROCEDURE SetMode*(X: INTEGER; s: SET);	(* noop *)
	END SetMode;

	PROCEDURE GetChar*(f: Font; ch: CHAR; VAR dx, x, y, w, h: INTEGER; VAR p: Pattern);
		VAR m: LONGINT; h1: INTEGER; h2: LONGINT;
	BEGIN
		X11.ccf := S.VAL(X11.Font, f); X11.ccch := ch;
		(* avoid indexing using SYSTEM.GET *)
		m := S.VAL(LONGINT, f) + ORD(ch)*SIZE(X11.MetricDesc);
		h2 := m + 8; p := h2; X11.ccp := h2;
		S.GET(m, h1); dx := h1; X11.ccdx := h1; INC(m, 2);
		S.GET(m, h1); x := h1; X11.ccx := h1; INC(m, 2);
		S.GET(m, h1); y := h1; X11.ccy := h1; INC(m, 12);
		S.GET(m, w); INC(m, 2);
		S.GET(m, h)
	END GetChar;

	PROCEDURE CopyBlock*(SX, SY, W, H, DX, DY, mode: INTEGER);
		VAR gc: X11.GC; src, dst: X11.Window;
	BEGIN
		Kernel.Lock();
		IF X11.lclen > 0 THEN X11.FlushLCache END ;
		gc := Gc;
		IF mode = paint THEN mode := replace END ;
		IF mode # lastmode THEN X11.SetFunction(X11.display, gc, X11.function[mode]); lastmode := mode END ;
		IF SY >= 0 THEN src := X11.primary ELSE src := X11.secondary; DEC(SY, X11.UBottom) END ;
		IF DY >= 0 THEN dst := X11.primary ELSE dst := X11.secondary; DEC(DY, X11.UBottom) END ;
		X11.CopyArea(X11.display, src, dst, gc, SX, Height-SY-H, W, H, DX, Height-DY-H);
		(* foreground not used *)
		Kernel.Unlock()
	END CopyBlock;

	PROCEDURE CopyPattern*(col: INTEGER; pat: Pattern; X, Y, mode: INTEGER);
		VAR p: X11.PatternPtr; gc: X11.GC; window: X11.Window; colPixel: LONGINT; spacedx: INTEGER;
	BEGIN
		IF (pat = X11.ccp) (*character cache valid*) & (X11.ccf.xid # 0) THEN (* X font present *)
			IF X11.lclen = 0 THEN
				X11.lcache[0] := X11.ccch; X11.lclen := 1;
				X11.lcf := X11.ccf; X11.lcx0 := X - X11.ccx; X11.lcy0 := Y - X11.ccy;
				X11.lccol := col; X11.lcmode := mode; X11.lcx := X11.lcx0 + X11.ccdx
			ELSIF (X11.ccf # X11.lcf) OR ((X - X11.ccx) # X11.lcx) OR ((Y - X11.ccy) # X11.lcy0)
			OR (col # X11.lccol) OR (mode # X11.lcmode) OR (X11.lclen = X11.LcLen) THEN
				spacedx := X11.lcf.metrics[ORD(" ")].dx;
				IF (X11.ccf = X11.lcf) & ((X - X11.ccx - spacedx) = X11.lcx) & ((Y - X11.ccy) = X11.lcy0)
				& (col = X11.lccol) & (mode = X11.lcmode) & (X11.lclen # X11.LcLen) THEN
					X11.lcache[X11.lclen] := " "; X11.lcache[X11.lclen + 1] := X11.ccch;
					INC(X11.lclen, 2); INC(X11.lcx, X11.ccdx + spacedx)
				ELSE
					X11.FlushLCache;
					X11.lcache[0] := X11.ccch; X11.lclen := 1;
					X11.lcf := X11.ccf; X11.lcx0 := X - X11.ccx; X11.lcy0 := Y - X11.ccy;
					X11.lccol := col; X11.lcmode := mode; X11.lcx := X11.lcx0 + X11.ccdx
				END
			ELSE (* append *)
				X11.lcache[X11.lclen] := X11.ccch; INC(X11.lclen); INC(X11.lcx, X11.ccdx)
			END
		ELSE
			IF X11.lclen > 0 THEN X11.FlushLCache END ;
			p := S.VAL(X11.PatternPtr, pat);
			gc := Gc;
			IF Y >= 0 THEN window := X11.primary ELSE window := X11.secondary; DEC(Y, X11.UBottom) END ;
			Kernel.Lock();
			IF mode = paint THEN
				colPixel := X11.pixelValues[col];
				IF colPixel # X11.basePixel + X11.planesMask THEN
					X11.SetFunction(X11.display, gc, X11.GXand);
					X11.SetBackground(X11.display, gc, X11.basePixel + X11.planesMask);
					X11.SetForeground(X11.display, gc, X11.basePixel);
					X11.CopyPlane(X11.display, p.pixmap, window, gc, p.x, p.y, p.w, p.h, X, Height-Y-p.h, 1)
				END ;
				IF colPixel # X11.basePixel THEN
					X11.SetFunction(X11.display, gc, X11.GXor);
					X11.SetBackground(X11.display, gc, X11.basePixel);
					X11.SetForeground(X11.display, gc, colPixel);
					X11.CopyPlane(X11.display, p.pixmap, window, gc, p.x, p.y, p.w, p.h, X, Height-Y-p.h, 1)
				END ;
				X11.SetBackground(X11.display, gc, X11.background); lastcol := -1; lastmode := -1
			ELSE
				IF mode # lastmode THEN X11.SetFunction(X11.display, gc, X11.function[mode]); lastmode := mode END ;
				IF col # lastcol THEN X11.SetForeground(X11.display, gc, X11.pixelValues[col]); lastcol := col END ;
				X11.CopyPlane(X11.display, p.pixmap, window, gc, p.x, p.y, p.w, p.h, X, Height-Y-p.h, 1)
			END ;
			Kernel.Unlock()
		END
	END CopyPattern;

	PROCEDURE ReplPattern*(col: INTEGER; pat: Pattern; X, Y, W, H, mode: INTEGER);
		VAR gc: X11.GC; p: X11.PatternPtr; window: X11.Window; colPixel: LONGINT;
	BEGIN
		IF X11.lclen > 0 THEN X11.FlushLCache END ;
		IF (H > 0) & (W > 0) THEN (* problem in X *)
			p := S.VAL(X11.PatternPtr, pat);
			gc := Gc;
			IF Y >= 0 THEN window := X11.primary ELSE window := X11.secondary; DEC(Y, X11.UBottom) END ;
			Kernel.Lock();
			X11.SetStipple(X11.display, gc, p.pixmap);
			X11.SetTSOrigin(X11.display, gc, 0, Height);
			X11.SetFillStyle(X11.display, gc, X11.FillOpaqueStippled);
			IF mode = paint THEN
				colPixel := X11.pixelValues[col];
				IF colPixel # X11.basePixel + X11.planesMask THEN
					X11.SetFunction(X11.display, gc, X11.GXand);
					X11.SetBackground(X11.display, gc, X11.basePixel + X11.planesMask);
					X11.SetForeground(X11.display, gc, X11.basePixel);
					X11.FillRectangle(X11.display, window, gc, X, Height-Y-H, W, H)
				END ;
				IF colPixel # X11.basePixel THEN
					X11.SetFunction(X11.display, gc, X11.GXor);
					X11.SetBackground(X11.display, gc, X11.basePixel);
					X11.SetForeground(X11.display, gc, colPixel);
					X11.FillRectangle(X11.display, window, gc, X, Height-Y-H, W, H)
				END ;
				X11.SetBackground(X11.display, gc, X11.background); lastcol := -1; lastmode := -1
			ELSE
				IF mode # lastmode THEN X11.SetFunction(X11.display, gc, X11.function[mode]); lastmode := mode END ;
				IF col # lastcol THEN X11.SetForeground(X11.display, gc, X11.pixelValues[col]); lastcol := col END ;
				X11.FillRectangle(X11.display, window, gc, X, Height-Y-H, W, H)
			END ;
			X11.SetFillStyle(X11.display, gc, X11.FillSolid);
			Kernel.Unlock()
		END
	END ReplPattern;

	PROCEDURE ReplConst*(col, X, Y, W, H, mode: INTEGER);
		VAR gc: X11.GC; window: X11.Window;
	BEGIN
		IF X11.lclen > 0 THEN X11.FlushLCache END ;
		IF (H > 0) & (W > 0) THEN (* problem in X *)
			gc := Gc;
			IF mode = paint THEN mode := replace END ;
			Kernel.Lock();
			IF mode # lastmode THEN X11.SetFunction(X11.display, gc, X11.function[mode]); lastmode := mode END ;
			IF col # lastcol THEN X11.SetForeground(X11.display, gc, X11.pixelValues[col]); lastcol := col END ;
			IF Y >= 0 THEN window := X11.primary ELSE window := X11.secondary; DEC(Y, X11.UBottom) END ;
			X11.FillRectangle(X11.display, window, gc, X, Height-Y-H, W, H);
			Kernel.Unlock()
		END
	END ReplConst;

	PROCEDURE Dot*(col, X, Y, mode: INTEGER);
		VAR gc: X11.GC; window: X11.Window;
	BEGIN
		IF X11.lclen > 0 THEN X11.FlushLCache END ;
		gc := Gc;
		IF mode = paint THEN mode := replace END ;
		Kernel.Lock();
		IF mode # lastmode THEN X11.SetFunction(X11.display, gc, X11.function[mode]); lastmode := mode END ;
		IF col # lastcol THEN X11.SetForeground(X11.display, gc, X11.pixelValues[col]); lastcol := col END ;
		IF Y >= 0 THEN window := X11.primary ELSE window := X11.secondary; DEC(Y, X11.UBottom) END ;
		X11.DrawPoint(X11.display, window, gc, X, Height-Y-1);
		Kernel.Unlock()
	END Dot;

	PROCEDURE DotC*(F: Frame; col, X, Y, mode: INTEGER);
	BEGIN
		IF (F.W <= 0) OR (F.H <= 0) THEN (* X would not clip *) RETURN END ;
		IF Secondary(F, col, mode) THEN DEC(Y, X11.UBottom) END ;
		Kernel.Lock(); X11.DrawPoint(X11.display, Window, GcC, X, Height-Y-1); Kernel.Unlock()
	END DotC;

	PROCEDURE ReplConstC*(F: Frame; col, X, Y, W, H, mode: INTEGER);
	(* Replicates a color col within the block (X, Y, W, H), clipped against F. *)
	BEGIN
		IF (H > 0) & (W > 0) THEN (* else problem in X *)
			IF (F.W <= 0) OR (F.H <= 0) THEN (* X would not clip *) RETURN END ;
			IF Secondary(F, col, mode) THEN DEC(Y, X11.UBottom) END ;
			Kernel.Lock(); X11.FillRectangle(X11.display, Window, GcC, X, X11.Height-Y-H, W, H); Kernel.Unlock()
		END
	END ReplConstC;

(*
PROCEDURE CopyBlockC* (F: Frame; SX, SY, W, H, DX, DY, mode: INTEGER);
END CopyBlockC;
*)

	PROCEDURE ReplPatternC*(F: Frame; col: INTEGER; pat: Pattern; X, Y, W, H, X0, Y0, mode: INTEGER);
	(* Replicates a pattern pat within the block (X, Y, W, H), clipped against F. The pattern origin is X0, Y0; i.e. for each
		completely visible occurrence of the pattern pat the following holds: ((x - X0) MOD w = 0) & ((y-Y0) MOD h = 0)
		where (x, y) denotes the left and bottom corner, and (w, h) the size of the pattern. *)
		VAR gc: X11.GC; p: X11.PatternPtr; colPixel: LONGINT;
	BEGIN
		IF (H > 0) & (W > 0) THEN (* else problem in X *)
			IF (F.W <= 0) OR (F.H <= 0) THEN (* X would not clip *) RETURN END ;
			p := S.VAL(X11.PatternPtr, pat); gc := GcC;
			IF Secondary(F, col, mode) THEN DEC(Y, X11.UBottom); DEC(Y0, X11.UBottom) END ;
			Kernel.Lock();
			X11.SetStipple(X11.display, gc, p.pixmap);
			X11.SetTSOrigin(X11.display, gc, X0, X11.Height-Y0);
			X11.SetFillStyle(X11.display, gc, X11.FillOpaqueStippled);
			IF mode = X11.paint THEN
				colPixel := X11.pixelValues[col];
				IF colPixel # X11.basePixel + X11.planesMask THEN
					X11.SetFunction(X11.display, gc, X11.GXand);
					X11.SetBackground(X11.display, gc, X11.basePixel + X11.planesMask);
					X11.SetForeground(X11.display, gc, X11.basePixel);
					X11.FillRectangle(X11.display, Window, gc, X, X11.Height-Y-H, W, H)
				END ;
				IF colPixel # X11.basePixel THEN
					X11.SetFunction(X11.display, gc, X11.GXor);
					X11.SetBackground(X11.display, gc, X11.basePixel);
					X11.SetForeground(X11.display, gc, colPixel);
					X11.FillRectangle(X11.display, Window, gc, X, X11.Height-Y-H, W, H)
				END ;
				X11.SetBackground(X11.display, gc, X11.background); lastcolC := -1; lastmodeC := -1
			ELSE
				X11.FillRectangle(X11.display, Window, gc, X, X11.Height-Y-H, W, H)
			END ;
			X11.SetFillStyle(X11.display, gc, X11.FillSolid);
			Kernel.Unlock()
		END
	END ReplPatternC;

	PROCEDURE CopyPatternC*(F: Frame; col: INTEGER; pat: Pattern; X, Y, mode: INTEGER);
	(* Draws pattern pat with lower-left corner (X, Y), clipped against F. *)
		VAR gc: X11.GC; p: X11.PatternPtr; colPixel: LONGINT;
	BEGIN
		p := S.VAL(X11.PatternPtr, pat);
		IF (X >= F.X) & (X+p.w <= F.X+F.W) & (Y >= F.Y) & (Y+p.h <= F.Y+F.H) THEN	(* pattern completely visible, try to use X font *)
			CopyPattern (col, pat, X, Y, mode)
		ELSE gc := GcC;
			IF Secondary(F, col, mode) THEN DEC(Y, X11.UBottom) END ;
			Kernel.Lock();
			IF mode = X11.paint THEN
				colPixel := X11.pixelValues[col];
				IF colPixel # X11.basePixel + X11.planesMask THEN
					X11.SetFunction(X11.display, gc, X11.GXand);
					X11.SetBackground(X11.display, gc, X11.basePixel + X11.planesMask);
					X11.SetForeground(X11.display, gc, X11.basePixel);
					X11.CopyPlane(X11.display, p.pixmap, Window, gc, p.x, p.y, p.w, p.h, X, X11.Height-Y-p.h, 1)
				END ;
				IF colPixel # X11.basePixel THEN
					X11.SetFunction(X11.display, gc, X11.GXor);
					X11.SetBackground(X11.display, gc, X11.basePixel);
					X11.SetForeground(X11.display, gc, colPixel);
					X11.CopyPlane(X11.display, p.pixmap, Window, gc, p.x, p.y, p.w, p.h, X, X11.Height-Y-p.h, 1)
				END ;
				X11.SetBackground(X11.display, gc, X11.background); lastcolC := -1; lastmodeC := -1
			ELSE
				X11.CopyPlane(X11.display, p.pixmap, Window, gc, p.x, p.y, p.w, p.h, X, X11.Height-Y-p.h, 1)
			END ;
			Kernel.Unlock()
		END
	END CopyPatternC;

	PROCEDURE CreateGcs;
	BEGIN
		Kernel.Lock();
		Gc := X11.CreateGC(X11.display, X11.primary, 0, 0);
		IF Gc = 0 THEN Console.String("Cannot create X graphic context"); Console.Ln; Kernel.Exit(1) END ;
		X11.SetPlaneMask(X11.display, Gc, X11.planesMask);
		X11.SetGraphicsExposures(X11.display, Gc, X11.True);
		X11.SetBackground(X11.display, Gc, X11.background);
		lastcol := -1;
		lastmode := -1;
		GcC := X11.CreateGC(X11.display, X11.primary, 0, 0);
		IF GcC = 0 THEN Console.String("Cannot create X graphic context"); Console.Ln; Kernel.Exit(1) END ;
		X11.SetPlaneMask(X11.display, GcC, X11.planesMask);
		X11.SetGraphicsExposures(X11.display, GcC, X11.True);
		X11.SetBackground(X11.display, GcC, X11.background);
		lastcolC := -1; lastmodeC := -1;
		lastx := -1; lasty := -1; lastw := -1; lasth := -1;
		Window := X11.secondary;
		Kernel.Unlock()
	END CreateGcs;
	
	PROCEDURE CreatePatterns;
		VAR image: ARRAY 17 OF SET;
	BEGIN
		image[1] := {13};
		image[2] := {12..14};
		image[3] := {11..13};
		image[4] := {10..12};
		image[5] := {9..11};
		image[6] := {8..10};
		image[7] := {7..9};
		image[8] := {0, 6..8};
		image[9] := {0, 1, 5..7};
		image[10] := {0..2, 4..6};
		image[11] := {0..5};
		image[12] := {0..4};
		image[13] := {0..5};
		image[14] := {0..6};
		image[15] := {0..7};
		arrow := X11.NewPattern(image, X11.StippleShape, 15, 15);
		
		image[1] := {0, 10};
		image[2] := {1, 9};
		image[3] := {2, 8};
		image[4] := {3, 7};
		image[5] := {4, 6};
		image[6] := {};
		image[7] := {4, 6};
		image[8] := {3, 7};
		image[9] := {2, 8};
		image[10] := {1, 9};
		image[11] := {0, 10};
		cross := X11.NewPattern(image, X11.StippleShape, 11, 11);
		
		image[1] := {6};
		image[2] := {5..7};
		image[3] := {4..8};
		image[4] := {3..9};
		image[5] := {2..10};
		image[6] := {5..7};
		image[7] := {5..7};
		image[8] := {5..7};
		image[9] := {5..7};
		image[10] := {5..7};
		image[11] := {5..7};
		image[12] := {5..7};
		image[13] := {5..7};
		image[14] := {5..7};
		image[15] := {};
		downArrow := X11.NewPattern(image, X11.StippleShape, 15, 15);
		
		image[1] := {0, 4, 8, 12};
		image[2] := {};
		image[3] := {2, 6, 10, 14};
		image[4] := {};
		image[5] := {0, 4, 8, 12};
		image[6] := {};
		image[7] := {2, 6, 10, 14};
		image[8] := {};
		image[9] := {0, 4, 8, 12};
		image[10] := {};
		image[11] := {2, 6, 10, 14};
		image[12] := {};
		image[13] := {0, 4, 8, 12};
		image[14] := {};
		image[15] := {2, 6, 10, 14};
		image[16] := {};
		grey0 := X11.NewPattern(image, X11.StippleShape, 16, 16);
		
		image[1] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[2] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[3] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[4] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[5] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[6] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[7] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[8] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[9] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[10] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[11] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[12] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[13] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[14] := {1, 3, 5, 7, 9, 11, 13, 15};
		image[15] := {0, 2, 4, 6, 8, 10, 12, 14};
		image[16] := {1, 3, 5, 7, 9, 11, 13, 15};
		grey1 := X11.NewPattern(image, X11.StippleShape, 16, 16);
		
		image[1] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[2] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[3] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[4] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[5] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[6] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[7] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[8] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[9] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[10] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[11] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[12] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[13] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[14] := {0, 1, 4, 5, 8, 9, 12, 13};
		image[15] := {2, 3, 6, 7, 10, 11, 14, 15};
		image[16] := {2, 3, 6, 7, 10, 11, 14, 15};
		grey2 := X11.NewPattern(image, X11.StippleShape, 16, 16);
		
		image[1] := {0..7};
		image[2] := {0..6};
		image[3] := {0..5};
		image[4] := {0..4};
		image[5] := {0..3};
		image[6] := {0..2};
		image[7] := {0..1};
		image[8] := {0};
		hook := NewPattern(image, 8, 8);
		
		image[1] := {7};
		image[2] := {7};
		image[3] := {2, 7, 12};
		image[4] := {3, 7, 11};
		image[5] := {4, 7, 10};
		image[6] := {5, 7, 9};
		image[7] := {6..8};
		image[8] := {0..6, 8..14};
		image[9] := {6..8};
		image[10] := {5, 7, 9};
		image[11] := {4, 7, 10};
		image[12] := {3, 7, 11};
		image[13] := {2, 7, 12};
		image[14] := {7};
		image[15] := {7};
		star := X11.NewPattern(image, X11.StippleShape, 15, 15);
		
		image[1] := {0};
		image[2] := {};
		image[3] := {};
		image[4] := {};
		image[5] := {};
		image[6] := {};
		image[7] := {};
		image[8] := {};
		image[9] := {};
		image[10] := {};
		image[11] := {};
		image[12] := {};
		image[13] := {};
		image[14] := {};
		image[15] := {};
		image[16] := {};
		ticks := X11.NewPattern(image, X11.StippleShape, 16, 16)
	END CreatePatterns;

BEGIN
	Unit := (36000*X11.screenhmm + X11.screenh DIV 2) DIV X11.screenh;
	Left := 0; ColLeft := X11.ColLeft; Bottom := X11.Bottom; UBottom := X11.UBottom; Width := X11.Width; Height := X11.Height;
	primary := X11.primary; secondary := X11.secondary;
	CreateGcs; CreatePatterns
END Display.
