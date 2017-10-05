MODULE Test2;
IMPORT Test, Edit, Out;

VAR x: INTEGER;

PROCEDURE Do*;
BEGIN 
	Out.String("Test2.Do "); Out.Int(x, 2); INC(x); Out.Ln
END Do;

BEGIN
	Out.String("loading Test2"); Out.Ln
END Test2.