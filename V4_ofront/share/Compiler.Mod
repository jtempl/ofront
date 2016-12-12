MODULE Compiler;

	(* like Ofront.Translate but in addition calls the C-compiler and linker *)

	IMPORT Kernel, Modules, Oberon, Out, Texts, 
		OfrontOPP, OfrontOPB, OfrontOPT, OfrontOPV, OfrontOPC, OfrontOPM;
	
	VAR
		cl*: ARRAY 128 OF CHAR; (* command to call C-compiler and linker for a module *)
	
	PROCEDURE Append(VAR s: ARRAY OF CHAR; VAR len: INTEGER; x: ARRAY OF CHAR);
		VAR i: INTEGER;
	BEGIN i := 0;
		WHILE x[i] # 0X DO s[len] := x[i]; INC(len); INC(i) END ;
		s[len] := 0X
	END Append;

	PROCEDURE LinkImports(obj: OfrontOPT.Object; VAR clCmd: ARRAY OF CHAR; VAR len: INTEGER);
	BEGIN
		IF obj # NIL THEN
			LinkImports(obj^.left, clCmd, len);
			IF (obj^.mode = OfrontOPT.Mod) & (obj^.mnolev # 0) THEN
				Append(clCmd, len, " -l");
				Append(clCmd, len, Modules.libPrefix);
				Append(clCmd, len, OfrontOPT.GlbMod[-obj^.mnolev].name);
			END ;
			LinkImports(obj^.right, clCmd, len)
		END
	END LinkImports;

	PROCEDURE GetClCmd(main: BOOLEAN; VAR clCmd: ARRAY OF CHAR); (* must be before OfrontOPT.Close *)
		VAR len: INTEGER; import: OfrontOPT.Object;
	BEGIN
		clCmd[0] := 0X; len := 0;
		Append(clCmd, len, cl);
		Append(clCmd, len, " ");
		(* module *)
		Append(clCmd, len, OfrontOPT.SelfName);
		Append(clCmd, len, " ");
		(* outname *)
		IF ~main THEN Append(clCmd, len, Modules.libPrefix) END ;
		Append(clCmd, len, OfrontOPT.SelfName);
		(* options *)
		Append(clCmd, len, " -");
		IF main THEN Append(clCmd, len, "m") END ;
		IF OfrontOPM.clverbose IN OfrontOPM.opt THEN Append(clCmd, len, "V") END ;
		IF OfrontOPM.cldebug IN OfrontOPM.opt THEN Append(clCmd, len, "G") END ;
		IF OfrontOPM.cloptimize IN OfrontOPM.opt THEN Append(clCmd, len, "O") END ;
		(* ccOptions *)
		Append(clCmd, len, ' "');
		IF OfrontOPT.SelfName # "SYSTEM" THEN Append(clCmd, len, "-l"); 
			Append(clCmd, len, Modules.libPrefix); Append(clCmd, len, "SYSTEM") 
		END ;
		LinkImports(OfrontOPT.topScope^.right, clCmd, len);
		Append(clCmd, len, " ");
		Append(clCmd, len, OfrontOPM.clOpts);
		Append(clCmd, len, '"')
	END GetClCmd;

	PROCEDURE Module*(VAR done: BOOLEAN);
		VAR ext, new, verbose: BOOLEAN; p: OfrontOPT.Node;
			clCmd: POINTER TO ARRAY 4000 OF CHAR;  status: LONGINT; out: Texts.Buffer; res: INTEGER;
	BEGIN
		clCmd := NIL;
		OfrontOPP.Module(p, OfrontOPM.opt);
		IF OfrontOPM.noerr THEN
			OfrontOPV.Init;
			OfrontOPV.AdrAndSize(OfrontOPT.topScope);
			OfrontOPT.Export(ext, new);
			IF OfrontOPM.noerr THEN
				NEW(clCmd);
				OfrontOPM.OpenFiles(OfrontOPT.SelfName);
				OfrontOPC.Init;
				OfrontOPV.Module(p);
				IF OfrontOPM.noerr THEN
					IF (OfrontOPM.mainprog IN OfrontOPM.opt) & (OfrontOPM.modName # "SYSTEM") THEN
						OfrontOPM.DeleteNewSym; OfrontOPM.LogWStr("  main program");
						GetClCmd(TRUE, clCmd^)
					ELSE
						IF new THEN OfrontOPM.LogWStr("  new symbol file"); OfrontOPM.RegisterNewSym
						ELSIF ext THEN OfrontOPM.LogWStr("  extended symbol file"); OfrontOPM.RegisterNewSym
						END ;
						GetClCmd(FALSE, clCmd^)
					END
				ELSE
					OfrontOPM.DeleteNewSym
				END ;
			END
		END ;
		verbose := OfrontOPM.clverbose IN OfrontOPM.opt;
		OfrontOPM.CloseFiles; OfrontOPT.Close;
		OfrontOPM.LogWLn;
		IF clCmd # NIL THEN (* must be after OfrontOPM.CloseFiles *)
			Oberon.ExecShell(clCmd^, status, out);
			IF verbose THEN Out.String(clCmd^); Out.Ln END ;
			IF (status # 0) OR verbose THEN Texts.Append(Oberon.Log, out) END
		END ;
		done := OfrontOPM.noerr & (status = 0);
		Oberon.Call("oberon.PinLog", Oberon.Par, FALSE, res); (* force scrolling *)
	END Module;

	PROCEDURE Compile*;
		VAR done: BOOLEAN;
	BEGIN
		OfrontOPM.OpenPar;
		OfrontOPT.bytetyp.size := OfrontOPM.ByteSize;
		OfrontOPT.sysptrtyp.size := OfrontOPM.PointerSize;
		OfrontOPT.chartyp.size := OfrontOPM.CharSize;
		OfrontOPT.settyp.size := OfrontOPM.SetSize;
		OfrontOPT.realtyp.size := OfrontOPM.RealSize;
		OfrontOPT.inttyp.size := OfrontOPM.IntSize;
		OfrontOPT.linttyp.size := OfrontOPM.LIntSize;
		OfrontOPT.lrltyp.size := OfrontOPM.LRealSize;
		OfrontOPT.sinttyp.size := OfrontOPM.SIntSize;
		OfrontOPT.booltyp.size := OfrontOPM.BoolSize;
		LOOP
			OfrontOPM.Init("compiling", done);
			IF ~done THEN EXIT END ;
			OfrontOPM.InitOptions;
			Module(done);
			Kernel.GC(TRUE);	(* someone might Oberon.Call("Compiler.Compile"...), so we have to mark the stack *)
			IF ~done THEN EXIT END
		END
	END Compile;

	PROCEDURE SetCL*;
		VAR S: Texts.Scanner; T: Texts.Text; beg, end, time: LONGINT;
	BEGIN
		Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
		IF (S.class = Texts.Char) & (S.c = "^") OR (S.line # 0) THEN
			Oberon.GetSelection(T, beg, end, time);
			IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
		END;
		IF S.class IN {Texts.Name, Texts.String} THEN
			COPY(S.s, cl)
		END
	END SetCL;
	
	PROCEDURE ShowCL*;
	BEGIN Out.String(cl); Out.Ln
	END ShowCL;

BEGIN
	cl := "cl.bash";
	OfrontOPB.typSize := OfrontOPV.TypSize; OfrontOPT.typSize := OfrontOPV.TypSize
END Compiler.