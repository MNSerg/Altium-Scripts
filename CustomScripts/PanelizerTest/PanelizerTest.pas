{..............................................................................}
{ PanelizerTest.pas                                                             }
{ Чистый mill+tab: контур платы, offset наружу, объединение каналов,           }
{ перемычки inward-only (горизонтальные = те же, что вертикальные, оси раз).   }
{..............................................................................}

const
    PTstOutlineW = 0.2;
    PTstPiValue         = 3.141592653589793;

var
    PTstSourceBoard : IPCB_Board;
    PTstPanelBoard  : IPCB_Board;
    PTstSourcePath  : String;
    PTstRows, PTstCols  : Integer;
    PTstGapX, PTstGapY, PTstMargin, PTstTabW, PTstFilletR, PTstOffMM : Double;
    PTstMechIndex   : Integer;
    PTstBoardW, PTstBoardH : Double;
    PTstPanelW, PTstPanelH : Double;
    PTstMechLayer   : TLayer;
    PTstLineW       : TCoord;
    PTstVX          : array[0..255] of TCoord;
    PTstVY          : array[0..255] of TCoord;
    PTstVN          : Integer;

{ Run Script: choose procedure StartPanelizerTest (project compiles only this .pas). }
procedure StartPanelizerTest; forward;
procedure _StartPanelizerTest; forward;
procedure TFormPTst.ButtonBrowseClick(PTstSender: TObject); forward;
procedure TFormPTst.ButtonOKClick(PTstSender: TObject); forward;
procedure TFormPTst.ButtonCancelClick(PTstSender: TObject); forward;
procedure TFormPTst.FormPTstShow(PTstSender: TObject); forward;
function PTstBoardOriginX(Col : Integer) : TCoord; forward;
function PTstBoardOriginY(Row : Integer) : TCoord; forward;
procedure PTstOffsetCopiedOutline(ABoard : IPCB_Board; Dx, Dy : TCoord; PTstALayer : TLayer; PTstOutMM : Double); forward;

function PTstParseFloat(const PTstS : String; var PTstV : Double) : Boolean;
var
    PTstT : String;
    PTsti : Integer;
    PTstCh : Char;
    PTstSign : Double;
    PTstScale : Double;
    PTstSeenDigit : Boolean;
    PTstFrac : Boolean;
begin
    Result := False;
    PTstV := 0;
    PTstT := PTstS;
    while (Length(PTstT) > 0) and (PTstT[1] = ' ') do
        PTstT := Copy(PTstT, 2, Length(PTstT));
    while (Length(PTstT) > 0) and (PTstT[Length(PTstT)] = ' ') do
        PTstT := Copy(PTstT, 1, Length(PTstT) - 1);
    if PTstT = '' then Exit;
    PTstSign := 1;
    PTsti := 1;
    if PTstT[1] = '-' then
    begin
        PTstSign := -1;
        PTsti := 2;
    end
    else if PTstT[1] = '+' then
        PTsti := 2;
    PTstSeenDigit := False;
    PTstFrac := False;
    PTstScale := 1;
    while PTsti <= Length(PTstT) do
    begin
        PTstCh := PTstT[PTsti];
        if (PTstCh = '.') or (PTstCh = ',') then
        begin
            if PTstFrac then Exit;
            PTstFrac := True;
        end
        else if (PTstCh >= '0') and (PTstCh <= '9') then
        begin
            PTstSeenDigit := True;
            if not PTstFrac then
                PTstV := PTstV * 10 + (Ord(PTstCh) - Ord('0'))
            else
            begin
                PTstScale := PTstScale * 10;
                PTstV := PTstV + (Ord(PTstCh) - Ord('0')) / PTstScale;
            end;
        end
        else
            Exit;
        PTsti := PTsti + 1;
    end;
    if not PTstSeenDigit then Exit;
    PTstV := PTstV * PTstSign;
    Result := True;
end;

function PTstParsePositive(const PTstS : String; var PTstV : Double) : Boolean;
begin
    Result := PTstParseFloat(PTstS, PTstV) and (PTstV > 0);
end;

function PTstParseNonNeg(const PTstS : String; var PTstV : Double) : Boolean;
begin
    Result := PTstParseFloat(PTstS, PTstV) and (PTstV >= 0);
end;

function PTstParsePositiveInt(const PTstS : String; var PTstV : Integer) : Boolean;
begin
    Result := False;
    try
        PTstV := StrToInt(PTstS);
        Result := PTstV > 0;
    except
        Result := False;
    end;
end;

function PTstAddTrack(ABoard : IPCB_Board; PTstX1, PTstY1, PTstX2, PTstY2 : TCoord; PTstALayer : TLayer) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := PTstX1;
    Result.Y1 := PTstY1;
    Result.X2 := PTstX2;
    Result.Y2 := PTstY2;
    Result.Layer := PTstALayer;
    Result.Width := PTstLineW;
    ABoard.AddPCBObject(Result);
end;

function PTstAddArc(ABoard : IPCB_Board; PTstCX, PTstCY, PTstRadius : TCoord; PTstSa, PTstEa : Double; PTstALayer : TLayer) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := PTstCX;
    Result.YCenter := PTstCY;
    Result.Radius := PTstRadius;
    Result.StartAngle := PTstSa;
    Result.EndAngle := PTstEa;
    Result.Layer := PTstALayer;
    Result.LineWidth := PTstLineW;
    ABoard.AddPCBObject(Result);
end;

procedure PTstDrawRoundedRect(ABoard : IPCB_Board; PTstX0, PTstY0, PTstX1, PTstY1, PTstR : TCoord; PTstALayer : TLayer);
begin
    if PTstR <= 0 then
    begin
        PTstAddTrack(ABoard, PTstX0, PTstY0, PTstX1, PTstY0, PTstALayer);
        PTstAddTrack(ABoard, PTstX1, PTstY0, PTstX1, PTstY1, PTstALayer);
        PTstAddTrack(ABoard, PTstX1, PTstY1, PTstX0, PTstY1, PTstALayer);
        PTstAddTrack(ABoard, PTstX0, PTstY1, PTstX0, PTstY0, PTstALayer);
        Exit;
    end;
    PTstAddTrack(ABoard, PTstX0 + PTstR, PTstY0, PTstX1 - PTstR, PTstY0, PTstALayer);
    PTstAddTrack(ABoard, PTstX1, PTstY0 + PTstR, PTstX1, PTstY1 - PTstR, PTstALayer);
    PTstAddTrack(ABoard, PTstX1 - PTstR, PTstY1, PTstX0 + PTstR, PTstY1, PTstALayer);
    PTstAddTrack(ABoard, PTstX0, PTstY1 - PTstR, PTstX0, PTstY0 + PTstR, PTstALayer);
    PTstAddArc(ABoard, PTstX0 + PTstR, PTstY0 + PTstR, PTstR, 180, 270, PTstALayer);
    PTstAddArc(ABoard, PTstX1 - PTstR, PTstY0 + PTstR, PTstR, 270, 0, PTstALayer);
    PTstAddArc(ABoard, PTstX1 - PTstR, PTstY1 - PTstR, PTstR, 0, 90, PTstALayer);
    PTstAddArc(ABoard, PTstX0 + PTstR, PTstY1 - PTstR, PTstR, 90, 180, PTstALayer);
end;

function PTstIntersectLL(X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Double; var Xi, Yi : Double) : Boolean;
var
    PTstDen, PTstT : Double;
begin
    Result := False;
    PTstDen := (X1 - X2) * (Y3 - Y4) - (Y1 - Y2) * (X3 - X4);
    if Abs(PTstDen) < 1e-18 then Exit;
    PTstT := ((X1 - X3) * (Y3 - Y4) - (Y1 - Y3) * (X3 - X4)) / PTstDen;
    Xi := X1 + PTstT * (X2 - X1);
    Yi := Y1 + PTstT * (Y2 - Y1);
    Result := True;
end;

function PTstNormDeg(PTstA : Double) : Double;
begin
    Result := PTstA;
    while Result < 0 do Result := Result + 360;
    while Result >= 360 do Result := Result - 360;
end;

function PTstAtan2Deg(PTstY, PTstX : Double) : Double;
begin
    if Abs(PTstX) < 1e-18 then
    begin
        if PTstY >= 0 then Result := 90 else Result := 270;
        Exit;
    end;
    Result := ArcTan(PTstY / PTstX) * 180.0 / PTstPiValue;
    if PTstX < 0 then Result := Result + 180;
    Result := PTstNormDeg(Result);
end;

function PTstIntersectLC(X1, Y1, X2, Y2, Cx, Cy, R : Double; HintX, HintY : Double; var Xi, Yi : Double) : Boolean;
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

function PTstIntersectCC(C1x, C1y, R1, C2x, C2y, R2, HintX, HintY : Double; var Xi, Yi : Double) : Boolean;
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

procedure PTstSetTrackPt(PTstT : IPCB_Track; PTstAtStart : Boolean; PTstX, PTstY : TCoord);
begin
    PTstT.BeginModify;
    if PTstAtStart then
    begin
        PTstT.X1 := PTstX; PTstT.Y1 := PTstY;
    end
    else
    begin
        PTstT.X2 := PTstX; PTstT.Y2 := PTstY;
    end;
    PTstT.EndModify;
    PTstT.GraphicallyInvalidate;
end;

procedure PTstSetArcEnd(PTstA : IPCB_Arc; PTstAtStart : Boolean; PTstX, PTstY : TCoord);
var
    Ang : Double;
begin
    Ang := PTstAtan2Deg(CoordToMMs(PTstY - PTstA.YCenter), CoordToMMs(PTstX - PTstA.XCenter));
    PTstA.BeginModify;
    if PTstAtStart then PTstA.StartAngle := Ang else PTstA.EndAngle := Ang;
    PTstA.EndModify;
    PTstA.GraphicallyInvalidate;
end;

procedure PTstJoinOff(PTstN0, PTstN1 : IPCB_Primitive; HintX, HintY : Double);
var
    Xi, Yi : Double;
    Ok : Boolean;
    T0, T1 : IPCB_Track;
    A0, A1 : IPCB_Arc;
    JX, JY : TCoord;
begin
    if (PTstN0 = nil) or (PTstN1 = nil) then Exit;
    Ok := False;
    Xi := 0; Yi := 0;
    if (PTstN0.ObjectId = eTrackObject) and (PTstN1.ObjectId = eTrackObject) then
    begin
        T0 := PTstN0; T1 := PTstN1;
        Ok := PTstIntersectLL(CoordToMMs(T0.X1), CoordToMMs(T0.Y1), CoordToMMs(T0.X2), CoordToMMs(T0.Y2),
                              CoordToMMs(T1.X1), CoordToMMs(T1.Y1), CoordToMMs(T1.X2), CoordToMMs(T1.Y2),
                              Xi, Yi);
    end
    else if (PTstN0.ObjectId = eTrackObject) and (PTstN1.ObjectId = eArcObject) then
    begin
        T0 := PTstN0; A1 := PTstN1;
        Ok := PTstIntersectLC(CoordToMMs(T0.X1), CoordToMMs(T0.Y1), CoordToMMs(T0.X2), CoordToMMs(T0.Y2),
                              CoordToMMs(A1.XCenter), CoordToMMs(A1.YCenter), CoordToMMs(A1.Radius),
                              HintX, HintY, Xi, Yi);
    end
    else if (PTstN0.ObjectId = eArcObject) and (PTstN1.ObjectId = eTrackObject) then
    begin
        A0 := PTstN0; T1 := PTstN1;
        Ok := PTstIntersectLC(CoordToMMs(T1.X1), CoordToMMs(T1.Y1), CoordToMMs(T1.X2), CoordToMMs(T1.Y2),
                              CoordToMMs(A0.XCenter), CoordToMMs(A0.YCenter), CoordToMMs(A0.Radius),
                              HintX, HintY, Xi, Yi);
    end
    else if (PTstN0.ObjectId = eArcObject) and (PTstN1.ObjectId = eArcObject) then
    begin
        A0 := PTstN0; A1 := PTstN1;
        if (Abs(A0.XCenter - A1.XCenter) < 80) and (Abs(A0.YCenter - A1.YCenter) < 80) then Exit;
        Ok := PTstIntersectCC(CoordToMMs(A0.XCenter), CoordToMMs(A0.YCenter), CoordToMMs(A0.Radius),
                              CoordToMMs(A1.XCenter), CoordToMMs(A1.YCenter), CoordToMMs(A1.Radius),
                              HintX, HintY, Xi, Yi);
    end;
    if not Ok then Exit;
    JX := MMsToCoord(Xi);
    JY := MMsToCoord(Yi);
    if PTstN0.ObjectId = eTrackObject then
        PTstSetTrackPt(PTstN0, False, JX, JY)
    else if PTstN0.ObjectId = eArcObject then
        PTstSetArcEnd(PTstN0, False, JX, JY);
    if PTstN1.ObjectId = eTrackObject then
        PTstSetTrackPt(PTstN1, True, JX, JY)
    else if PTstN1.ObjectId = eArcObject then
        PTstSetArcEnd(PTstN1, True, JX, JY);
end;

procedure PTstOffsetCopiedOutline(ABoard : IPCB_Board; Dx, Dy : TCoord; PTstALayer : TLayer; PTstOutMM : Double);
var
    PTsti, PTstj, PTstn : Integer;
    PTstSeg, PTstNxt : TPolySegment;
    Area, Dxmm, Dymm, Len, Nx, Ny, Cross : Double;
    OffLeft, Away : Boolean;
    PTstR, CX, CY, SX, SY, EX, EY, NR : TCoord;
    SA, EA : Double;
    News : TStringList;
    TN : IPCB_Track;
    AN : IPCB_Arc;
    HX, HY : Double;
begin
    if PTstOutMM <= 0 then Exit;
    try
        PTstn := PTstSourceBoard.BoardOutline.PointCount;
    except
        PTstn := 0;
    end;
    if PTstn < 2 then Exit;
    Area := 0;
    for PTsti := 0 to PTstn - 1 do
    begin
        PTstSeg := PTstSourceBoard.BoardOutline.Segments[PTsti];
        PTstj := PTsti + 1;
        if PTstj >= PTstn then PTstj := 0;
        PTstNxt := PTstSourceBoard.BoardOutline.Segments[PTstj];
        Area := Area + CoordToMMs(PTstSeg.vx) * CoordToMMs(PTstNxt.vy) -
                CoordToMMs(PTstNxt.vx) * CoordToMMs(PTstSeg.vy);
    end;
    OffLeft := Area <= 0;
    News := TStringList.Create;
    try
        for PTsti := 0 to PTstn - 1 do
        begin
            PTstSeg := PTstSourceBoard.BoardOutline.Segments[PTsti];
            PTstj := PTsti + 1;
            if PTstj >= PTstn then PTstj := 0;
            PTstNxt := PTstSourceBoard.BoardOutline.Segments[PTstj];
            PTstR := 0;
            try PTstR := PTstSeg.Radius; except PTstR := 0; end;
            CX := 0; CY := 0; SA := 0; EA := 0;
            try
                CX := PTstSeg.cx;
                CY := PTstSeg.cy;
                SA := PTstSeg.Angle1;
                EA := PTstSeg.Angle2;
            except
                CX := 0;
            end;
            if (PTstR > 1) and ((CX <> 0) or (CY <> 0)) then
            begin
                SX := PTstSeg.vx;
                SY := PTstSeg.vy;
                EX := PTstNxt.vx;
                EY := PTstNxt.vy;
                Cross := CoordToMMs(EX - SX) * CoordToMMs(CY - SY) -
                         CoordToMMs(EY - SY) * CoordToMMs(CX - SX);
                if Cross > 0 then Away := OffLeft else Away := not OffLeft;
                if Away then
                    NR := PTstR + MMsToCoord(PTstOutMM)
                else
                    NR := PTstR - MMsToCoord(PTstOutMM);
                if NR < 1 then
                    News.AddObject('N', nil)
                else
                begin
                    AN := PTstAddArc(ABoard, CX + Dx, CY + Dy, NR, SA, EA, PTstALayer);
                    News.AddObject('A', AN);
                end;
            end
            else
            begin
                Dxmm := CoordToMMs(PTstNxt.vx - PTstSeg.vx);
                Dymm := CoordToMMs(PTstNxt.vy - PTstSeg.vy);
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
                    TN := PTstAddTrack(ABoard,
                        PTstSeg.vx + Dx + MMsToCoord(Nx * PTstOutMM),
                        PTstSeg.vy + Dy + MMsToCoord(Ny * PTstOutMM),
                        PTstNxt.vx + Dx + MMsToCoord(Nx * PTstOutMM),
                        PTstNxt.vy + Dy + MMsToCoord(Ny * PTstOutMM),
                        PTstALayer);
                    News.AddObject('T', TN);
                end;
            end;
        end;
        for PTsti := 0 to News.Count - 1 do
        begin
            PTstj := PTsti + 1;
            if PTstj >= News.Count then PTstj := 0;
            if News.Objects[PTsti] = nil then Continue;
            if News.Objects[PTstj] = nil then Continue;
            PTstSeg := PTstSourceBoard.BoardOutline.Segments[PTstj];
            HX := CoordToMMs(PTstSeg.vx + Dx);
            HY := CoordToMMs(PTstSeg.vy + Dy);
            PTstJoinOff(News.Objects[PTsti], News.Objects[PTstj], HX, HY);
        end;
    finally
        News.Free;
    end;
end;

procedure PTstLoadOutlineVerts(Dx, Dy : TCoord);
var
    PTsti, PTstn : Integer;
    PTstSeg : TPolySegment;
    SrcR : TCoordRect;
begin
    PTstVN := 0;
    SrcR := PTstSourceBoard.BoardOutline.BoundingRectangle;
    try
        PTstn := PTstSourceBoard.BoardOutline.PointCount;
    except
        PTstn := 0;
    end;
    if PTstn > 256 then PTstn := 256;
    if PTstn >= 2 then
    begin
        for PTsti := 0 to PTstn - 1 do
        begin
            PTstSeg := PTstSourceBoard.BoardOutline.Segments[PTsti];
            PTstVX[PTstVN] := PTstSeg.vx + Dx;
            PTstVY[PTstVN] := PTstSeg.vy + Dy;
            PTstVN := PTstVN + 1;
        end;
    end;
    if PTstVN < 3 then
    begin
        PTstVX[0] := Dx + SrcR.Left;     PTstVY[0] := Dy + SrcR.Bottom;
        PTstVX[1] := Dx + SrcR.Right;    PTstVY[1] := Dy + SrcR.Bottom;
        PTstVX[2] := Dx + SrcR.Right;    PTstVY[2] := Dy + SrcR.Top;
        PTstVX[3] := Dx + SrcR.Left;     PTstVY[3] := Dy + SrcR.Top;
        PTstVN := 4;
    end;
end;

procedure PTstDrawLoadedPoly(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    PTsti, PTstj : Integer;
begin
    if PTstVN < 2 then Exit;
    for PTsti := 0 to PTstVN - 1 do
    begin
        PTstj := PTsti + 1;
        if PTstj >= PTstVN then PTstj := 0;
        PTstAddTrack(ABoard, PTstVX[PTsti], PTstVY[PTsti], PTstVX[PTstj], PTstVY[PTstj], PTstALayer);
    end;
end;

procedure PTstOffsetAndDraw(ABoard : IPCB_Board; PTstALayer : TLayer; PTstOutMM : Double);
var
    PTsti, PTstj, PTstk : Integer;
    Ox : array[0..255] of TCoord;
    Oy : array[0..255] of TCoord;
    Area, Dx, Dy, Len, Nx, Ny, X1, Y1, X2, Y2, X3, Y3, X4, Y4, Xi, Yi, Sign : Double;
    Left : Boolean;
begin
    if PTstVN < 3 then Exit;
    Area := 0;
    for PTsti := 0 to PTstVN - 1 do
    begin
        PTstj := PTsti + 1;
        if PTstj >= PTstVN then PTstj := 0;
        Area := Area + CoordToMMs(PTstVX[PTsti]) * CoordToMMs(PTstVY[PTstj]) -
                CoordToMMs(PTstVX[PTstj]) * CoordToMMs(PTstVY[PTsti]);
    end;
    Left := Area < 0;
    Sign := 1;
    if not Left then Sign := -1;
    for PTsti := 0 to PTstVN - 1 do
    begin
        PTstj := PTsti + 1;
        if PTstj >= PTstVN then PTstj := 0;
        PTstk := PTstj + 1;
        if PTstk >= PTstVN then PTstk := 0;
        Dx := CoordToMMs(PTstVX[PTstj] - PTstVX[PTsti]);
        Dy := CoordToMMs(PTstVY[PTstj] - PTstVY[PTsti]);
        Len := Sqrt(Dx * Dx + Dy * Dy);
        if Len < 0.0001 then
        begin
            Ox[PTstj] := PTstVX[PTstj];
            Oy[PTstj] := PTstVY[PTstj];
            Continue;
        end;
        Nx := -Dy / Len * Sign;
        Ny := Dx / Len * Sign;
        X1 := CoordToMMs(PTstVX[PTsti]) + Nx * PTstOutMM;
        Y1 := CoordToMMs(PTstVY[PTsti]) + Ny * PTstOutMM;
        X2 := CoordToMMs(PTstVX[PTstj]) + Nx * PTstOutMM;
        Y2 := CoordToMMs(PTstVY[PTstj]) + Ny * PTstOutMM;
        Dx := CoordToMMs(PTstVX[PTstk] - PTstVX[PTstj]);
        Dy := CoordToMMs(PTstVY[PTstk] - PTstVY[PTstj]);
        Len := Sqrt(Dx * Dx + Dy * Dy);
        if Len < 0.0001 then
        begin
            Ox[PTstj] := MMsToCoord(X2);
            Oy[PTstj] := MMsToCoord(Y2);
            Continue;
        end;
        Nx := -Dy / Len * Sign;
        Ny := Dx / Len * Sign;
        X3 := CoordToMMs(PTstVX[PTstj]) + Nx * PTstOutMM;
        Y3 := CoordToMMs(PTstVY[PTstj]) + Ny * PTstOutMM;
        X4 := CoordToMMs(PTstVX[PTstk]) + Nx * PTstOutMM;
        Y4 := CoordToMMs(PTstVY[PTstk]) + Ny * PTstOutMM;
        if PTstIntersectLL(X1, Y1, X2, Y2, X3, Y3, X4, Y4, Xi, Yi) then
        begin
            Ox[PTstj] := MMsToCoord(Xi);
            Oy[PTstj] := MMsToCoord(Yi);
        end
        else
        begin
            Ox[PTstj] := MMsToCoord(X2);
            Oy[PTstj] := MMsToCoord(Y2);
        end;
    end;
    for PTsti := 0 to PTstVN - 1 do
    begin
        PTstj := PTsti + 1;
        if PTstj >= PTstVN then PTstj := 0;
        PTstAddTrack(ABoard, Ox[PTsti], Oy[PTsti], Ox[PTstj], Oy[PTstj], PTstALayer);
    end;
end;

procedure PTstDrawCellOutline(ABoard : IPCB_Board; Col, Row : Integer; PTstALayer : TLayer);
var
    SrcR : TCoordRect;
    Dx, Dy : TCoord;
begin
    SrcR := PTstSourceBoard.BoardOutline.BoundingRectangle;
    Dx := PTstBoardOriginX(Col) - SrcR.Left;
    Dy := PTstBoardOriginY(Row) - SrcR.Bottom;
    PTstLoadOutlineVerts(Dx, Dy);
    PTstDrawLoadedPoly(ABoard, PTstALayer);
    PTstOffsetAndDraw(ABoard, PTstALayer, PTstOffMM);
end;

procedure PTstDrawSlotV(ABoard : IPCB_Board; X0, X1, Y0, Y1 : TCoord; NTabs : Integer; PTstALayer : TLayer);
var
    RR, Neck, Half, MidX, Span, Yc, Ya, Yb, Yprev : TCoord;
    Ti : Integer;
begin
    if (X1 <= X0) or (Y1 <= Y0) then Exit;
    RR := MMsToCoord(PTstFilletR);
    if RR > ((X1 - X0) div 2) then RR := (X1 - X0) div 2;
    if RR < 1 then RR := 1;
    Neck := MMsToCoord(PTstTabW);
    if Neck < 1 then Neck := 1;
    Half := (Neck div 2) + RR;
    MidX := (X0 + X1) div 2;
    Span := Y1 - Y0;
    if NTabs < 1 then NTabs := 1;
    if Span < (Half + Half) * NTabs then
    begin
        PTstAddTrack(ABoard, X0, Y0, X0, Y1, PTstALayer);
        PTstAddTrack(ABoard, X1, Y0, X1, Y1, PTstALayer);
        Exit;
    end;
    Yprev := Y0;
    for Ti := 1 to NTabs do
    begin
        if NTabs = 1 then
            Yc := (Y0 + Y1) div 2
        else
            Yc := Y0 + (Span * (2 * Ti - 1)) div (2 * NTabs);
        Ya := Yc - Half;
        Yb := Yc + Half;
        if Ya < Y0 then Ya := Y0;
        if Yb > Y1 then Yb := Y1;
        if Ya > Yprev then
        begin
            PTstAddTrack(ABoard, X0, Yprev, X0, Ya, PTstALayer);
            PTstAddTrack(ABoard, X1, Yprev, X1, Ya, PTstALayer);
        end;
        PTstAddArc(ABoard, MidX, Ya, RR, 0, 180, PTstALayer);
        PTstAddArc(ABoard, MidX, Yb, RR, 180, 0, PTstALayer);
        Yprev := Yb;
    end;
    if Yprev < Y1 then
    begin
        PTstAddTrack(ABoard, X0, Yprev, X0, Y1, PTstALayer);
        PTstAddTrack(ABoard, X1, Yprev, X1, Y1, PTstALayer);
    end;
end;

procedure PTstDrawSlotH(ABoard : IPCB_Board; Y0, Y1, X0, X1 : TCoord; NTabs : Integer; PTstALayer : TLayer);
var
    RR, Neck, Half, MidY, Span, Xc, Xa, Xb, Xprev : TCoord;
    Ti : Integer;
begin
    if (Y1 <= Y0) or (X1 <= X0) then Exit;
    RR := MMsToCoord(PTstFilletR);
    if RR > ((Y1 - Y0) div 2) then RR := (Y1 - Y0) div 2;
    if RR < 1 then RR := 1;
    Neck := MMsToCoord(PTstTabW);
    if Neck < 1 then Neck := 1;
    Half := (Neck div 2) + RR;
    MidY := (Y0 + Y1) div 2;
    Span := X1 - X0;
    if NTabs < 1 then NTabs := 1;
    if Span < (Half + Half) * NTabs then
    begin
        PTstAddTrack(ABoard, X0, Y0, X1, Y0, PTstALayer);
        PTstAddTrack(ABoard, X0, Y1, X1, Y1, PTstALayer);
        Exit;
    end;
    Xprev := X0;
    for Ti := 1 to NTabs do
    begin
        if NTabs = 1 then
            Xc := (X0 + X1) div 2
        else
            Xc := X0 + (Span * (2 * Ti - 1)) div (2 * NTabs);
        Xa := Xc - Half;
        Xb := Xc + Half;
        if Xa < X0 then Xa := X0;
        if Xb > X1 then Xb := X1;
        if Xa > Xprev then
        begin
            PTstAddTrack(ABoard, Xprev, Y0, Xa, Y0, PTstALayer);
            PTstAddTrack(ABoard, Xprev, Y1, Xa, Y1, PTstALayer);
        end;
        PTstAddArc(ABoard, Xa, MidY, RR, 270, 90, PTstALayer);
        PTstAddArc(ABoard, Xb, MidY, RR, 90, 270, PTstALayer);
        Xprev := Xb;
    end;
    if Xprev < X1 then
    begin
        PTstAddTrack(ABoard, Xprev, Y0, X1, Y0, PTstALayer);
        PTstAddTrack(ABoard, Xprev, Y1, X1, Y1, PTstALayer);
    end;
end;

procedure PTstDeleteCoincident(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    PTstIter : IPCB_BoardIterator;
    PTstPrim : IPCB_Primitive;
    Tracks : TStringList;
    PTsti, PTstj : Integer;
    T0, T1 : IPCB_Track;
    Kill : TStringList;
begin
    Tracks := TStringList.Create;
    Kill := TStringList.Create;
    PTstIter := ABoard.BoardIterator_Create;
    PTstIter.AddFilter_ObjectSet(MkSet(eTrackObject));
    PTstIter.AddFilter_LayerSet(MkSet(PTstALayer));
    PTstIter.AddFilter_Method(eProcessAll);
    PTstPrim := PTstIter.FirstPCBObject;
    while PTstPrim <> nil do
    begin
        Tracks.AddObject('T', PTstPrim);
        PTstPrim := PTstIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PTstIter);
    for PTsti := 0 to Tracks.Count - 1 do
    begin
        if Kill.IndexOf(IntToStr(PTsti)) >= 0 then Continue;
        T0 := Tracks.Objects[PTsti];
        for PTstj := PTsti + 1 to Tracks.Count - 1 do
        begin
            if Kill.IndexOf(IntToStr(PTstj)) >= 0 then Continue;
            T1 := Tracks.Objects[PTstj];
            if ((Abs(T0.X1 - T1.X1) < 80) and (Abs(T0.Y1 - T1.Y1) < 80) and
                (Abs(T0.X2 - T1.X2) < 80) and (Abs(T0.Y2 - T1.Y2) < 80)) or
               ((Abs(T0.X1 - T1.X2) < 80) and (Abs(T0.Y1 - T1.Y2) < 80) and
                (Abs(T0.X2 - T1.X1) < 80) and (Abs(T0.Y2 - T1.Y1) < 80)) then
                Kill.Add(IntToStr(PTstj));
        end;
    end;
    for PTsti := 0 to Kill.Count - 1 do
    begin
        T1 := Tracks.Objects[StrToInt(Kill[PTsti])];
        ABoard.BeginModify;
        ABoard.RemovePCBObject(T1);
        ABoard.EndModify;
    end;
    Tracks.Free;
    Kill.Free;
end;

procedure PTstCopyOutlineWithArcs(ABoard : IPCB_Board; Col, Row : Integer; PTstALayer : TLayer);
var
    SrcR : TCoordRect;
    Dx, Dy, PTstR, CX, CY : TCoord;
    PTsti, PTstn, PTstj : Integer;
    PTstSeg, PTstNxt : TPolySegment;
    SA, EA : Double;
begin
    SrcR := PTstSourceBoard.BoardOutline.BoundingRectangle;
    Dx := PTstBoardOriginX(Col) - SrcR.Left;
    Dy := PTstBoardOriginY(Row) - SrcR.Bottom;
    try
        PTstn := PTstSourceBoard.BoardOutline.PointCount;
    except
        PTstn := 0;
    end;
    if PTstn < 2 then
    begin
        PTstLoadOutlineVerts(Dx, Dy);
        PTstDrawLoadedPoly(ABoard, PTstALayer);
        PTstOffsetCopiedOutline(ABoard, Dx, Dy, PTstALayer, PTstOffMM);
        Exit;
    end;
    for PTsti := 0 to PTstn - 1 do
    begin
        PTstSeg := PTstSourceBoard.BoardOutline.Segments[PTsti];
        PTstj := PTsti + 1;
        if PTstj >= PTstn then PTstj := 0;
        PTstNxt := PTstSourceBoard.BoardOutline.Segments[PTstj];
        PTstR := 0;
        try PTstR := PTstSeg.Radius; except PTstR := 0; end;
        CX := 0; CY := 0; SA := 0; EA := 0;
        try
            CX := PTstSeg.cx;
            CY := PTstSeg.cy;
            SA := PTstSeg.Angle1;
            EA := PTstSeg.Angle2;
        except
            CX := 0;
        end;
        if (PTstR > 1) and ((CX <> 0) or (CY <> 0)) then
            PTstAddArc(ABoard, CX + Dx, CY + Dy, PTstR, SA, EA, PTstALayer)
        else
            PTstAddTrack(ABoard, PTstSeg.vx + Dx, PTstSeg.vy + Dy,
                         PTstNxt.vx + Dx, PTstNxt.vy + Dy, PTstALayer);
    end;
end;

function PTstBoardCornerR : TCoord;
var
    PTsti, PTstn : Integer;
    PTstSeg : TPolySegment;
    PTstR : TCoord;
begin
    Result := 0;
    if PTstSourceBoard = nil then Exit;
    try
        PTstn := PTstSourceBoard.BoardOutline.PointCount;
        for PTsti := 0 to PTstn - 1 do
        begin
            PTstSeg := PTstSourceBoard.BoardOutline.Segments[PTsti];
            PTstR := 0;
            try PTstR := PTstSeg.Radius; except PTstR := 0; end;
            if PTstR > Result then Result := PTstR;
        end;
    except
        Result := 0;
    end;
end;

function PTstInOpenSlot(PTstX, PTstY : TCoord) : Boolean;
var
    r, c : Integer;
    L, B, Rgt, Tp, Gx, Gy, L0, B0, R1, T1, M : TCoord;
begin
    Result := False;
    Gx := MMsToCoord(PTstGapX);
    Gy := MMsToCoord(PTstGapY);
    M := 80;
    L0 := PTstBoardOriginX(0);
    B0 := PTstBoardOriginY(0);
    R1 := PTstBoardOriginX(PTstCols - 1) + MMsToCoord(PTstBoardW);
    T1 := PTstBoardOriginY(PTstRows - 1) + MMsToCoord(PTstBoardH);
    for r := 0 to PTstRows - 1 do
        for c := 0 to PTstCols - 2 do
        begin
            L := PTstBoardOriginX(c) + MMsToCoord(PTstBoardW);
            B := PTstBoardOriginY(r);
            Tp := B + MMsToCoord(PTstBoardH);
            if (PTstX > L + M) and (PTstX < L + Gx - M) and (PTstY > B + M) and (PTstY < Tp - M) then
            begin
                Result := True;
                Exit;
            end;
        end;
    for r := 0 to PTstRows - 2 do
        for c := 0 to PTstCols - 1 do
        begin
            L := PTstBoardOriginX(c);
            Rgt := L + MMsToCoord(PTstBoardW);
            B := PTstBoardOriginY(r) + MMsToCoord(PTstBoardH);
            if (PTstY > B + M) and (PTstY < B + Gy - M) and (PTstX > L + M) and (PTstX < Rgt - M) then
            begin
                Result := True;
                Exit;
            end;
        end;
    if (PTstY > B0 - Gy + M) and (PTstY < B0 - M) and (PTstX > L0 + M) and (PTstX < R1 - M) then
        Result := True;
    if (PTstY > T1 + M) and (PTstY < T1 + Gy - M) and (PTstX > L0 + M) and (PTstX < R1 - M) then
        Result := True;
    if (PTstX > L0 - Gx + M) and (PTstX < L0 - M) and (PTstY > B0 + M) and (PTstY < T1 - M) then
        Result := True;
    if (PTstX > R1 + M) and (PTstX < R1 + Gx - M) and (PTstY > B0 + M) and (PTstY < T1 - M) then
        Result := True;
end;

procedure PTstDeleteInterior(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    PTstIter : IPCB_BoardIterator;
    PTstPrim : IPCB_Primitive;
    Kill : TStringList;
    PTsti : Integer;
    T0 : IPCB_Track;
    A0 : IPCB_Arc;
    MX, MY : TCoord;
begin
    Kill := TStringList.Create;
    PTstIter := ABoard.BoardIterator_Create;
    PTstIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    PTstIter.AddFilter_LayerSet(MkSet(PTstALayer));
    PTstIter.AddFilter_Method(eProcessAll);
    PTstPrim := PTstIter.FirstPCBObject;
    while PTstPrim <> nil do
    begin
        if PTstPrim.ObjectId = eTrackObject then
        begin
            T0 := PTstPrim;
            MX := (T0.X1 + T0.X2) div 2;
            MY := (T0.Y1 + T0.Y2) div 2;
            if PTstInOpenSlot(MX, MY) then
                Kill.AddObject('K', PTstPrim);
        end
        else if PTstPrim.ObjectId = eArcObject then
        begin
            A0 := PTstPrim;
            if PTstInOpenSlot(A0.XCenter, A0.YCenter) then
                Kill.AddObject('K', PTstPrim);
        end;
        PTstPrim := PTstIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PTstIter);
    for PTsti := 0 to Kill.Count - 1 do
    begin
        ABoard.BeginModify;
        ABoard.RemovePCBObject(Kill.Objects[PTsti]);
        ABoard.EndModify;
    end;
    Kill.Free;
end;

procedure PTstDrawAllMillPaths(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    r, c : Integer;
    L, B, Rgt, Tp, Gx, Gy, CR, CRo : TCoord;
    L0, B0, R1, T1 : TCoord;
begin
    { Inner = actual BoardOutline (tracks+arcs) + CAD offset outer. }
    for r := 0 to PTstRows - 1 do
        for c := 0 to PTstCols - 1 do
            PTstCopyOutlineWithArcs(ABoard, c, r, PTstALayer);

    Gx := MMsToCoord(PTstGapX);
    Gy := MMsToCoord(PTstGapY);
    CR := PTstBoardCornerR;
    L0 := PTstBoardOriginX(0);
    B0 := PTstBoardOriginY(0);
    R1 := PTstBoardOriginX(PTstCols - 1) + MMsToCoord(PTstBoardW);
    T1 := PTstBoardOriginY(PTstRows - 1) + MMsToCoord(PTstBoardH);

    for r := 0 to PTstRows - 1 do
        for c := 0 to PTstCols - 2 do
        begin
            L := PTstBoardOriginX(c) + MMsToCoord(PTstBoardW);
            B := PTstBoardOriginY(r) + CR;
            Tp := PTstBoardOriginY(r) + MMsToCoord(PTstBoardH) - CR;
            PTstDrawSlotV(ABoard, L, L + Gx, B, Tp, 2, PTstALayer);
        end;
    for r := 0 to PTstRows - 2 do
        for c := 0 to PTstCols - 1 do
        begin
            L := PTstBoardOriginX(c) + CR;
            Rgt := PTstBoardOriginX(c) + MMsToCoord(PTstBoardW) - CR;
            B := PTstBoardOriginY(r) + MMsToCoord(PTstBoardH);
            PTstDrawSlotH(ABoard, B, B + Gy, L, Rgt, 1, PTstALayer);
        end;
    for r := 0 to PTstRows - 1 do
    begin
        L := PTstBoardOriginX(0);
        Rgt := PTstBoardOriginX(PTstCols - 1) + MMsToCoord(PTstBoardW);
        B := PTstBoardOriginY(r) + CR;
        Tp := PTstBoardOriginY(r) + MMsToCoord(PTstBoardH) - CR;
        PTstDrawSlotV(ABoard, L - Gx, L, B, Tp, 2, PTstALayer);
        PTstDrawSlotV(ABoard, Rgt, Rgt + Gx, B, Tp, 2, PTstALayer);
    end;
    for c := 0 to PTstCols - 1 do
    begin
        L := PTstBoardOriginX(c) + CR;
        Rgt := PTstBoardOriginX(c) + MMsToCoord(PTstBoardW) - CR;
        B := PTstBoardOriginY(0);
        Tp := PTstBoardOriginY(PTstRows - 1) + MMsToCoord(PTstBoardH);
        PTstDrawSlotH(ABoard, B - Gy, B, L, Rgt, 1, PTstALayer);
        PTstDrawSlotH(ABoard, Tp, Tp + Gy, L, Rgt, 1, PTstALayer);
    end;

    { Standalone T-pockets: outer mill of two edge boards meets across the alley.
      Same tabs as Panelizer (DrawSlotV/H). Not connected to the panel outline. }
    for c := 0 to PTstCols - 2 do
    begin
        L := PTstBoardOriginX(c) + MMsToCoord(PTstBoardW);
        PTstAddTrack(ABoard, L - CR, B0 - Gy, L + Gx + CR, B0 - Gy, PTstALayer);
        PTstAddTrack(ABoard, L - CR, T1 + Gy, L + Gx + CR, T1 + Gy, PTstALayer);
    end;
    for r := 0 to PTstRows - 2 do
    begin
        B := PTstBoardOriginY(r) + MMsToCoord(PTstBoardH);
        PTstAddTrack(ABoard, L0 - Gx, B - CR, L0 - Gx, B + Gy + CR, PTstALayer);
        PTstAddTrack(ABoard, R1 + Gx, B - CR, R1 + Gx, B + Gy + CR, PTstALayer);
    end;

    if CR > 0 then
    begin
        CRo := CR + Gx;
        PTstAddArc(ABoard, L0 + CR, B0 + CR, CRo, 180, 270, PTstALayer);
        PTstAddArc(ABoard, R1 - CR, B0 + CR, CRo, 270, 0, PTstALayer);
        PTstAddArc(ABoard, R1 - CR, T1 - CR, CRo, 0, 90, PTstALayer);
        PTstAddArc(ABoard, L0 + CR, T1 - CR, CRo, 90, 180, PTstALayer);
    end
    else
    begin
        PTstAddArc(ABoard, L0, B0, Gx, 180, 270, PTstALayer);
        PTstAddArc(ABoard, R1, B0, Gx, 270, 0, PTstALayer);
        PTstAddArc(ABoard, R1, T1, Gx, 0, 90, PTstALayer);
        PTstAddArc(ABoard, L0, T1, Gx, 90, 180, PTstALayer);
    end;

    PTstDeleteCoincident(ABoard, PTstALayer);
    PTstDeleteInterior(ABoard, PTstALayer);
end;

procedure PTstDrawCommonOuterContour(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    X0, Y0, X1, Y1 : TCoord;
begin
    X0 := PTstBoardOriginX(0) - MMsToCoord(PTstMargin);
    Y0 := PTstBoardOriginY(0) - MMsToCoord(PTstMargin);
    X1 := PTstBoardOriginX(PTstCols - 1) + MMsToCoord(PTstBoardW) + MMsToCoord(PTstMargin);
    Y1 := PTstBoardOriginY(PTstRows - 1) + MMsToCoord(PTstBoardH) + MMsToCoord(PTstMargin);
    PTstAddTrack(ABoard, X0, Y0, X1, Y0, PTstALayer);
    PTstAddTrack(ABoard, X1, Y0, X1, Y1, PTstALayer);
    PTstAddTrack(ABoard, X1, Y1, X0, Y1, PTstALayer);
    PTstAddTrack(ABoard, X0, Y1, X0, Y0, PTstALayer);
end;

function PTstBoardOriginX(Col : Integer) : TCoord;
begin
    Result := MMsToCoord(PTstMargin + Col * (PTstBoardW + PTstGapX));
end;

function PTstBoardOriginY(Row : Integer) : TCoord;
begin
    Result := MMsToCoord(PTstMargin + Row * (PTstBoardH + PTstGapY));
end;

procedure PTstPlaceEmbeddedArray(ABoard : IPCB_Board);
var
    Emb : IPCB_EmbeddedBoard;
    PTstX0, PTstY0 : TCoord;
begin
    Emb := PCBServer.PCBObjectFactory(eEmbeddedBoardObject, eNoDimension, eCreate_Default);
    Emb.DocumentPath := PTstSourcePath;
    Emb.RowCount := PTstRows;
    Emb.ColCount := PTstCols;
    Emb.ColSpacing := MMsToCoord(PTstBoardW + PTstGapX);
    Emb.RowSpacing := MMsToCoord(PTstBoardH + PTstGapY);
    PTstX0 := PTstBoardOriginX(0);
    PTstY0 := PTstBoardOriginY(0);
    Emb.XLocation := PTstX0;
    Emb.YLocation := PTstY0;
    ABoard.AddPCBObject(Emb);
end;

procedure PTstShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

procedure ApplyPTstPanelBoardOutline(ABoard : IPCB_Board);
var
    PTstIter : IPCB_BoardIterator;
    PTstPrim : IPCB_Primitive;
begin
    { Выделить рамку панели и сделать из неё board outline. }
    PTstIter := ABoard.BoardIterator_Create;
    PTstIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    PTstIter.AddFilter_LayerSet(MkSet(PTstMechLayer));
    PTstIter.AddFilter_Method(eProcessAll);
    PTstPrim := PTstIter.FirstPCBObject;
    while PTstPrim <> nil do
    begin
        PTstPrim.Selected := False;
        PTstPrim := PTstIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PTstIter);

    ResetParameters;
    AddStringParameter('Scope', 'All');
    RunProcess('PCB:DeSelect');
end;

procedure PTstBuildPanel;
var
    PTstWS : IWorkspace;
    PTstRect : TCoordRect;
begin
    PTstRect := PTstSourceBoard.BoardOutline.BoundingRectangle;
    PTstBoardW := CoordToMMs(PTstRect.Right - PTstRect.Left);
    PTstBoardH := CoordToMMs(PTstRect.Top - PTstRect.Bottom);
    if (PTstBoardW <= 0) or (PTstBoardH <= 0) then
    begin
        PTstShowBox(LabelErrSize.Caption, 16);
        Exit;
    end;

    PTstPanelW := PTstMargin * 2 + PTstCols * PTstBoardW + (PTstCols - 1) * PTstGapX;
    PTstPanelH := PTstMargin * 2 + PTstRows * PTstBoardH + (PTstRows - 1) * PTstGapY;
    PTstLineW := MMsToCoord(PTstOutlineW);
    PTstMechLayer := LayerUtils.MechanicalLayer(PTstMechIndex);

    PTstWS := GetWorkspace;
    if PTstWS = nil then Exit;
    PTstWS.DM_CreateNewDocument('PCB');
    PTstPanelBoard := PCBServer.GetCurrentPCBBoard;
    if PTstPanelBoard = nil then
    begin
        PTstShowBox(LabelErrNew.Caption, 16);
        Exit;
    end;

    PCBServer.PreProcess;
    try
        PTstPlaceEmbeddedArray(PTstPanelBoard);
        PTstDrawAllMillPaths(PTstPanelBoard, PTstMechLayer);
        PTstDrawCommonOuterContour(PTstPanelBoard, PTstMechLayer);

        PTstPanelBoard.LayerIsDisplayed[PTstMechLayer] := True;

        { Board outline панели из внешнего контура. }
        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        { Выделить только внешнюю рамку сложно; задаём outline из примитивов на mech, если пользователь подтвердит.
          Делаем outline из четырёх сторон панели через PlaceBoardOutline. }
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=All', 255, Client.CurrentView);
    PTstShowBox(LabelInfoDone.Caption + IntToStr(PTstCols) + 'x' + IntToStr(PTstRows) + sLineBreak +
               LabelInfoSize.Caption + FormatFloat('0.##', PTstPanelW) + ' x ' + FormatFloat('0.##', PTstPanelH) + sLineBreak +
               LabelInfoLayer.Caption + Layer2String(PTstMechLayer), 64);
end;

procedure TFormPTst.ButtonBrowseClick(PTstSender: TObject);
var
    PTstDlg : TOpenDialog;
    PTstWS : IWorkspace;
begin
    PTstDlg := TOpenDialog.Create(nil);
    try
        PTstDlg.Title := LabelDlgTitle.Caption;
        PTstDlg.Filter := 'PCB (*.PcbDoc)|*.PcbDoc';
        if PTstDlg.Execute then
        begin
            PTstSourcePath := PTstDlg.FileName;
            EditFile.Text := PTstSourcePath;
            PTstWS := GetWorkspace;
            if PTstWS <> nil then
                PTstWS.DM_OpenProject(PTstSourcePath, False);
            PTstSourceBoard := PCBServer.GetPCBBoardByPath(PTstSourcePath);
            if PTstSourceBoard = nil then
                PTstSourceBoard := PCBServer.GetCurrentPCBBoard;
            if PTstSourceBoard = nil then
                PTstShowBox(LabelWarnOpen.Caption, 48);
        end;
    finally
        PTstDlg.Free;
    end;
end;

procedure TFormPTst.ButtonOKClick(PTstSender: TObject);
begin
    PTstSourcePath := EditFile.Text;
    if (PTstSourcePath = '') or (not FileExists(PTstSourcePath)) then
    begin
        PTstShowBox(LabelErrFile.Caption, 16);
        Exit;
    end;
    if not PTstParsePositiveInt(EditRows.Text, PTstRows) then
    begin
        PTstShowBox(LabelErrRows.Caption, 16);
        Exit;
    end;
    if not PTstParsePositiveInt(EditCols.Text, PTstCols) then
    begin
        PTstShowBox(LabelErrCols.Caption, 16);
        Exit;
    end;
    if not PTstParsePositive(EditGapX.Text, PTstGapX) then begin PTstShowBox(LabelErrGapX.Caption, 16); Exit; end;
    if not PTstParsePositive(EditGapY.Text, PTstGapY) then begin PTstShowBox(LabelErrGapY.Caption, 16); Exit; end;
    if not PTstParsePositive(EditMargin.Text, PTstMargin) then begin PTstShowBox(LabelErrMargin.Caption, 16); Exit; end;
    if not PTstParsePositive(EditTab.Text, PTstTabW) then begin PTstShowBox(LabelErrTab.Caption, 16); Exit; end;
    if not PTstParseNonNeg(EditFillet.Text, PTstFilletR) then begin PTstShowBox(LabelErrMill.Caption, 16); Exit; end;
    if not PTstParsePositive(EditOff.Text, PTstOffMM) then begin PTstShowBox(LabelErrOff.Caption, 16); Exit; end;
    if not PTstParsePositiveInt(EditMech.Text, PTstMechIndex) then
    begin
        PTstShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;
    if (PTstMechIndex < 1) or (PTstMechIndex > 32) then
    begin
        PTstShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;

    if PTstSourceBoard = nil then
        PTstSourceBoard := PCBServer.GetPCBBoardByPath(PTstSourcePath);
    if PTstSourceBoard = nil then
    begin
        PTstShowBox(LabelErrLoad.Caption, 16);
        Exit;
    end;

    FormPTst.Close;
    PTstBuildPanel;
end;

procedure TFormPTst.ButtonCancelClick(PTstSender: TObject);
begin
    FormPTst.Close;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function PTstCS_ScriptFolder : String;
var
    PTstWS  : IWorkspace;
    PTstPrj : IProject;
    PTsti   : Integer;
    PTstP, PTstName : String;
begin
    Result := '';
    try
        PTstWS := GetWorkspace;
        if PTstWS = nil then Exit;
        for PTsti := 0 to PTstWS.DM_ProjectCount - 1 do
        begin
            PTstPrj := PTstWS.DM_Projects(PTsti);
            if PTstPrj = nil then Continue;
            PTstP := PTstPrj.DM_ProjectFullPath;
            PTstName := UpperCase(ExtractFileName(PTstP));
            if PTstName = 'PANELIZERTEST.PRJSCR' then
            begin
                Result := ExtractFilePath(PTstP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function PTstCS_FindImageFile(const PTstFileName : String) : String;
var
    PTstDir, PTstP : String;
begin
    Result := '';
    PTstDir := PTstCS_ScriptFolder;
    if PTstDir <> '' then
    begin
        PTstP := PTstDir + PTstFileName;
        if FileExists(PTstP) then begin Result := PTstP; Exit; end;
        PTstP := PTstDir + 'images\' + PTstFileName;
        if FileExists(PTstP) then begin Result := PTstP; Exit; end;
    end;
    if FileExists(PTstFileName) then begin Result := PTstFileName; Exit; end;
    PTstP := 'images\' + PTstFileName;
    if FileExists(PTstP) then Result := PTstP;
end;

procedure PTstCS_TryOneHelpFile(const PTstName : String; var PTstDone : Boolean);
var
    PTstP : String;
begin
    if PTstDone then Exit;
    PTstP := PTstCS_FindImageFile(PTstName);
    if (PTstP = '') or (not FileExists(PTstP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(PTstP);
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
        PTstDone := True;
    except
    end;
end;

procedure PTstCS_TryLoadHelpImage(const PTstBmpName : String; const PTstPngName : String);
var
    PTstDone : Boolean;
begin
    PTstDone := False;
    PTstCS_TryOneHelpFile(PTstPngName, PTstDone);
    PTstCS_TryOneHelpFile(PTstBmpName, PTstDone);
    PTstCS_TryOneHelpFile('PanelizerTest.png', PTstDone);
    PTstCS_TryOneHelpFile('PanelizerTest.bmp', PTstDone);
    if not PTstDone then
        LabelImageHint.Caption := 'No image. Put ' + PTstPngName + ' next to the script or in images\.';
end;


procedure TFormPTst.FormPTstShow(PTstSender: TObject);
begin
    try
        PTstCS_TryLoadHelpImage('PanelizerTest.bmp', 'PanelizerTest.png');
    except
    end;
    EditCols.Text := '4';
    EditRows.Text := '2';
    EditGapX.Text := '2';
    EditGapY.Text := '2';
    EditMargin.Text := '10';
    EditTab.Text := '4';
    EditFillet.Text := '1';
    EditOff.Text := '2';
    try
        if PCBServer <> nil then
            PTstSourceBoard := PCBServer.GetCurrentPCBBoard
        else
            PTstSourceBoard := nil;
        if PTstSourceBoard <> nil then
        begin
            PTstSourcePath := PTstSourceBoard.FileName;
            EditFile.Text := PTstSourcePath;
        end;
    except
    end;
end;

procedure StartPanelizerTest;
begin
    FormPTst.ShowModal;
end;

procedure _StartPanelizerTest;
begin
    StartPanelizerTest;
end;
