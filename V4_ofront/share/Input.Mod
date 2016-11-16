MODULE Input;	(* RC 4.11.93 *)
(* Based on X Window System Version 11 *)

	IMPORT X11, Unix, Kernel, S := SYSTEM;

	TYPE
		MouseState = RECORD
			buttons, x, y: LONGINT
		END ;

	CONST
		ML = 2; MM = 1; MR = 0;
    	ESC = 1BX; SETUP = 0A4X; FF = 0CX;
		QueueLen = 128;

	VAR
		TimeUnit*: LONGINT;
		keyQueue: ARRAY QueueLen OF CHAR;
		mouseQueue: ARRAY QueueLen OF MouseState;
		kin, kout, msin, msout: INTEGER;
		maxX, maxY: INTEGER;
		event: X11.Event;
		lastButtons, lastX, lastY: LONGINT;
		firstClick: BOOLEAN;
		compstatus: RECORD ptr, matched: LONGINT END ;

	PROCEDURE PollXQueue;
		CONST bufsize = 20;
		VAR eventcount, keycount, xr, yr, xw, yw, i: LONGINT;
			rw, cw: X11.Window;
			buffer: ARRAY bufsize OF CHAR;
			keysym: X11.KeySym;
			buttons: LONGINT;
			Xerror: ARRAY 32 OF CHAR;
	BEGIN
		IF X11.ErrorFlag THEN X11.ErrorFlag := FALSE; COPY(X11.ErrorText, Xerror); HALT(99) END ;
		eventcount := X11.EventsQueued(X11.display, X11.QueuedAfterReading);
		IF eventcount > 0 THEN
			REPEAT
				X11.NextEvent(X11.display, S.ADR(event));
				CASE event.type OF
					X11.KeyPress:
						X11.lastEventTime := event.time;
						keycount := X11.LookupString(S.ADR(event), S.ADR(buffer), bufsize, keysym, S.ADR(compstatus));
						i := 0;
						WHILE i < keycount DO
							IF (kin - kout) MOD QueueLen # QueueLen - 1 THEN
								keyQueue[kin] := buffer[i]; kin := (kin + 1) MOD QueueLen
							ELSE X11.Bell(X11.display, 0)
							END ;
							INC(i)
						END
				| X11.ButtonPress:
						X11.lastEventTime := event.time;
						CASE event.button OF
							X11.Button1: lastButtons := S.VAL(LONGINT, S.VAL(SET, lastButtons) + S.VAL(SET, X11.Button1Mask));
								X11.SetInputFocus(X11.display, X11.primary, X11.RevertToParent, event.time)
						| X11.Button2: lastButtons := S.VAL(LONGINT, S.VAL(SET, lastButtons) + S.VAL(SET, X11.Button2Mask))
						| X11.Button3: lastButtons := S.VAL(LONGINT, S.VAL(SET, lastButtons) + S.VAL(SET, X11.Button3Mask))
						ELSE
						END ;
						lastX := event.x; lastY := event.y;
						IF (msin - msout) MOD QueueLen # QueueLen - 1 THEN 
							mouseQueue[msin].buttons := lastButtons;
							mouseQueue[msin].x := lastX;
							mouseQueue[msin].y := lastY;
							msin := (msin + 1) MOD QueueLen
						ELSE X11.Bell(X11.display, 0)
						END ;
						IF firstClick THEN firstClick := FALSE;
							X11.StoreName(X11.display, X11.primary, S.ADR(X11.WinName))
						END
				| X11.ButtonRelease:
						X11.lastEventTime := event.time;
						CASE event.button OF
							X11.Button1: lastButtons := S.VAL(LONGINT, S.VAL(SET, lastButtons) - S.VAL(SET, X11.Button1Mask))
						| X11.Button2: lastButtons := S.VAL(LONGINT, S.VAL(SET, lastButtons) - S.VAL(SET, X11.Button2Mask))
						| X11.Button3: lastButtons := S.VAL(LONGINT, S.VAL(SET, lastButtons) - S.VAL(SET, X11.Button3Mask))
						ELSE
						END ;
						lastX := event.x; lastY := event.y;
						IF (msin - msout) MOD QueueLen # QueueLen - 1 THEN 
							mouseQueue[msin].buttons := lastButtons;
							mouseQueue[msin].x := lastX;
							mouseQueue[msin].y := lastY;
							msin := (msin + 1) MOD QueueLen
						ELSE X11.Bell(X11.display, 0)
						END
				| X11.MotionNotify:
						X11.QueryPointer(X11.display, event.window, rw, cw, xr, yr, lastX, lastY, buttons);
				| X11.Expose, X11.GraphicsExpose:
						IF ((kin - kout) MOD QueueLen # QueueLen - 1) & (keyQueue[kout] # FF) OR (kin = kout) THEN
							keyQueue[kin] := FF; kin := (kin + 1) MOD QueueLen
						END
				| X11.NoExpose:
				| X11.MappingNotify:
						X11.RefreshKeyboardMapping(S.ADR(event))
				| X11.ClientMessage:
				| X11.UnmapNotify:
				| X11.MapNotify:
				| X11.SelectionClear: IF X11.ClearSelection # NIL THEN X11.ClearSelection() END
				| X11.SelectionNotify:
					IF X11.ReceiveSelection # NIL THEN X11.ReceiveSelection(S.VAL(X11.SelectionEvent, event)) END
				| X11.SelectionRequest:
					IF X11.SendSelection # NIL THEN X11.SendSelection(S.VAL(X11.SelectionRequestEvent, event)) END
				ELSE
				END ;
				DEC(eventcount)
			UNTIL eventcount = 0
		END ;
		X11.DoSync
	END PollXQueue;
		
	PROCEDURE Available*(): INTEGER;
	BEGIN
		PollXQueue;
		RETURN (kin - kout) MOD QueueLen
	END Available;

	PROCEDURE Mouse*(VAR keys: SET; VAR x, y: INTEGER);
		VAR k: SET; lb: LONGINT; lx, ly: INTEGER;
	BEGIN
		PollXQueue;
		IF msin = msout THEN (* mouseQueue empty *)
			lb := lastButtons;
			lx := SHORT(lastX);
			ly := X11.Height - 1 - SHORT(lastY)
		ELSE
			lb := mouseQueue[msout].buttons;
			lx := SHORT(mouseQueue[msout].x);
			ly := X11.Height - 1 - SHORT(mouseQueue[msout].y);
			msout := (msout + 1) MOD QueueLen
		END ;
		k := {};
		IF lb DIV X11.Button1Mask MOD 2 = 1 THEN INCL(k, ML) END ;
		IF lb DIV X11.Button2Mask MOD 2 = 1 THEN INCL(k, MM) END ;
		IF lb DIV X11.Button3Mask MOD 2 = 1 THEN INCL(k, MR) END ;
		IF lx > maxX THEN lx := maxX ELSIF lx < 0 THEN lx := 0 END ;
		IF ly > maxY THEN ly := maxY ELSIF ly < 0 THEN ly := 0 END ;
		keys := k; x := lx; y := ly
	END Mouse;

	PROCEDURE Read*(VAR ch: CHAR);
	BEGIN
		WHILE kout = kin DO PollXQueue END ;
		ch := keyQueue[kout]; kout := (kout + 1) MOD QueueLen
	END Read;

	PROCEDURE SetMouseLimits*(w, h: INTEGER);
	BEGIN  maxX := w - 1; maxY := h - 1
	END SetMouseLimits;

	PROCEDURE Time*(): LONGINT;																						(* << *)
	BEGIN RETURN Kernel.Time()
	END Time;

	PROCEDURE Init;
		CONST Shift = "Shift_L"; Control = "Control_L"; CapsLock = "Caps_Lock";
		VAR from, to: ARRAY 8 OF CHAR;
			modlist: X11.Modlist;
			n, i: LONGINT;
	BEGIN
		X11.SelectInput(X11.display, X11.primary,
			X11.ExposureMask+X11.ButtonPressMask+X11.OwnerGrabButtonMask+X11.ButtonReleaseMask+
			X11.PointerMotionHintMask+X11.PointerMotionMask+X11.KeyPressMask+X11.StructureNotifyMask);
		kin := 0; kout := 0; msin := 0; msout := 0;
		X11.QueryPointer(X11.display, X11.primary, n, n, n, n, lastX, lastY, lastButtons);
		modlist[0] := CapsLock;
		to[0] := SETUP; X11.Rebind("F1", modlist, 0, to, 1); X11.Rebind("F1", modlist, 1, to, 1);
		to[0] := ESC; X11.Rebind("F2", modlist, 0, to, 1); X11.Rebind("F2", modlist, 1, to, 1);
		to[0] := 7FX; X11.Rebind("BackSpace", modlist, 0, to, 1); X11.Rebind("BackSpace", modlist, 1, to, 1);
		to[0] := 0F5X; X11.Rebind("Menu", modlist, 0, to, 1); X11.Rebind("Menu", modlist, 1, to, 1);	(* Do = F5 *)
		to[0] := 91X; X11.Rebind("Prior", modlist, 0, to, 1); X11.Rebind("Prior", modlist, 1, to, 1);	(* NOSCRLL for Draw *)
		to[0] := 0ACX; X11.Rebind("F3", modlist, 0, to, 1);	(* BREAK *)
		modlist[0] := Shift;
		to[0] := 0ADX; X11.Rebind("F3", modlist, 1, to, 1);	(* SHIFT-BREAK *)
		modlist[0] := Control;
		to[0] := 93X; X11.Rebind("Prior", modlist, 1, to, 1);	(* CTRL-NOSCRLL for Draw *)

		modlist[0] := CapsLock; i := 4; from := "F4";
		WHILE i < 10 DO
			to[0] := CHR(0F0H + i); from[1] := CHR(ORD("0")+i);
			X11.Rebind(from, modlist, 0, to, 1); X11.Rebind(from, modlist, 1, to, 1); INC(i)
		END ;
		i := 10; from := "F10";
		WHILE i < 16 DO
			to[0] := CHR(0F0H + i); from[2] := CHR(ORD("0")+i-10);
			X11.Rebind(from, modlist, 0, to, 1); X11.Rebind(from, modlist, 1, to, 1); INC(i)
		END ;

		to[0] := 0AX; X11.Rebind("Select", modlist, 0, to, 1); X11.Rebind("Select", modlist, 1, to, 1);
		to[0] := 0C1X; X11.Rebind("Up", modlist, 0, to, 1); X11.Rebind("Up", modlist, 1, to, 1);
		to[0] := 0C2X; X11.Rebind("Down", modlist, 0, to, 1); X11.Rebind("Down", modlist, 1, to, 1);
		to[0] := 0C3X; X11.Rebind("Right", modlist, 0, to, 1); X11.Rebind("Right", modlist, 1, to, 1);
		to[0] := 0C4X; X11.Rebind("Left", modlist, 0, to, 1); X11.Rebind("Left", modlist, 1, to, 1);
		to[0] := 0C5X; X11.Rebind("Page_Up", modlist, 0, to, 1); X11.Rebind("Page_Up", modlist, 1, to, 1);
		to[0] := 0C6X; X11.Rebind("Page_Down", modlist, 0, to, 1); X11.Rebind("Page_Down", modlist, 1, to, 1);
		to[0] := 0C7X; X11.Rebind("End", modlist, 0, to, 1); X11.Rebind("End", modlist, 1, to, 1);
		to[0] := 0C8X; X11.Rebind("Home", modlist, 0, to, 1); X11.Rebind("Home", modlist, 1, to, 1);
		to[0] := 0A1X; X11.Rebind("Delete", modlist, 0, to, 1); X11.Rebind("Delete", modlist, 1, to, 1);

		modlist[0] := Control;
		(*A diaeresis*) to[0] := 080X; X11.Rebind("A", modlist, 1, to, 1);
		(*O diaeresis*) to[0] := 081X; X11.Rebind("O", modlist, 1, to, 1);
		(*U diaeresis*) to[0] := 082X; X11.Rebind("U", modlist, 1, to, 1);
		(*a diaeresis*) to[0] := 083X; X11.Rebind("a", modlist, 1, to, 1);
		(*e diaeresis*) to[0] := 091X; X11.Rebind("e", modlist, 1, to, 1);
		(*i diaeresis*) to[0] := 092X; X11.Rebind("i", modlist, 1, to, 1);
		(*o diaeresis*) to[0] := 084X; X11.Rebind("o", modlist, 1, to, 1);
		(*u diaeresis*) to[0] := 085X; X11.Rebind("u", modlist, 1, to, 1);
		(*c cedilla*) to[0] := 093X; X11.Rebind("c", modlist, 1, to, 1);
		(*n tilde*) to[0] := 095X; X11.Rebind("n", modlist, 1, to, 1);
		(*s sharp*) to[0] := 0ABX; X11.Rebind("s", modlist, 1, to, 1);

		(* special keyboard: *)
		modlist[0] := Shift;
		(*a acute*) to[0] := 094X; X11.Rebind("aacute", modlist, 0, to, 1); X11.Rebind("aacute", modlist, 1, to, 1);
		(*a grave*) to[0] := 08BX; X11.Rebind("agrave", modlist, 0, to, 1); X11.Rebind("agrave", modlist, 1, to, 1);
		(*a diaeresis*) to[0] := 083X; X11.Rebind("adiaeresis", modlist, 0, to, 1); X11.Rebind("adiaeresis", modlist, 1, to, 1);
		(*a circumflex*) to[0] := 086X; X11.Rebind("acircumflex", modlist, 0, to, 1); X11.Rebind("acircumflex", modlist, 1, to, 1);
		(*e acute*) to[0] := 090X; X11.Rebind("eacute", modlist, 0, to, 1); X11.Rebind("eacute", modlist, 1, to, 1);
		(*e grave*) to[0] := 08CX; X11.Rebind("egrave", modlist, 0, to, 1); X11.Rebind("egrave", modlist, 1, to, 1);
		(*e diaeresis*) to[0] := 091X; X11.Rebind("ediaeresis", modlist, 0, to, 1); X11.Rebind("ediaeresis", modlist, 1, to, 1);
		(*e circumflex*) to[0] := 087X; X11.Rebind("ecircumflex", modlist, 0, to, 1); X11.Rebind("ecircumflex", modlist, 1, to, 1);
		(*i grave*) to[0] := 08DX; X11.Rebind("igrave", modlist, 0, to, 1); X11.Rebind("igrave", modlist, 1, to, 1);
		(*i diaeresis*) to[0] := 092X; X11.Rebind("idiaeresis", modlist, 0, to, 1); X11.Rebind("idiaeresis", modlist, 1, to, 1);
		(*i circumflex*) to[0] := 088X; X11.Rebind("icircumflex", modlist, 0, to, 1); X11.Rebind("icircumflex", modlist, 1, to, 1);
		(*o grave*) to[0] := 08EX; X11.Rebind("ograve", modlist, 0, to, 1); X11.Rebind("ograve", modlist, 1, to, 1);
		(*o diaeresis*) to[0] := 084X; X11.Rebind("odiaeresis", modlist, 0, to, 1); X11.Rebind("odiaeresis", modlist, 1, to, 1);
		(*o circumflex*) to[0] := 089X; X11.Rebind("ocircumflex", modlist, 0, to, 1); X11.Rebind("ocircumflex", modlist, 1, to, 1);
		(*u grave*) to[0] := 08FX; X11.Rebind("ugrave", modlist, 0, to, 1); X11.Rebind("ugrave", modlist, 1, to, 1);
		(*u diaeresis*) to[0] := 085X; X11.Rebind("udiaeresis", modlist, 0, to, 1); X11.Rebind("udiaeresis", modlist, 1, to, 1);
		(*u circumflex*) to[0] := 08AX; X11.Rebind("ucircumflex", modlist, 0, to, 1); X11.Rebind("ucircumflex", modlist, 1, to, 1);
		(*c cedilla*) to[0] := 093X; X11.Rebind("ccedilla", modlist, 0, to, 1); X11.Rebind("ccedilla", modlist, 1, to, 1);
		(*n tilde*) to[0] := 095X; X11.Rebind("ntilde", modlist, 0, to, 1);
		(*s sharp*) to[0] := 0ABX; X11.Rebind("ssharp", modlist, 0, to, 1);
		(*A diaeresis*) to[0] := 080X; X11.Rebind("Adiaeresis", modlist, 0, to, 1); X11.Rebind("Adiaeresis", modlist, 1, to, 1);
		(*O diaeresis*) to[0] := 081X; X11.Rebind("Odiaeresis", modlist, 0, to, 1); X11.Rebind("Odiaeresis", modlist, 1, to, 1);
		(*U diaeresis*) to[0] := 082X; X11.Rebind("Udiaeresis", modlist, 0, to, 1); X11.Rebind("Udiaeresis", modlist, 1, to, 1);	END Init;

BEGIN TimeUnit := Kernel.TimeUnit; Init
END Input.

