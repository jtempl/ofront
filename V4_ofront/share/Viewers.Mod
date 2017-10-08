MODULE Viewers; (* Copyright (c)  ETH Z…rich, 1989-95 / jg 14.9.90*)

    IMPORT Display, X11;

    CONST
  	restore* = 0; modify* = 1; suspend* = 2; (*message ids*)
      inf = MAX(INTEGER);

    TYPE
	   Viewer* = POINTER TO ViewerDesc;

	   ViewerDesc* = RECORD
		   (Display.FrameDesc)
	       state*: INTEGER
  	 END;

  	 (*state > 1: displayed
	  	  state = 1: filler
	  	  state = 0: closed
	  	  state < 0: suspended*)

	   ViewerMsg* = RECORD
	      (Display.FrameMsg)
	  	 id*: INTEGER;
	  	 X*, Y*, W*, H*: INTEGER;
	  	 state*: INTEGER
  	 END;

  	 Track = POINTER TO TrackDesc;

	   TrackDesc = RECORD
	  	 (ViewerDesc)
	  	 under: Display.Frame
  	 END;

    VAR
      curW*, minH*, DW, DH: INTEGER;
      FillerTrack: Track; FillerViewer, buf: Viewer; (*for closed viewers*)

    PROCEDURE Open* (V: Viewer; X, Y: INTEGER);
	    VAR T, u, v: Display.Frame; M: ViewerMsg;
    BEGIN
	    IF (V.state = 0) & (X < inf) THEN
          IF Y > DH THEN Y := DH END;
		  T := FillerTrack.next;
		  WHILE X >= T.X + T.W DO T := T.next END;
		  u := T.dsc; v := u.next;
		  WHILE Y > v.Y + v.H DO u := v; v := u.next END;
          IF Y < v.Y + minH THEN Y := v.Y + minH END;
		  IF (v.next.Y # 0) & (Y > v.Y + v.H - minH) THEN
            WITH v: Viewer DO
		      V.X := T.X; V.W := T.W; V.Y := v.Y; V.H := v.H;
		  	M.id := suspend; M.state := 0;
              v.handle(v, M); v.state := 0; buf := v;
		      V.next := v.next; u.next := V;
		      V.state := 2
            END
		  ELSE
		    V.X := T.X; V.W := T.W; V.Y := v.Y; V.H := Y - v.Y;
		    M.id := modify; M.Y := Y; M.H := v.Y + v.H - Y;
            v.handle(v, M); v.Y := M.Y; v.H := M.H;
			V.next := v; u.next := V;
		    V.state := 2
		  END
	    END
    END Open;
	
    PROCEDURE Change* (V: Viewer; Y: INTEGER);
	    VAR v: Display.Frame; M: ViewerMsg;
    BEGIN
	    IF V.state > 1 THEN
		   IF Y > DH THEN Y := DH END;
		   v := V.next;
		   IF (v.next.Y # 0) & (Y > v.Y + v.H - minH) THEN
		  	Y := v.Y + v.H - minH
		  END;
		  IF Y >= V.Y + minH THEN
			  M.id := modify; M.Y := Y; M.H := v.Y + v.H - Y;
              v.handle(v, M); v.Y := M.Y; v.H := M.H;
			  V.H := Y - V.Y
		  END
	   END
    END Change;

    PROCEDURE RestoreTrack (S: Display.Frame);
	    VAR T, t, v: Display.Frame; M: ViewerMsg;
	BEGIN
		WITH S: Track DO
		   t := S.next;
		    WHILE t.next.X # S.X DO t := t.next END;
		    T := S.under;
		    WHILE T.next # NIL DO T := T.next END;
		    t.next := S.under; T.next := S.next;
		    M.id := restore;
		    REPEAT t := t.next;
			    v := t.dsc;
			    REPEAT v := v.next; v.handle(v, M);
				    WITH v: Viewer DO v.state := - v.state END
			    UNTIL v = t.dsc
		    UNTIL t = T
		 END
     END RestoreTrack;

    PROCEDURE Close* (V: Viewer);
	    VAR T, U: Display.Frame; M: ViewerMsg;
    BEGIN
        IF V.state > 1 THEN
            U := V.next; T := FillerTrack;
		    REPEAT T := T.next UNTIL V.X < T.X + T.W;
            IF (T(Track).under = NIL) OR (U.next # V) THEN
		        M.id := suspend; M.state := 0;
                V.handle(V, M); V.state := 0; buf := V;
                M.id := modify; M.Y := V.Y; M.H := V.H + U.H;
		        U.handle(U, M); U.Y := M.Y; U.H := M.H;
		  	  WHILE U.next # V DO U := U.next END;
    	        U.next := V.next
            ELSE (*close track*)
    	        M.id := suspend; M.state := 0;
                V.handle(V, M); V.state := 0; buf := V;
		        U.handle(U, M); U(Viewer).state := 0;
		    	RestoreTrack(T)
            END
        END
     END Close;

    PROCEDURE Recall* ( VAR V: Viewer);
    BEGIN V := buf
    END Recall;

    PROCEDURE This* (X, Y: INTEGER): Viewer;
	    VAR T, V: Display.Frame;
    BEGIN
	    IF (X < inf) & (Y < DH) THEN
	  	  T := FillerTrack;
		    REPEAT T := T.next UNTIL X < T.X + T.W;
		    V := T.dsc;
		    REPEAT V := V.next UNTIL Y < V.Y + V.H;
		    RETURN V(Viewer)
	    ELSE RETURN NIL
	    END
    END This;

    PROCEDURE Next* (V: Viewer): Viewer;
    BEGIN RETURN V.next(Viewer)
    END Next;

    PROCEDURE Locate* (X, H: INTEGER; VAR fil, bot, alt, max: Display.Frame);
	    VAR T, V: Display.Frame;
    BEGIN
	    IF X < inf THEN
		    T := FillerTrack;
		    REPEAT T := T.next UNTIL X < T.X + T.W;
		    fil := T.dsc; bot := fil.next;
		    IF bot.next # fil THEN
			    alt := bot.next; V := alt.next;
			    WHILE (V # fil) & (alt.H < H) DO
				    IF V.H > alt.H THEN alt := V END; V := V.next
			    END
		    ELSE alt := bot
		    END;
		    max := T.dsc; V := max.next;
			WHILE V # fil DO
			    IF V.H > max.H THEN max := V END; V := V.next
		    END
	    END
    END Locate;

    PROCEDURE InitTrack* (W, H: INTEGER; Filler: Viewer);
	    VAR S: Display.Frame; T: Track;
	BEGIN
        IF Filler.state = 0 THEN
	        Filler.X := curW; Filler.W := W; Filler.Y := 0; Filler.H := H;
	        Filler.state := 1;
	        Filler.next := Filler;
	    	NEW(T);
		    T.X := curW; T.W := W; T.Y := 0; T.H := H;
		    T.dsc := Filler; T.under := NIL;
	        FillerViewer.X := curW + W; FillerViewer.W := inf - FillerViewer.X;
		    FillerTrack.X := FillerViewer.X; FillerTrack.W := FillerViewer.W;
	        S := FillerTrack;
            WHILE S.next # FillerTrack DO S := S.next END;
		    S.next := T; T.next := FillerTrack;
            curW := curW + W
        END
    END InitTrack;

    PROCEDURE OpenTrack* (X, W: INTEGER; Filler: Viewer);
	    VAR newT: Track; S, T, t, v: Display.Frame; M: ViewerMsg;
    BEGIN
	    IF (X < inf) & (Filler.state = 0) THEN
		    S := FillerTrack; T := S.next;
		    WHILE X >= T.X + T.W DO S := T; T := S.next END;
		    WHILE X + W > T.X + T.W DO T := T.next END;
		    M.id := suspend;
		    t := S;
		    REPEAT t := t.next; v := t.dsc;
			    REPEAT v := v.next;
                    WITH v: Viewer DO
                      M.state := -v.state; v.handle(v, M); v.state := M.state
                    END
				UNTIL v = t.dsc
			UNTIL t = T;
		    Filler.X := S.next.X; Filler.W := T.X + T.W - S.next.X; Filler.Y := 0; Filler.H := DH;
			Filler.state := 1;
			Filler.next := Filler;
			NEW(newT);
			 newT.X := Filler.X; newT.W := Filler.W; newT.Y := 0; newT.H := DH;
		    newT.dsc := Filler; newT.under := S.next; S.next := newT;
		    newT.next := T.next; T.next := NIL
	    END
    END OpenTrack;

    PROCEDURE CloseTrack* (X: INTEGER);
	    VAR T, V: Display.Frame; M: ViewerMsg;
    BEGIN
	    IF X < inf THEN
		    T := FillerTrack;
		    REPEAT T := T.next UNTIL X < T.X + T.W;
		    IF T(Track).under # NIL THEN
			    M.id := suspend; M.state := 0; V := T.dsc;
			    REPEAT V := V.next; V.handle(V, M); V(Viewer).state := 0 UNTIL V = T.dsc;
		  	  RestoreTrack(T)
		    END
	    END
    END CloseTrack;

	PROCEDURE Broadcast* (VAR M: Display.FrameMsg);
	    VAR T, V: Display.Frame;
	BEGIN
	    T := FillerTrack.next;
	    WHILE T # FillerTrack DO
		    V := T.dsc; 
		    REPEAT V := V.next; V.handle(V, M) UNTIL V = T.dsc;
		    T := T.next
	    END;
	    X11.DoFlush
	END Broadcast;

	PROCEDURE HandleUnloaded(f: Display.Frame; VAR msg: Display.FrameMsg);
	END HandleUnloaded;

	PROCEDURE CheckUnload* (handle: Display.Handler);
	    VAR T: Display.Frame;

		PROCEDURE Check(F: Display.Frame);
			VAR f: Display.Frame;
		BEGIN
			IF F.handle = handle THEN F.handle := HandleUnloaded END ;
			F := F.dsc; f := F;
			IF f # NIL THEN
				REPEAT Check(f); f := f.next UNTIL (f = NIL) OR (f = F)
			END
		END Check;
	BEGIN
	    T := FillerTrack.next;
	    WHILE T # FillerTrack DO Check(T); T := T.next END
	END CheckUnload;

BEGIN buf := NIL;
    NEW(FillerViewer);
    FillerViewer.X := 0; FillerViewer.W := inf; FillerViewer.Y := 0; FillerViewer.H := DH;
    FillerViewer.next := FillerViewer;
    NEW(FillerTrack);
    FillerTrack.X := 0; FillerTrack.W := inf; FillerTrack.Y := 0; FillerTrack.H := DH;
    FillerTrack.dsc := FillerViewer;
    FillerTrack.next := FillerTrack;
    curW := 0; minH := 1;
    DW := Display.Width; DH := Display.Height
END Viewers.
