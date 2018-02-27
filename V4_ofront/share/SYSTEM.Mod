(*
*	The Ofront runtime system, Version 1.4
*
*	Copyright (c) Software Templ OG, 1994-2018
*
*	Module SYSTEM is subject to change any time without prior notification.
*	Software Templ disclaims all warranties with regard to module SYSTEM,
*	in particular shall Software Templ not be liable for any damage resulting
*	from inappropriate use or modification of module SYSTEM.
*)

MODULE SYSTEM;	(* J. Templ, 31.5.95 *)

	IMPORT SYSTEM;	(*must not import other modules*)

	CONST
		ModNameLen = 20;
		CmdNameLen = 24;
		SZL = SIZE(LONGINT); (* TODO assumes SIZE(PTR) = SIZE(LONGINT), which may not hold for 64 bit targets *)
		Unit = 4*SZL;	(* smallest possible heap block *)
		ldUnit = 4;	(* Unit = 2^ldUnit, for unsigned division expressed as logical shift right *)
		nofLists = 9;	(* number of freeList entries excluding sentinel *)
		heapSize0 = 8000*Unit;	(* startup heap size *)

	(* Allocated and free blocks look the same: they start with a type tag pointing to a type descriptor.
		A type descriptor starts with the block size followed by the pointer offset table (>=0) followed by a sentinel (< 0)
		that describes the size of the pointer offset table. Free blocks have a pseudo type descriptor inside.
		The size of free blocks must be <= Unit. Free blocks look like this:
		tag = &tag++
	-> blksize
		sentinel = -SZL
		next
	*)

	(* heap chunks *)
		nextChnkOff = 0;	(* next heap chunk, sorted ascendingly! *)
		endOff = SZL;	(* end of heap chunk *)
		blkOff = 3*SZL;	(* first block in a chunk, starts with tag *)

	(* free heap blocks *)
		tagOff = 0 * SZL;	(* any block starts with a tag *)
		sizeOff = 1 * SZL;	(* block size in free block relative to block start *)
		sntlOff = 2 * SZL;	(* pointer offset table sentinel in free block relative to block start *)
		nextOff = 3 * SZL;	(* next pointer in free block relative to block start *)
		NoPtrSntl = LONG(LONG(-SZL));


	TYPE
		ModuleName = ARRAY ModNameLen OF CHAR;
		CmdName = ARRAY CmdNameLen OF CHAR;

		Module = POINTER TO ModuleDesc;
		Cmd = POINTER TO CmdDesc;
		EnumProc = PROCEDURE(P: PROCEDURE(p: SYSTEM.PTR));
		ModuleDesc = RECORD
			next: Module;
			name: ModuleName;
			refcnt: LONGINT;
			cmds: Cmd;
			types: LONGINT;
			enumPtrs: EnumProc;
			reserved1, reserved2: LONGINT	(* 1=shared object handle; 2=import list *)
		END ;

		Command = PROCEDURE;

		CmdDesc = RECORD
			next: Cmd;
			name: CmdName;
			cmd: Command
		END ;

		Finalizer = PROCEDURE(obj: SYSTEM.PTR);

		FinNode = POINTER TO FinDesc;
		FinDesc = RECORD 
			next: FinNode;
			obj: LONGINT;	(* weak pointer *)
			marked: BOOLEAN;
			finalize: Finalizer;
		END ;

	VAR
		(* the list of loaded (=initialization started) modules *)
		modules*: SYSTEM.PTR;

		freeList: ARRAY nofLists + 1 OF LONGINT;	(* dummy, 16, 32, 48, 64, 80, 96, 112, 128, sentinel *)
		bigBlocks, allocated*: LONGINT;
		firstTry: BOOLEAN;

		(* extensible heap *)
		heap,	(* the sorted list of heap chunks *)
		heapMin, heapMax, (* filter for pointers; used for stack collection *)
		heapsize*,	(* the sum of all heap chunk sizes *)
		heapMinExpand: LONGINT;	(* minimum heap expansion size *)

		(* finalization candidates *)
		fin: FinNode;

		(* garbage collector locking *)
		gclock*: SHORTINT;

		(* for supporting two different kinds of module "Modules", one with and one without dependency on -ldl *)
		refLibHandle*: PROCEDURE(body: LONGINT): LONGINT;


	PROCEDURE -malloc(size: LONGINT): LONGINT	"(LONGINT)malloc(size)";
	PROCEDURE -free(ptr: LONGINT)	"free((void*)ptr)";
	PROCEDURE -uLT(x, y: LONGINT): BOOLEAN	"((unsigned long)x < (unsigned long)y)";
	PROCEDURE -uLE(x, y: LONGINT): BOOLEAN	"((unsigned long)x <= (unsigned long)y)";
	PROCEDURE -Lock()	"Lock";
	PROCEDURE -Unlock()	"Unlock";
	PROCEDURE -Mainfrm(): LONGINT	"SYSTEM_mainfrm";
	PROCEDURE -CallMarkStack()	"SYSTEM_callMarkStack()";

	PROCEDURE REGMOD*(VAR name: ModuleName; enumPtrs: EnumProc; body, imps: LONGINT): SYSTEM.PTR;
		VAR m: Module;
	BEGIN
		IF name = "SYSTEM" THEN (* cannot use NEW *)
			SYSTEM.NEW(m, SIZE(ModuleDesc)); m.cmds := NIL
		ELSE NEW(m)
		END ;
		COPY(name, m.name); m.refcnt := 0; m.enumPtrs := enumPtrs;
		IF refLibHandle # NIL THEN m.reserved1 := refLibHandle(body) ELSE m.reserved1 := 0 END;
		m.reserved2 := imps;
		m.next := SYSTEM.VAL(Module, modules); modules := m;
		RETURN m
	END REGMOD;

	PROCEDURE REGCMD*(m: Module; VAR name: CmdName; cmd: Command);
		VAR c: Cmd;
	BEGIN NEW(c);
		COPY(name, c.name); c.cmd := cmd; c.next := m.cmds; m.cmds := c
	END REGCMD;

	PROCEDURE REGTYP*(m: Module; typ: LONGINT);
	BEGIN SYSTEM.PUT(typ, m.types); m.types := typ
	END REGTYP;

	PROCEDURE INCREF*(m: Module; VAR imps: LONGINT);
		VAR imp: LONGINT;
	BEGIN INC(m.refcnt);
		imp := malloc(SIZE(LONGINT) * 2); SYSTEM.PUT(imp + SIZE(LONGINT), m); SYSTEM.PUT(imp, imps); imps := imp
	END INCREF;

	PROCEDURE NewChunk(blksz: LONGINT): LONGINT;
		VAR chnk, blk, end: LONGINT;
	BEGIN
		chnk := malloc(blksz + blkOff);
		IF chnk # 0 THEN
			blk := chnk + blkOff; end := blk + blksz; (* heap chunk consists of a single block *)
			SYSTEM.PUT(chnk + endOff, end);
			SYSTEM.PUT(blk + tagOff, blk + sizeOff);
			SYSTEM.PUT(blk + sizeOff, blksz);
			SYSTEM.PUT(blk + sntlOff, NoPtrSntl);
			SYSTEM.PUT(blk + nextOff, bigBlocks); bigBlocks := blk; (* prepend block to list of big blocks *)
			INC(heapsize, blksz);
			IF uLT(blk + SZL, heapMin) THEN heapMin := blk + SZL END ;
			IF uLT(heapMax, end) THEN heapMax := end END
		END ;
		RETURN chnk
	END NewChunk;

	PROCEDURE ExtendHeap(blksz: LONGINT);
		VAR size, chnk, j, next: LONGINT;
	BEGIN
		ASSERT(blksz MOD Unit = 0);
		IF uLT(heapMinExpand, blksz) THEN size := blksz
		ELSE size := heapMinExpand	(* heuristics for avoiding many small heap expansions *)
		END ;
		chnk := NewChunk(size);
		IF chnk # 0 THEN 
			(*sorted insertion*)
			IF uLT(chnk, heap) THEN
				SYSTEM.PUT(chnk, heap); heap := chnk
			ELSE
				j := heap; SYSTEM.GET(j, next);
				WHILE (next # 0) & uLT(next, chnk) DO j := next; SYSTEM.GET(j, next) END ;
				SYSTEM.PUT(chnk, next); SYSTEM.PUT(j, chnk)
			END
		ELSIF ~firstTry THEN
			(* heap memory exhausted, i.e. heap is not expanded and NEWREC() will return NIL.
			In order to be able to report a trap due to NIL access there is more 
			memory needed, which may be available by reducing heapMinExpand *) 
			heapMinExpand := Unit
		(* ELSE firstTry: ignore failed heap expansion for anti-thrashing heuristics *)
		END
	END ExtendHeap;

	PROCEDURE ^GC*(markStack: BOOLEAN);

	PROCEDURE NEWREC*(tag: LONGINT): SYSTEM.PTR;
		VAR i, i0, di, blksz, restsize, t, adr, end, next, prev: LONGINT; new: SYSTEM.PTR;
	BEGIN
		Lock();
		SYSTEM.GET(tag, blksz);
		ASSERT(blksz MOD Unit = 0);
		i0 := SYSTEM.LSH(blksz, -ldUnit) (*uDIV Unit*); i := i0;
		IF i < nofLists THEN adr := freeList[i];
			WHILE adr = 0 DO INC(i); adr := freeList[i] END
		END ;
		IF i < nofLists THEN (* unlink from freelist[i] *)
			SYSTEM.GET(adr + nextOff, next);
			freeList[i] := next;
			IF i # i0 THEN (* split *)
				di := i - i0; restsize := di * Unit; end := adr + restsize;
				SYSTEM.PUT(end + sizeOff, blksz);
				SYSTEM.PUT(end + sntlOff, NoPtrSntl);
				SYSTEM.PUT(end, end + sizeOff);
				SYSTEM.PUT(adr + sizeOff, restsize);
				SYSTEM.PUT(adr + nextOff, freeList[di]);
				freeList[di] := adr;
				INC(adr, restsize)
			END
		ELSE (* search in bigBlocks *)
			adr := bigBlocks; prev := 0;
			LOOP
				IF adr = 0 THEN (* nothing free *)
					IF firstTry THEN
						GC(TRUE); INC(blksz, Unit);
						(* anti-thrashing heuristics: ensure 1/5 of the heap will not be allocated *)
						t := SYSTEM.LSH(allocated + blksz, -(2+ldUnit)) (*uDIV (4*Unit)*) * (5*Unit); (* min. preferred heapsize *)
						IF uLT(heapsize, t) THEN ExtendHeap(t - heapsize)
							(* if there is not enough heap memory then the heap will be expanded below by blksz *)
						END ;
						firstTry := FALSE; new := NEWREC(tag);
						IF new = NIL THEN (* heap is 1/5 free but fragmentation prevented allocation *)
							ExtendHeap(blksz);
							new := NEWREC(tag)	(* will find a free block if heap has been expanded successfully *)
						END ;
						firstTry := TRUE;
						Unlock(); RETURN new
					ELSE
						Unlock(); RETURN NIL
					END
				END ;
				SYSTEM.GET(adr+sizeOff, t);
				IF uLE(blksz, t) THEN EXIT END ;
				prev := adr; SYSTEM.GET(adr + nextOff, adr)
			END ;
			restsize := t - blksz; end := adr + restsize;
			SYSTEM.PUT(end + sizeOff, blksz);
			SYSTEM.PUT(end + sntlOff, NoPtrSntl);
			SYSTEM.PUT(end, end + sizeOff);
			IF uLT(nofLists * Unit, restsize) THEN (*resize*)
				SYSTEM.PUT(adr + sizeOff, restsize)
			ELSE (*unlink*)
				SYSTEM.GET(adr + nextOff, next);
				IF prev = 0 THEN bigBlocks := next
				ELSE SYSTEM.PUT(prev + nextOff, next);
				END ;
				IF restsize # 0 THEN (*move*)
					di := restsize DIV Unit;
					SYSTEM.PUT(adr + sizeOff, restsize);
					SYSTEM.PUT(adr + nextOff, freeList[di]);
					freeList[di] := adr
				END
			END ;
			INC(adr, restsize)
		END ;
		i := adr + 4*SZL; end := adr + blksz;
		WHILE uLT(i, end) DO	(*deliberately unrolled*)
			SYSTEM.PUT(i, LONG(LONG(0)));
			SYSTEM.PUT(i + SZL, LONG(LONG(0)));
			SYSTEM.PUT(i + 2*SZL, LONG(LONG(0)));
			SYSTEM.PUT(i + 3*SZL, LONG(LONG(0)));
			INC(i, 4*SZL)
		END ;
		SYSTEM.PUT(adr + nextOff, LONG(LONG(0)));
		SYSTEM.PUT(adr, tag);
		SYSTEM.PUT(adr + sizeOff, LONG(LONG(0)));
		SYSTEM.PUT(adr + sntlOff, LONG(LONG(0)));
		INC(allocated, blksz);
		Unlock();
		RETURN SYSTEM.VAL(SYSTEM.PTR, adr + SZL)
	END NEWREC;

	PROCEDURE NEWBLK*(size: LONGINT): SYSTEM.PTR;
		 VAR blksz, tag: LONGINT; new: SYSTEM.PTR;
	BEGIN
		Lock();
		blksz := (size + (4*SZL + Unit - 1)) DIV Unit * Unit;	(*size + tag + meta + blksz + sntnl + UnitAlignment*)
		new := NEWREC(SYSTEM.ADR(blksz));
		tag := SYSTEM.VAL(LONGINT, new) + blksz - 3*SZL;
		SYSTEM.PUT(tag - SZL, LONG(LONG(0))); (*reserved for meta info*)
		SYSTEM.PUT(tag, blksz);
		SYSTEM.PUT(tag + SZL, NoPtrSntl);
		SYSTEM.PUT(SYSTEM.VAL(LONGINT, new) - SZL, tag);
		Unlock();
		RETURN new
	END NEWBLK;

	PROCEDURE Mark(q: LONGINT);
		VAR p, tag, fld, n, offset, tagbits: LONGINT;
	BEGIN
		IF q # 0 THEN SYSTEM.GET(q - SZL, tagbits);
			IF ~ODD(tagbits) THEN
				SYSTEM.PUT(q - SZL, tagbits + 1);
				p := 0; tag := tagbits + SZL;
				LOOP
					SYSTEM.GET(tag, offset);
					IF offset < 0 THEN
						SYSTEM.PUT(q - SZL, tag + offset + 1);
						IF p = 0 THEN EXIT END ;
						n := q; q := p;
						SYSTEM.GET(q - SZL, tag); DEC(tag, 1);
						SYSTEM.GET(tag, offset); fld := q + offset;
						SYSTEM.GET(fld, p); SYSTEM.PUT(fld, n)
					ELSE
						fld := q + offset;
						SYSTEM.GET(fld, n);
						IF n # 0 THEN
							SYSTEM.GET(n - SZL, tagbits);
							IF ~ODD(tagbits) THEN
								SYSTEM.PUT(n - SZL, tagbits + 1);
								SYSTEM.PUT(q - SZL, tag + 1);
								SYSTEM.PUT(fld, p); p := q; q := n;
								tag := tagbits
							END
						END
					END ;
					INC(tag, SZL)
				END
			END
		END
	END Mark;

	PROCEDURE MarkP(p: SYSTEM.PTR);	(* for compatibility with EnumPtrs in ANSI mode *)
	BEGIN
		Mark(SYSTEM.VAL(LONGINT, p))
	END MarkP;

	PROCEDURE Scan;
		VAR chnk, prevChnk, nextChnk, adr, end, start, tag, i, size, freesize: LONGINT;
	BEGIN bigBlocks := 0; i := 1;
		WHILE i < nofLists DO freeList[i] := 0; INC(i) END ;
		freesize := 0; allocated := 0; chnk := heap; prevChnk := 0;
		WHILE chnk # 0 DO
			adr := chnk + blkOff; SYSTEM.GET(chnk + endOff, end);
			WHILE uLT(adr, end) DO
				SYSTEM.GET(adr, tag);
				IF ODD(tag) THEN	(*marked*)
					IF freesize # 0 THEN
						start := adr - freesize;
						SYSTEM.PUT(start, start+SZL);
						SYSTEM.PUT(start+sizeOff, freesize);
						SYSTEM.PUT(start+sntlOff, NoPtrSntl);
						i := SYSTEM.LSH(freesize, -ldUnit) (*uDIV Unit*); freesize := 0;
						IF uLT(i, nofLists) THEN SYSTEM.PUT(start + nextOff, freeList[i]); freeList[i] := start
						ELSE SYSTEM.PUT(start + nextOff, bigBlocks); bigBlocks := start
						END
					END ;
					DEC(tag, 1);
					SYSTEM.PUT(adr, tag);
					SYSTEM.GET(tag, size);
					INC(allocated, size);
					INC(adr, size)
				ELSE	(*unmarked*)
					SYSTEM.GET(tag, size);
					INC(freesize, size);
					INC(adr, size)
				END
			END ;
			(* new variant with recycling of empty chunks *)
			SYSTEM.GET(chnk + nextChnkOff, nextChnk);
			IF freesize # 0 THEN (*collect last block(s)*)
				start := adr - freesize;
				IF (start = chnk + blkOff) & (prevChnk # nextChnk) THEN (* chnk is empty and not the only node *)
					DEC(heapsize, freesize);
					IF prevChnk = 0 THEN heap := nextChnk; heapMin := nextChnk + blkOff + SZL
					ELSIF nextChnk # 0 THEN SYSTEM.PUT(prevChnk + nextChnkOff, nextChnk)
					ELSE SYSTEM.PUT(prevChnk + nextChnkOff, nextChnk); heapMax := end
					END;
					free(chnk)
				ELSE
					SYSTEM.PUT(start, start+SZL);
					SYSTEM.PUT(start+sizeOff, freesize);
					SYSTEM.PUT(start+sntlOff, NoPtrSntl);
					i := SYSTEM.LSH(freesize, -ldUnit) (*uDIV Unit*);
					IF uLT(i, nofLists) THEN SYSTEM.PUT(start + nextOff, freeList[i]); freeList[i] := start
					ELSE SYSTEM.PUT(start + nextOff, bigBlocks); bigBlocks := start
					END;
					prevChnk :=  chnk
				END;
				freesize := 0
			ELSE prevChnk :=  chnk
			END;
			chnk :=  nextChnk
			(* old variant without recycling of empty chunks
			IF freesize # 0 THEN (*collect last block(s)*)
				start := adr - freesize;
				SYSTEM.PUT(start, start+SZL);
				SYSTEM.PUT(start+sizeOff, freesize);
				SYSTEM.PUT(start+sntlOff, NoPtrSntl);
				i := SYSTEM.LSH(freesize, -ldUnit) (*uDIV Unit*); freesize := 0;
				IF uLT(i, nofLists) THEN SYSTEM.PUT(start + nextOff, freeList[i]); freeList[i] := start
				ELSE SYSTEM.PUT(start + nextOff, bigBlocks); bigBlocks := start
				END
			END ;
			SYSTEM.GET(chnk, chnk)
			*)
		END
	END Scan;

	PROCEDURE Sift (l, r: LONGINT; VAR a: ARRAY OF LONGINT);
		VAR i, j, x: LONGINT;
	BEGIN j := l; x := a[j];
		LOOP i := j; j := 2*j + 1;
			IF (j < r) & uLT(a[j], a[j+1]) THEN INC(j) END;
			IF (j > r) OR uLE(a[j], x) THEN EXIT END;
			a[i] := a[j]
		END;
		a[i] := x
	END Sift;

	PROCEDURE HeapSort (n: LONGINT; VAR a: ARRAY OF LONGINT);
		VAR l, r, x: LONGINT;
	BEGIN l := n DIV 2; r := n - 1;
		WHILE l > 0 DO DEC(l); Sift(l, r, a) END;
		WHILE r > 0 DO x := a[0]; a[0] := a[r]; a[r] := x; DEC(r); Sift(l, r, a) END
	END HeapSort;

	PROCEDURE MarkCandidates(n: LONGINT; VAR cand: ARRAY OF LONGINT);
		VAR chnk, end, adr, tag, next, i, ptr, size: LONGINT;
	BEGIN
		ASSERT(n > 0);
		chnk := heap; i := 0;
		WHILE chnk # 0 DO
			SYSTEM.GET(chnk + endOff, end);
			adr := chnk + blkOff;
			WHILE uLT(adr, end) DO
				SYSTEM.GET(adr, tag);
				IF ODD(tag) THEN (*already marked*)
					SYSTEM.GET(tag-1, size); INC(adr, size); ptr := adr + SZL;
					WHILE uLT(cand[i], ptr) DO INC(i); IF i = n THEN RETURN END END ;
				ELSE
					SYSTEM.GET(tag, size); ptr := adr + SZL; INC(adr, size);
					WHILE uLT(cand[i], ptr) DO INC(i); IF i = n THEN RETURN END END ;
					IF uLT(cand[i], adr) THEN Mark(ptr) END
				END ;
				IF uLE(end, cand[i]) THEN (*skip rest of this heap chunk*) adr := end END
			END ;
			SYSTEM.GET(chnk + nextChnkOff, chnk)
		END
	END MarkCandidates;

	PROCEDURE CheckFin;
		VAR n: FinNode; tag: LONGINT;
	BEGIN n := fin;
		WHILE n # NIL DO
			SYSTEM.GET(n.obj - SZL, tag);
			IF ~ODD(tag) THEN n.marked := FALSE; Mark(n.obj)
			ELSE n.marked := TRUE
			END ;
			n := n.next
		END
	END CheckFin;

	PROCEDURE Finalize;
		VAR n, prev: FinNode;
	BEGIN n := fin; prev := NIL;
		WHILE n # NIL DO
			IF ~n.marked THEN
				IF n = fin THEN fin := fin.next ELSE prev.next := n.next END ;
				n.finalize(SYSTEM.VAL(SYSTEM.PTR, n.obj));
				(* new nodes may have been pushed in n.finalize, therefore: *)
				IF prev = NIL THEN n := fin ELSE n := n.next END
			ELSE prev := n; n := n.next
			END
		END
	END Finalize;

	PROCEDURE FINALL*;
		VAR n: FinNode;
	BEGIN
		WHILE fin # NIL DO
			n := fin; fin := fin.next;
			n.finalize(SYSTEM.VAL(SYSTEM.PTR, n.obj))
		END
	END FINALL;

	PROCEDURE MarkStack0*(sp: LONGINT); (* exported in order to prevent inlining by C optimizers *)
		VAR
			inc, nofcand: LONGINT;
			p, stack0, ptr: LONGINT;
			align: RECORD ch: CHAR; p: SYSTEM.PTR END ;
			cand: ARRAY 10000 OF LONGINT;
	BEGIN
		nofcand := 0; stack0 := Mainfrm();
		(* check for minimum alignment of pointers *)
		inc := SYSTEM.ADR(align.p) - SYSTEM.ADR(align);
		IF uLT(stack0, sp) THEN inc := -inc END ;
		WHILE sp # stack0 DO
			SYSTEM.GET(sp, p);
			IF uLE(heapMin, p) & uLT(p, heapMax) THEN
				IF nofcand = LEN(cand) THEN HeapSort(nofcand, cand); MarkCandidates(nofcand, cand); nofcand := 0 END ;
				cand[nofcand] := p; INC(nofcand)
			END ;
			INC(sp, inc)
		END ;
		IF nofcand > 0 THEN HeapSort(nofcand, cand); MarkCandidates(nofcand, cand) END
	END MarkStack0;

	PROCEDURE MarkStack*(); (* exported in order to prevent inlining by C optimizers *)
		VAR x: LONGINT;
	BEGIN
		MarkStack0(SYSTEM.ADR(x))
	END MarkStack;

	PROCEDURE GC*(markStack: BOOLEAN);
		VAR m: Module;
	BEGIN
		IF (gclock = 0) OR (gclock = 1) & ~markStack THEN
			Lock();
			m := SYSTEM.VAL(Module, modules);
			WHILE m # NIL DO 
				IF m.enumPtrs # NIL THEN m.enumPtrs(MarkP) END ;
				m := m^.next
			END ;
			IF markStack THEN
				(* indirect call for allowing to flush the registers onto the stack *)
				CallMarkStack()
			END;
			CheckFin;
			Scan;
			Finalize;
			Unlock()
		END
	END GC;

	PROCEDURE REGFIN*(obj: SYSTEM.PTR; finalize: Finalizer);
		VAR f: FinNode;
	BEGIN NEW(f);
		f.obj := SYSTEM.VAL(LONGINT, obj); f.finalize := finalize; f.marked := TRUE; f.next := fin; fin := f
	END REGFIN;

	PROCEDURE InitHeap;	(* initialized before body to enable NEW, SYSTEM.NEW *)
	BEGIN
		heap := 0; heapsize := 0; allocated := 0; gclock := 0;
		heapMin := 0FFFFFFFFH; heapMax := 0;
		heap := NewChunk(heapSize0);
		SYSTEM.PUT(heap + nextChnkOff, LONG(LONG(0)));
		firstTry := TRUE; freeList[nofLists] := 1 (* sentinel, # 0 *)
	END InitHeap;

BEGIN heapMinExpand := heapSize0
END SYSTEM.
