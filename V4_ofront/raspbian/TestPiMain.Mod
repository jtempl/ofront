MODULE TestPiMain;

IMPORT WiringPi, Console;

VAR
	i: INTEGER;
	model, rev, mem, maker, overVolted: LONGINT;

BEGIN
	WiringPi.SetupSys;
	FOR i := 0 TO 15 DO
		Console.Int(i, 2);
		Console.String(": model="); Console.String(WiringPi.piModelNames[i]^); 
		Console.String(", revision="); Console.String(WiringPi.piRevisionNames[i]^); 
		Console.String(", maker="); Console.String(WiringPi.piMakerNames[i]^); 
		Console.Ln
	END;
	Console.String("PiBoardRev="); Console.Int(WiringPi.PiBoardRev(), 1); Console.Ln;
	WiringPi.PiBoardId(model, rev, mem, maker, overVolted);
	Console.String("PiBoardId: model="); Console.Int(model, 1); 
	Console.String(", rev="); Console.Int(rev, 1); 
	Console.String(", mem="); Console.Int(mem, 1); 
	Console.String(", maker="); Console.Int(maker, 1); 
	Console.String(", overVolted="); Console.Int(overVolted, 1); 
	Console.Ln
END TestPiMain.