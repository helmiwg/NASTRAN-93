      SUBROUTINE GENCOS        
C        
C     GENCOS  GENERATES DIRECTION COSINE MATRIX, UP TO NX3, FOR DDAM.   
C     THE SHOCK DIRECTIONS ARE GIVEN BY A COORDINATE SYSTEM (PROBABLY   
C     RECTANGULAR, BUT NOT NECESSARILY) DEFINED ON A CORDIJ CARD.       
C     THE ID OF THAT SYSTEM MUST BE SPECIFIED BY PARAM SHOCK ID.        
C     THE DIRECTIONS OF INTEREST MUST BE SPECIFIED ON A PARAM DIRECT DIR
C     CARD WHERE DIR=1,2,3,12,13,23,OR 123 GIVING THE SHOCK DIRECTIONS  
C     DESIRED IN THE SHOCK COORDINATE SYSTEM.  (DEFAULT IS 123)  WE WILL
C     BE CONVERTING A ROW VECTOR IN THE GLOBAL SYSTEM TO A ROW VECTOR IN
C     THE SHOCK SYSTEM.  TO CONVERT A COLUMN VECTOR FROM GLOBAL TO SHOCK
C     FIRST CONVERT TO BASIC.  THEN TRANSFORM FROM BASIC TO SHOCK, I.E. 
C     (VECTOR-SHOCK) = (TRANSPOSE(T-SHOCK TO BASIC))*        
C                      (T-GLOBAL TO BASIC)*(VECTOR-GLOBAL)        
C     BUT BECAUSE WE ARE TRANSFORMING ROW VECTORS, THE EQUATION IS      
C     TRANSPOSED . NSCALE =1 MEANS THERE ARE SCALAR POINTS,=0 MEANS NO  
C        
C     GENCOS    BGPDT,CSTM/DIRCOS/C,Y,SHOCK=0/C,Y,DIRECT=123/        
C               V,N,LUSET/V,N,NSCALE $        
C        
      LOGICAL         REC,ALL        
      INTEGER         BGPDT,CSTM,DIRCOS,BUF1,FILE,SHOCK,DIRECT,OTPE     
      DIMENSION       NAM(2),MCB(7),IZ(1),TSHOCK(9),COORD(4),ICOORD(4), 
     1                TPOINT(9),TFINAL(9),IDIR(3),ISUB(3)        
      CHARACTER       UFM*23        
      COMMON /XMSSG / UFM        
      COMMON /BLANK / SHOCK,DIRECT,LUSET,NSCALE        
      COMMON /SYSTEM/ IBUF,OTPE        
      COMMON /PACKX / IN,IOUT,II,NN,INCR        
CZZ   COMMON /ZZGENC/ Z(1)        
      COMMON /ZZZZZZ/ Z(1)        
      EQUIVALENCE     (Z(1),IZ(1)), (COORD(1),ICOORD(1))        
      DATA    BGPDT , CSTM,DIRCOS   / 101,102,201 /        
      DATA    NAM   / 4HGENC,4HOS   /        
C        
C     OPEN CORE AND BUFFERS        
C        
      LCORE = KORSZ(Z)        
      BUF1  = LCORE - IBUF + 1        
      LCORE = BUF1  - 1        
      IF (LCORE .LE. 0) GO TO 1008        
C        
C     CHECK FOR SCALAR POINTS AND SET NSCALE        
C        
      MCB(1) = BGPDT        
      CALL RDTRL (MCB)        
      NPTS = MCB(2)        
      CALL GOPEN (BGPDT,Z(BUF1),0)        
      DO 1 I = 1,NPTS        
      CALL FREAD (BGPDT,COORD,4,0)        
      IF (ICOORD(1) .EQ. -1) GO TO 2        
    1 CONTINUE        
      NSCALE = 0        
      GO TO 3        
    2 NSCALE = 1        
    3 CALL CLOSE (BGPDT,1)        
C        
      IF (DIRECT.GE.1  .AND. DIRECT.LE.3) GO TO 5        
      IF (DIRECT.NE.12 .AND. DIRECT.NE.13 .AND. DIRECT.NE.23 .AND.      
     1    DIRECT.NE.123) GO TO 500        
    5 IF (SHOCK .LT.  0) GO TO 500        
      NCSTM  = 0        
      NCOUNT = 0        
      ALL    = .FALSE.        
      REC    = .FALSE.        
      NDIR   = 2        
      IF (DIRECT .LE. 3) NDIR = 1        
      IF (DIRECT .EQ. 123)  NDIR = 3        
      IF (LUSET*NDIR .GT. LCORE) GO TO 1008        
C        
      GO TO (6,7,8), NDIR        
C        
    6 IDIR(1) = DIRECT        
      GO TO 9        
C        
    7 IF (DIRECT .EQ. 23) GO TO 175        
      IDIR(1) = 1        
      IDIR(2) = 2        
      IF (DIRECT .EQ. 13) IDIR(2) = 3        
      GO TO 9        
  175 IDIR(1) = 2        
      IDIR(2) = 3        
      GO TO 9        
C        
    8 IDIR(1) = 1        
      IDIR(2) = 2        
      IDIR(3) = 3        
    9 CONTINUE        
C        
C        
C     READ CSTM FOR FETCHING TRANSFORMATION MATRICES        
C        
      CALL OPEN (*10,CSTM,Z(BUF1),0)        
      GO TO 30        
C        
C     CSTM IS PURGED.  SO, GLOBAL SYSTEM IS BASIC AND SHOCK SYSTEM MUST 
C     BE ALSO.  IF SHOCK SYSTEM IS NOT 0, FATAL MESSAGE.  IF IT IS 0,   
C     THEN NEED ONLY IDENTITIES.        
C        
   10 IF (SHOCK .EQ. 0) GO TO 25        
      WRITE  (OTPE,20) UFM        
   20 FORMAT (A23,', IN GENCOS, CSTM IS PURGED AND SHOCK COORDINATE ',  
     1       'SYSTEM IS NOT BASIC')        
      CALL MESAGE (-61,0,0)        
C        
C     EVERYTHING IS BASIC - CHECK FOR SCALAR POINTS - IF THEY EXIST,    
C     WE MUST READ BGPDT        
C        
   25 IF (NSCALE .EQ. 1) GO TO 55        
      ALL  = .TRUE.        
      ISYS = 0        
      GO TO 130        
C        
   30 FILE = CSTM        
      CALL FWDREC (*1002,CSTM)        
      CALL READ (*1002,*40,CSTM,Z,LCORE,0,NCSTM)        
      GO TO 1008        
   40 CALL CLOSE (CSTM,1)        
C        
C     CHECK FOR ENOUGH OPEN CORE        
C        
      IF (NCSTM+LUSET*NDIR .GT. LCORE) GO TO 1008        
      CALL PRETRS (Z(1),NCSTM)        
C        
C     IF SHOCK COORDINATE SYSTEM IS RECTANGULAR, LET'S GET THE TRANS-   
C     FORMATION MATRIX ONCE SINCE IT WILL NOT BE POINT-DEPENDENT.       
C        
      IF (SHOCK .EQ. 0) GO TO 55        
      DO 50 I = 1,NCSTM,14        
      IF (SHOCK .NE. IZ(I)) GO TO 50        
      IF (IZ(I+1) .NE. 1) GO TO 60        
C        
C     RECTANGULAR        
C        
      REC = .TRUE.        
      DO 45 J = 1,9        
   45 TSHOCK(J) = Z(I+J+4)        
      GO TO 60        
   50 CONTINUE        
C        
C     CAN'T FIND SHOCK COORDINATE SYSTEM        
C        
      CALL MESAGE (-30,25,SHOCK)        
C        
C     SHOCK IS BASIC        
C        
   55 REC = .TRUE.        
      DO 56 I = 1,9        
   56 TSHOCK(I) = 0.        
      TSHOCK(1) = 1.        
      TSHOCK(5) = 1.        
      TSHOCK(9) = 1.        
C        
C     OPEN BGPDT TO GET GRID POINT OUTPUT COORDINATE SYSTEMS AND        
C     BASIC COORDINATES        
C        
   60 CALL GOPEN (BGPDT,Z(BUF1),0)        
      FILE = BGPDT        
   70 CALL READ (*1002,*210,BGPDT,COORD,4,0,IWORDS)        
      ISYS = ICOORD(1)        
      IF (ICOORD(1) .EQ. -1) GO TO 150        
      IF (ICOORD(1) .NE.  0) GO TO 80        
C        
C     IDENTITY - BASIC SYSTEM        
C        
      DO 75 I = 1,9        
   75 TPOINT(I) = 0.        
      TPOINT(1) = 1.        
      TPOINT(5) = 1.        
      TPOINT(9) = 1.        
      GO TO 85        
C        
C     FETCH GLOBAL-TO-BASIC MATRIX FOR THIS POINT        
C        
   80 CALL TRANSS (COORD,TPOINT)        
C        
C     IF SHOCK IS NOT RECTANGULAR, FETCH SHOCK-TO-BASIC FOR THIS POINT  
C        
   85 IF (REC) GO TO 90        
      ICOORD(1) = SHOCK        
      CALL TRANSS (COORD,TSHOCK)        
C        
C     THE MATRIX WE NEED IS (TRANSPOSE(TPOINT))*(TSHOCK)        
C        
   90 IF (SHOCK .EQ. 0) GO TO 100        
      IF (ISYS  .EQ. 0) GO TO 110        
C        
C     NEITHER MATRIX IS NECESSARILY IDENTITY        
C        
      CALL GMMATS (TPOINT,3,3,1,TSHOCK,3,3,0,TFINAL)        
      GO TO 150        
C        
C     TSHOCK IS IDENTITY        
C        
  100 IF (ISYS .EQ. 0) GO TO 130        
C        
C     BUT TPOINT IS NOT        
C        
      TFINAL(1) = TPOINT(1)        
      TFINAL(2) = TPOINT(4)        
      TFINAL(3) = TPOINT(7)        
      TFINAL(4) = TPOINT(2)        
      TFINAL(5) = TPOINT(5)        
      TFINAL(6) = TPOINT(8)        
      TFINAL(7) = TPOINT(3)        
      TFINAL(8) = TPOINT(6)        
      TFINAL(9) = TPOINT(9)        
      GO TO 150        
C        
C     TPOINT IS IDENTITY, BUT TSHOCK IS NOT        
C        
  110 DO 120 I = 1,9        
  120 TFINAL(I) = TSHOCK(I)        
      GO TO 150        
C        
C     BOTH ARE IDENTITY        
C        
  130 DO 140 I = 1,9        
  140 TFINAL(I) = 0.        
      TFINAL(1) = 1.        
      TFINAL(5) = 1.        
      TFINAL(9) = 1.        
C        
C     STORE TFINAL BY INTERNAL ORDERING AND DIRECTIONS REQUESTED START- 
C     ING AT Z(NCSTM+1) - MAKE UP TO 3 COLUMNS OF LUSET EACH        
C        
  150 ISUB(1) = NCSTM   + NCOUNT        
      ISUB(2) = ISUB(1) + LUSET        
      ISUB(3) = ISUB(2) + LUSET        
C        
      DO 200 I = 1,NDIR        
      IP   = IDIR(I)        
      JSUB = ISUB(I)        
      IF (ISYS .EQ. -1) GO TO 195        
      Z(JSUB+1) = TFINAL(IP  )        
      Z(JSUB+2) = TFINAL(IP+3)        
      Z(JSUB+3) = TFINAL(IP+6)        
      Z(JSUB+4) = 0.        
      Z(JSUB+5) = 0.        
      Z(JSUB+6) = 0.        
      GO TO 200        
C        
C     SCALAR        
C        
  195 Z(JSUB+1) = 1.        
  200 CONTINUE        
C        
C     GO BACK FOR ANOTHER POINT        
C        
      NCOUNT = NCOUNT + 6        
      IF (ISYS .EQ. -1)  NCOUNT = NCOUNT - 5        
      IF (.NOT.ALL) GO TO 70        
      IF (NCOUNT .EQ. LUSET) GO TO 210        
      GO TO 150        
C        
C     DONE WITH ALL POINTS - PACK RESULTS        
C        
  210 IF (.NOT.ALL) CALL CLOSE (BGPDT,1)        
      CALL GOPEN (DIRCOS,Z(BUF1),1)        
      IN   = 1        
      IOUT = 1        
      II   = 1        
      NN   = LUSET        
      INCR = 1        
      MCB(1) = DIRCOS        
      MCB(2) = 0        
      MCB(3) = LUSET        
      MCB(4) = 2        
      MCB(5) = 1        
      MCB(6) = 0        
      MCB(7) = 0        
      DO 220 I = 1,NDIR        
      JSUB = NCSTM + LUSET*(I-1)        
      CALL PACK (Z(JSUB+1),DIRCOS,MCB)        
  220 CONTINUE        
C        
      CALL CLOSE (DIRCOS,1)        
      CALL WRTTRL (MCB)        
      RETURN        
C        
  500 WRITE  (OTPE,510) UFM,SHOCK,DIRECT        
  510 FORMAT (A23,', SHOCK AND DIRECT ARE',2I10, /10X,'RESPECTIVELY. ', 
     1       'SHOCK MUST BE NONNEGATIVE AND DIRECT MUST BE EITHER 1,2', 
     2       ',3,12,13,23, OR 123')        
      CALL MESAGE (-61,0,0)        
C        
 1002 N = -2        
      GO TO 1010        
 1008 N = -8        
      FILE = 0        
 1010 CALL MESAGE (N,FILE,NAM)        
      RETURN        
      END        