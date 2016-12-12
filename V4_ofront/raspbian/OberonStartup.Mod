(* sample startup module for showing how to automate settings upon startup of oberon.

Note: this is a template only, it is not part of the binaries.
You can adapt this module to your needs, store it, and
from within a running oberon system use the following command for
creating the binaries in the form of a shared object file.

Compiler.Compile OberonStartup.Mod
*)

MODULE OberonStartup;

IMPORT FKeys, Modules, Unix, RPI, Out;

PROCEDURE OpenRPI;
BEGIN
	IF Unix.Getuid() = 0 THEN (* running as root *)
		IF RPI.Open(RPI.base3) THEN
			Out.String("RPI.Open succeeded"); Out.Ln;
			IF Unix.Setuid(1000) = 0 THEN Out.String("user id set to 1000 (pi)");
			ELSE Out.String("user id could not be set to 1000 (pi)")
			END
		ELSE Out.String("RPI.Open failed")
		END
	ELSE
		Out.String("RPI.Open needs root privileges; start with 'sudo ... oberon'")
	END ;
	Out.Ln
END OpenRPI;

PROCEDURE Init;
	VAR M: Modules.Module;
BEGIN
	OpenRPI;
	M := Modules.ThisMod("Miscellaneous");
	IF M # NIL THEN
		FKeys.Set(5, Modules.ThisCommand(M, "Cut"));
		FKeys.Set(6, Modules.ThisCommand(M, "Copy"));
		FKeys.Set(7, Modules.ThisCommand(M, "Paste"));
		Out.String("function keys F5..F7 set"); Out.Ln;
	END
END Init;

BEGIN Init;
END OberonStartup.