MODULE Reals;
	(* JT, 5.2.89/7.3.95 conversion between reals and strings for sparc *)

	IMPORT SYSTEM, Kernel;

	VAR inc: LONGINT;

	(* not reentrant but portable; *)
	PROCEDURE -ecvt (x: LONGREAL; ndigit: LONGINT; VAR decpt, sign: LONGINT): LONGINT
			"ecvt (x, ndigit, decpt, sign)";

	PROCEDURE Ten* (e: INTEGER): REAL;
		VAR r, power: LONGREAL;
	BEGIN r := 1;
		power := 10;
		WHILE e > 0 DO
			IF ODD(e) THEN r := r * power END ;
			power := power * power; e := e DIV 2
		END ;
		RETURN SHORT(r)
	END Ten;

	PROCEDURE TenL* (e: INTEGER): LONGREAL;
		VAR r, power: LONGREAL;
	BEGIN r := 1;
		power := 10;
		LOOP
			IF ODD(e) THEN r := r * power END ;
			e := e DIV 2;
			IF e <= 0 THEN RETURN r END ;
			power := power * power
		END
	END TenL;

	PROCEDURE Expo* (x: REAL): INTEGER;
	BEGIN RETURN SHORT(ASH(SYSTEM.VAL(LONGINT, x), -23) MOD 256)
	END Expo;

	PROCEDURE ExpoL* (x: LONGREAL): INTEGER;
		VAR h: LONGINT;
	BEGIN 
		SYSTEM.GET(SYSTEM.ADR(x)+inc, h);
		RETURN SHORT(ASH(h, -20) MOD 2048)
	END ExpoL;

	PROCEDURE SetExpo*(e: INTEGER; VAR x: REAL);
	BEGIN
		SYSTEM.PUT(SYSTEM.ADR(x), SYSTEM.VAL(SET, x) - {23..30} + SYSTEM.VAL(SET, ASH(LONG(e), 23)))
	END SetExpo;

	PROCEDURE SetExpoL*(e: INTEGER; VAR x: LONGREAL);
		VAR h: SET;
	BEGIN
		SYSTEM.GET(SYSTEM.ADR(x)+inc, h);
		h := h - {20..30} + SYSTEM.VAL(SET, ASH(LONG(e), 20));
		SYSTEM.PUT(SYSTEM.ADR(x)+inc, h)
	END SetExpoL;

	PROCEDURE Convert* (x: REAL; n: INTEGER; VAR d: ARRAY OF CHAR);
		VAR i, k: LONGINT;
	BEGIN
		i := ENTIER(x); k := 0;
		WHILE k < n DO
			d[k] := CHR(i MOD 10 + 48); i := i DIV 10; INC(k)
		END
	END Convert;

	PROCEDURE ConvertL* (x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
		VAR decpt, sign, i: LONGINT; buf: (* ARRAY 32 OF CHAR; *) LONGINT;
	BEGIN
		(*x := x - 0.5; already rounded in ecvt*)
		buf := ecvt(x, n + 2, decpt, sign);
		i := 0;
		WHILE i < decpt DO SYSTEM.GET(buf + i, d[n - i -1]); INC(i) END ;
		i := n - i - 1;
		WHILE i >= 0 DO d[i] := "0"; DEC(i) END ;
	END ConvertL;

	PROCEDURE Unpack(VAR b, d: ARRAY OF SYSTEM.BYTE);
		VAR i, k: SHORTINT;
	BEGIN i := 0;
		WHILE i < LEN(b) DO
			k := SHORT(ORD(SYSTEM.VAL(CHAR, b[i])) DIV 16);
			IF k > 9 THEN d[i*2] := k + 55 ELSE d[i*2] := k + 48 END ;
			k := SHORT(ORD(SYSTEM.VAL(CHAR, b[i])) MOD 16);
			IF k > 9 THEN d[i*2+1] := k + 55 ELSE d[i*2+1] := k + 48 END ;
			INC(i)
		END
	END Unpack;

	PROCEDURE ConvertH* (y: REAL; VAR d: ARRAY OF CHAR);
	BEGIN Unpack(y, d)
	END ConvertH;

	PROCEDURE ConvertHL* (x: LONGREAL; VAR d: ARRAY OF CHAR);
	BEGIN Unpack(x, d)
	END ConvertHL;

BEGIN
	IF Kernel.littleEndian THEN inc := 4 ELSE inc := 0 END
END Reals.
