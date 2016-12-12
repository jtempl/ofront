MODULE Modules;	(* jt 27.2.95, 3.10.2016 *)

	(* shared libraries are named lib_V4_<Modulename>.so by default. (see also CompilerCmd.Mod).
	For prefixes other than "_V4_" define environment variable OBERON_LIBPREFIX *)

	IMPORT SYSTEM, Console, Unix(*for errno*), Kernel, Args;

	CONST
		ModNameLen* = 20;

	TYPE
		ModuleName* = ARRAY ModNameLen OF CHAR;
		Module* = POINTER TO ModuleDesc;
		Cmd* = POINTER TO CmdDesc;
		ModuleDesc* = RECORD	(* cf. SYSTEM.Mod *)
			next-: Module;
			name-: ModuleName;
			refcnt-: LONGINT;
			cmds-: Cmd;
			types-: LONGINT;
			enumPtrs-: PROCEDURE (P: PROCEDURE(p: LONGINT));
			reserved1, reserved2: LONGINT; (* 1=shared object handle; 2=import list *)
		END ;

		Command* = PROCEDURE;

		CmdDesc* = RECORD
			next-: Cmd;
			name-: ARRAY 24 OF CHAR;
			cmd-: Command
		END ;

		Dlinfo = RECORD [1] (* cf. <dlfcn.h> *)
			fname, fbase, sname, saddr: LONGINT
		END;

		ModuleBody = PROCEDURE (): Module;

	VAR
		res*: INTEGER;
		resMsg*: ARRAY 256 OF CHAR;
		imported*, importing*: ModuleName;
		libPrefix*: ARRAY 20 OF CHAR;
		trace: BOOLEAN; (* log module loading activities on Console *)

	PROCEDURE -UseGNU()
		"#define __USE_GNU 1";

	PROCEDURE -include()
		"#include <dlfcn.h>";	(* extensions enabled by __USE_GNU *)

	PROCEDURE -dlopen(path: ARRAY OF CHAR): LONGINT
		"(long)dlopen((const char*)path, RTLD_NOW + RTLD_GLOBAL)";

	PROCEDURE -dlsym(handle: LONGINT; name: ARRAY OF CHAR): ModuleBody
		"(Modules_ModuleBody)dlsym((void*)handle, name)";

	PROCEDURE -dlsymDefault(name: ARRAY OF CHAR): ModuleBody
		"(Modules_ModuleBody)dlsym(RTLD_DEFAULT, name)";

	PROCEDURE -dlclose(handle: LONGINT): LONGINT
		"dlclose((void*)handle)";

	PROCEDURE -dlerror(VAR s: ARRAY OF CHAR)
		"__COPY(dlerror(), s, s__len)";

	PROCEDURE -dlopenRef(pathAdr: LONGINT): LONGINT
		"(long)dlopen((const char*)pathAdr, RTLD_NOW + RTLD_GLOBAL)";

	PROCEDURE -dladdr(addr: LONGINT; VAR info: Dlinfo): LONGINT
		"(LONGINT)dladdr((void*)addr, (Dl_info*)info)";

	PROCEDURE -externRefLibHandle()
			"extern LONGINT (*SYSTEM_refLibHandle)(LONGINT);";

	PROCEDURE -installRefLibHandle()
			"SYSTEM_refLibHandle = &Modules_RefLibHandle";

	PROCEDURE -modules*(): Module
			"(Modules_Module)SYSTEM_modules";

	PROCEDURE -setmodules*(m: Module)
			"SYSTEM_modules = m";

	PROCEDURE -externfree()
			"extern void free(void*);";

	PROCEDURE -free(ptr: LONGINT)
			"free((void*)ptr)";

	PROCEDURE Append(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
		VAR i, j: INTEGER;
	BEGIN
		i := 0; WHILE a[i] # 0X DO INC(i) END;
		j := 0; WHILE b[j] # 0X DO a[i] := b[j]; INC(i); INC(j) END;
		a[i] := 0X
	END Append;

	(* digit treated as upper case *)
	PROCEDURE GetSubsys1(n: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
		VAR i: INTEGER; ch: CHAR;
	BEGIN
		ch := n[0]; i := 0;
		WHILE (ch # 0X) & ((ch < "a") OR (ch > "z")) DO s[i] := ch; INC(i); ch := n[i] END ;
		WHILE (ch >= "a") & (ch <= "z") DO s[i] := ch; INC(i); ch := n[i] END ;
		IF ch = 0X THEN s[0] := 0X ELSE s[i] := 0X END
	END GetSubsys1;

	(* digit treated as lower case *)
	PROCEDURE GetSubsys2(n: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
		VAR i: INTEGER; ch: CHAR;
	BEGIN
		ch := n[0]; i := 0;
		WHILE (ch >= "A") & (ch <= "Z") DO s[i] := ch; INC(i); ch := n[i] END ;
		WHILE (ch # 0X) & ((ch < "A") OR (ch > "Z")) DO s[i] := ch; INC(i); ch := n[i] END ;
		IF ch = 0X THEN s[0] := 0X ELSE s[i] := 0X END
	END GetSubsys2;

	PROCEDURE FullName(VAR n: ARRAY OF CHAR): BOOLEAN;
		VAR i: INTEGER; ch: CHAR;
	BEGIN
		i := 0; ch := n[0];
		WHILE ch # 0X DO
			IF ch = "." THEN RETURN TRUE END ;
			INC(i); ch := n[i]
		END ;
		RETURN FALSE
	END FullName;

	PROCEDURE err();
		VAR s: ARRAY 1024 OF CHAR;
	BEGIN dlerror(s);
		IF trace THEN
			Console.String("  dlerror: "); Console.String(s); Console.Ln;
		END
	END err;

	PROCEDURE Load(name, bodyname: ARRAY OF CHAR; VAR lib: LONGINT; VAR body: ModuleBody);
		VAR libname: ARRAY 256 OF CHAR; rc: LONGINT;
	BEGIN
		libname := "lib"; Append(libname, libPrefix); 
		Append(libname, name); Append(libname, ".so");
		IF trace THEN
			Console.String("  Modules.Load(libname="); Console.String(libname);
			Console.String(", entry="); Console.String(bodyname);
			Console.String(")"); Console.Ln
		END ;
		lib := dlopen(libname);
		IF lib # 0 THEN body := dlsym(lib, bodyname);
			IF body = NIL THEN err(); rc := dlclose(lib) END
		ELSE err()
		END ;
	END Load;

	PROCEDURE CloseLib(libHandle: LONGINT);
	BEGIN libHandle := dlclose(libHandle)
	END CloseLib;

	PROCEDURE ThisMod* (name: ARRAY OF CHAR): Module;
		VAR m: Module; bodyname, libname1, libname2: ARRAY 128 OF CHAR;
			body: ModuleBody; lib, rc: LONGINT;
	BEGIN
		m := modules();
		WHILE (m # NIL) & (m.name # name) DO m := m.next END ;
		IF m = NIL THEN
			IF trace THEN Console.String("Modules.ThisMod(name=");
				Console.String(name); Console.String(")"); Console.Ln
			END ;
			body := NIL;
			COPY(name, bodyname); Append(bodyname, "__init");
			body := dlsymDefault(bodyname);
			IF body # NIL THEN
				m := body(); (* no dlclose(lib) because no dlopen *)
			ELSE
				(* module looked up in lib<libPrefix><name>.so *)
				Load(name, bodyname, lib, body);
				IF body # NIL THEN
					Kernel.PushTrapCleaner(CloseLib, lib);
					m := body();	(* increments reference count of lib *)
					Kernel.PopTrapCleaner;
					CloseLib(lib)
				END
			END
		END ;
		IF m # NIL THEN res := 0; resMsg := ""
		ELSE res := 1; COPY(name, importing);
			resMsg := ' module "'; Append(resMsg, name); Append(resMsg, '" not found or library not loadable');
		END ;
		RETURN m
	END ThisMod;

	PROCEDURE ThisCommand* (mod: Module; name: ARRAY OF CHAR): Command;
		VAR c: Cmd;
	BEGIN c := mod.cmds;
		WHILE (c # NIL) & (c.name # name) DO c := c.next END ;
		IF c # NIL THEN res := 0; resMsg := ""; RETURN c.cmd
		ELSE res := 2; resMsg := ' command "'; COPY(name, importing);
			Append(resMsg, mod.name); Append(resMsg, "."); Append(resMsg, name); Append(resMsg, '" not found');
			RETURN NIL
		END
	END ThisCommand;

	PROCEDURE IsSingletonLib(libHandle: LONGINT): BOOLEAN;
		VAR m: Module; cnt: INTEGER;
	BEGIN m := modules(); cnt := 0;
		WHILE (m # NIL) & (cnt < 2) DO
			IF m.reserved1 = libHandle THEN INC(cnt) END;
			m := m.next
		END ;
		RETURN cnt < 2
	END IsSingletonLib;

	PROCEDURE Free*(name: ARRAY OF CHAR; all: BOOLEAN);
		VAR m, p, im: Module; imps, ptr: LONGINT;
	BEGIN m := modules();
		WHILE (m # NIL) & (m.name # name) DO p := m; m := m.next END ;
		IF (m # NIL) & (m.refcnt = 0) THEN
			IF (m.reserved1 # 0) & IsSingletonLib(m.reserved1) THEN
				IF dlclose(m.reserved1) # 0 THEN
					res := 1; dlerror(resMsg);
				ELSE
					IF m = modules() THEN setmodules(m.next) ELSE p.next := m.next END;
					imps := m.reserved2;
					WHILE imps # 0 DO
						SYSTEM.GET(imps + SIZE(LONGINT), im); (* im := imps.mod *)
						DEC(im.refcnt);
						IF all & (im.refcnt = 0) & (im.reserved1 # 0) THEN Free(im.name, all) END;
						ptr := imps; SYSTEM.GET(imps, imps); (* imps := imps.next *)
						free(ptr)
					END;
					res := 0; m.reserved1 := 0; m.reserved2 := 0
				END
			ELSE res := 1;
				resMsg := "module not loaded in separate library"
			END
		ELSE res := 1;
			IF m = NIL THEN resMsg := "module not found"
			ELSE resMsg := "clients of this module exist"
			END
		END
	END Free;

	PROCEDURE RefLibHandle(body: LONGINT): LONGINT;
		VAR info: Dlinfo; res, libHandle: LONGINT;
	BEGIN
		res := dladdr(body, info);
		IF (res # 0) & (info.sname # 0) THEN
			libHandle := dlopenRef(info.fname); (* inc ref. count of shared object *)
			IF libHandle # 0 THEN RETURN libHandle END
		END;
		RETURN 0;
	END RefLibHandle;

	PROCEDURE TraceOn*;
	BEGIN trace := TRUE; Console.String("Modules.TraceOn"); Console.Ln
	END TraceOn;

	PROCEDURE TraceOff*;
	BEGIN trace := FALSE; Console.String("Modules.TraceOff"); Console.Ln
	END TraceOff;

BEGIN
	libPrefix := "_V4_"; Args.GetEnv("OBERON_LIBPREFIX", libPrefix);
	installRefLibHandle()
END Modules.
