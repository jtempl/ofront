MODULE RPI;

(* J. Templ, 2016-11-23
	Direct hardware access to peripherals memory on Raspberry Pi.
	See datasheet for Broadcom BCM2835 ARM Peripherals.
	See also RPI.c0 .

	User must be able to open virtual file /dev/mem in read+write mode.
	This is only possible if oberon ist started with sudo, e.g:
	sudo OBERON=... LD_LIBRARY_PATH=... OFRONT_HOME=... PATH=... oberon -f Big.Map

	Warning: Even reading from the wrong address can crash your Raspberry Pi, let alone writing.
*)

IMPORT SYSTEM;

CONST
	(* peripherals memory physical RAM address *)
	base0* = 20000000H; (* for Raspberry Zero *)
	base1* = 20000000H; (* for Raspberry 1 *)
	base2* = 3F000000H; (* for Raspberry 2 *)
	base3* = 3F000000H; (* for Raspberry 3 *)

PROCEDURE- includeRPIc0()	'#include "RPI.c0"';
PROCEDURE- map(base: LONGINT): LONGINT	"mapPeripherals(base)";
PROCEDURE- read(adr: LONGINT): LONGINT	"*(long*)((long)periMem + adr)";
PROCEDURE- write(adr, val: LONGINT)	"*(long*)((long)periMem + adr) = val";
PROCEDURE- unmap()	"unmapPeripherals()";

PROCEDURE Open*(base: LONGINT): BOOLEAN;
BEGIN
	RETURN map(base) = 0
END Open;

PROCEDURE Read*(adr: LONGINT): LONGINT;
BEGIN
	RETURN read(adr MOD 1000000H)
END Read;

PROCEDURE Write*(adr, val: LONGINT);
BEGIN
	write(adr MOD 1000000H, val)
END Write;

PROCEDURE Close*;
BEGIN
	unmap()
END Close;

END RPI.
