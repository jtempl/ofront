MODULE System; (*JG 25.4.90 / NW 22.4.90, JT 21.01.93*)

	IMPORT SYSTEM,
		Unix, Kernel, Modules, Files, Input, Display, Viewers, MenuViewers, Oberon, Fonts, Texts, TextFrames, Args,
		Out, Console;

	CONST
		StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store ";
		LogMenu = "System.Close System.Grow Edit.Locate Edit.Store ";

	VAR
		W: Texts.Writer;
		trapLevel: INTEGER;


	PROCEDURE -halt(): LONGINT
		"SYSTEM_halt";

	PROCEDURE -assert(): LONGINT
		"SYSTEM_assert";

	PROCEDURE -resetHalt()
		"SYSTEM_halt = -128";

	PROCEDURE -setIntd(v: BOOLEAN)
		"SYSTEM_interrupted = v";

	PROCEDURE -system(cmd: ARRAY OF CHAR)
		"system(cmd)";

	PROCEDURE -FinalizeAll()
		"SYSTEM_FINALL()";

	PROCEDURE -Locked(): BOOLEAN
		"(SYSTEM_lock > 0)";

	PROCEDURE Trap*(sig, siginfo, sigctx: LONGINT);
		VAR addr: LONGINT;
	BEGIN
		IF Locked() THEN
			CASE sig OF
			| 2, 13, 18: (* no change *)
			| 3, 4, 8, 10, 11: Console.String("received a signal while in critical section (GC or NEW): sig="); 
				Console.Int(sig, 1); Console.String("; terminated"); Console.Ln;
				Unix.Exit(0)
			ELSE RETURN (* ignore *)
			END
		END ;
		IF trapLevel = 0 THEN
			trapLevel := 1;
			CASE sig OF
			| 2:
					(* interrupt from keyboard *)
					IF Locked() THEN (* delay interrupt until lock = 0 *)
						setIntd(TRUE); trapLevel := 0; RETURN
					ELSE Out.String("INTERRUPT")
					END
			| 3:
					(* quit from keyboard *)
					FinalizeAll(); Unix.Exit(0)
			| 4:
					(* illegal instruction *)
					CASE halt() OF
					|   0: (* silent halt *) resetHalt(); trapLevel := 0; Kernel.siglongjmp(Kernel.trapEnv, 1)
					| -1: Out.String("ASSERT("); Out.Int(assert(), 1); Out.String(") FAILED")
					| -2: Out.String("INDEX OUT OF RANGE")
					| -3: Out.String("FUNCTION WITHOUT RETURN")
					| -4: Out.String("INVALID CASE")
					| -5: Out.String("TYPE GUARD FAILED")
					| -6: Out.String("IMPLICIT TYPE GUARD FAILED")
					| -7: Out.String("WITH GUARD FAILED")
					| -8: Out.String("VALUE OUT OF RANGE")
					| -9: setIntd(FALSE); Out.String("DELAYED INTERRUPT")
					ELSE
						IF (halt() > 0) & (halt() < 256) THEN Out.String("HALT("); Out.Int(halt(), 1); Out.Char(")")
						ELSE Out.String("ILLEGAL INSTRUCTION")
						END
					END ;
					resetHalt()
			| 8:
					Out.String("ARITHMETIC EXCEPTION")
			| 10:
					Out.String("BUS ERROR")
			| 11:
					(* SIGSEGV *)
					(* first check if caused by a frame handler of an unloaded module; this would lead to recursion in Out. *)
					addr := Unix.SiginfoAddr(siginfo);
					IF addr # 0 THEN Viewers.CheckUnload(SYSTEM.VAL(Display.Handler, addr)) END ;
					Out.String("SEGMENTATION VIOLATION")
			| 13: 
					(* broken pipe *)
					(* better ignore this signal if the X11 connection is the broken pipe. 
						(E.g. in OpenWindows after Quit in Window Menu.)
						Otherwise an infinite loop with maximum cpu usage follows.
						Use SYSTEM_lock as a heuristics to detect this case. *)
					IF Locked() THEN FinalizeAll(); Unix.Exit(0)
					ELSE Out.String("UNCONNECTED PIPE")
					END
			| 18:
					(* remove zombies *)
					(* code := Unix.Wait(code); TODO unclear *) RETURN
			ELSE
					Out.String("SIGNAL "); Out.Int(sig, 0)
			END ;
			Out.Ln
		ELSE
			Console.String("received a signal while handing a signal: sig="); Console.Int(sig, 0); Console.Ln
		END ;
		trapLevel := 0;
		Kernel.siglongjmp(Kernel.trapEnv, 1)
	END Trap;

	PROCEDURE Max (i, j: LONGINT): LONGINT;
	BEGIN IF i >= j THEN RETURN i ELSE RETURN j END
	END Max;

	PROCEDURE Open*;
		VAR par: Oberon.ParList;
			T: Texts.Text;
			S: Texts.Scanner;
			V: Viewers.Viewer;
            X, Y: INTEGER;
            beg, end, time: LONGINT;
	BEGIN
		par := Oberon.Par;
		Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") OR (S.line # 0) THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		END;
        IF S.class IN {Texts.Name, Texts.String} THEN
            Oberon.AllocateSystemViewer(par.vwr.X, X, Y);
		    V := MenuViewers.New(
              TextFrames.NewMenu(S.s, StandardMenu),
              TextFrames.NewText(TextFrames.Text(S.s), 0),
              TextFrames.menuH,
              X, Y)
        END
	END Open;

	PROCEDURE OpenLog*;
      VAR logV: Viewers.Viewer; X, Y: INTEGER;
	BEGIN
        Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
        logV := MenuViewers.New(
          TextFrames.NewMenu("System.Log", LogMenu),
          TextFrames.NewText(Oberon.Log, Max(0, Oberon.Log.len - 200)),
          TextFrames.menuH,
          X, Y)
	END OpenLog;

	PROCEDURE ClearLog*;
	BEGIN Texts.Delete(Oberon.Log, 0, Oberon.Log.len); Texts.OpenWriter(W)
	END ClearLog;

	PROCEDURE Close*;
		VAR par: Oberon.ParList; V: Viewers.Viewer; M: Viewers.ViewerMsg;
	BEGIN
		par := Oberon.Par;
		IF par.frame = par.vwr.dsc THEN V := par.vwr
		ELSE V := Oberon.MarkedViewer()
		END;
		Viewers.Close(V)
	END Close;

	PROCEDURE CloseTrack*;
      VAR V: Viewers.Viewer;
	BEGIN V := Oberon.MarkedViewer(); Viewers.CloseTrack(V.X)
	END CloseTrack;

    PROCEDURE Recall*;
      VAR V: Viewers.Viewer; M: Viewers.ViewerMsg;
    BEGIN
      Viewers.Recall(V);
      IF (V # NIL) & (V.state = 0) THEN
        Viewers.Open(V, V.X, V.Y + V.H); M.id := Viewers.restore; V.handle(V, M)
      END
    END Recall;

	PROCEDURE Copy*;
		VAR V, V1: Viewers.Viewer; M: Oberon.CopyMsg; N: Viewers.ViewerMsg;
	BEGIN
        V := Oberon.Par.vwr; V.handle(V, M); V1 := M.F(Viewers.Viewer);
        Viewers.Open(V1, V.X, V.Y + V.H DIV 2);
        N.id := Viewers.restore; V1.handle(V1, N)
	END Copy;

	PROCEDURE Grow*;
		VAR V, V1: Viewers.Viewer; M: Oberon.CopyMsg; N: Viewers.ViewerMsg;
          DW, DH: INTEGER;
	BEGIN V := Oberon.Par.vwr;
        DW := Oberon.DisplayWidth(V.X); DH := Oberon.DisplayHeight(V.X);
		IF V.H < DH - Viewers.minH THEN Oberon.OpenTrack(V.X, V.W)
          ELSIF V.W < DW THEN Oberon.OpenTrack(Oberon.UserTrack(V.X), DW)
        END;
        IF (V.H < DH - Viewers.minH) OR (V.W < DW) THEN
          V.handle(V, M); V1 := M.F(Viewers.Viewer);
          Viewers.Open(V1, V.X, DH);
          N.id := Viewers.restore; V1.handle(V1, N)
       END
	END Grow;

	PROCEDURE GetArg(VAR S: Texts.Scanner);
		VAR T: Texts.Text; beg, end, time: LONGINT;
	BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		END
	END GetArg;

	PROCEDURE EndLine;
	BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
	END EndLine;

	PROCEDURE SetFont*;
		VAR S: Texts.Scanner;
	BEGIN GetArg(S);
		IF S.class IN {Texts.Name, Texts.String} THEN Oberon.SetFont(Fonts.This(S.s)) END
	END SetFont;

	PROCEDURE SetColor*;
		VAR S: Texts.Scanner;
	BEGIN GetArg(S);
		IF S.class = Texts.Int THEN Oberon.SetColor(SHORT(SHORT(S.i))) END
	END SetColor;

	PROCEDURE SetOffset*;
		VAR S: Texts.Scanner;
	BEGIN GetArg(S);
		IF S.class = Texts.Int THEN Oberon.SetOffset(SHORT(SHORT(S.i))) END
	END SetOffset;

	PROCEDURE Time*;
		VAR t, d: LONGINT;
	BEGIN
		Texts.WriteString(W, "System.Time");
		Oberon.GetClock(t, d); Texts.WriteDate(W, t, d); Texts.WriteLn(W);
		Texts.Append(Oberon.Log, W.buf)
	END Time;

	PROCEDURE Watch*;
	BEGIN
		Texts.WriteString(W, "System.Watch"); Texts.WriteLn(W);
		Texts.WriteInt(W, Kernel.allocated(), 0); Texts.WriteString(W, " bytes allocated from ");
		Texts.WriteInt(W, Kernel.heapsize(), 0); Texts.WriteLn(W);
		Texts.WriteInt(W, Kernel.nofiles, 0); Texts.WriteString(W, " file(s) open"); Texts.WriteLn(W);
		Texts.Append(Oberon.Log, W.buf)
	END Watch;

	PROCEDURE Collect*;
	BEGIN Oberon.Collect(0)
	END Collect;

	PROCEDURE SetUser*;
		VAR i: INTEGER; ch: CHAR;
			user: ARRAY 8 OF CHAR;
			password: ARRAY 16 OF CHAR;
	BEGIN
		i := 0; Input.Read(ch);
		WHILE (ch # "/") & (i < 7) DO user[i] := ch; INC(i); Input.Read(ch) END;
		user[i] := 0X;
		i := 0; Input.Read(ch);
		WHILE (ch > " ") & (i < 15) DO password[i] := ch; INC(i); Input.Read(ch) END;
		password[i] := 0X;
		Oberon.SetUser(user, password)
	END SetUser;
	
	PROCEDURE FreeMod(VAR S: Texts.Scanner);
	BEGIN
		Out.String(S.s); Out.String(" unloading");
		IF S.nextCh # "*" THEN Modules.Free(S.s, FALSE)
		ELSE Modules.Free(S.s, TRUE); Texts.Scan(S); Out.String(" all")
		END ;
		IF Modules.res # 0 THEN
			Out.String(" failed: "); Out.String(Modules.resMsg); Modules.res := 0
		END ;
		Out.Ln()
	END FreeMod;

	PROCEDURE Free*;
		VAR par: Oberon.ParList;
			T: Texts.Text;
			S: Texts.Scanner;
			V: Viewers.Viewer;
            beg, end, time: LONGINT;
	BEGIN
		par := Oberon.Par;
		Out.String("System.Free"); Out.Ln();
		Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
		WHILE S.class = Texts.Name DO FreeMod(S); Texts.Scan(S) END;
		IF (S.class = Texts.Char) & (S.c = "^") THEN Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S);
				IF S.class = Texts.Name THEN FreeMod(S) END
			END
		 END
	END Free;

	PROCEDURE ShowModules*;
		VAR T: Texts.Text;
			V: Viewers.Viewer;
			M: Modules.Module;
            X, Y: INTEGER;
	BEGIN
        T := TextFrames.Text("");
        Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
        V := MenuViewers.New(
          TextFrames.NewMenu("System.ShowModules", StandardMenu),
          TextFrames.NewText(T, 0),
          TextFrames.menuH,
          X, Y);
		M := Modules.modules();
		WHILE M # NIL DO
			Texts.WriteString(W, M.name); Texts.WriteInt(W, M.refcnt, 5); Texts.WriteLn(W);
			M := M.next
		END;
		Texts.Append(T, W.buf)
	END ShowModules;

	PROCEDURE ShowCommands*;
		VAR M: Modules.Module; S: Texts.Scanner; beg, end, time, i: LONGINT;
			T: Texts.Text; V: Viewers.Viewer; X, Y: INTEGER;
			cmd: Modules.Cmd;
	BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") THEN Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END ;
		END ;
		IF S.class IN {Texts.Name, Texts.String} THEN
			i := 0; WHILE S.s[i] >= "0" DO INC(i) END ;
			S.s[i] := 0X; M := Modules.ThisMod(S.s);
			IF M # NIL THEN
				Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
				T := TextFrames.Text("");
				V := MenuViewers.New(
					TextFrames.NewMenu("System.Commands", StandardMenu),
					TextFrames.NewText(T, 0),
					TextFrames.menuH,
					X, Y);
				cmd := M.cmds;
				WHILE cmd # NIL DO
					Texts.WriteString(W, M.name); Texts.Write(W, "."); Texts.WriteString(W, cmd.name); Texts.WriteLn(W);
					cmd := cmd.next
				END ;
				Texts.Append(T, W.buf)
			END
		END
	END ShowCommands;

	PROCEDURE ChangeDirectory*;
		VAR par: Oberon.ParList;
            T: Texts.Text;
			S: Texts.Scanner;
			res: INTEGER;
			beg, end, time: LONGINT;
	BEGIN
		Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.c = "^") OR (S.line # 0) THEN
           Oberon.GetSelection(T, beg, end, time);
            IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
        END;
		IF (S.class IN {Texts.Name, Texts.String}) & (S.line = 0) THEN
			Texts.WriteString(W, "System.ChangeDirectory "); Texts.WriteString(W, S.s);
			Files.ChangeDirectory(S.s, res);
			IF res # 0 THEN Texts.WriteString(W, "  -- failed") END ;
			Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
		END
	END ChangeDirectory;

	PROCEDURE CopyFile(name: ARRAY OF CHAR; VAR S: Texts.Scanner);
		VAR f, g: Files.File; Rf, Rg: Files.Rider; ch: CHAR;
	BEGIN Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
			IF (S.class = Texts.Char) & (S.c = ">") THEN Texts.Scan(S);
				IF S.class IN {Texts.Name, Texts.String} THEN
					Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
					Texts.WriteString(W, " copying"); Texts.Append(Oberon.Log, W.buf);
					f := Files.Old(name);
					IF f # NIL THEN g := Files.New(S.s);
						Files.Set(Rf, f, 0); Files.Set(Rg, g, 0); Files.Read(Rf, ch);
						WHILE ~Rf.eof DO Files.Write(Rg, ch); Files.Read(Rf, ch) END;
						Files.Register(g)
					ELSE Texts.WriteString(W, " failed")
					END ;
					EndLine
				END
			END
		END
	END CopyFile;

	PROCEDURE CopyFiles*;
		VAR S: Texts.Scanner;
	BEGIN GetArg(S);
		Texts.WriteString(W, "System.CopyFiles"); EndLine;
		WHILE S.class IN {Texts.Name, Texts.String} DO CopyFile(S.s, S); Texts.Scan(S) END
	END CopyFiles;

	PROCEDURE RenameFile (name: ARRAY OF CHAR; VAR S: Texts.Scanner);
		VAR res: INTEGER;
	BEGIN Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "=") THEN Texts.Scan(S);
			IF (S.class = Texts.Char) & (S.c = ">") THEN Texts.Scan(S);
				IF S.class IN {Texts.Name, Texts.String} THEN
					Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
					Texts.WriteString(W, " renaming"); Files.Rename(name, S.s, res);
					IF res > 1 THEN Texts.WriteString(W, " failed") END;
					EndLine
				END
			END
		END
	END RenameFile;

	PROCEDURE RenameFiles*;
		VAR S: Texts.Scanner;
	BEGIN GetArg(S);
		Texts.WriteString(W, "System.RenameFiles"); EndLine;
		WHILE S.class IN {Texts.Name, Texts.String} DO RenameFile(S.s, S); Texts.Scan(S) END
	END RenameFiles;

	PROCEDURE DeleteFile(VAR name: ARRAY OF CHAR);
		VAR res: INTEGER;
	BEGIN Texts.WriteString(W, name); Texts.WriteString(W, " deleting");
		Files.Delete(name, res);
		IF res # 0 THEN Texts.WriteString(W, " failed") END;
		EndLine
	END DeleteFile;

	PROCEDURE DeleteFiles*;
		VAR S: Texts.Scanner;
	BEGIN GetArg(S);
		Texts.WriteString(W, "System.DeleteFiles"); EndLine;
		WHILE S.class IN {Texts.Name, Texts.String} DO DeleteFile(S.s); Texts.Scan(S) END
	END DeleteFiles;

	PROCEDURE Quit*;
		VAR res: LONGINT;
	BEGIN res := Unix.Kill(Unix.Getpid(), 3)
	END Quit;

	PROCEDURE Execute*;
		VAR par: Oberon.ParList;
			t: Texts.Text; R: Texts.Reader; V: Viewers.Viewer;
			i, bufsize, beg, end, time, stdin, stdout, stderr, fd, res: LONGINT;
			boldFnt, italicFnt: Fonts.Font;
			cmd: ARRAY 4096 OF CHAR;
			buf: ARRAY 32000 OF CHAR;
			X, Y: INTEGER;
			ch: CHAR;
	BEGIN par := Oberon.Par;
		Oberon.AllocateSystemViewer(par.vwr.X, X, Y);
		Texts.OpenReader(R, par.text, par.pos);
		i := 0; cmd := ""; Texts.Read(R, ch);
		WHILE ch = " " DO Texts.Read(R, ch) END ;
		WHILE (ch >= " ") & (ch # "^") DO cmd[i] := ch; INC(i); Texts.Read(R, ch) END ;
		IF (i = 0) OR (ch = "^") THEN
			Oberon.GetSelection(t, beg, end, time);
			IF time >= 0 THEN Texts.OpenReader(R, t, beg);
				Texts.Read(R, ch);
				WHILE Texts.Pos(R) <= end DO
					IF ch = 0DX THEN ch := " " END ;
					cmd[i] := ch; INC(i); Texts.Read(R, ch)
				END
			END
		END ;
		cmd[i] := 0X;
		stdin := Unix.Dup(Unix.stdin);
		stdout := Unix.Dup(Unix.stdout);
		stderr := Unix.Dup(Unix.stderr);
		res := Unix.Close(Unix.stdin);
		res := Unix.Close(Unix.stdout);
		res := Unix.Close(Unix.stderr);
		fd := Unix.Open("/dev/null", Unix.rdwr, {0..31});
		fd := Unix.Open("/tmp/System.Execute", Unix.rdwr + Unix.creat + Unix.trunc, {0..31});
		res := Unix.Unlink("/tmp/System.Execute");
		fd := Unix.Dup(fd);
		system(cmd);
		boldFnt := Fonts.This("Syntax10b.Scn.Fnt");
		italicFnt := Fonts.This("Syntax10i.Scn.Fnt");
		res := Unix.Lseek(Unix.stdout, 0, 0);
		bufsize := Unix.ReadBlk(Unix.stdout, buf);
		IF bufsize > 0 THEN t := TextFrames.Text("");
			V := MenuViewers.New(
				TextFrames.NewMenu("System.Execute", StandardMenu),
				TextFrames.NewText(t, 0),
				TextFrames.menuH,
				X, Y);
			REPEAT i := 0;
				WHILE i < bufsize DO ch := buf[i];
					IF ch = 0AX THEN ch := 0DX END ;	(* LF -> CR *)
					IF (i < bufsize-2) & (buf[i+1] = 08X) THEN	(* -almost- correct (consider buf limit...) *)
						Texts.SetFont(W, boldFnt);
						IF ch # "_" THEN Texts.SetFont(W, boldFnt); Texts.Write(W, ch)
						ELSE Texts.SetFont(W, boldFnt); Texts.Write(W, buf[i+2])
						END ;
						Texts.SetFont(W, Fonts.Default);
						REPEAT INC(i, 2) UNTIL (i+1 >= bufsize) OR (buf[i+1] # 08X);
					ELSE Texts.Write(W, ch)
					END ;
					INC(i)
				END ;
				bufsize := Unix.ReadBlk(Unix.stdout, buf)
			UNTIL bufsize = 0;
			Texts.Append(t, W.buf);
			res := Unix.Ftruncate(Unix.stdout, 0);
			res := Unix.Lseek(Unix.stdout, 0, 0)
		END ;
		res := Unix.Close(Unix.stdin);
		res := Unix.Close(Unix.stdout);
		res := Unix.Close(Unix.stderr);
		fd := Unix.Dup(stdin);
		fd := Unix.Dup(stdout);
		fd := Unix.Dup(stderr);
		res := Unix.Close(stdin);
		res := Unix.Close(stdout);
		res := Unix.Close(stderr)
	END Execute;

	PROCEDURE Scan(VAR pos: INTEGER; VAR O, path: ARRAY OF CHAR);
		VAR i: INTEGER;
	BEGIN i := 0;
		WHILE (O[pos] = " ") OR (O[pos] = ":") DO INC(pos) END ;
		WHILE (O[pos] > " ") & (O[pos] # ":") DO path[i] := O[pos]; INC(i); INC(pos) END ;
		WHILE (O[pos] = " ") OR (O[pos] = ":") DO INC(pos) END ;
		path[i] := 0X
	END Scan;

	PROCEDURE SlashPos(VAR name: ARRAY OF CHAR): INTEGER;
		VAR i: INTEGER;
	BEGIN i := 0;
		WHILE name[i] # 0X DO INC(i) END ;
		WHILE (i >= 0) & (name[i] # "/") DO DEC(i) END ;
		RETURN i
	END SlashPos;

	PROCEDURE Directory*;
		VAR T: Texts.Text; pat, OBERON, path: ARRAY 1024 OF CHAR;
			i, opos, slash: INTEGER; ch: CHAR; R: Texts.Reader; t, beg, end: LONGINT;
	BEGIN i := 0;
		Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos); Texts.Read(R, ch);
		WHILE (ch = " ") OR (ch = 09X) DO Texts.Read(R, ch) END ;
		WHILE ch > " " DO pat[i] := ch; INC(i); Texts.Read(R, ch) END ;
		pat[i] := 0X;
		IF pat[0] = "^" THEN Oberon.GetSelection(T, beg, end, t);
			IF t >= 0 THEN Texts.OpenReader(R, T, beg); Texts.Read(R, ch);
				WHILE (ch = " ") OR (ch = 09X) DO Texts.Read(R, ch) END ;
				i := 0; WHILE ch > " " DO pat[i] := ch; INC(i); Texts.Read(R, ch) END ;
				pat[i] := 0X
			END
		END ;
		IF pat # "" THEN 
			T := TextFrames.Text("");
			slash := SlashPos(pat);
			IF slash >= 0 THEN Texts.WriteString(W, "ls -d ");
				IF (slash = 1) & (pat[0] = ".") THEN pat[0] := " "; pat[1] := " " END ;
				Texts.WriteString(W, pat)
			ELSE
				OBERON := ""; opos := 0;
				Args.GetEnv("OBERON", OBERON);
				WHILE OBERON[opos] # 0X DO
					Texts.WriteString(W, "ls -d "); Scan(opos, OBERON, path);
					IF path # "." THEN Texts.WriteString(W, path); Texts.Write(W, "/") END ;
					Texts.WriteString(W, pat); Texts.WriteString(W, " 2>/dev/null;")
				END
			END ;
			Texts.Append(T, W.buf);
			Oberon.Par.text := T; Oberon.Par.pos := 0;
			Execute
		END
	END Directory;

BEGIN
	Texts.OpenWriter(W);
	trapLevel := 0;
	Unix.SigSetHandler(2, Trap);	(* keyboard interrupt *)
	Unix.SigSetHandler(3, Trap);	(* quit *)
	Unix.SigSetHandler(4, Trap);	(* illegal instruction *)
	Unix.SigSetHandler(8, Trap);	(* arithmetic error *)
	Unix.SigSetHandler(10, Trap);	(* bus error *)
	Unix.SigSetHandler(11, Trap);	(* segmentation violation *)
	Unix.SigSetHandler(13, Trap);	(* unconnected pipe *)
	IF Kernel.LIB = "" THEN Kernel.LIB := "OberonV4" END
END System.
