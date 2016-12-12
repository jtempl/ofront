MODULE CompilerCmd;

	(* like Compiler but as a stand-alone main program *)

	IMPORT
		SYSTEM, Unix, Kernel, Args,
		OfrontOPP, OfrontOPB, OfrontOPT, OfrontOPV, OfrontOPC, OfrontOPM;

	VAR
		cl: ARRAY 64 OF CHAR; (* command to call C-compiler and linker for a module *)
		libPrefix: ARRAY 20 OF CHAR;

	PROCEDURE -fin()
		"SYSTEM_FINALL()";

	PROCEDURE -halt(): LONGINT
		"SYSTEM_halt";

	PROCEDURE -system(cmd: ARRAY OF CHAR): LONGINT
		"(LONGINT)system(cmd)";
		
	PROCEDURE Trap(sig, siginfo, sigctx: LONGINT);
	BEGIN fin();
		IF sig = 3 THEN Unix.Exit(1)
		ELSE
			IF (sig = 4) & (halt() = -15) THEN
				OfrontOPM.LogWStr(" --- ofront: internal error");  OfrontOPM.LogWLn
			END ;
			Unix.Exit(2)
		END
	END Trap;
	
	PROCEDURE Append(VAR s: ARRAY OF CHAR; VAR len: INTEGER; x: ARRAY [1] OF CHAR);
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
				Append(clCmd, len, libPrefix);
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
		IF ~main THEN Append(clCmd, len, libPrefix) END ;
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
			Append(clCmd, len, libPrefix); Append(clCmd, len, "SYSTEM") 
		END ;
		LinkImports(OfrontOPT.topScope^.right, clCmd, len);
		Append(clCmd, len, " ");
		Append(clCmd, len, OfrontOPM.clOpts);
		Append(clCmd, len, '"')
	END GetClCmd;

	PROCEDURE Module*(VAR done: BOOLEAN);
		VAR ext, new, verbose: BOOLEAN; p: OfrontOPT.Node;
			clCmd: POINTER TO ARRAY 4000 OF CHAR; status: LONGINT; res: INTEGER;
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
			IF verbose THEN OfrontOPM.LogWStr(clCmd^); OfrontOPM.LogWLn END;
			status := system(clCmd^)
		END ;
		done := OfrontOPM.noerr & (status = 0);
	END Module;

	PROCEDURE Compile*; (* Note: export mark keeps C optimizers from inlining into main,
					which may invalidate SYSTEM_mainfrm and thereby stack collection *)
		VAR done: BOOLEAN;
	BEGIN
		OfrontOPM.OpenPar("Ofront (TM) - Oberon-2 Compiler V1.4", "ocl");
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
			IF ~done THEN
				IF ~OfrontOPM.noerr THEN (* source file not found *) fin(); Unix.Exit(1) END;
				EXIT (* end of argument vector *)
			END ;
			OfrontOPM.InitOptions;
			Module(done);
			Kernel.GC(TRUE);	(* someone might Oberon.Call("Compiler.Compile"...), so we have to mark the stack *)
			IF ~done THEN fin(); Unix.Exit(1) END
		END
	END Compile;
	
BEGIN
	libPrefix := "_V4_"; Args.GetEnv("OBERON_LIBPREFIX", libPrefix); (* see also ./Modules.Mod *)
	cl := "cl.bash";
	OfrontOPB.typSize := OfrontOPV.TypSize; OfrontOPT.typSize := OfrontOPV.TypSize;
	Unix.SigSetHandler(2, Trap);	(* interrupt *)
	Unix.SigSetHandler(3, Trap);	(* quit *)
	Unix.SigSetHandler(4, Trap);	(* illegal instruction, HALT *)
	Compile
END CompilerCmd.