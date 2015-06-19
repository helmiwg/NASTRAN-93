      SUBROUTINE LINEL (IZ,NWDS,OPCOR,OPT,X,PEN,DEFORM,GPLST)        
C        
C     CALL TO LINEL IS AS FOLLOWS -        
C        
C     (1)        
C     OPT = ZERO (INPUT) - TO CREATE COMPLETE LINE CONNECTION TABLE OF  
C     **********           ELEMENTS OF ALL TYPES, TO BE USED BY SUPLT   
C                          SUBROUTINE        
C        INPUT-        
C           OPCOR (INPUT) = NUMBER OF WORDS OF OPEN CORE FOR -IZ-       
C        OUTPUT-        
C           IZ   = LIST OF GRID POINT ELEMENET CONNECTIONS AND POINTERS 
C                  TO EACH GRID POINT, FROM IZ(1) THRU IZ(NWDS). DATA   
C                  COMPOSED OF   1. GPCT,  AND 2. NGP WORDS OF CONTROL  
C                  POINTERS        
C           NWDS = NO. OF WORDS IN IZ PRIOR TO POINTER ARRAY.        
C                  I.E. 1 LESS THAN LOCATION OF POINTERS,        
C                = 0 IF ARRAY NOT CREATED        
C           OPT  = NWDS        
C        
C     (2)        
C     OPT = NONZERO (INPUT) - LOAD INTO CORE THE GRID POINT CNNECTION   
C     *************           LIST OF ALL ELEMENTS OF THE SAME TYPE     
C        
C        INPUT-        
C           NWDS  = ETYP, 2 BCD WORDS (CALLING ROUTINE HAS ALREADY READ 
C                   THIS WORD FROM DATA BLOCK ELSET)        
C           OPT   = MO. OF GRID POINT CONNECTIONS PER ELEMENT, NGPEL    
C                   (CALLING ROUTINE HAS ALREADY READ THIS WORD)        
C           OPCOR = OPEN CORE AVAILABLE W.R.T. IZ(1)        
C           GPLST = A SUBSET LIST OF GRID POINTS PERTAINING TO THOSE    
C                   POINTS USED ONLY IN THIS PLOT        
C        OUTPUT-        
C           IZ    = GRID POINT CONNECTION LIST FOR ALL ELEMENTS OF THIS 
C                   TYPE, OR AS MANY ELEMS OF THIS TYPE AS CORE ALLOWS. 
C           NWDS  = TOTAL LENGTH OF TABLE IZ        
C           OPT   = NUMBER OF CONNECTIONS PER ELEMENT        
C           (IF INSUFF. CORE TO READ ALL THE ELEMENTS, BOTH NWDS AND OPT
C           ARE SET TO NEGATIVE UPON RETURN. FURTHER CALLS MUST BE MADE 
C           TO COMPLETE THIS ELEMENT        
C           IF ILLEGAL ELEMENT IS ENCOUNTERED, NWDS AND OPT ARE SET TO  
C           ZERO, AND ELSET IS SPACED OVER THE ELEMENT)        
C        
C           (NOTE THAT  'DO 100 I=1,NWDS,OPT'  MAY THEN BE USED        
C           BUT IT IS MORE EFFICIENT TO USE  'DO 100 I=1,NWDS' AND CHECK
C           ZERO AS THE COMMAND TO LIFT THE PEN)        
C        
C     EACH ELEMENT TYPE HAS THE FOLLOWING DATA IN ELSET FILE        
C           ELTYP = BCD SYMBOL (1 WORD)        
C           NGPEL = NUM. GRID POINTS.        
C                   IF NEGATIVE OR .GT. 4 NOT A CLOSED LOOP        
C           ELID  = ELEMENT ID        
C           G     = NGPEL GRIDS.        
C           LOOP THRU ELID AND G UNTIL ELID = 0 (I.E. NO MORE ELEMS OF  
C                                              THIS TYPE)        
C     (3)        
C     ELEMENT OFFSET PLOT (UNDEFORMED PLOT ONLY, PEDGE=3),        
C     *******************        
C     IF ELEMENTS WITH OFFSET ARE PRESENT, CALL OFSPLT TO PLOT THEM OUT 
C     AND DO NOT INCLUDE THEM IN THE IZ TABLE        
C     IF OFFSET COMMAND IS REQUESTED BY USER VIA THE PLOT CARD        
C     (PEDGE = 3), SKIP COMPLETELY THE GENERATION OF THE IZ TABLE       
C        
C     OFFSET n OPTION (ON PLOT CONNAND CARD IN CASE CONTROL SECTION) -  
C       n .LT. 0, SKIP OFFSET VALUES ON GENERAL PLOTS. (PEDGE.NE.3)     
C       n =    0, OFFSET VALUES INCLUDED IN ALL GENERAL PLOTS (PEDGE=3) 
C       n .GT. 0, PLOT ONLY THOSE ELEMENTS HAVING OFFSET DATA, OFFSET   
C                 DATA ARE MAGNIFIED n TIMES. (PEDGE=3)        
C     SUBROUTINE PLOT SETS THE PEDGE FLAG, AND PLTSET SETS THE OFFSCL.  
C        
      INTEGER         ELID,ELSET,ETYP,G,IZ(1),M1(16),NAME(2),GPLST(1),  
     1                NG(121),OPCOR,OPT,TYPE,NGTYP(2,13),LDX(9),OFFSCL, 
     2                OFFSET,DEFORM,PEN,PEDGE        
      REAL            X(3,1)        
      COMMON /BLANK / NGP,SKP1(9),SKP2(2),ELSET,SKP3(7),MERR        
      COMMON /SYSTEM/ SKP4,IOUT        
      COMMON /PLTSCR/ NNN,G(3)        
      COMMON /DRWDAT/ SKP5(15),PEDGE        
      COMMON /XXPARM/ SKP6(235),OFFSCL        
      DATA    NAME  / 4HLINE, 1HL  /,  NM1,M1 / 16,        
     1                4H(33X, 4H,13H, 4HELEM, 4HENT , 4HTYPE, 4H ,A5,   
     2                4H,4HW, 4HITH,, 4HI8,2, 4H4H G, 4HRIDS, 4H SKI,   
     3                4HPPED, 4H IN , 4HLINE, 4HL.)   /        
C        
C     SPECIAL ELEMENT CONNECTION PATTERNS        
C        
      DATA LDX  / 2HD1,2HD2,2HD3,2HD4,2HD5,2HD6,2HD7,2HD8,2HD9      /   
      DATA KTET / 2HTE /, KWEG / 2HWG /, KHX1 / 2HH1 /, KHX2 / 2HH2 /,  
     1     KIX1 / 2HXL /, KIX2 / 2HXQ /, KIX3 / 2HXC /, KAE  / 2HAE /,  
     2     KTM6 / 2HT6 /,KTRPLT/ 2HP6 /,KTRSHL/ 2HSL /, KFH1 / 2HFA /,  
     3     KFH2 / 2HFB /, KFWD / 2HFW /, KFTE / 2HFT /, K2D8 / 2HD8 /,  
     4     KHB  / 2HHB /, KBAR / 2HBR /, KT3  / 2HT3 /, KQ4  / 2HQ4 /   
C        
C     NGTYP(1,TYPE) = LOCATION WORD 1 IN -NG-, +N = POINTER TO G        
C                                              -N = THRU POINTER TO G   
C     BE SURE TO KEEP PEN DOWN                  0 = LIFT PEN        
C     AS MUCH AS POSSIBLE.        
C     NGTYP(2,TYPE) = NUMBER OF ENTRIES/ELEMENT MINUS 1 IN TABLE IZ     
C        
      DATA NGTYP/ 0,0,  3,9,  10,14,  22,19,  37,30,  56,43,  79,6,     
     1           83,7, 86,9,  95,10, 102, 8, 108, 2, 110, 7/        
      DATA  NG  /        
C    1 - LINE,TRIANGLE,QUAD        
     1   1,-5,        
C    2 - TETRA (WORD 3)        
     2   1,-4,1,3,0,2,4,        
C    3 - WEDGE (WORD 10)        
     3   1,-3,1,4,-6,4,0,5,2,0,3,6,        
C    4 - HEXA  (WORD 22)        
     4   1,-4,1,5,-8,5,0,6,2,0,3,7,0,8,4,        
C    5 - IHEXA2 (WORD 37)        
     5   1,-8,1,9,13,-20,13,0,15,10,3,0,5,11,17,0,19,12,7,        
C    6 - IHEXA3 (WORD 56)        
     6   1,-12,1,13,17,21,-32,21,0,24,18,14,4,0,7,15,19,27,0,30,20,16,10
C    7 - AREO (WORD 79)        
     7,  1,-4,1,0,        
C    8 - TRIM6, TRPLT1, AND TRSHL (WORD 83)        
     8   1,-6,1,        
C    9 - IS2D8 (WORD 86)        
     9   1,5,2,6,3,7,4,8,1,        
C   1O - POINT (WORD 95)        
     O   2,-6,7,2,0,1,8,        
C   11 - LINE (WORD 102)        
     1   3,-6,3,0,7,8,        
C   12 - REV OR ELIP CYL. (WORD 108)        
     2   1,2,        
C   13 - AREA3 (WORD 110)        
     3   1,-3,1,0,4,5,        
C   14 - AREA4 (WORD 116)        
     4   1,-4,1,0,5,6        
     * /        
C        
      K    = 1        
      IF (OPT .EQ. 0) GO TO 20        
      ETYP = NWDS        
      I    = OPT        
      GO TO 30        
C        
   20 IF (OPT .NE. 0) GO TO 170        
      CALL READ (*420,*190,ELSET,ETYP,1,0,I)        
      CALL FREAD (ELSET,I,1,0)        
C        
   30 NGPEL  = IABS(I)        
      NGPELX = NGPEL        
      OFFSET = 0        
      IF (ETYP .EQ. KBAR) OFFSET = 6        
      IF (ETYP.EQ.KT3 .OR. ETYP.EQ.KQ4) OFFSET = 1        
C        
      TYPE  = 1        
      IF (ETYP.EQ.KTET .OR. ETYP.EQ.KFTE) TYPE = 2        
      IF (ETYP.EQ.KWEG .OR. ETYP.EQ.KFWD) TYPE = 3        
      IF (ETYP.EQ.KHX1 .OR. ETYP.EQ.KHX2 .OR. ETYP.EQ.KFH1 .OR.        
     1    ETYP.EQ.KFH2 .OR. ETYP.EQ.KIX1) TYPE = 4        
      IF (ETYP .EQ. KIX2) TYPE = 5        
      IF (ETYP .EQ. KIX3) TYPE = 6        
      IF (ETYP .EQ.  KAE) TYPE = 7        
      IF (ETYP.EQ.KTM6 .OR. ETYP.EQ.KTRPLT .OR. ETYP.EQ.KTRSHL) TYPE = 8
      IF (ETYP .EQ. K2D8) TYPE = 9        
      IF (ETYP .EQ. KHB ) TYPE = 10        
C                   CHBDY TYPE = 10,11,12,13,14        
C        
      IF (TYPE .NE. 1) GO TO 40        
C        
C     SIMPLE ELEMENT        
C        
      IF (NGPEL.GT.2 .AND. I.GT.0) NGPELX = NGPEL + 1        
      IF (NGPEL .GT. 4) GO TO 131        
      L1 = 1        
      M  = NGPELX        
      GO TO 50        
C        
C     COMPLEX ELEMENT        
C        
   40 L1 = NGTYP(1,TYPE)        
      M  = NGTYP(2,TYPE)        
   50 IF (NGPELX .GT. NNN) GO TO 140        
C        
C     READ THE ELEMENT DATA        
C        
   55 CALL FREAD (ELSET,ELID,1,0)        
      IF (ELID .LE. 0) GO TO 20        
      CALL FREAD (ELSET,LID,1,0)        
      CALL FREAD (ELSET,G,NGPEL,0)        
      IF (NGPEL .NE. NGPELX) G(NGPELX) = G(1)        
C        
C     CALL OFSPLT TO PROCESS OFFSET PLOT        
C        
      IF (OFFSET .NE. 0)        
     1   CALL OFSPLT (*55,ETYP,ELID,G,OFFSET,X,DEFORM,GPLST)        
      IF (TYPE.LT.10 .OR. TYPE.GT.14) GO TO 57        
C        
C     SPECIAL HANDLING FOR CHBDY        
C        
      TYPE = 9 + G(NGPEL)        
      L1 = NGTYP(1,TYPE)        
      M  = NGTYP(2,TYPE)        
C        
   57 L = L1        
C        
      IF (OPT .NE. 0) GO TO 70        
C        
C     CREATING CONNECTION ARRAY FOR SUPLT        
C        
      LL = 0        
      I1 = 0        
   60 I2 = NG(L)        
      IF (I1 .EQ. 0) GO TO 66        
      IF (I2) 62,64,65        
C        
C     THRU RANGE        
C        
   62 I2 =-I2        
      I2 = MIN0(I2,M)        
      J  = I1 + 1        
      I1 = G(I1)        
      IF (2*(I2-J+1)+K .GT. OPCOR) GO TO 390        
      DO 63 I = J,I2        
      IZ(K  ) = MIN0(G(I),I1)        
      IZ(K+1) = MAX0(G(I),I1)        
      K  = K  + 2        
      LL = LL + 1        
   63 I1 = G(I)        
      IF (LL .EQ. M-1) LL = LL - 1        
      GO TO 66        
C        
   64 I1 = 0        
      L  = L + 1        
      GO TO 60        
C        
   65 IF (K+1 .GT. OPCOR) GO TO 180        
      IZ(K  ) = MIN0(G(I2),G(I1))        
      IZ(K+1) = MAX0(G(I2),G(I1))        
      K  = K  + 2        
   66 LL = LL + 1        
      I1 = I2        
      IF (LL .GE. M) GO TO 55        
      L  = L + 1        
      GO TO 60        
C        
C     ON CONVERSION REMOVE ABOVE CODE        
C        
C     LOAD ELEMENT INTO CORE        
C        
   70 N = K + M        
C        
C     THIS TEST PROTECTS THE CORE FOR THE FIRST ELEMENT READ        
C        
      IF (N+1 .GT. OPCOR) GO TO 140        
      I1 = 0        
      I2 = NG(L)        
      GO TO 125        
   80 IF (I1 .EQ. 0) GO TO 90        
      IF (I2) 110,100,90        
C        
   90 IZ(K) = G(I2)        
      GO TO 120        
  100 IZ(K) = I2        
      GO TO 120        
  110 I2 =-I2        
C        
C     NEXT LINE FOR ELEMENTS WITH MORE THAN ONE THRU POINTER        
C        
      IF (N .NE. K+M) I1 = I1 + 1        
      DO 115 I = I1,I2        
      IZ(K) = G(I)        
  115 K = K + 1        
      K = K - 1        
  120 K = K + 1        
      IF (K .GE. N) GO TO 130        
  125 I1 = I2        
      L  = L + 1        
      I2 = NG(L)        
      GO TO 80        
C        
C     STORE ZERO AT THE END OF EACH ELEMENT        
C        
  130 IZ(K) = 0        
      K = K + 1        
      IF (K+M+1 .GT. OPCOR) GO TO 180        
      GO TO 55        
C        
C     CHECK FOR PDUM ELEMENTS BEFORE REJECTING        
C        
  131 DO 132 II = 1,9        
      IF (ETYP .EQ. LDX(II)) CALL PDUMI (*20,*180,*140,II,M,OPCOR,NGPEL,
     1                                   K,ELSET,OPT)        
  132 CONTINUE        
C        
C     ILLEGAL ELEMENT, NO CORE FOR 1 ELEMENT        
C        
  140 G(1) = 2        
      G(2) = ETYP        
      G(3) = NGPEL        
      CALL WRTPRT (MERR,G,M1,NM1)        
C        
C     READ TO THE END OF THIS ELEMENT        
C        
  150 CALL FREAD (ELSET,ELID,1,0)        
      IF (ELID .LE. 0) GO TO 160        
      J = 1 + NGPEL + OFFSET        
      CALL FREAD (ELSET,0,-J,0)        
      GO TO 150        
  160 CONTINUE        
C        
C     NOTE THAT BOTH OPT AND NWDS=0 FOR ILLEGAL ELEMENTS        
C        
      IF (OPT .NE. 0) GO TO 390        
      GO TO 20        
C        
C     END OF OPT.NE.0        
C        
  170 NWDS = K - 1        
      OPT  = M + 2        
      GO TO 410        
C        
C     INSUFFICIENT CORE FOR ALL ELEMENTS        
C        
  180 IF (OPT .EQ. 0) GO TO 390        
      NWDS = 1 - K        
      OPT  = -(M+2)        
      GO TO 410        
C        
C     SORT        
C        
  190 IF (PEDGE .EQ. 3) GO TO 400        
      IF (OPT   .NE. 0) GO TO 170        
      IF (K     .LE. 1) GO TO 400        
      CALL SORT (0,0,2,1,IZ,K-1)        
C        
C     NWDS IS SET TO NO. OF WORDS PRIOR TO ELIMINATING DUPLICATES       
C        
      NWDS = K - 1        
      IF (NWDS .LE. 2) GO TO 310        
      ASSIGN 310 TO IRET        
C        
C     ELIMINATE DUPLICATE ENTRIES FROM LIST SORTED ON FIRST ENTRY       
C        
  200 CONTINUE        
      I = 1        
      L = 1        
      LL= IZ(L)        
C        
C        
      DO 300 J = 3,NWDS,2        
      IF (IZ(J) .EQ. LL) GO TO 220        
C        
C     NEW PIVOT        
C        
      L  = I + 2        
      LL = IZ(J)        
      GO TO 230        
  220 IF (IZ(J+1)-IZ(I+1)) 240,300,230        
C        
C     UNIQUE ENTRY FOR PIVOT FOUND        
C        
  230 IZ(I+2) = LL        
      IZ(I+3) = IZ(J+1)        
      GO TO 290        
C        
C     SECOND COLUMN OUT-OF-SORT        
C     LOAD ENTRY SORTED.  CHECK PREVIOUS ENTRIES        
C     L = LOWER LIMIT OF COLUMN 1 FOR MERGING        
C     K SET TO FIRST ENTRY OF NEXT NEW ENTRY IN LIST INITIALLY        
C        
  240 K = I        
  250 IF (K .LE. L) GO TO 270        
      IF (IZ(J+1)-IZ(K-1)) 260,300,270        
  260 K = K - 2        
      GO TO 250        
C        
C     LOAD ENTRY INTO LOCATION        
C        
  270 N = IZ(J+1)        
      M = I + 2        
  280 IZ(M+1) = IZ(M-1)        
      M = M - 2        
      IF (M .GT. K) GO TO 280        
      IZ(K+1) = N        
      IZ(I+2) = LL        
C        
C     INCREMENT FOR ENTRY LOADED        
C        
  290 I = I + 2        
  300 CONTINUE        
C        
C     NWDS RESET TO NO. WORDS AFTER ELIMINATING DUPLICATE ENTRIES       
C        
      NWDS = I + 1        
      GO TO IRET, (310,330)        
C        
C        
C     K IS SET TO THE NEXT PART OF CORE WHICH WILL BE FILLED WITH THE   
C     HIGHER ENTRY IN THE FIRST POSITION        
C        
  310 K = NWDS + 1        
      IF (2*NWDS .GT. OPCOR) GO TO 400        
      DO 320 I = 1,NWDS,2        
      IZ(K  ) = IZ(I+1)        
      IZ(K+1) = IZ(I  )        
      K = K + 2        
  320 CONTINUE        
      NWDS = K - 1        
      CALL SORT (0,0,2,1,IZ,NWDS)        
      ASSIGN 330 TO IRET        
      GO TO 200        
C        
  330 CONTINUE        
      IF (NWDS+NGP+1 .GT. OPCOR) GO TO 400        
      K = 1        
      J = 1        
      L = 1        
      M = 1 + NWDS        
      I = 0        
      IZ(M) = 1        
C        
C     CREATE A GPCT --- M = POINTER FOR POINTER ARRAY        
C                       L = SIL NUMBER        
C                       J = POINTER TO NEXT GPCT ENTRY        
C        
  340 IF (IZ(K) .EQ. L) GO TO 360        
C        
C     NEW PIVOT        
C        
  350 M = M + 1        
      IZ(M) = IZ(M-1) + I        
      L = L + 1        
      I = 0        
      IF (L .GT.  NGP) GO TO 370        
      IF (K .GT. NWDS) GO TO 350        
      GO TO 340        
C        
C     CONNECTED POINT        
C        
  360 IZ(J) = IZ(K+1)        
      K = K + 2        
      J = J + 1        
      I = I + 1        
      GO TO 340        
C        
C     EFFICIENCY PLOT POSSIBLE        
C        
  370 CONTINUE        
      OPT = NWDS        
      GO TO 410        
C        
  390 OPT  = 0        
  400 NWDS = 0        
  410 RETURN        
C        
  420 CALL MESAGE (-2,ELSET,NAME)        
      GO TO 410        
      END        