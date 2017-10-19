MODULE Configuration;	(* jt 22.10.93 *)

(* in addition to the standard configuration, this module sets up an intelligent scrolling log viewer
	with a command-level pin point *)

	IMPORT
		Viewers, Oberon, TextFrames, MenuViewers, Display, Texts, FKeys, System, In, Out,

		Kepler, Kepler1, Kepler2, Kepler4, Kepler5, Kepler6, Kepler7, Kepler8, Kepler9,
		KeplerElems, StyleElems, MenuElems, TableElems, IconElems, ClockElems, ChartElems,
		LineElems, StampElems, Folds, ErrorElems, PopupElems, TextPreview, 
		Browser, Ofront, Edit, EdiT, EditTools, FontToBDF, AsciiCoder, Miscellaneous, Mailer;

	CONST
		StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store ";
		LogMenu = "System.Close System.Grow Edit.Locate Edit.Store ";

	VAR
		pinPos: LONGINT;

	PROCEDURE PinLog*;
	BEGIN pinPos := Oberon.Log.len;
	END PinLog;

	PROCEDURE HandleLog(F: Display.Frame; VAR M: Display.FrameMsg);
		VAR ch: CHAR; R: Texts.Reader; org: LONGINT;
	BEGIN
		TextFrames.Handle(F, M);
		IF M IS TextFrames.UpdateMsg THEN
			WITH M: TextFrames.UpdateMsg DO
				IF (M.text = Oberon.Log) & (M.id = TextFrames.insert) & (M.beg > 0) THEN
					Texts.OpenReader(R, Oberon.Log, M.beg-1); Texts.Read(R, ch);
					IF ch = 0DX THEN
						WITH F: TextFrames.Frame DO
							IF M.beg > TextFrames.Pos(F, F.X + F.W, F.Y) + 1  THEN org := M.beg - 200 ELSE org := F.org END ;
							WHILE (org < pinPos) & (org < M.beg) & (TextFrames.Pos(F, F.X + F.W, F.Y) < M.end-1) DO
								Texts.OpenReader(R, F.text, org);
								REPEAT Texts.Read(R, ch) UNTIL R.eot OR (ch = 0DX);
								org := Texts.Pos(R); TextFrames.Show(F, org)
							END
						END
					END
				END
			END
		END
	END HandleLog;

	PROCEDURE Init*;
		VAR logV, toolV: Viewers.Viewer; X, Y: INTEGER; logger: Oberon.Task;
	BEGIN
		Oberon.OpenDisplay(Display.Width DIV 8 * 5, Display.Width DIV 8 * 3, Display.Height);
		Oberon.FocusViewer := Viewers.This(0, 0);
		Oberon.AllocateSystemViewer(0, X, Y);
		logV := MenuViewers.New(
			TextFrames.NewMenuEx("System.Log", "Log.Menu.Text", LogMenu),
			TextFrames.NewText(Oberon.Log, 0),
			TextFrames.menuH,
			X, Y);
		logV.dsc.next.handle := HandleLog;
		Oberon.AllocateSystemViewer(0, X, Y);
		toolV := MenuViewers.New(
			TextFrames.NewMenuEx("System.Tool", "System.Menu.Text", StandardMenu),
			TextFrames.NewText(TextFrames.Text("System.Tool"), 0),
			TextFrames.menuH,
			X, Y + 50) ;
		NEW(logger); logger.safe := TRUE; logger.time := -1; logger.handle := PinLog;
		Oberon.Install(logger);
		FKeys.Set(12, FKeys.InternationalKey);
		FKeys.Set(10, FKeys.InternationalKey);
		Out.String("Ofront 1.4, Oberon V4"); Out.Ln;
		Oberon.Loop
	END Init;

BEGIN Init
END Configuration.
