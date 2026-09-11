{..............................................................................}
{ Panelize_Hard_Form.pas                                                       }
{ Mill = closed CAD offset of BoardOutline chain (contour order), one loop per }
{ cell. Alleys collapse to one slot pair. Tabs on long straight edges.         }
{ T-pockets join neighbor outer walls, not the frame. Prefix PHF*.             }
{..............................................................................}

const
    PHFOutlineW = 0.2;
    PHFPiValue         = 3.141592653589793;

var
    PHFSourceBoard : IPCB_Board;
    PHFPanelBoard  : IPCB_Board;
    PHFSourcePath  : String;
    PHFRows, PHFCols  : Integer;
    PHFTabCountH, PHFTabCountV : Integer;
    PHFGapX, PHFGapY, PHFMargin, PHFTabW, PHFFilletR : Double;
    PHFMechIndex   : Integer;
    PHFBoardW, PHFBoardH : Double;
    PHFPanelW, PHFPanelH : Double;
    PHFMechLayer   : TLayer;
    PHFLineW       : TCoord;
    PHFMillMinX, PHFMillMinY, PHFMillMaxX, PHFMillMaxY : TCoord;
    PHFHaveMill    : Boolean;
    PHFOffMM       : Double;

{ Run Script: choose procedure StartPanelizeHardForm (this .pas only). }
procedure StartPanelizeHardForm; forward;
procedure _StartPanelizeHardForm; forward;
procedure TFormPHF.ButtonBrowseClick(PHFSender: TObject); forward;
procedure TFormPHF.ButtonOKClick(PHFSender: TObject); forward;
procedure TFormPHF.ButtonCancelClick(PHFSender: TObject); forward;
procedure TFormPHF.FormPHFShow(PHFSender: TObject); forward;
function PHFBoardOriginX(Col : Integer) : TCoord; forward;
function PHFBoardOriginY(Row : Integer) : TCoord; forward;
procedure PHFOffsetCopiedOutline(ABoard : IPCB_Board; Col, Row : Integer; PHFALayer : TLayer); forward;
procedure PHFPunchAllTabs(ABoard : IPCB_Board; PHFALayer : TLayer); forward;
procedure PHFDeleteCoincident(ABoard : IPCB_Board; PHFALayer : TLayer); forward;
procedure PHFJoinOuterTPockets(ABoard : IPCB_Board; PHFALayer : TLayer); forward;
procedure PHFDeleteDangling(ABoard : IPCB_Board; PHFALayer : TLayer); forward;
function PHFInAlley(PHFX, PHFY : TCoord) : Boolean; forward;

function PHFParseFloat(const PanS : String; var PanV : Double) : Boolean;
var
    PanT : String;
    PHFj : Integer;
    PanCh : Char;
    PanSign : Double;
    PanScale : Double;
    PanSeenDigit : Boolean;
    PanFrac : Boolean;
begin
    Result := False;
    PanV := 0;
    PanT := PanS;
    while (Length(PanT) > 0) and (PanT[1] = ' ') do
        PanT := Copy(PanT, 2, Length(PanT));
    while (Length(PanT) > 0) and (PanT[Length(PanT)] = ' ') do
        PanT := Copy(PanT, 1, Length(PanT) - 1);
    if PanT = '' then Exit;
    PanSign := 1;
    PHFj := 1;
    if PanT[1] = '-' then
    begin
        PanSign := -1;
        PHFj := 2;
    end
    else if PanT[1] = '+' then
        PHFj := 2;
    PanSeenDigit := False;
    PanFrac := False;
    PanScale := 1;
    while PHFj <= Length(PanT) do
    begin
        PanCh := PanT[PHFj];
        if (PanCh = '.') or (PanCh = ',') then
        begin
            if PanFrac then Exit;
            PanFrac := True;
        end
        else if (PanCh >= '0') and (PanCh <= '9') then
        begin
            PanSeenDigit := True;
            if not PanFrac then
                PanV := PanV * 10 + (Ord(PanCh) - Ord('0'))
            else
            begin
                PanScale := PanScale * 10;
                PanV := PanV + (Ord(PanCh) - Ord('0')) / PanScale;
            end;
        end
        else
            Exit;
        PHFj := PHFj + 1;
    end;
    if not PanSeenDigit then Exit;
    PanV := PanV * PanSign;
    Result := True;
end;

function PHFParsePositive(const PanS : String; var PanV : Double) : Boolean;
begin
    Result := PHFParseFloat(PanS, PanV) and (PanV > 0);
end;

function PHFParseNonNeg(const PanS : String; var PanV : Double) : Boolean;
begin
    Result := PHFParseFloat(PanS, PanV) and (PanV >= 0);
end;

function PHFParsePositiveInt(const PanS : String; var PanV : Integer) : Boolean;
begin
    Result := False;
    try
        PanV := StrToInt(PanS);
        Result := PanV > 0;
    except
        Result := False;
    end;
end;

procedure PHFTrySetMetricGrid(ABoard : IPCB_Board; GridMM : Double);
var
    Grid : TCoord;
begin
    try
        ABoard.DisplayUnit := eMetric;
    except
    end;
    try
        ABoard.SnapGridUnit := eMetric;
    except
    end;
    Grid := MMsToCoord(GridMM);
    try
        ABoard.SnapGridSize := Grid;
    except
        try
            ABoard.SetState_SnapGridSize(Grid);
        except
        end;
    end;
end;

function PHFSnap1mm(PanC : TCoord) : TCoord;
begin
    Result := MMsToCoord(Round(CoordToMMs(PanC)));
end;

function PHFAddTrack(ABoard : IPCB_Board; PanX1, PanY1, PanX2, PanY2 : TCoord; PanALayer : TLayer) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := PanX1;
    Result.Y1 := PanY1;
    Result.X2 := PanX2;
    Result.Y2 := PanY2;
    Result.Layer := PanALayer;
    Result.Width := PHFLineW;
    ABoard.AddPCBObject(Result);
end;

function PHFAddArc(ABoard : IPCB_Board; PanCX, PanCY, PanRadius : TCoord; PanSa, PanEa : Double; PanALayer : TLayer) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := PanCX;
    Result.YCenter := PanCY;
    Result.Radius := PanRadius;
    Result.StartAngle := PanSa;
    Result.EndAngle := PanEa;
    Result.Layer := PanALayer;
    Result.LineWidth := PHFLineW;
    ABoard.AddPCBObject(Result);
end;


procedure PHFNoteMillXY(PHFX, PHFY : TCoord);
begin
    if not PHFHaveMill then
    begin
        PHFMillMinX := PHFX; PHFMillMaxX := PHFX;
        PHFMillMinY := PHFY; PHFMillMaxY := PHFY;
        PHFHaveMill := True;
    end
    else
    begin
        if PHFX < PHFMillMinX then PHFMillMinX := PHFX;
        if PHFX > PHFMillMaxX then PHFMillMaxX := PHFX;
        if PHFY < PHFMillMinY then PHFMillMinY := PHFY;
        if PHFY > PHFMillMaxY then PHFMillMaxY := PHFY;
    end;
end;

procedure PHFNoteMillTrack(PHFT : IPCB_Track);
begin
    if PHFT = nil then Exit;
    PHFNoteMillXY(PHFT.X1, PHFT.Y1);
    PHFNoteMillXY(PHFT.X2, PHFT.Y2);
end;

procedure PHFNoteMillArc(PHFA : IPCB_Arc);
begin
    if PHFA = nil then Exit;
    PHFNoteMillXY(PHFA.XCenter - PHFA.Radius, PHFA.YCenter - PHFA.Radius);
    PHFNoteMillXY(PHFA.XCenter + PHFA.Radius, PHFA.YCenter + PHFA.Radius);
end;

function PHFAddMillTrack(ABoard : IPCB_Board; PHFX1, PHFY1, PHFX2, PHFY2 : TCoord; PHFALayer : TLayer) : IPCB_Track;
begin
    Result := PHFAddTrack(ABoard, PHFX1, PHFY1, PHFX2, PHFY2, PHFALayer);
    PHFNoteMillTrack(Result);
end;

function PHFAddMillArc(ABoard : IPCB_Board; PHFCX, PHFCY, PHFRadius : TCoord; PHFSa, PHFEa : Double; PHFALayer : TLayer) : IPCB_Arc;
begin
    Result := PHFAddArc(ABoard, PHFCX, PHFCY, PHFRadius, PHFSa, PHFEa, PHFALayer);
    PHFNoteMillArc(Result);
end;

function PHFIntersectLL(X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Double; var Xi, Yi : Double) : Boolean;
var
    PHFDen, PHFT : Double;
begin
    Result := False;
    PHFDen := (X1 - X2) * (Y3 - Y4) - (Y1 - Y2) * (X3 - X4);
    if Abs(PHFDen) < 1e-18 then Exit;
    PHFT := ((X1 - X3) * (Y3 - Y4) - (Y1 - Y3) * (X3 - X4)) / PHFDen;
    Xi := X1 + PHFT * (X2 - X1);
    Yi := Y1 + PHFT * (Y2 - Y1);
    Result := True;
end;

function PHFNormDeg(PHFA : Double) : Double;
begin
    Result := PHFA;
    while Result < 0 do Result := Result + 360;
    while Result >= 360 do Result := Result - 360;
end;

function PHFAtan2Deg(PHFY, PHFX : Double) : Double;
begin
    if Abs(PHFX) < 1e-18 then
    begin
        if PHFY >= 0 then Result := 90 else Result := 270;
        Exit;
    end;
    Result := ArcTan(PHFY / PHFX) * 180.0 / PHFPiValue;
    if PHFX < 0 then Result := Result + 180;
    Result := PHFNormDeg(Result);
end;

function PHFIntersectLC(X1, Y1, X2, Y2, Cx, Cy, R : Double; HintX, HintY : Double; var Xi, Yi : Double) : Boolean;
var
    Dx, Dy, Fx, Fy, A, B, C, Disc, T1, T2, Px1, Py1, Px2, Py2, D1, D2 : Double;
begin
    Result := False;
    Dx := X2 - X1;
    Dy := Y2 - Y1;
    Fx := X1 - Cx;
    Fy := Y1 - Cy;
    A := Dx * Dx + Dy * Dy;
    if A < 1e-18 then Exit;
    B := 2 * (Fx * Dx + Fy * Dy);
    C := Fx * Fx + Fy * Fy - R * R;
    Disc := B * B - 4 * A * C;
    if Disc < -1e-9 then Exit;
    if Disc < 0 then Disc := 0;
    Disc := Sqrt(Disc);
    T1 := (-B - Disc) / (2 * A);
    T2 := (-B + Disc) / (2 * A);
    Px1 := X1 + T1 * Dx;
    Py1 := Y1 + T1 * Dy;
    Px2 := X1 + T2 * Dx;
    Py2 := Y1 + T2 * Dy;
    D1 := Sqr(Px1 - HintX) + Sqr(Py1 - HintY);
    D2 := Sqr(Px2 - HintX) + Sqr(Py2 - HintY);
    if D1 <= D2 then begin Xi := Px1; Yi := Py1; end else begin Xi := Px2; Yi := Py2; end;
    Result := True;
end;

function PHFIntersectCC(C1x, C1y, R1, C2x, C2y, R2, HintX, HintY : Double; var Xi, Yi : Double) : Boolean;
var
    Dx, Dy, Dist, A, Hx, Hy, Rx, Ry, Px1, Py1, Px2, Py2, D1, D2 : Double;
begin
    Result := False;
    Dx := C2x - C1x;
    Dy := C2y - C1y;
    Dist := Sqrt(Dx * Dx + Dy * Dy);
    if Dist < 1e-12 then Exit;
    if Dist > R1 + R2 + 1e-9 then Exit;
    if Dist < Abs(R1 - R2) - 1e-9 then Exit;
    A := (R1 * R1 - R2 * R2 + Dist * Dist) / (2 * Dist);
    Hx := C1x + Dx * A / Dist;
    Hy := C1y + Dy * A / Dist;
    Rx := -Dy / Dist;
    Ry := Dx / Dist;
    D1 := R1 * R1 - A * A;
    if D1 < 0 then D1 := 0;
    D1 := Sqrt(D1);
    Px1 := Hx + Rx * D1;
    Py1 := Hy + Ry * D1;
    Px2 := Hx - Rx * D1;
    Py2 := Hy - Ry * D1;
    D1 := Sqr(Px1 - HintX) + Sqr(Py1 - HintY);
    D2 := Sqr(Px2 - HintX) + Sqr(Py2 - HintY);
    if D1 <= D2 then begin Xi := Px1; Yi := Py1; end else begin Xi := Px2; Yi := Py2; end;
    Result := True;
end;

procedure PHFSetTrackPt(PHFT : IPCB_Track; PHFAtStart : Boolean; PHFX, PHFY : TCoord);
begin
    PHFT.BeginModify;
    if PHFAtStart then
    begin
        PHFT.X1 := PHFX; PHFT.Y1 := PHFY;
    end
    else
    begin
        PHFT.X2 := PHFX; PHFT.Y2 := PHFY;
    end;
    PHFT.EndModify;
    PHFT.GraphicallyInvalidate;
end;

procedure PHFSetArcEnd(PHFA : IPCB_Arc; PHFAtStart : Boolean; PHFX, PHFY : TCoord);
var
    Ang : Double;
begin
    Ang := PHFAtan2Deg(CoordToMMs(PHFY - PHFA.YCenter), CoordToMMs(PHFX - PHFA.XCenter));
    PHFA.BeginModify;
    if PHFAtStart then PHFA.StartAngle := Ang else PHFA.EndAngle := Ang;
    PHFA.EndModify;
    PHFA.GraphicallyInvalidate;
end;

procedure PHFJoinOff(PHFN0, PHFN1 : IPCB_Primitive; HintX, HintY : Double);
var
    Xi, Yi : Double;
    Ok : Boolean;
    T0, T1 : IPCB_Track;
    A0, A1 : IPCB_Arc;
    JX, JY : TCoord;
begin
    if (PHFN0 = nil) or (PHFN1 = nil) then Exit;
    Ok := False;
    Xi := 0; Yi := 0;
    if (PHFN0.ObjectId = eTrackObject) and (PHFN1.ObjectId = eTrackObject) then
    begin
        T0 := PHFN0; T1 := PHFN1;
        Ok := PHFIntersectLL(CoordToMMs(T0.X1), CoordToMMs(T0.Y1), CoordToMMs(T0.X2), CoordToMMs(T0.Y2),
                              CoordToMMs(T1.X1), CoordToMMs(T1.Y1), CoordToMMs(T1.X2), CoordToMMs(T1.Y2),
                              Xi, Yi);
    end
    else if (PHFN0.ObjectId = eTrackObject) and (PHFN1.ObjectId = eArcObject) then
    begin
        T0 := PHFN0; A1 := PHFN1;
        Ok := PHFIntersectLC(CoordToMMs(T0.X1), CoordToMMs(T0.Y1), CoordToMMs(T0.X2), CoordToMMs(T0.Y2),
                              CoordToMMs(A1.XCenter), CoordToMMs(A1.YCenter), CoordToMMs(A1.Radius),
                              HintX, HintY, Xi, Yi);
    end
    else if (PHFN0.ObjectId = eArcObject) and (PHFN1.ObjectId = eTrackObject) then
    begin
        A0 := PHFN0; T1 := PHFN1;
        Ok := PHFIntersectLC(CoordToMMs(T1.X1), CoordToMMs(T1.Y1), CoordToMMs(T1.X2), CoordToMMs(T1.Y2),
                              CoordToMMs(A0.XCenter), CoordToMMs(A0.YCenter), CoordToMMs(A0.Radius),
                              HintX, HintY, Xi, Yi);
    end
    else if (PHFN0.ObjectId = eArcObject) and (PHFN1.ObjectId = eArcObject) then
    begin
        A0 := PHFN0; A1 := PHFN1;
        if (Abs(A0.XCenter - A1.XCenter) < 80) and (Abs(A0.YCenter - A1.YCenter) < 80) then Exit;
        Ok := PHFIntersectCC(CoordToMMs(A0.XCenter), CoordToMMs(A0.YCenter), CoordToMMs(A0.Radius),
                              CoordToMMs(A1.XCenter), CoordToMMs(A1.YCenter), CoordToMMs(A1.Radius),
                              HintX, HintY, Xi, Yi);
    end;
    if not Ok then Exit;
    JX := MMsToCoord(Xi);
    JY := MMsToCoord(Yi);
    if PHFN0.ObjectId = eTrackObject then
        PHFSetTrackPt(PHFN0, False, JX, JY)
    else if PHFN0.ObjectId = eArcObject then
        PHFSetArcEnd(PHFN0, False, JX, JY);
    if PHFN1.ObjectId = eTrackObject then
        PHFSetTrackPt(PHFN1, True, JX, JY)
    else     if PHFN1.ObjectId = eArcObject then
        PHFSetArcEnd(PHFN1, True, JX, JY);
end;

{ Keep concentric mill arcs (same SA/EA). Snap tracks to nearest StartX/EndX. }
function PHFCoordDist(PHFX1, PHFY1, PHFX2, PHFY2 : TCoord) : Double;
begin
    Result := Sqrt(Sqr(1.0 * (PHFX2 - PHFX1)) + Sqr(1.0 * (PHFY2 - PHFY1)));
end;

procedure PHFSnapTrackToArc(PHFT : IPCB_Track; PHFAtStart : Boolean; PHFA : IPCB_Arc);
var
    TX, TY : TCoord;
    Ds, De : Double;
begin
    if PHFAtStart then begin TX := PHFT.X1; TY := PHFT.Y1; end
    else begin TX := PHFT.X2; TY := PHFT.Y2; end;
    Ds := PHFCoordDist(TX, TY, PHFA.StartX, PHFA.StartY);
    De := PHFCoordDist(TX, TY, PHFA.EndX, PHFA.EndY);
    if Ds <= De then
        PHFSetTrackPt(PHFT, PHFAtStart, PHFA.StartX, PHFA.StartY)
    else
        PHFSetTrackPt(PHFT, PHFAtStart, PHFA.EndX, PHFA.EndY);
end;

procedure PHFConnectMill(PHFN0, PHFN1 : IPCB_Primitive);
var
    T0, T1 : IPCB_Track;
    A0, A1 : IPCB_Arc;
begin
    if (PHFN0 = nil) or (PHFN1 = nil) then Exit;
    if (PHFN0.ObjectId = eTrackObject) and (PHFN1.ObjectId = eArcObject) then
    begin
        T0 := PHFN0; A1 := PHFN1;
        PHFSnapTrackToArc(T0, False, A1);
        Exit;
    end;
    if (PHFN0.ObjectId = eArcObject) and (PHFN1.ObjectId = eTrackObject) then
    begin
        A0 := PHFN0; T1 := PHFN1;
        PHFSnapTrackToArc(T1, True, A0);
        Exit;
    end;
    if (PHFN0.ObjectId = eArcObject) and (PHFN1.ObjectId = eArcObject) then
    begin
        A0 := PHFN0; A1 := PHFN1;
        if (Abs(A0.XCenter - A1.XCenter) < 80) and (Abs(A0.YCenter - A1.YCenter) < 80) then Exit;
    end;
    PHFJoinOff(PHFN0, PHFN1, 0, 0);
end;

{ Closed-chain CAD offset of BoardOutline (contour order), then translate to cell. }
procedure PHFOffsetCopiedOutline(ABoard : IPCB_Board; Col, Row : Integer; PHFALayer : TLayer);
var
    PHFi, PHFj, PHFn, PHFGuard : Integer;
    PHFSeg, PHFNxt : TPolySegment;
    Area, Dxmm, Dymm, Len, Nx, Ny, Cross : Double;
    OffLeft, Away : Boolean;
    PHFR, CX, CY, SX, SY, EX, EY, NR, Dx, Dy : TCoord;
    SA, EA : Double;
    News : TStringList;
    TN : IPCB_Track;
    AN : IPCB_Arc;
    SrcR : TCoordRect;
begin
    if PHFOffMM <= 0 then Exit;
    SrcR := PHFSourceBoard.BoardOutline.BoundingRectangle;
    Dx := PHFBoardOriginX(Col) - SrcR.Left;
    Dy := PHFBoardOriginY(Row) - SrcR.Bottom;
    try
        PHFn := PHFSourceBoard.BoardOutline.PointCount;
    except
        PHFn := 0;
    end;
    if PHFn < 2 then
    begin
        PHFAddMillTrack(ABoard, SrcR.Left + Dx - MMsToCoord(PHFOffMM), SrcR.Bottom + Dy - MMsToCoord(PHFOffMM),
                        SrcR.Right + Dx + MMsToCoord(PHFOffMM), SrcR.Bottom + Dy - MMsToCoord(PHFOffMM), PHFALayer);
        PHFAddMillTrack(ABoard, SrcR.Right + Dx + MMsToCoord(PHFOffMM), SrcR.Bottom + Dy - MMsToCoord(PHFOffMM),
                        SrcR.Right + Dx + MMsToCoord(PHFOffMM), SrcR.Top + Dy + MMsToCoord(PHFOffMM), PHFALayer);
        PHFAddMillTrack(ABoard, SrcR.Right + Dx + MMsToCoord(PHFOffMM), SrcR.Top + Dy + MMsToCoord(PHFOffMM),
                        SrcR.Left + Dx - MMsToCoord(PHFOffMM), SrcR.Top + Dy + MMsToCoord(PHFOffMM), PHFALayer);
        PHFAddMillTrack(ABoard, SrcR.Left + Dx - MMsToCoord(PHFOffMM), SrcR.Top + Dy + MMsToCoord(PHFOffMM),
                        SrcR.Left + Dx - MMsToCoord(PHFOffMM), SrcR.Bottom + Dy - MMsToCoord(PHFOffMM), PHFALayer);
        Exit;
    end;
    Area := 0;
    for PHFi := 0 to PHFn - 1 do
    begin
        PHFSeg := PHFSourceBoard.BoardOutline.Segments[PHFi];
        PHFj := PHFi + 1;
        if PHFj >= PHFn then PHFj := 0;
        PHFNxt := PHFSourceBoard.BoardOutline.Segments[PHFj];
        Area := Area + CoordToMMs(PHFSeg.vx) * CoordToMMs(PHFNxt.vy) -
                CoordToMMs(PHFNxt.vx) * CoordToMMs(PHFSeg.vy);
    end;
    { CCW (Area>0): interior is left; mill is outside = not left. Same as Offset.pas. }
    if Area > 0 then OffLeft := False else OffLeft := True;
    News := TStringList.Create;
    try
        for PHFi := 0 to PHFn - 1 do
        begin
            PHFSeg := PHFSourceBoard.BoardOutline.Segments[PHFi];
            PHFj := PHFi + 1;
            if PHFj >= PHFn then PHFj := 0;
            PHFNxt := PHFSourceBoard.BoardOutline.Segments[PHFj];
            PHFR := 0;
            try PHFR := PHFSeg.Radius; except PHFR := 0; end;
            CX := 0; CY := 0; SA := 0; EA := 0;
            try
                CX := PHFSeg.cx;
                CY := PHFSeg.cy;
                SA := PHFSeg.Angle1;
                EA := PHFSeg.Angle2;
            except
                CX := 0;
            end;
            if (PHFR > 1) and ((CX <> 0) or (CY <> 0)) then
            begin
                SX := PHFSeg.vx;
                SY := PHFSeg.vy;
                EX := PHFNxt.vx;
                EY := PHFNxt.vy;
                Cross := CoordToMMs(EX - SX) * CoordToMMs(CY - SY) -
                         CoordToMMs(EY - SY) * CoordToMMs(CX - SX);
                if Cross > 0 then Away := not OffLeft else Away := OffLeft;
                if Away then
                    NR := PHFR + MMsToCoord(PHFOffMM)
                else
                    NR := PHFR - MMsToCoord(PHFOffMM);
                if NR < 1 then
                    News.AddObject('N', nil)
                else
                begin
                    AN := PHFAddMillArc(ABoard, CX + Dx, CY + Dy, NR, SA, EA, PHFALayer);
                    News.AddObject('A', AN);
                end;
            end
            else
            begin
                Dxmm := CoordToMMs(PHFNxt.vx - PHFSeg.vx);
                Dymm := CoordToMMs(PHFNxt.vy - PHFSeg.vy);
                Len := Sqrt(Dxmm * Dxmm + Dymm * Dymm);
                if Len < 0.0001 then
                    News.AddObject('N', nil)
                else
                begin
                    Nx := -Dymm / Len;
                    Ny := Dxmm / Len;
                    if not OffLeft then
                    begin
                        Nx := -Nx;
                        Ny := -Ny;
                    end;
                    TN := PHFAddMillTrack(ABoard,
                        PHFSeg.vx + Dx + MMsToCoord(Nx * PHFOffMM),
                        PHFSeg.vy + Dy + MMsToCoord(Ny * PHFOffMM),
                        PHFNxt.vx + Dx + MMsToCoord(Nx * PHFOffMM),
                        PHFNxt.vy + Dy + MMsToCoord(Ny * PHFOffMM),
                        PHFALayer);
                    News.AddObject('T', TN);
                end;
            end;
        end;
        { Join consecutive mill pieces, skipping collapsed (nil) inner arcs. }
        for PHFi := 0 to News.Count - 1 do
        begin
            if News.Objects[PHFi] = nil then Continue;
            PHFj := PHFi + 1;
            if PHFj >= News.Count then PHFj := 0;
            PHFGuard := 0;
            while (News.Objects[PHFj] = nil) and (PHFj <> PHFi) and (PHFGuard < News.Count + 2) do
            begin
                Inc(PHFGuard);
                PHFj := PHFj + 1;
                if PHFj >= News.Count then PHFj := 0;
            end;
            if (PHFj <> PHFi) and (News.Objects[PHFj] <> nil) then
                PHFConnectMill(News.Objects[PHFi], News.Objects[PHFj]);
        end;
    finally
        News.Free;
    end;
end;

procedure PHFNearestBoardCenter(PHFX, PHFY : TCoord; var CX, CY : TCoord);
var
    r, c : Integer;
    BX, BY, Best, D : Double;
begin
    CX := PHFBoardOriginX(0) + MMsToCoord(PHFBoardW / 2);
    CY := PHFBoardOriginY(0) + MMsToCoord(PHFBoardH / 2);
    Best := 1e100;
    for r := 0 to PHFRows - 1 do
        for c := 0 to PHFCols - 1 do
        begin
            BX := CoordToMMs(PHFBoardOriginX(c)) + PHFBoardW / 2;
            BY := CoordToMMs(PHFBoardOriginY(r)) + PHFBoardH / 2;
            D := Sqr(BX - CoordToMMs(PHFX)) + Sqr(BY - CoordToMMs(PHFY));
            if D < Best then
            begin
                Best := D;
                CX := MMsToCoord(BX);
                CY := MMsToCoord(BY);
            end;
        end;
end;

procedure PHFPunchOneTrack(ABoard : IPCB_Board; T : IPCB_Track; PHFALayer : TLayer);
var
    DX, DY, Len : Double;
    X0, Y0, X1, Y1, RR, Neck, Half, Pos, A, B, Prev, PHFSpan : TCoord;
    CX, CY, MX, MY : TCoord;
    NTabs, Ti : Integer;
    Horiz, WastePos : Boolean;
begin
    if T = nil then Exit;
    DX := CoordToMMs(T.X2 - T.X1);
    DY := CoordToMMs(T.Y2 - T.Y1);
    Len := Sqrt(DX * DX + DY * DY);
    if Len < 0.2 then Exit;
    { Tabs only on long axis-aligned edges, not diagonals or fillets. }
    if (Abs(DX) > 0.3) and (Abs(DY) > 0.3) then Exit;
    Horiz := Abs(DX) >= Abs(DY);
    if Horiz then NTabs := PHFTabCountH else NTabs := PHFTabCountV;
    if NTabs < 1 then NTabs := 1;
    RR := MMsToCoord(PHFFilletR);
    if RR < 1 then RR := 1;
    Neck := MMsToCoord(PHFTabW);
    if Neck < 1 then Neck := 1;
    Half := (Neck div 2) + RR;
    PHFSpan := MMsToCoord(Len);
    if PHFSpan < (Half + Half) * NTabs then Exit;
    MX := (T.X1 + T.X2) div 2;
    MY := (T.Y1 + T.Y2) div 2;
    PHFNearestBoardCenter(MX, MY, CX, CY);
    if Horiz then
    begin
        if T.X1 <= T.X2 then
        begin
            X0 := T.X1; Y0 := T.Y1; X1 := T.X2; Y1 := T.Y2;
        end
        else
        begin
            X0 := T.X2; Y0 := T.Y2; X1 := T.X1; Y1 := T.Y1;
        end;
        WastePos := CY < MY;
        Prev := X0;
        for Ti := 1 to NTabs do
        begin
            if NTabs = 1 then
                Pos := (X0 + X1) div 2
            else
                Pos := X0 + ((X1 - X0) * (2 * Ti - 1)) div (2 * NTabs);
            A := Pos - Half;
            B := Pos + Half;
            if A < X0 then A := X0;
            if B > X1 then B := X1;
            if A > Prev then
                PHFAddTrack(ABoard, Prev, Y0, A, Y0, PHFALayer);
            if WastePos then
            begin
                PHFAddArc(ABoard, A, Y0, RR, 0, 180, PHFALayer);
                PHFAddArc(ABoard, B, Y0, RR, 0, 180, PHFALayer);
            end
            else
            begin
                PHFAddArc(ABoard, A, Y0, RR, 180, 0, PHFALayer);
                PHFAddArc(ABoard, B, Y0, RR, 180, 0, PHFALayer);
            end;
            Prev := B;
        end;
        if Prev < X1 then
            PHFAddTrack(ABoard, Prev, Y0, X1, Y1, PHFALayer);
    end
    else
    begin
        if T.Y1 <= T.Y2 then
        begin
            X0 := T.X1; Y0 := T.Y1; X1 := T.X2; Y1 := T.Y2;
        end
        else
        begin
            X0 := T.X2; Y0 := T.Y2; X1 := T.X1; Y1 := T.Y1;
        end;
        WastePos := CX < MX;
        Prev := Y0;
        for Ti := 1 to NTabs do
        begin
            if NTabs = 1 then
                Pos := (Y0 + Y1) div 2
            else
                Pos := Y0 + ((Y1 - Y0) * (2 * Ti - 1)) div (2 * NTabs);
            A := Pos - Half;
            B := Pos + Half;
            if A < Y0 then A := Y0;
            if B > Y1 then B := Y1;
            if A > Prev then
                PHFAddTrack(ABoard, X0, Prev, X0, A, PHFALayer);
            if WastePos then
            begin
                PHFAddArc(ABoard, X0, A, RR, 90, 270, PHFALayer);
                PHFAddArc(ABoard, X0, B, RR, 90, 270, PHFALayer);
            end
            else
            begin
                PHFAddArc(ABoard, X0, A, RR, 270, 90, PHFALayer);
                PHFAddArc(ABoard, X0, B, RR, 270, 90, PHFALayer);
            end;
            Prev := B;
        end;
        if Prev < Y1 then
            PHFAddTrack(ABoard, X0, Prev, X1, Y1, PHFALayer);
    end;
    ABoard.BeginModify;
    ABoard.RemovePCBObject(T);
    ABoard.EndModify;
end;

procedure PHFPunchAllTabs(ABoard : IPCB_Board; PHFALayer : TLayer);
var
    PHFIter : IPCB_BoardIterator;
    PHFPrim : IPCB_Primitive;
    Tracks : TStringList;
    PHFi : Integer;
begin
    Tracks := TStringList.Create;
    PHFIter := ABoard.BoardIterator_Create;
    PHFIter.AddFilter_ObjectSet(MkSet(eTrackObject));
    PHFIter.AddFilter_LayerSet(MkSet(PHFALayer));
    PHFIter.AddFilter_Method(eProcessAll);
    PHFPrim := PHFIter.FirstPCBObject;
    while PHFPrim <> nil do
    begin
        Tracks.AddObject('T', PHFPrim);
        PHFPrim := PHFIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PHFIter);
    for PHFi := 0 to Tracks.Count - 1 do
        PHFPunchOneTrack(ABoard, Tracks.Objects[PHFi], PHFALayer);
    Tracks.Free;
end;

function PHFInAlley(PHFX, PHFY : TCoord) : Boolean;
var
    r, c : Integer;
    L, B, Rgt, Tp, Gx, Gy, Pad : TCoord;
begin
    Result := False;
    Gx := MMsToCoord(PHFGapX);
    Gy := MMsToCoord(PHFGapY);
    Pad := MMsToCoord(PHFOffMM) + MMsToCoord(0.2);
    for r := 0 to PHFRows - 1 do
        for c := 0 to PHFCols - 2 do
        begin
            L := PHFBoardOriginX(c) + MMsToCoord(PHFBoardW);
            B := PHFBoardOriginY(r);
            Tp := B + MMsToCoord(PHFBoardH);
            if (PHFX >= L - Pad) and (PHFX <= L + Gx + Pad) and
               (PHFY >= B + Pad) and (PHFY <= Tp - Pad) then
            begin
                Result := True;
                Exit;
            end;
        end;
    for r := 0 to PHFRows - 2 do
        for c := 0 to PHFCols - 1 do
        begin
            L := PHFBoardOriginX(c);
            Rgt := L + MMsToCoord(PHFBoardW);
            B := PHFBoardOriginY(r) + MMsToCoord(PHFBoardH);
            if (PHFY >= B - Pad) and (PHFY <= B + Gy + Pad) and
               (PHFX >= L + Pad) and (PHFX <= Rgt - Pad) then
            begin
                Result := True;
                Exit;
            end;
        end;
end;

procedure PHFDeleteCoincident(ABoard : IPCB_Board; PHFALayer : TLayer);
var
    PHFIter : IPCB_BoardIterator;
    PHFPrim : IPCB_Primitive;
    Tracks : TStringList;
    PHFi, PHFj : Integer;
    T0, T1 : IPCB_Track;
    Kill : TStringList;
    Tol, MergeD : TCoord;
    DX0, DY0, DX1, DY1, L0, L1, Dot, MX, MY : Double;
begin
    Tracks := TStringList.Create;
    Kill := TStringList.Create;
    Tol := MMsToCoord(0.05);
    MergeD := MMsToCoord(PHFOffMM * 2);
    if MergeD < Tol then MergeD := Tol;
    PHFIter := ABoard.BoardIterator_Create;
    PHFIter.AddFilter_ObjectSet(MkSet(eTrackObject));
    PHFIter.AddFilter_LayerSet(MkSet(PHFALayer));
    PHFIter.AddFilter_Method(eProcessAll);
    PHFPrim := PHFIter.FirstPCBObject;
    while PHFPrim <> nil do
    begin
        Tracks.AddObject('T', PHFPrim);
        PHFPrim := PHFIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PHFIter);
    for PHFi := 0 to Tracks.Count - 1 do
    begin
        if Kill.IndexOf(IntToStr(PHFi)) >= 0 then Continue;
        T0 := Tracks.Objects[PHFi];
        for PHFj := PHFi + 1 to Tracks.Count - 1 do
        begin
            if Kill.IndexOf(IntToStr(PHFj)) >= 0 then Continue;
            T1 := Tracks.Objects[PHFj];
            if ((Abs(T0.X1 - T1.X1) < Tol) and (Abs(T0.Y1 - T1.Y1) < Tol) and
                (Abs(T0.X2 - T1.X2) < Tol) and (Abs(T0.Y2 - T1.Y2) < Tol)) or
               ((Abs(T0.X1 - T1.X2) < Tol) and (Abs(T0.Y1 - T1.Y2) < Tol) and
                (Abs(T0.X2 - T1.X1) < Tol) and (Abs(T0.Y2 - T1.Y1) < Tol)) then
            begin
                Kill.Add(IntToStr(PHFj));
                Continue;
            end;
            { Parallel mills in a shared alley -> one slot. }
            DX0 := CoordToMMs(T0.X2 - T0.X1);
            DY0 := CoordToMMs(T0.Y2 - T0.Y1);
            DX1 := CoordToMMs(T1.X2 - T1.X1);
            DY1 := CoordToMMs(T1.Y2 - T1.Y1);
            L0 := Sqrt(DX0 * DX0 + DY0 * DY0);
            L1 := Sqrt(DX1 * DX1 + DY1 * DY1);
            if (L0 < 0.05) or (L1 < 0.05) then Continue;
            Dot := Abs((DX0 * DX1 + DY0 * DY1) / (L0 * L1));
            if Dot < 0.95 then Continue;
            MX := CoordToMMs(((T0.X1 + T0.X2) div 2) - ((T1.X1 + T1.X2) div 2));
            MY := CoordToMMs(((T0.Y1 + T0.Y2) div 2) - ((T1.Y1 + T1.Y2) div 2));
            if Sqrt(MX * MX + MY * MY) > CoordToMMs(MergeD) then Continue;
            if not PHFInAlley((T0.X1 + T0.X2) div 2, (T0.Y1 + T0.Y2) div 2) then Continue;
            if not PHFInAlley((T1.X1 + T1.X2) div 2, (T1.Y1 + T1.Y2) div 2) then Continue;
            Kill.Add(IntToStr(PHFj));
        end;
    end;
    for PHFi := 0 to Kill.Count - 1 do
    begin
        T1 := Tracks.Objects[StrToInt(Kill[PHFi])];
        ABoard.BeginModify;
        ABoard.RemovePCBObject(T1);
        ABoard.EndModify;
    end;
    Tracks.Free;
    Kill.Free;
end;

function PHFMillEnds(PHFP : IPCB_Primitive; var X1, Y1, X2, Y2 : TCoord) : Boolean;
begin
    Result := False;
    if PHFP = nil then Exit;
    if PHFP.ObjectId = eTrackObject then
    begin
        X1 := PHFP.X1; Y1 := PHFP.Y1; X2 := PHFP.X2; Y2 := PHFP.Y2;
        Result := True;
    end
    else if PHFP.ObjectId = eArcObject then
    begin
        X1 := PHFP.StartX; Y1 := PHFP.StartY; X2 := PHFP.EndX; Y2 := PHFP.EndY;
        Result := True;
    end;
end;

procedure PHFBestMillEnd(ABoard : IPCB_Board; PHFALayer : TLayer;
    TX, TY, XLo, XHi, YLo, YHi : TCoord; var BX, BY : TCoord; var Found : Boolean);
var
    PHFIter : IPCB_BoardIterator;
    PHFP : IPCB_Primitive;
    X1, Y1, X2, Y2 : TCoord;
    D, Best : Double;
begin
    Found := False;
    Best := 1e100;
    BX := TX; BY := TY;
    PHFIter := ABoard.BoardIterator_Create;
    PHFIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    PHFIter.AddFilter_LayerSet(MkSet(PHFALayer));
    PHFIter.AddFilter_Method(eProcessAll);
    PHFP := PHFIter.FirstPCBObject;
    while PHFP <> nil do
    begin
        if PHFMillEnds(PHFP, X1, Y1, X2, Y2) then
        begin
            if (X1 >= XLo) and (X1 <= XHi) and (Y1 >= YLo) and (Y1 <= YHi) then
            begin
                D := PHFCoordDist(X1, Y1, TX, TY);
                if (not Found) or (D < Best) then
                begin
                    Best := D; BX := X1; BY := Y1; Found := True;
                end;
            end;
            if (X2 >= XLo) and (X2 <= XHi) and (Y2 >= YLo) and (Y2 <= YHi) then
            begin
                D := PHFCoordDist(X2, Y2, TX, TY);
                if (not Found) or (D < Best) then
                begin
                    Best := D; BX := X2; BY := Y2; Found := True;
                end;
            end;
        end;
        PHFP := PHFIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PHFIter);
end;

procedure PHFTryTBar(ABoard : IPCB_Board; PHFALayer : TLayer;
    TX0, TY0, TX1, TY1, XLo, XHi, YLo, YHi, MaxD : TCoord);
var
    Xa, Ya, Xb, Yb : TCoord;
    Fa, Fb : Boolean;
begin
    PHFBestMillEnd(ABoard, PHFALayer, TX0, TY0, XLo, XHi, YLo, YHi, Xa, Ya, Fa);
    PHFBestMillEnd(ABoard, PHFALayer, TX1, TY1, XLo, XHi, YLo, YHi, Xb, Yb, Fb);
    if not (Fa and Fb) then Exit;
    if PHFCoordDist(Xa, Ya, Xb, Yb) < 2 then Exit;
    if PHFCoordDist(Xa, Ya, Xb, Yb) > MaxD then Exit;
    PHFAddMillTrack(ABoard, Xa, Ya, Xb, Yb, PHFALayer);
end;

{ T-pockets: join neighbor OUTER mill walls across the alley, not the frame. }
procedure PHFJoinOuterTPockets(ABoard : IPCB_Board; PHFALayer : TLayer);
var
    c, r : Integer;
    OffC, Gx, Gy, MaxD, Ax0, Ax1, Ay0, Ay1 : TCoord;
    L0, B0, R1, T1, Box : TCoord;
begin
    OffC := MMsToCoord(PHFOffMM);
    Gx := MMsToCoord(PHFGapX);
    Gy := MMsToCoord(PHFGapY);
    MaxD := Gx + OffC + OffC + MMsToCoord(4);
    Box := OffC + MMsToCoord(4);
    L0 := PHFBoardOriginX(0);
    B0 := PHFBoardOriginY(0);
    R1 := PHFBoardOriginX(PHFCols - 1) + MMsToCoord(PHFBoardW);
    T1 := PHFBoardOriginY(PHFRows - 1) + MMsToCoord(PHFBoardH);

    for c := 0 to PHFCols - 2 do
    begin
        Ax0 := PHFBoardOriginX(c) + MMsToCoord(PHFBoardW);
        Ax1 := PHFBoardOriginX(c + 1);
        { South outer walls of row 0, across alley — not into the frame. }
        PHFTryTBar(ABoard, PHFALayer,
            Ax0, B0 - OffC, Ax1, B0 - OffC,
            Ax0 - Box, Ax1 + Box, B0 - Box - OffC, B0 + Box, MaxD);
        { North outer walls of last row. }
        PHFTryTBar(ABoard, PHFALayer,
            Ax0, T1 + OffC, Ax1, T1 + OffC,
            Ax0 - Box, Ax1 + Box, T1 - Box, T1 + Box + OffC, MaxD);
    end;
    for r := 0 to PHFRows - 2 do
    begin
        Ay0 := PHFBoardOriginY(r) + MMsToCoord(PHFBoardH);
        Ay1 := PHFBoardOriginY(r + 1);
        MaxD := Gy + OffC + OffC + MMsToCoord(4);
        PHFTryTBar(ABoard, PHFALayer,
            L0 - OffC, Ay0, L0 - OffC, Ay1,
            L0 - Box - OffC, L0 + Box, Ay0 - Box, Ay1 + Box, MaxD);
        PHFTryTBar(ABoard, PHFALayer,
            R1 + OffC, Ay0, R1 + OffC, Ay1,
            R1 - Box, R1 + Box + OffC, Ay0 - Box, Ay1 + Box, MaxD);
    end;
end;

function PHFEndConnected(ABoard : IPCB_Board; PHFALayer : TLayer;
    Skip : IPCB_Primitive; PX, PY, Tol : TCoord) : Boolean;
var
    PHFIter : IPCB_BoardIterator;
    PHFP : IPCB_Primitive;
    X1, Y1, X2, Y2 : TCoord;
begin
    Result := False;
    PHFIter := ABoard.BoardIterator_Create;
    PHFIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    PHFIter.AddFilter_LayerSet(MkSet(PHFALayer));
    PHFIter.AddFilter_Method(eProcessAll);
    PHFP := PHFIter.FirstPCBObject;
    while PHFP <> nil do
    begin
        if PHFP <> Skip then
            if PHFMillEnds(PHFP, X1, Y1, X2, Y2) then
                if (PHFCoordDist(PX, PY, X1, Y1) <= Tol) or
                   (PHFCoordDist(PX, PY, X2, Y2) <= Tol) then
                begin
                    Result := True;
                    Break;
                end;
        PHFP := PHFIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PHFIter);
end;

procedure PHFDeleteDangling(ABoard : IPCB_Board; PHFALayer : TLayer);
var
    Pass, PHFi : Integer;
    PHFIter : IPCB_BoardIterator;
    PHFP : IPCB_Primitive;
    Kill : TStringList;
    X1, Y1, X2, Y2 : TCoord;
    Tol, MinLen : Double;
    Hit1, Hit2 : Boolean;
begin
    Tol := MMsToCoord(0.15);
    MinLen := MMsToCoord(0.05);
    for Pass := 1 to 6 do
    begin
        Kill := TStringList.Create;
        PHFIter := ABoard.BoardIterator_Create;
        PHFIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
        PHFIter.AddFilter_LayerSet(MkSet(PHFALayer));
        PHFIter.AddFilter_Method(eProcessAll);
        PHFP := PHFIter.FirstPCBObject;
        while PHFP <> nil do
        begin
            if PHFMillEnds(PHFP, X1, Y1, X2, Y2) then
            begin
                if (PHFP.ObjectId = eTrackObject) and (PHFCoordDist(X1, Y1, X2, Y2) < MinLen) then
                    Kill.AddObject('K', PHFP)
                else
                begin
                    Hit1 := PHFEndConnected(ABoard, PHFALayer, PHFP, X1, Y1, Tol);
                    Hit2 := PHFEndConnected(ABoard, PHFALayer, PHFP, X2, Y2, Tol);
                    if (not Hit1) or (not Hit2) then
                        Kill.AddObject('K', PHFP);
                end;
            end;
            PHFP := PHFIter.NextPCBObject;
        end;
        ABoard.BoardIterator_Destroy(PHFIter);
        if Kill.Count = 0 then
        begin
            Kill.Free;
            Exit;
        end;
        for PHFi := 0 to Kill.Count - 1 do
        begin
            ABoard.BeginModify;
            ABoard.RemovePCBObject(Kill.Objects[PHFi]);
            ABoard.EndModify;
        end;
        Kill.Free;
    end;
end;

procedure PHFDrawRoundedRect(ABoard : IPCB_Board; PHFX0, PHFY0, PanX1, PanY1, PHFR : TCoord; PanALayer : TLayer);
begin
    if PHFR <= 0 then
    begin
        PHFAddTrack(ABoard, PHFX0, PHFY0, PanX1, PHFY0, PanALayer);
        PHFAddTrack(ABoard, PanX1, PHFY0, PanX1, PanY1, PanALayer);
        PHFAddTrack(ABoard, PanX1, PanY1, PHFX0, PanY1, PanALayer);
        PHFAddTrack(ABoard, PHFX0, PanY1, PHFX0, PHFY0, PanALayer);
        Exit;
    end;
    PHFAddTrack(ABoard, PHFX0 + PHFR, PHFY0, PanX1 - PHFR, PHFY0, PanALayer);
    PHFAddTrack(ABoard, PanX1, PHFY0 + PHFR, PanX1, PanY1 - PHFR, PanALayer);
    PHFAddTrack(ABoard, PanX1 - PHFR, PanY1, PHFX0 + PHFR, PanY1, PanALayer);
    PHFAddTrack(ABoard, PHFX0, PanY1 - PHFR, PHFX0, PHFY0 + PHFR, PanALayer);
    PHFAddArc(ABoard, PHFX0 + PHFR, PHFY0 + PHFR, PHFR, 180, 270, PanALayer);
    PHFAddArc(ABoard, PanX1 - PHFR, PHFY0 + PHFR, PHFR, 270, 0, PanALayer);
    PHFAddArc(ABoard, PanX1 - PHFR, PanY1 - PHFR, PHFR, 0, 90, PanALayer);
    PHFAddArc(ABoard, PHFX0 + PHFR, PanY1 - PHFR, PHFR, 90, 180, PanALayer);
end;

{ Example_Panelizer: один паз ширины Gap (обе стенки + dogbone).
  Вертикальный проём (соседи слева-справа): 2 перемычки на 1/4 и 3/4.
  Горизонтальный проём (соседи снизу-сверху) и юг/север рамки: 1 перемычка в центре.
  Шея = PHFTabW, R dogbone = PHFFilletR (не больше Gap/2). Внешних луковиц нет. }
procedure PHFDrawSlotV(ABoard : IPCB_Board; X0, X1, Y0, Y1 : TCoord; NTabs : Integer; PanALayer : TLayer);
var
    RR, Neck, Half, MidX, PHFSlotSpan, Yc, Ya, Yb, Yprev : TCoord;
    Ti : Integer;
begin
    if (X1 <= X0) or (Y1 <= Y0) then Exit;
    RR := MMsToCoord(PHFFilletR);
    if RR > ((X1 - X0) div 2) then RR := (X1 - X0) div 2;
    if RR < 1 then RR := 1;
    Neck := MMsToCoord(PHFTabW);
    if Neck < 1 then Neck := 1;
    Half := (Neck div 2) + RR;
    MidX := (X0 + X1) div 2;
    PHFSlotSpan := Y1 - Y0;
    if NTabs < 1 then NTabs := 1;
    if PHFSlotSpan < (Half + Half) * NTabs then
    begin
        PHFAddTrack(ABoard, X0, Y0, X0, Y1, PanALayer);
        PHFAddTrack(ABoard, X1, Y0, X1, Y1, PanALayer);
        Exit;
    end;
    Yprev := Y0;
    for Ti := 1 to NTabs do
    begin
        if NTabs = 1 then
            Yc := (Y0 + Y1) div 2
        else
            Yc := Y0 + (PHFSlotSpan * (2 * Ti - 1)) div (2 * NTabs);
        Ya := Yc - Half;
        Yb := Yc + Half;
        if Ya < Y0 then Ya := Y0;
        if Yb > Y1 then Yb := Y1;
        if Ya > Yprev then
        begin
            PHFAddTrack(ABoard, X0, Yprev, X0, Ya, PanALayer);
            PHFAddTrack(ABoard, X1, Yprev, X1, Ya, PanALayer);
        end;
        PHFAddArc(ABoard, MidX, Ya, RR, 0, 180, PanALayer);
        PHFAddArc(ABoard, MidX, Yb, RR, 180, 0, PanALayer);
        Yprev := Yb;
    end;
    if Yprev < Y1 then
    begin
        PHFAddTrack(ABoard, X0, Yprev, X0, Y1, PanALayer);
        PHFAddTrack(ABoard, X1, Yprev, X1, Y1, PanALayer);
    end;
end;

procedure PHFDrawSlotH(ABoard : IPCB_Board; Y0, Y1, X0, X1 : TCoord; NTabs : Integer; PanALayer : TLayer);
var
    RR, Neck, Half, MidY, PHFSlotSpan, Xc, Xa, Xb, Xprev : TCoord;
    Ti : Integer;
begin
    if (Y1 <= Y0) or (X1 <= X0) then Exit;
    RR := MMsToCoord(PHFFilletR);
    if RR > ((Y1 - Y0) div 2) then RR := (Y1 - Y0) div 2;
    if RR < 1 then RR := 1;
    Neck := MMsToCoord(PHFTabW);
    if Neck < 1 then Neck := 1;
    Half := (Neck div 2) + RR;
    MidY := (Y0 + Y1) div 2;
    PHFSlotSpan := X1 - X0;
    if NTabs < 1 then NTabs := 1;
    if PHFSlotSpan < (Half + Half) * NTabs then
    begin
        PHFAddTrack(ABoard, X0, Y0, X1, Y0, PanALayer);
        PHFAddTrack(ABoard, X0, Y1, X1, Y1, PanALayer);
        Exit;
    end;
    Xprev := X0;
    for Ti := 1 to NTabs do
    begin
        if NTabs = 1 then
            Xc := (X0 + X1) div 2
        else
            Xc := X0 + (PHFSlotSpan * (2 * Ti - 1)) div (2 * NTabs);
        Xa := Xc - Half;
        Xb := Xc + Half;
        if Xa < X0 then Xa := X0;
        if Xb > X1 then Xb := X1;
        if Xa > Xprev then
        begin
            PHFAddTrack(ABoard, Xprev, Y0, Xa, Y0, PanALayer);
            PHFAddTrack(ABoard, Xprev, Y1, Xa, Y1, PanALayer);
        end;
        PHFAddArc(ABoard, Xa, MidY, RR, 270, 90, PanALayer);
        PHFAddArc(ABoard, Xb, MidY, RR, 90, 270, PanALayer);
        Xprev := Xb;
    end;
    if Xprev < X1 then
    begin
        PHFAddTrack(ABoard, Xprev, Y0, X1, Y0, PanALayer);
        PHFAddTrack(ABoard, Xprev, Y1, X1, Y1, PanALayer);
    end;
end;

function PHFBoardCornerR : TCoord;
var
    PHFi, PHFn : Integer;
    PHFSeg : TPolySegment;
    PHFR : TCoord;
begin
    Result := 0;
    if PHFSourceBoard = nil then Exit;
    try
        PHFn := PHFSourceBoard.BoardOutline.PointCount;
        for PHFi := 0 to PHFn - 1 do
        begin
            PHFSeg := PHFSourceBoard.BoardOutline.Segments[PHFi];
            PHFR := 0;
            try PHFR := PHFSeg.Radius; except PHFR := 0; end;
            if PHFR > Result then Result := PHFR;
        end;
    except
        Result := 0;
    end;
end;

procedure PHFDrawBoardCornerArcs(ABoard : IPCB_Board; L, B, Rgt, Tp, CR : TCoord; PanALayer : TLayer);
begin
    if CR < 1 then Exit;
    PHFAddArc(ABoard, L + CR, B + CR, CR, 180, 270, PanALayer);
    PHFAddArc(ABoard, Rgt - CR, B + CR, CR, 270, 0, PanALayer);
    PHFAddArc(ABoard, Rgt - CR, Tp - CR, CR, 0, 90, PanALayer);
    PHFAddArc(ABoard, L + CR, Tp - CR, CR, 90, 180, PanALayer);
end;

procedure PHFDrawAllMillPaths(ABoard : IPCB_Board; PanALayer : TLayer);
var
    r, c : Integer;
begin
    { One closed offset loop per board from BoardOutline chain (not bbox). }
    PHFHaveMill := False;
    for r := 0 to PHFRows - 1 do
        for c := 0 to PHFCols - 1 do
            PHFOffsetCopiedOutline(ABoard, c, r, PanALayer);

    { Shared alleys: coincident parallel offset mills collapse to one slot. }
    PHFDeleteCoincident(ABoard, PanALayer);
    { Drop unjoined construction leftovers before tabs. }
    PHFDeleteDangling(ABoard, PanALayer);
    { Tabs = inward dogbones on long straight mill edges only. }
    PHFPunchAllTabs(ABoard, PanALayer);
    { T-pockets join neighbor outer walls to each other, not the frame. }
    PHFJoinOuterTPockets(ABoard, PanALayer);
end;

procedure PHFFrameRect(var X0, Y0, X1, Y1 : TCoord);
begin
    { Frame = bbox of offset mill outlines + margin. }
    if PHFHaveMill then
    begin
        X0 := PHFMillMinX - MMsToCoord(PHFMargin);
        Y0 := PHFMillMinY - MMsToCoord(PHFMargin);
        X1 := PHFMillMaxX + MMsToCoord(PHFMargin);
        Y1 := PHFMillMaxY + MMsToCoord(PHFMargin);
    end
    else
    begin
        X0 := PHFBoardOriginX(0) - MMsToCoord(PHFMargin);
        Y0 := PHFBoardOriginY(0) - MMsToCoord(PHFMargin);
        X1 := PHFBoardOriginX(PHFCols - 1) + MMsToCoord(PHFBoardW) + MMsToCoord(PHFMargin);
        Y1 := PHFBoardOriginY(PHFRows - 1) + MMsToCoord(PHFBoardH) + MMsToCoord(PHFMargin);
    end;
end;

{ Рамка: bbox массива плат + поле (PHFMargin) с каждой стороны. }
procedure PHFDrawCommonOuterContour(ABoard : IPCB_Board; PanALayer : TLayer);
var
    X0, Y0, X1, Y1 : TCoord;
    T : IPCB_Track;
begin
    PHFFrameRect(X0, Y0, X1, Y1);
    T := PHFAddTrack(ABoard, X0, Y0, X1, Y0, PanALayer); T.Selected := True;
    T := PHFAddTrack(ABoard, X1, Y0, X1, Y1, PanALayer); T.Selected := True;
    T := PHFAddTrack(ABoard, X1, Y1, X0, Y1, PanALayer); T.Selected := True;
    T := PHFAddTrack(ABoard, X0, Y1, X0, Y0, PanALayer); T.Selected := True;
end;

procedure PHFPlaceFiducials(ABoard : IPCB_Board);
var
    X0, Y0, X1, Y1, Inset, PX, PY, Sz : TCoord;
    Pad : IPCB_Pad;
begin
    PHFFrameRect(X0, Y0, X1, Y1);
    Inset := MMsToCoord(PHFMargin / 2);
    Sz := MMsToCoord(1.5);

    PX := PHFSnap1mm(X0 + Inset);
    PY := PHFSnap1mm(Y0 + Inset);
    Pad := PCBServer.PCBObjectFactory(ePadObject, eNoDimension, eCreate_Default);
    Pad.Layer := eTopLayer;
    Pad.X := PX;
    Pad.Y := PY;
    Pad.TopXSize := Sz;
    Pad.TopYSize := Sz;
    Pad.HoleSize := 0;
    try Pad.SetState_HoleSize(0); except end;
    try Pad.Mode := ePadMode_Simple; except end;
    try Pad.TopShape := eRounded; except end;
    try Pad.SetState_SolderMaskExpansion(0); except end;
    try Pad.Cache.SolderMaskExpansion := 0; except end;
    ABoard.AddPCBObject(Pad);

    PX := PHFSnap1mm(X1 - Inset);
    PY := PHFSnap1mm(Y1 - Inset);
    Pad := PCBServer.PCBObjectFactory(ePadObject, eNoDimension, eCreate_Default);
    Pad.Layer := eTopLayer;
    Pad.X := PX;
    Pad.Y := PY;
    Pad.TopXSize := Sz;
    Pad.TopYSize := Sz;
    Pad.HoleSize := 0;
    try Pad.SetState_HoleSize(0); except end;
    try Pad.Mode := ePadMode_Simple; except end;
    try Pad.TopShape := eRounded; except end;
    try Pad.SetState_SolderMaskExpansion(0); except end;
    try Pad.Cache.SolderMaskExpansion := 0; except end;
    ABoard.AddPCBObject(Pad);
end;

function PHFBoardOriginX(Col : Integer) : TCoord;
begin
    Result := MMsToCoord(PHFMargin + Col * (PHFBoardW + PHFGapX));
end;

function PHFBoardOriginY(Row : Integer) : TCoord;
begin
    Result := MMsToCoord(PHFMargin + Row * (PHFBoardH + PHFGapY));
end;

procedure PHFPlaceEmbeddedArray(ABoard : IPCB_Board);
var
    Emb : IPCB_EmbeddedBoard;
    PHFX0, PHFY0 : TCoord;
begin
    Emb := PCBServer.PCBObjectFactory(eEmbeddedBoardObject, eNoDimension, eCreate_Default);
    Emb.DocumentPath := PHFSourcePath;
    Emb.RowCount := PHFRows;
    Emb.ColCount := PHFCols;
    Emb.ColSpacing := MMsToCoord(PHFBoardW + PHFGapX);
    Emb.RowSpacing := MMsToCoord(PHFBoardH + PHFGapY);
    PHFX0 := PHFBoardOriginX(0);
    PHFY0 := PHFBoardOriginY(0);
    Emb.XLocation := PHFX0;
    Emb.YLocation := PHFY0;
    ABoard.AddPCBObject(Emb);
end;

procedure PHFShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

procedure PHFApplyOutline(ABoard : IPCB_Board);
begin
    { Рамка уже выделена в PHFDrawCommonOuterContour. }
    ResetParameters;
    AddStringParameter('MODE', 'BOARDOUTLINE_FROM_SEL_PRIMS');
    RunProcess('PCB:PlaceBoardOutline');
    ResetParameters;
    AddStringParameter('Scope', 'All');
    RunProcess('PCB:DeSelect');
end;

procedure PHFBuildPanel;
var
    PHFWS : IWorkspace;
    PHFRect : TCoordRect;
begin
    PHFRect := PHFSourceBoard.BoardOutline.BoundingRectangle;
    PHFBoardW := CoordToMMs(PHFRect.Right - PHFRect.Left);
    PHFBoardH := CoordToMMs(PHFRect.Top - PHFRect.Bottom);
    if (PHFBoardW <= 0) or (PHFBoardH <= 0) then
    begin
        PHFShowBox(LabelErrSize.Caption, 16);
        Exit;
    end;

    PHFPanelW := PHFMargin * 2 + PHFCols * PHFBoardW + (PHFCols - 1) * PHFGapX;
    PHFPanelH := PHFMargin * 2 + PHFRows * PHFBoardH + (PHFRows - 1) * PHFGapY;
    PHFLineW := MMsToCoord(PHFOutlineW);
    { Path offset = mill radius; mill diameter 2R is the kerf. }
    PHFOffMM := PHFFilletR;
    PHFMechLayer := LayerUtils.MechanicalLayer(PHFMechIndex);

    PHFWS := GetWorkspace;
    if PHFWS = nil then Exit;
    PHFWS.DM_CreateNewDocument('PCB');
    PHFPanelBoard := PCBServer.GetCurrentPCBBoard;
    if PHFPanelBoard = nil then
    begin
        PHFShowBox(LabelErrNew.Caption, 16);
        Exit;
    end;

    PCBServer.PreProcess;
    try
        PHFPlaceEmbeddedArray(PHFPanelBoard);
        PHFDrawAllMillPaths(PHFPanelBoard, PHFMechLayer);

        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        PHFDrawCommonOuterContour(PHFPanelBoard, PHFMechLayer);
        PHFApplyOutline(PHFPanelBoard);
        PHFPlaceFiducials(PHFPanelBoard);

        PHFPanelBoard.LayerIsDisplayed[PHFMechLayer] := True;
        PHFTrySetMetricGrid(PHFPanelBoard, 0.1);
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=All', 255, Client.CurrentView);
    if PHFHaveMill then
    begin
        PHFPanelW := CoordToMMs(PHFMillMaxX - PHFMillMinX) + 2 * PHFMargin;
        PHFPanelH := CoordToMMs(PHFMillMaxY - PHFMillMinY) + 2 * PHFMargin;
    end;
    PHFShowBox(LabelInfoDone.Caption + IntToStr(PHFCols) + 'x' + IntToStr(PHFRows) + sLineBreak +
               LabelInfoSize.Caption + FormatFloat('0.##', PHFPanelW) + ' x ' + FormatFloat('0.##', PHFPanelH) + sLineBreak +
               LabelInfoLayer.Caption + Layer2String(PHFMechLayer), 64);
end;

procedure TFormPHF.ButtonBrowseClick(PHFSender: TObject);
var
    PHFDlg : TOpenDialog;
    PHFWS : IWorkspace;
begin
    PHFDlg := TOpenDialog.Create(nil);
    try
        PHFDlg.Title := LabelDlgTitle.Caption;
        PHFDlg.Filter := 'PCB (*.PcbDoc)|*.PcbDoc';
        if PHFDlg.Execute then
        begin
            PHFSourcePath := PHFDlg.FileName;
            EditFile.Text := PHFSourcePath;
            PHFWS := GetWorkspace;
            if PHFWS <> nil then
                PHFWS.DM_OpenProject(PHFSourcePath, False);
            PHFSourceBoard := PCBServer.GetPCBBoardByPath(PHFSourcePath);
            if PHFSourceBoard = nil then
                PHFSourceBoard := PCBServer.GetCurrentPCBBoard;
            if PHFSourceBoard = nil then
                PHFShowBox(LabelWarnOpen.Caption, 48);
        end;
    finally
        PHFDlg.Free;
    end;
end;

procedure TFormPHF.ButtonOKClick(PHFSender: TObject);
begin
    PHFSourcePath := EditFile.Text;
    if (PHFSourcePath = '') or (not FileExists(PHFSourcePath)) then
    begin
        PHFShowBox(LabelErrFile.Caption, 16);
        Exit;
    end;
    if not PHFParsePositiveInt(EditRows.Text, PHFRows) then
    begin
        PHFShowBox(LabelErrRows.Caption, 16);
        Exit;
    end;
    if not PHFParsePositiveInt(EditCols.Text, PHFCols) then
    begin
        PHFShowBox(LabelErrCols.Caption, 16);
        Exit;
    end;
    if not PHFParsePositive(EditGapX.Text, PHFGapX) then begin PHFShowBox(LabelErrGapX.Caption, 16); Exit; end;
    if not PHFParsePositive(EditGapY.Text, PHFGapY) then begin PHFShowBox(LabelErrGapY.Caption, 16); Exit; end;
    if not PHFParsePositive(EditMargin.Text, PHFMargin) then begin PHFShowBox(LabelErrMargin.Caption, 16); Exit; end;
    if not PHFParsePositive(EditTab.Text, PHFTabW) then begin PHFShowBox(LabelErrTab.Caption, 16); Exit; end;
    if not PHFParsePositiveInt(EditTabH.Text, PHFTabCountH) then begin PHFShowBox(LabelErrTabH.Caption, 16); Exit; end;
    if not PHFParsePositiveInt(EditTabV.Text, PHFTabCountV) then begin PHFShowBox(LabelErrTabV.Caption, 16); Exit; end;
    if not PHFParseNonNeg(EditFillet.Text, PHFFilletR) then begin PHFShowBox(LabelErrMill.Caption, 16); Exit; end;
    if not PHFParsePositiveInt(EditMech.Text, PHFMechIndex) then
    begin
        PHFShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;
    if (PHFMechIndex < 1) or (PHFMechIndex > 32) then
    begin
        PHFShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;

    if PHFSourceBoard = nil then
        PHFSourceBoard := PCBServer.GetPCBBoardByPath(PHFSourcePath);
    if PHFSourceBoard = nil then
    begin
        PHFShowBox(LabelErrLoad.Caption, 16);
        Exit;
    end;

    FormPHF.Close;
    PHFBuildPanel;
end;

procedure TFormPHF.ButtonCancelClick(PHFSender: TObject);
begin
    FormPHF.Close;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function PHFCS_ScriptFolder : String;
var
    PHFWS  : IWorkspace;
    PHFPrj : IProject;
    PHFj   : Integer;
    PHFP, PHFName : String;
begin
    Result := '';
    try
        PHFWS := GetWorkspace;
        if PHFWS = nil then Exit;
        for PHFj := 0 to PHFWS.DM_ProjectCount - 1 do
        begin
            PHFPrj := PHFWS.DM_Projects(PHFj);
            if PHFPrj = nil then Continue;
            PHFP := PHFPrj.DM_ProjectFullPath;
            PHFName := UpperCase(ExtractFileName(PHFP));
            if PHFName = 'PANELIZE_HARD_FORM.PRJSCR' then
            begin
                Result := ExtractFilePath(PHFP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function PHFCS_FindImageFile(const PHFFileName : String) : String;
var
    PHFDir, PHFP : String;
begin
    Result := '';
    PHFDir := PHFCS_ScriptFolder;
    if PHFDir <> '' then
    begin
        PHFP := PHFDir + PHFFileName;
        if FileExists(PHFP) then begin Result := PHFP; Exit; end;
        PHFP := PHFDir + 'images\' + PHFFileName;
        if FileExists(PHFP) then begin Result := PHFP; Exit; end;
    end;
    if FileExists(PHFFileName) then begin Result := PHFFileName; Exit; end;
    PHFP := 'images\' + PHFFileName;
    if FileExists(PHFP) then Result := PHFP;
end;

procedure PHFCS_TryOneHelpFile(const PHFName : String; var PHFDone : Boolean);
var
    PHFP : String;
begin
    if PHFDone then Exit;
    PHFP := PHFCS_FindImageFile(PHFName);
    if (PHFP = '') or (not FileExists(PHFP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(PHFP);
        ImageHelp.Stretch := True;
        try
            ImageHelp.Proportional := True;
        except
        end;
        try
            ImageHelp.Center := True;
        except
        end;
        LabelImageHint.Caption := '';
        PHFDone := True;
    except
    end;
end;

procedure PHFCS_TryLoadHelpImage(const PHFBmpName : String; const PHFPngName : String);
var
    PHFDone : Boolean;
begin
    PHFDone := False;
    PHFCS_TryOneHelpFile(PHFPngName, PHFDone);
    PHFCS_TryOneHelpFile(PHFBmpName, PHFDone);
    PHFCS_TryOneHelpFile('Panelize_Hard_Form.png', PHFDone);
    PHFCS_TryOneHelpFile('Panelize_Hard_Form.bmp', PHFDone);
    if not PHFDone then
        LabelImageHint.Caption := 'No image. Put ' + PHFPngName + ' next to the script or in images\.';
end;


procedure TFormPHF.FormPHFShow(PHFSender: TObject);
begin
    try
        PHFCS_TryLoadHelpImage('Panelize_Hard_Form.bmp', 'Panelize_Hard_Form.png');
    except
    end;
    EditCols.Text := '4';
    EditRows.Text := '2';
    EditGapX.Text := '2';
    EditGapY.Text := '2';
    EditMargin.Text := '10';
    EditTab.Text := '4';
    EditTabH.Text := '1';
    EditTabV.Text := '2';
    EditFillet.Text := '2';
    EditMech.Text := '3';
    try
        if PCBServer <> nil then
            PHFSourceBoard := PCBServer.GetCurrentPCBBoard
        else
            PHFSourceBoard := nil;
        if PHFSourceBoard <> nil then
        begin
            PHFSourcePath := PHFSourceBoard.FileName;
            EditFile.Text := PHFSourcePath;
        end;
    except
    end;
end;

procedure StartPanelizeHardForm;
begin
    FormPHF.ShowModal;
end;

procedure _StartPanelizeHardForm;
begin
    StartPanelizeHardForm;
end;
