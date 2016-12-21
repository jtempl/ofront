MODULE EdiT; (* gri 5.9.90, jt 10.9.90/07.10.93 *)

(*  this module shows by example how to extend the standard Oberon text editor
	by additional commands and a special message handler *)

	IMPORT
		Display, Viewers, Texts, TextFrames, MenuViewers, Oberon, Files, Unix;

	CONST
		BS = 8X; CR = 0DX; LF = 0AX;
		maxlen = 128;
		Menu = "System.Close  System.Copy  System.Grow  Edit.Search  Edit.Replace  Edit.Store ";

	VAR
		W: Texts.Writer;

		search: RECORD
			len: INTEGER;
			buf: ARRAY maxlen OF CHAR;
			d: ARRAY maxlen OF SHORTINT
		END;
	
	PROCEDURE BegOfLine(text: Texts.Text; pos: LONGINT): LONGINT;
		VAR r: Texts.Reader; ch: CHAR;
	BEGIN
		LOOP
			DEC(pos);
			IF pos < 0 THEN RETURN 0 END;
			Texts.OpenReader(r, text, pos); Texts.Read(r, ch);
			IF ch = CR THEN RETURN pos+1 END
		END
	END BegOfLine;
	
	PROCEDURE BackSpace(f: TextFrames.Frame);
		VAR r: Texts.Reader; ch: CHAR; pos: LONGINT;
	BEGIN
		pos := f.carloc.org-1; IF pos < 0 THEN pos := 0 END;
		Texts.OpenReader(r, f.text, pos); Texts.Read(r, ch);
		WHILE ~r.eot & (Texts.Pos(r) <= f.carloc.pos) DO (* search white space begin *)
			IF ch > " " THEN pos := Texts.Pos(r) END;
			Texts.Read(r, ch)
		END;
		IF pos < f.carloc.pos THEN
			Texts.Delete(f.text, pos, f.carloc.pos);
			TextFrames.SetCaret(f, pos)
		END
	END BackSpace;
				
	PROCEDURE ShowPos(f: TextFrames.Frame; car: LONGINT);
		VAR m: INTEGER;
	BEGIN
		IF f.hasCar THEN TextFrames.RemoveCaret(f) END;
		IF f.hasSel THEN TextFrames.RemoveSelection(f) END;
		Oberon.RemoveMarks(f.X, f.Y, f.W, f.H); m := 200;
		WHILE (car < f.org) OR (TextFrames.Pos(f, f.X+f.W, f.Y) < car) DO
			TextFrames.Show(f, BegOfLine(f.text, car-m));
			DEC(m, 20)
		END;
		TextFrames.SetCaret(f, car)
	END ShowPos;
	
	PROCEDURE CompileDk;
		VAR d, k, l: SHORTINT;
	BEGIN k := 1; d := 1;
		WHILE k < search.len DO
			l := 0;
			WHILE (d + l < search.len) & (search.buf[l] = search.buf[d + l]) DO l := l + 1 END ;
			WHILE k <= d + l DO search.d[k] := d; k := k + 1 END ;
			d := d + 1
		END
	END CompileDk;
	
	PROCEDURE KMPsearch(text: Texts.Text; beg: LONGINT): LONGINT;
		VAR R: Texts.Reader; ch: CHAR; k: SHORTINT;
	BEGIN
		IF search.len > 0 THEN
			Texts.OpenReader(R, text, beg); Texts.Read(R, ch);
			k := 0;
			WHILE ~R.eot DO
				IF ch = search.buf[k] THEN k := k + 1;
					IF k = search.len THEN RETURN Texts.Pos(R) - k + search.len
					ELSE Texts.Read(R, ch)
					END ;
				ELSIF k = 0 THEN Texts.Read(R, ch)
				ELSE k := k - search.d[k]
				END
			END
		END;
		RETURN -1
	END KMPsearch;

	PROCEDURE Handle*(F: Display.Frame; VAR M: Display.FrameMsg);
	BEGIN
		WITH F: TextFrames.Frame DO
			WITH M: Oberon.InputMsg DO
				IF (M.id = Oberon.consume) & F.hasCar & (M.ch = BS) THEN BackSpace(F)
				ELSE TextFrames.Handle(F, M)
				END
			ELSE TextFrames.Handle(F, M)
			END
		END
	END Handle;

(* ------------------------------------- commands ------------------------------------- *)

	PROCEDURE Open*;			(* like Edit.Open, but installs the EdiT message handler *)
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
			Oberon.AllocateUserViewer(par.vwr.X, X, Y);
			V := MenuViewers.New(
				TextFrames.NewMenu(S.s, "^Edit.Menu.Text"),
				TextFrames.NewText(TextFrames.Text(S.s), 0),
				TextFrames.menuH,
				X, Y);
			V.dsc.next.handle := Handle
		END
	END Open;

	PROCEDURE UnmarkMenu* (V: Viewers.Viewer); (* from EditTools.Mod *)
		VAR R: Texts.Reader; text: Texts.Text; ch: CHAR;
	BEGIN
		IF (V IS MenuViewers.Viewer) & (V.dsc IS TextFrames.Frame) THEN
			text := V.dsc(TextFrames.Frame).text;
			IF text.len > 0 THEN Texts.OpenReader(R, text, text.len - 1); Texts.Read(R, ch);
				IF ch = "!" THEN Texts.Delete(text, text.len - 1, text.len) END
			END
		END
	END UnmarkMenu;

	PROCEDURE StoreAscii*;			(* store text as Ascii file; no backup, retain Unix file permissions *)
		VAR par: Oberon.ParList;
			V: Viewers.Viewer;
			T: Texts.Text;
			S: Texts.Scanner;
			TF: TextFrames.Frame;
			ch: CHAR;
			beg, end, time: LONGINT;
			R: Texts.Reader;
			F, F0: Files.File;
			O: Files.Rider;
			stat: Unix.Status;
			res: LONGINT;
	BEGIN
		Texts.WriteString(W, "EdiT.StoreAscii ");
		par := Oberon.Par; 
		IF par.frame = par.vwr.dsc THEN
			V := par.vwr; Texts.OpenScanner(S, V.dsc(TextFrames.Frame).text, 0)
		ELSE V := Oberon.MarkedViewer(); Texts.OpenScanner(S, par.text, par.pos)
		END;
		Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		ELSIF (S.class = Texts.Char) & (S.c = "*") THEN Texts.OpenScanner(S, V.dsc(TextFrames.Frame).text, 0); Texts.Scan(S)
		END;
		IF (S.class IN {Texts.Name, Texts.String}) & (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
			TF := V.dsc.next(TextFrames.Frame);
			TextFrames.Mark(TF, -1);
			Texts.WriteString(W, S.s); Texts.WriteLn(W);
			Texts.Append(Oberon.Log, W.buf);
			Texts.OpenReader(R, TF.text, 0);
			F := Files.New(S.s); Files.Set(O, F, 0); Texts.Read(R, ch);
			WHILE ~R.eot DO
				IF ch = CR THEN ch := 0AX END ;
				IF ch # Texts.ElemChar THEN Files.Write(O, ch) END;
				Texts.Read(R, ch)
			END ;
			F0 := Files.Old(S.s);
			Files.Register(F);
			IF F0 # NIL THEN res := Unix.Fstat(F0.fd, stat);
				(* don't mess around with the set-user-id bit *)
				IF stat.uid = Unix.Getuid() THEN res := Unix.Fchmod(F.fd, stat.mode) END
			END ;
			UnmarkMenu(V);
			TextFrames.Mark(TF, 1)
		END
	END StoreAscii;

	PROCEDURE StoreMacAscii*;			(* store as MacOs ascii file *)
		VAR par: Oberon.ParList;
			V: Viewers.Viewer;
			T: Texts.Text;
			S: Texts.Scanner;
			TF: TextFrames.Frame;
			ch: CHAR;
			beg, end, time: LONGINT;
			R: Texts.Reader;
			F, F0: Files.File;
			O: Files.Rider;
			stat: Unix.Status;
			res: LONGINT;
	BEGIN
		Texts.WriteString(W, "EdiT.StoreMacAscii ");
		par := Oberon.Par; 
		IF par.frame = par.vwr.dsc THEN
			V := par.vwr; Texts.OpenScanner(S, V.dsc(TextFrames.Frame).text, 0)
		ELSE V := Oberon.MarkedViewer(); Texts.OpenScanner(S, par.text, par.pos)
		END;
		Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		ELSIF (S.class = Texts.Char) & (S.c = "*") THEN Texts.OpenScanner(S, V.dsc(TextFrames.Frame).text, 0); Texts.Scan(S)
		END;
		IF (S.class IN {Texts.Name, Texts.String}) & (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
			TF := V.dsc.next(TextFrames.Frame);
			TextFrames.Mark(TF, -1);
			Texts.WriteString(W, S.s); Texts.WriteLn(W);
			Texts.Append(Oberon.Log, W.buf);
			Texts.OpenReader(R, TF.text, 0);
			F := Files.New(S.s); Files.Set(O, F, 0); Texts.Read(R, ch);
			WHILE ~R.eot DO
				(*IF ch = CR THEN ch := 0AX END ;*)
				IF (ch # 1CX) & (ch # 0AX) THEN Files.Write(O, ch) END;
				Texts.Read(R, ch)
			END ;
			F0 := Files.Old(S.s);
			Files.Register(F);
			IF F0 # NIL THEN res := Unix.Fstat(F0.fd, stat);
				(* don't mess around with the set-user-id bit *)
				IF stat.uid = Unix.Getuid() THEN res := Unix.Fchmod(F.fd, stat.mode) END
			END ;
			TextFrames.Mark(TF, 1)
		END
	END StoreMacAscii;

	PROCEDURE StoreDosAscii*;			(* store as DOS ascii file *)
		VAR par: Oberon.ParList;
			V: Viewers.Viewer;
			T: Texts.Text;
			S: Texts.Scanner;
			TF: TextFrames.Frame;
			ch: CHAR;
			beg, end, time: LONGINT;
			R: Texts.Reader;
			F, F0: Files.File;
			O: Files.Rider;
			stat: Unix.Status;
			res: LONGINT;
	BEGIN
		Texts.WriteString(W, "EdiT.StoreDosAscii ");
		par := Oberon.Par; 
		IF par.frame = par.vwr.dsc THEN
			V := par.vwr; Texts.OpenScanner(S, V.dsc(TextFrames.Frame).text, 0)
		ELSE V := Oberon.MarkedViewer(); Texts.OpenScanner(S, par.text, par.pos)
		END;
		Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		ELSIF (S.class = Texts.Char) & (S.c = "*") THEN Texts.OpenScanner(S, V.dsc(TextFrames.Frame).text, 0); Texts.Scan(S)
		END;
		IF (S.class IN {Texts.Name, Texts.String}) & (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
			TF := V.dsc.next(TextFrames.Frame);
			TextFrames.Mark(TF, -1);
			Texts.WriteString(W, S.s); Texts.WriteLn(W);
			Texts.Append(Oberon.Log, W.buf);
			Texts.OpenReader(R, TF.text, 0);
			F := Files.New(S.s); Files.Set(O, F, 0); Texts.Read(R, ch);
			WHILE ~R.eot DO
				IF ch = CR THEN Files.Write(O, CR); Files.Write(O, LF)
				ELSIF ch # LF THEN Files.Write(O, ch)
				END;
				Texts.Read(R, ch)
			END ;
			F0 := Files.Old(S.s);
			Files.Register(F);
			IF F0 # NIL THEN res := Unix.Fstat(F0.fd, stat);
				(* don't mess around with the set-user-id bit *)
				IF stat.uid = Unix.Getuid() THEN res := Unix.Fchmod(F.fd, stat.mode) END
			END ;
			TextFrames.Mark(TF, 1)
		END
	END StoreDosAscii;

	PROCEDURE LocateLine*;					(* locate caret at specified line number *)
		VAR par: Oberon.ParList;
			V: Viewers.Viewer;
			F: TextFrames.Frame;
			T: Texts.Text;
			S: Texts.Scanner;
			R: Texts.Reader;
			line: LONGINT;
			beg, end, time: LONGINT;
			ch: CHAR;
	BEGIN
		par := Oberon.Par; 
		V := Oberon.FocusViewer;
		Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
 	   IF (S.class = Texts.Char) & (S.c = "^") OR (S.line # 0) THEN
   	   Oberon.GetSelection(T, beg, end, time);
   	    IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
 	   END;
		WHILE (S.class < Texts.Int) & (S.line = 0) DO Texts.Scan(S) END ;	(*skip names*)
	    IF (S.class = Texts.Int) & (V.state > 1) & (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
			F := V.dsc.next(TextFrames.Frame);
			Texts.OpenReader(R, F.text, 0); line := 1; Texts.Read(R, ch);
			WHILE ~R.eot & (line < S.i) DO
				IF ch = CR THEN INC(line) END ;
				Texts.Read(R, ch)
			END ;
			ShowPos(F, Texts.Pos(R)-1)
		END
	END LocateLine;

	PROCEDURE Match*;	(* select text between matching brackets *)
		CONST
			selLength = 32;
		VAR
			R:Texts.Reader;
			V: Viewers.Viewer;
			F: TextFrames.Frame;
			len, i, lev: LONGINT;
			ch: CHAR;
			lpar, rpar, tx: ARRAY selLength OF CHAR;
	BEGIN
		V := Oberon.MarkedViewer();
		IF (V.dsc # NIL) & (V.dsc.next IS TextFrames.Frame) THEN
			F := V.dsc.next(TextFrames.Frame);
			IF (F.hasSel) & (F.selend.pos - F.selbeg.pos < selLength) THEN
				i := 0; len := F.selend.pos - F.selbeg.pos;
				Texts.OpenReader(R, F.text, F.selbeg.pos);
				WHILE i < len DO
					Texts.Read(R, ch); lpar[i] := ch;
					IF ch = "(" THEN ch := ")"
					ELSIF ch = "[" THEN ch := "]"
					ELSIF ch = "{" THEN ch := "}"
					ELSIF ch = "<" THEN ch := ">"
					END ;
					INC(i); rpar[len - i] := ch
				END ;
				lpar[len] := 0X; rpar[len] := 0X; tx[len] := 0X; lev := 1;
				LOOP i := 0;
					WHILE (i < len) & ~R.eot DO Texts.Read(R, tx[i]); INC(i) END ;
					IF R.eot THEN RETURN
					ELSIF tx = rpar THEN DEC(lev);
						IF lev = 0 THEN EXIT END
					ELSIF tx = lpar THEN INC(lev)
					ELSE Texts.OpenReader(R, F.text, Texts.Pos(R) - len + 1)
					END
				END ;
				TextFrames.SetSelection(F, F.selbeg.pos, Texts.Pos(R))
			END
		END
	END Match;

	PROCEDURE SearchDiff0(precise: BOOLEAN);
		VAR
			f1, f2: TextFrames.Frame;
			p1, p2: LONGINT;
			r1, r2: Texts.Reader;
			ch1, ch2: CHAR;
	
		PROCEDURE GetSelection(VAR F: TextFrames.Frame; VAR pos: LONGINT);
			VAR time: LONGINT; v: Viewers.Viewer; x: INTEGER; f: TextFrames.Frame;
		BEGIN
			time := -1; x := 0; F := NIL;
			WHILE x < Display.Width DO
				v := Viewers.This(x, 0);
				WHILE v.state > 1 DO
					IF v.dsc.next IS TextFrames.Frame THEN
						f := v.dsc.next(TextFrames.Frame); 
						IF (f.hasSel) & (f.time > time) THEN F := f; pos := f.selbeg.pos; time := f.time END;
					END;
					v := Viewers.Next(v)
				END;
				x := x + v.W
			END;
			IF F # NIL THEN TextFrames.RemoveSelection(F); TextFrames.RemoveCaret(F) END
		END GetSelection;

		PROCEDURE ShowSelection(f: TextFrames.Frame; pos: LONGINT);
			VAR x: LONGINT;
		BEGIN
			IF pos > TextFrames.Pos(f, f.X + f.W - 1, f.Y) THEN 
				x := pos - 150; IF x < 0 THEN x := 0 END;
				TextFrames.Show(f, x)
			END;
			TextFrames.SetSelection(f, pos, pos+1)
		END ShowSelection;

		PROCEDURE Read(VAR r: Texts.Reader; VAR ch: CHAR; VAR p: LONGINT);
		BEGIN
			Texts.Read(r, ch); INC(p);
			IF ~precise & (ch <= " ") & (ch # 0X) THEN
				REPEAT Texts.Read(r, ch); INC(p) UNTIL (ch > " ") OR (ch = 0X);
			END
		END Read;

	BEGIN
		GetSelection(f1, p1); GetSelection(f2, p2);
		IF (f1 # NIL) & (f2 # NIL) THEN
			Texts.OpenReader(r1, f1.text, p1); 
			Texts.OpenReader(r2, f2.text, p2); 
			REPEAT
				Read(r1, ch1, p1); Read(r2, ch2, p2)
			UNTIL (ch1 # ch2) OR (ch1 = 0X);
			IF (ch1 = 0X) OR (ch2 = 0X) THEN DEC(p1); DEC(p2) END;
			ShowSelection(f1, p1-1); ShowSelection(f2, p2-1)
		END
	END SearchDiff0;

	(*search for the first difference starting at the last two text selections, ignore white space differences *)
	PROCEDURE SearchDiff*;
	BEGIN SearchDiff0(FALSE);
	END SearchDiff;

	(*search for the first difference starting at the last two text selections, stop also at white space differences *)
	PROCEDURE SearchDiffW*;
	BEGIN SearchDiff0(TRUE);
	END SearchDiffW;

	PROCEDURE SearchStr(t: Texts.Text; pos: LONGINT; s: ARRAY OF CHAR; at: INTEGER): LONGINT;
		VAR i, j: INTEGER;
	BEGIN i := 0; j := at;
		WHILE (i # maxlen) & (s[j] # 0X) DO search.buf[i] := s[j]; j := j+1; i := i+1 END;
		search.len := i; CompileDk;
		RETURN KMPsearch(t, pos)
	END SearchStr;

	PROCEDURE Show*;
		VAR T: Texts.Text;
			S: Texts.Scanner;
			V: Viewers.Viewer;
			X, Y, i, j: INTEGER;
			pos, beg, end, time: LONGINT;
			name: ARRAY 64 OF CHAR;
    BEGIN
		Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") OR (S.line # 0) THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		END;
		IF S.class IN {Texts.Name, Texts.String} THEN
			i := -1; j := 0;
			WHILE S.s[j] # 0X DO
				IF S.s[j] = "." THEN i := j END;
				name[j] := S.s[j]; j := j+1
			END;
			IF i < 0 THEN name[j] := "."; i := j END;
			name[i+1] := "M"; name[i+2] := "o"; name[i+3] := "d"; name[i+4] := 0X;
			T := TextFrames.Text(name);
			pos := 0;
			IF j > i THEN (*object name specified*)
				IF j = i + 1 THEN Texts.Scan(S);
					IF (S.class = Texts.Char) & (S.c = "(") THEN (*type bound proc*)
						Texts.Scan(S);
						IF S.class IN {Texts.Name, Texts.String} THEN
							pos := SearchStr(T, 0, "PROCEDURE", 0);
							pos := SearchStr(T, pos, S.s, 0);
							Texts.Scan(S); Texts.Scan(S);
							IF S.class IN {Texts.Name, Texts.String} THEN pos := SearchStr(T, pos, S.s, 0) ELSE pos := 0 END
						END
					END
				ELSE
					pos := SearchStr(T, 0, S.s, i+1);
				END
			END;
			Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
			V := MenuViewers.New(
				TextFrames.NewMenu(S.s, "^Edit.Menu.Text"),
				TextFrames.NewText(T, pos-200),
				TextFrames.menuH,
				X, Y);
			V.dsc.next.handle := Handle;
			Oberon.PassFocus(V);
			TextFrames.SetCaret(V.dsc.next(TextFrames.Frame), pos)
		END
	END Show;

	PROCEDURE Grep*;	(* EdiT.Grep pattern {filename} *)
		VAR S: Texts.Scanner; R: Texts.Reader; ch: CHAR; n: INTEGER;
			T: Texts.Text; beg, end, time, pos: LONGINT;
	BEGIN search.len := 0;
		IF Oberon.Par.vwr.dsc = Oberon.Par.frame THEN (* in menu; use selection beg-end *)
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenReader(R, T, beg); Texts.Read(R, ch);
				WHILE ~R.eot & (beg + search.len < end) DO 
					search.buf[search.len] := ch; INC(search.len); Texts.Read(R, ch)
				END ;
				search.buf[search.len] := 0X;
				IF search.len > 0 THEN
					IF Oberon.Par.vwr.dsc.next IS TextFrames.Frame THEN
						Texts.OpenScanner(S, Oberon.Par.vwr.dsc.next(TextFrames.Frame).text, 0);
						Texts.Scan(S)
					ELSE
						Texts.WriteString(W, "not a text viewer"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
					END
				ELSE
					Texts.WriteString(W, "empty selection"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
				END
			ELSE
				Texts.WriteString(W, "no selection"); Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
			END
		ELSE
			Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
			IF S.class IN {Texts.Name, Texts.String} THEN
				COPY(S.s, search.buf); search.len := S.len;
				IF S.class = Texts.String THEN DEC(search.len) END ;
				Texts.Scan(S)
			END
		END;
		IF (search.len > 0) & (S.class IN {Texts.Name, Texts.String}) THEN
			CompileDk;
			WHILE S.class IN {Texts.Name, Texts.String} DO
				T := TextFrames.Text(S.s);
				n := 0; pos := KMPsearch(T, 0);
				WHILE pos >= 0 DO
					IF n = 0 THEN Texts.WriteString(W, S.s) END ;
					IF n MOD 4 = 0 THEN Texts.WriteLn(W) END ;
					Texts.WriteInt(W, pos, 10);
					INC(n); pos := KMPsearch(T, pos)
				END ;
				IF n > 0 THEN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf) END ;
				Texts.Scan(S)
			END
		END
	END Grep;

BEGIN
	Texts.OpenWriter(W); search.len := 0; search.buf[0] := 0X
END EdiT.
