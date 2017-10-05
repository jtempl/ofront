MODULE TestPi;

IMPORT WiringPi, Out;

PROCEDURE ShowModel*;
	VAR i: INTEGER; model, rev, mem, maker, overVolted: LONGINT;
BEGIN
	FOR i := 0 TO 15 DO
		Out.Int(i, 2);
		Out.String(": model="); Out.String(WiringPi.piModelNames[i]^); 
		Out.String(", revision="); Out.String(WiringPi.piRevisionNames[i]^); 
		Out.String(", maker="); Out.String(WiringPi.piMakerNames[i]^); 
		Out.Ln
	END;
	Out.String("PiBoardRev="); Out.Int(WiringPi.PiBoardRev(), 1); Out.Ln;
	WiringPi.PiBoardId(model, rev, mem, maker, overVolted);
	Out.String("PiBoardId: model="); Out.Int(model, 1); 
	Out.String(", rev="); Out.Int(rev, 1); 
	Out.String(", mem="); Out.Int(mem, 1); 
	Out.String(", maker="); Out.Int(maker, 1); 
	Out.String(", overVolted="); Out.Int(overVolted, 1); 
	Out.Ln
END ShowModel;

BEGIN
	WiringPi.SetupSys
END TestPi.