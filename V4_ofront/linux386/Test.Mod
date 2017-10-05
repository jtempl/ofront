MODULE Test;
IMPORT Edit, Out;

VAR x: INTEGER;

PROCEDURE Do*;
BEGIN 
	Out.String("Test.Do "); Out.Int(x, 2); INC(x); Out.Ln
END Do;

BEGIN
	Out.String("loading Test"); Out.Ln; HALT(99) (* for testing TRAP in module body *)
END Test.