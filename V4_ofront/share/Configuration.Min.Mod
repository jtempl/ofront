MODULE Configuration;	(* jt 17.4.95 *)

(* minimal configuration to obtain a running Oberon system *)

	IMPORT
		Viewers, Oberon, TextFrames, MenuViewers, Display, Texts, System, Out;

	CONST
		StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store ";
		LogMenu = "System.Close System.Grow Edit.Locate Edit.Store ";

	PROCEDURE Init*;
		VAR logV, toolV: Viewers.Viewer; X, Y: INTEGER;
	BEGIN
		Oberon.OpenDisplay(Display.Width DIV 8 * 5, Display.Width DIV 8 * 3, Display.Height);
		Oberon.FocusViewer := Viewers.This(0, 0);
		Oberon.Log := TextFrames.Text(""); NEW(Oberon.Par);
		Oberon.AllocateSystemViewer(0, X, Y);
		logV := MenuViewers.New(
			TextFrames.NewMenu("System.Log", LogMenu),
			TextFrames.NewText(Oberon.Log, 0),
			TextFrames.menuH,
			X, Y);
		Oberon.AllocateSystemViewer(0, X, Y);
		toolV := MenuViewers.New(
			TextFrames.NewMenu("System.Tool", StandardMenu),
			TextFrames.NewText(TextFrames.Text("System.Tool"), 0),
			TextFrames.menuH,
			X, Y);
		Out.String("Ofront 1.4, minimal Oberon V4"); Out.Ln;
		Oberon.Loop
	END Init;

BEGIN Init
END Configuration.
