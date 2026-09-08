{..............................................................................}
{ Offset.pas                                                                    }
{ CAD OFFSET: цепи треков/дуг/окружностей, параллель/концентр, стык            }
{ extend/trim в пересечении. Замкнутый: наружу от внутренней области.           }
{ Открытый: наружу = слева по ходу, внутрь = справа.                            }
{..............................................................................}

const
    OffPiValue = 3.141592653589793;
    OffJoinTol = 80;

var
    OffBoard     : IPCB_Board;
    OffDistMM    : Double;
    OffOutward   : Boolean;
    OffReplace   : Boolean;
    OffCreated   : Integer;
    OffRemoved   : Integer;
    OffSkipR     : Boolean;

procedure StartOffset; forward;
procedure _StartOffset; forward;
procedure TFormOff.ButtonOKClick(OffSender: TObject); forward;
procedure TFormOff.ButtonCancelClick(OffSender: TObject); forward;
procedure TFormOff.FormOffShow(OffSender: TObject); forward;

procedure OffShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

function OffParseFloat(const OffS : String; var OffV : Double) : Boolean;
var
    OffT : String;
    Offi : Integer;
    OffCh : Char;
    OffSign : Double;
    OffScale : Double;
    OffSeenDigit : Boolean;
    OffFrac : Boolean;
begin
    Result := False;
    OffV := 0;
    OffT := OffS;
    while (Length(OffT) > 0) and (OffT[1] = ' ') do
        OffT := Copy(OffT, 2, Length(OffT));
    while (Length(OffT) > 0) and (OffT[Length(OffT)] = ' ') do
        OffT := Copy(OffT, 1, Length(OffT) - 1);
    if OffT = '' then Exit;
    OffSign := 1;
    Offi := 1;
    if OffT[1] = '-' then
    begin
        OffSign := -1;
        Offi := 2;
    end
    else if OffT[1] = '+' then
        Offi := 2;
    OffSeenDigit := False;
    OffFrac := False;
    OffScale := 1;
    while Offi <= Length(OffT) do
    begin
        OffCh := OffT[Offi];
        if (OffCh = '.') or (OffCh = ',') then
        begin
            if OffFrac then Exit;
            OffFrac := True;
        end
        else if (OffCh >= '0') and (OffCh <= '9') then
        begin
            OffSeenDigit := True;
            if not OffFrac then
                OffV := OffV * 10 + (Ord(OffCh) - Ord('0'))
            else
            begin
                OffScale := OffScale * 10;
                OffV := OffV + (Ord(OffCh) - Ord('0')) / OffScale;
            end;
        end
        else
            Exit;
        Offi := Offi + 1;
    end;
    if not OffSeenDigit then Exit;
    OffV := OffV * OffSign;
    Result := True;
end;

function OffDist(OffX1, OffY1, OffX2, OffY2 : TCoord) : Double;
begin
    Result := Sqrt(Sqr(1.0 * (OffX2 - OffX1)) + Sqr(1.0 * (OffY2 - OffY1)));
end;

function OffSamePt(OffX1, OffY1, OffX2, OffY2 : TCoord) : Boolean;
begin
    Result := OffDist(OffX1, OffY1, OffX2, OffY2) <= OffJoinTol;
end;

function OffNormDeg(OffA : Double) : Double;
begin
    Result := OffA;
    while Result < 0 do
        Result := Result + 360;
    while Result >= 360 do
        Result := Result - 360;
end;

function OffAtan2Deg(OffY, OffX : Double) : Double;
begin
    if Abs(OffX) < 1e-18 then
    begin
        if OffY >= 0 then Result := 90 else Result := 270;
        Exit;
    end;
    Result := ArcTan(OffY / OffX) * 180.0 / OffPiValue;
    if OffX < 0 then Result := Result + 180;
    Result := OffNormDeg(Result);
end;

procedure OffArcXY(OffA : IPCB_Arc; OffDeg : Double; var OffX, OffY : TCoord);
var
    OffRmm, OffRad : Double;
begin
    OffRmm := CoordToMMs(OffA.Radius);
    OffRad := OffDeg * OffPiValue / 180.0;
    OffX := OffA.XCenter + MMsToCoord(OffRmm * Cos(OffRad));
    OffY := OffA.YCenter + MMsToCoord(OffRmm * Sin(OffRad));
end;

function OffIsCircle(OffA : IPCB_Arc) : Boolean;
var
    OffD : Double;
begin
    OffD := OffNormDeg(OffA.EndAngle - OffA.StartAngle);
    Result := (OffD < 0.5) or (OffD > 359.5);
end;

function OffAddTrack(OffX1, OffY1, OffX2, OffY2 : TCoord; OffALayer : TLayer; OffW : TCoord) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := OffX1;
    Result.Y1 := OffY1;
    Result.X2 := OffX2;
    Result.Y2 := OffY2;
    Result.Layer := OffALayer;
    Result.Width := OffW;
    OffBoard.AddPCBObject(Result);
    Inc(OffCreated);
end;

function OffAddArc(OffCX, OffCY, OffRadius : TCoord; OffSa, OffEa : Double; OffALayer : TLayer; OffW : TCoord) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := OffCX;
    Result.YCenter := OffCY;
    Result.Radius := OffRadius;
    Result.StartAngle := OffSa;
    Result.EndAngle := OffEa;
    Result.Layer := OffALayer;
    Result.LineWidth := OffW;
    OffBoard.AddPCBObject(Result);
    Inc(OffCreated);
end;

function OffIntersectLL(X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Double; var Xi, Yi : Double) : Boolean;
var
    OffDen, OffT : Double;
begin
    Result := False;
    OffDen := (X1 - X2) * (Y3 - Y4) - (Y1 - Y2) * (X3 - X4);
    if Abs(OffDen) < 1e-18 then Exit;
    OffT := ((X1 - X3) * (Y3 - Y4) - (Y1 - Y3) * (X3 - X4)) / OffDen;
    Xi := X1 + OffT * (X2 - X1);
    Yi := Y1 + OffT * (Y2 - Y1);
    Result := True;
end;

function OffIntersectLC(X1, Y1, X2, Y2, Cx, Cy, R : Double; HintX, HintY : Double; var Xi, Yi : Double) : Boolean;
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
    if D1 <= D2 then
    begin
        Xi := Px1; Yi := Py1;
    end
    else
    begin
        Xi := Px2; Yi := Py2;
    end;
    Result := True;
end;

function OffIntersectCC(C1x, C1y, R1, C2x, C2y, R2, HintX, HintY : Double; var Xi, Yi : Double) : Boolean;
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
    if D1 <= D2 then
    begin
        Xi := Px1; Yi := Py1;
    end
    else
    begin
        Xi := Px2; Yi := Py2;
    end;
    Result := True;
end;

procedure OffTrackEnds(OffT : IPCB_Track; OffRev : Boolean; var OffX1, OffY1, OffX2, OffY2 : TCoord);
begin
    if OffRev then
    begin
        OffX1 := OffT.X2; OffY1 := OffT.Y2;
        OffX2 := OffT.X1; OffY2 := OffT.Y1;
    end
    else
    begin
        OffX1 := OffT.X1; OffY1 := OffT.Y1;
        OffX2 := OffT.X2; OffY2 := OffT.Y2;
    end;
end;

procedure OffArcEnds(OffA : IPCB_Arc; OffRev : Boolean; var OffX1, OffY1, OffX2, OffY2 : TCoord);
begin
    if OffRev then
    begin
        OffArcXY(OffA, OffA.EndAngle, OffX1, OffY1);
        OffArcXY(OffA, OffA.StartAngle, OffX2, OffY2);
    end
    else
    begin
        OffArcXY(OffA, OffA.StartAngle, OffX1, OffY1);
        OffArcXY(OffA, OffA.EndAngle, OffX2, OffY2);
    end;
end;

function OffPrimStart(OffP : IPCB_Primitive; OffRev : Boolean; var OffX, OffY : TCoord) : Boolean;
var
    OffX2, OffY2 : TCoord;
begin
    Result := False;
    if OffP.ObjectId = eTrackObject then
    begin
        OffTrackEnds(OffP, OffRev, OffX, OffY, OffX2, OffY2);
        Result := True;
    end
    else if OffP.ObjectId = eArcObject then
    begin
        OffArcEnds(OffP, OffRev, OffX, OffY, OffX2, OffY2);
        Result := True;
    end;
end;

function OffPrimEnd(OffP : IPCB_Primitive; OffRev : Boolean; var OffX, OffY : TCoord) : Boolean;
var
    OffX1, OffY1 : TCoord;
begin
    Result := False;
    if OffP.ObjectId = eTrackObject then
    begin
        OffTrackEnds(OffP, OffRev, OffX1, OffY1, OffX, OffY);
        Result := True;
    end
    else if OffP.ObjectId = eArcObject then
    begin
        OffArcEnds(OffP, OffRev, OffX1, OffY1, OffX, OffY);
        Result := True;
    end;
end;

function OffNewRadius(OffOld : TCoord; OffAwayFromCenter : Boolean) : TCoord;
var
    OffRmm, OffD : Double;
begin
    OffRmm := CoordToMMs(OffOld);
    OffD := OffDistMM;
    if OffAwayFromCenter then
        OffRmm := OffRmm + OffD
    else
        OffRmm := OffRmm - OffD;
    if OffRmm <= 0 then
        Result := 0
    else
        Result := MMsToCoord(OffRmm);
end;

{ Сторона: +1 = слева по ходу (нормаль (-dy, dx) в мм). }
procedure OffOffsetTrackDir(OffT : IPCB_Track; OffRev : Boolean; OffLeft : Boolean; var OffNew : IPCB_Track);
var
    X1, Y1, X2, Y2 : TCoord;
    Dxfdx, Dxfdy, Len, Nx, Ny, OffD : Double;
    OffW : TCoord;
begin
    OffNew := nil;
    OffTrackEnds(OffT, OffRev, X1, Y1, X2, Y2);
    Dxfdx := CoordToMMs(X2 - X1);
    Dxfdy := CoordToMMs(Y2 - Y1);
    Len := Sqrt(Dxfdx * Dxfdx + Dxfdy * Dxfdy);
    if Len < 0.0001 then Exit;
    Nx := -Dxfdy / Len;
    Ny := Dxfdx / Len;
    if not OffLeft then
    begin
        Nx := -Nx;
        Ny := -Ny;
    end;
    OffD := OffDistMM;
    OffW := OffT.Width;
    if OffW < 1 then OffW := MMsToCoord(0.2);
    OffNew := OffAddTrack(
        X1 + MMsToCoord(Nx * OffD),
        Y1 + MMsToCoord(Ny * OffD),
        X2 + MMsToCoord(Nx * OffD),
        Y2 + MMsToCoord(Ny * OffD),
        OffT.Layer, OffW);
    if OffT.InNet then OffNew.Net := OffT.Net;
end;

procedure OffOffsetArcDir(OffA : IPCB_Arc; OffLeft : Boolean; var OffNew : IPCB_Arc);
var
    SX, SY, EX, EY : TCoord;
    Mx, My, Cx, Cy, Cross : Double;
    Away : Boolean;
    OffNR, OffW : TCoord;
begin
    OffNew := nil;
    OffArcXY(OffA, OffA.StartAngle, SX, SY);
    OffArcXY(OffA, OffA.EndAngle, EX, EY);
    Mx := CoordToMMs(EX - SX);
    My := CoordToMMs(EY - SY);
    Cx := CoordToMMs(OffA.XCenter - SX);
    Cy := CoordToMMs(OffA.YCenter - SY);
    { CCW-дуга: центр слева от хорды, если Cross > 0. }
    Cross := Mx * Cy - My * Cx;
    Away := OffLeft;
    if Cross > 0 then
        Away := OffLeft
    else
        Away := not OffLeft;
    OffNR := OffNewRadius(OffA.Radius, Away);
    if OffNR < 1 then
    begin
        OffSkipR := True;
        Exit;
    end;
    OffW := OffA.LineWidth;
    if OffW < 1 then OffW := MMsToCoord(0.2);
    OffNew := OffAddArc(OffA.XCenter, OffA.YCenter, OffNR,
                        OffA.StartAngle, OffA.EndAngle, OffA.Layer, OffW);
    if OffA.InNet then OffNew.Net := OffA.Net;
end;

procedure OffOffsetCircle(OffA : IPCB_Arc; OffGrow : Boolean; var OffNew : IPCB_Arc);
var
    OffNR, OffW : TCoord;
begin
    OffNew := nil;
    OffNR := OffNewRadius(OffA.Radius, OffGrow);
    if OffNR < 1 then
    begin
        OffSkipR := True;
        Exit;
    end;
    OffW := OffA.LineWidth;
    if OffW < 1 then OffW := MMsToCoord(0.2);
    OffNew := OffAddArc(OffA.XCenter, OffA.YCenter, OffNR,
                        OffA.StartAngle, OffA.EndAngle, OffA.Layer, OffW);
    if OffA.InNet then OffNew.Net := OffA.Net;
end;

procedure OffSetTrackPt(OffT : IPCB_Track; OffAtStart : Boolean; OffX, OffY : TCoord);
begin
    OffT.BeginModify;
    if OffAtStart then
    begin
        OffT.X1 := OffX; OffT.Y1 := OffY;
    end
    else
    begin
        OffT.X2 := OffX; OffT.Y2 := OffY;
    end;
    OffT.EndModify;
    OffT.GraphicallyInvalidate;
end;

{ OffChainStart: join at the chain-start of this offset arc (else chain-end). }
procedure OffSetArcChain(OffA : IPCB_Arc; OffChainStart : Boolean; OffRev : Boolean; OffX, OffY : TCoord);
var
    Ang : Double;
    UseStart : Boolean;
begin
    Ang := OffAtan2Deg(CoordToMMs(OffY - OffA.YCenter), CoordToMMs(OffX - OffA.XCenter));
    if OffChainStart then
        UseStart := not OffRev
    else
        UseStart := OffRev;
    OffA.BeginModify;
    if UseStart then
        OffA.StartAngle := Ang
    else
        OffA.EndAngle := Ang;
    OffA.EndModify;
    OffA.GraphicallyInvalidate;
end;

procedure OffJoinTwo(OffP0, OffN0 : IPCB_Primitive; OffRev0 : Boolean;
                     OffP1, OffN1 : IPCB_Primitive; OffRev1 : Boolean;
                     OffLeft : Boolean);
var
    Xi, Yi : Double;
    TX1, TY1, TX2, TY2, UX1, UY1, UX2, UY2 : TCoord;
    VX, VY : TCoord;
    A0, A1 : IPCB_Arc;
    T0, T1 : IPCB_Track;
    EX, EY, SX, SY : TCoord;
    D0x, D0y, D1x, D1y, Cross : Double;
    Ok, RoundC : Boolean;
    HX, HY : Double;
    W0 : TCoord;
begin
    if (OffN0 = nil) or (OffN1 = nil) then Exit;
    OffPrimStart(OffP0, OffRev0, SX, SY);
    OffPrimEnd(OffP0, OffRev0, VX, VY);
    OffPrimStart(OffP1, OffRev1, EX, EY);
    OffPrimEnd(OffP1, OffRev1, UX2, UY2);
    D0x := CoordToMMs(VX - SX);
    D0y := CoordToMMs(VY - SY);
    D1x := CoordToMMs(UX2 - EX);
    D1y := CoordToMMs(UY2 - EY);
    Cross := D0x * D1y - D0y * D1x;
    { Convex sharp (VCarve round): offset side opposite the turn. }
    RoundC := (OffP0.ObjectId = eTrackObject) and (OffP1.ObjectId = eTrackObject) and
              (((Cross > 0) and (not OffLeft)) or ((Cross < 0) and OffLeft));
    if RoundC then
    begin
        OffPrimEnd(OffN0, False, TX2, TY2);
        OffPrimStart(OffN1, False, UX1, UY1);
        W0 := MMsToCoord(0.2);
        if OffN0.ObjectId = eTrackObject then
        begin
            T0 := OffN0;
            if T0.Width > 0 then W0 := T0.Width;
        end;
        OffAddArc(VX, VY, MMsToCoord(OffDistMM),
                  OffAtan2Deg(CoordToMMs(TY2 - VY), CoordToMMs(TX2 - VX)),
                  OffAtan2Deg(CoordToMMs(UY1 - VY), CoordToMMs(UX1 - VX)),
                  OffN0.Layer, W0);
        Exit;
    end;
    Ok := False;
    Xi := 0; Yi := 0;
    HX := CoordToMMs(VX);
    HY := CoordToMMs(VY);
    if (OffN0.ObjectId = eTrackObject) and (OffN1.ObjectId = eTrackObject) then
    begin
        T0 := OffN0; T1 := OffN1;
        Ok := OffIntersectLL(CoordToMMs(T0.X1), CoordToMMs(T0.Y1), CoordToMMs(T0.X2), CoordToMMs(T0.Y2),
                             CoordToMMs(T1.X1), CoordToMMs(T1.Y1), CoordToMMs(T1.X2), CoordToMMs(T1.Y2),
                             Xi, Yi);
    end
    else if (OffN0.ObjectId = eTrackObject) and (OffN1.ObjectId = eArcObject) then
    begin
        T0 := OffN0; A1 := OffN1;
        Ok := OffIntersectLC(CoordToMMs(T0.X1), CoordToMMs(T0.Y1), CoordToMMs(T0.X2), CoordToMMs(T0.Y2),
                             CoordToMMs(A1.XCenter), CoordToMMs(A1.YCenter), CoordToMMs(A1.Radius),
                             HX, HY, Xi, Yi);
    end
    else if (OffN0.ObjectId = eArcObject) and (OffN1.ObjectId = eTrackObject) then
    begin
        A0 := OffN0; T1 := OffN1;
        Ok := OffIntersectLC(CoordToMMs(T1.X1), CoordToMMs(T1.Y1), CoordToMMs(T1.X2), CoordToMMs(T1.Y2),
                             CoordToMMs(A0.XCenter), CoordToMMs(A0.YCenter), CoordToMMs(A0.Radius),
                             HX, HY, Xi, Yi);
    end
    else if (OffN0.ObjectId = eArcObject) and (OffN1.ObjectId = eArcObject) then
    begin
        A0 := OffN0; A1 := OffN1;
        if OffSamePt(A0.XCenter, A0.YCenter, A1.XCenter, A1.YCenter) then
            Exit;
        Ok := OffIntersectCC(CoordToMMs(A0.XCenter), CoordToMMs(A0.YCenter), CoordToMMs(A0.Radius),
                             CoordToMMs(A1.XCenter), CoordToMMs(A1.YCenter), CoordToMMs(A1.Radius),
                             HX, HY, Xi, Yi);
    end;
    if Ok then
    begin
        TX1 := MMsToCoord(Xi);
        TY1 := MMsToCoord(Yi);
        if OffN0.ObjectId = eTrackObject then
            OffSetTrackPt(OffN0, False, TX1, TY1)
        else if OffN0.ObjectId = eArcObject then
            OffSetArcChain(OffN0, False, OffRev0, TX1, TY1);
        if OffN1.ObjectId = eTrackObject then
            OffSetTrackPt(OffN1, True, TX1, TY1)
        else if OffN1.ObjectId = eArcObject then
            OffSetArcChain(OffN1, True, OffRev1, TX1, TY1);
    end
    else
    begin
        OffPrimEnd(OffN0, False, TX2, TY2);
        OffPrimStart(OffN1, False, UX1, UY1);
        OffAddArc(VX, VY, MMsToCoord(OffDistMM),
                  OffAtan2Deg(CoordToMMs(TY2 - VY), CoordToMMs(TX2 - VX)),
                  OffAtan2Deg(CoordToMMs(UY1 - VY), CoordToMMs(UX1 - VX)),
                  OffN0.Layer, MMsToCoord(0.2));
    end;
end;

function OffChainArea(OffPrims, OffRevs : TStringList) : Double;
var
    Offi : Integer;
    X1, Y1, X2, Y2 : TCoord;
    OffP : IPCB_Primitive;
begin
    Result := 0;
    for Offi := 0 to OffPrims.Count - 1 do
    begin
        OffP := OffPrims.Objects[Offi];
        if not OffPrimStart(OffP, OffRevs[Offi] = '1', X1, Y1) then Continue;
        if not OffPrimEnd(OffP, OffRevs[Offi] = '1', X2, Y2) then Continue;
        Result := Result + CoordToMMs(X1) * CoordToMMs(Y2) - CoordToMMs(X2) * CoordToMMs(Y1);
    end;
end;

function OffFindMate(OffUsed : TStringList; OffAll : TStringList; OffX, OffY : TCoord;
                     var OffIdx : Integer; var OffRev : Boolean) : Boolean;
var
    Offi : Integer;
    OffP : IPCB_Primitive;
    SX, SY, EX, EY : TCoord;
begin
    Result := False;
    OffIdx := -1;
    for Offi := 0 to OffAll.Count - 1 do
    begin
        if OffUsed[Offi] = '1' then Continue;
        OffP := OffAll.Objects[Offi];
        if OffP.ObjectId = eArcObject then
            if OffIsCircle(OffP) then Continue;
        if OffP.ObjectId = eTrackObject then
        begin
            SX := OffP.X1; SY := OffP.Y1; EX := OffP.X2; EY := OffP.Y2;
            if OffSamePt(OffX, OffY, SX, SY) then
            begin
                OffIdx := Offi; OffRev := False; Result := True; Exit;
            end;
            if OffSamePt(OffX, OffY, EX, EY) then
            begin
                OffIdx := Offi; OffRev := True; Result := True; Exit;
            end;
        end
        else if OffP.ObjectId = eArcObject then
        begin
            OffArcEnds(OffP, False, SX, SY, EX, EY);
            if OffSamePt(OffX, OffY, SX, SY) then
            begin
                OffIdx := Offi; OffRev := False; Result := True; Exit;
            end;
            if OffSamePt(OffX, OffY, EX, EY) then
            begin
                OffIdx := Offi; OffRev := True; Result := True; Exit;
            end;
        end;
    end;
end;

procedure OffOffsetChain(OffPrims, OffRevs : TStringList; OffClosed : Boolean);
var
    Offi : Integer;
    OffLeft : Boolean;
    Area : Double;
    OffP : IPCB_Primitive;
    OffTN : IPCB_Track;
    OffAN : IPCB_Arc;
    News : TStringList;
begin
    if OffPrims.Count = 0 then Exit;
    OffLeft := OffOutward;
    if OffClosed then
    begin
        Area := OffChainArea(OffPrims, OffRevs);
        { CCW (Area>0): интерьер слева; наружу = справа = not left. }
        if Area > 0 then
            OffLeft := not OffOutward
        else
            OffLeft := OffOutward;
    end;
    News := TStringList.Create;
    try
        for Offi := 0 to OffPrims.Count - 1 do
        begin
            OffP := OffPrims.Objects[Offi];
            if OffP.ObjectId = eTrackObject then
            begin
                OffOffsetTrackDir(OffP, OffRevs[Offi] = '1', OffLeft, OffTN);
                News.AddObject('T', OffTN);
            end
            else
            begin
                OffOffsetArcDir(OffP, OffLeft, OffAN);
                News.AddObject('A', OffAN);
            end;
        end;
        for Offi := 0 to OffPrims.Count - 2 do
            OffJoinTwo(OffPrims.Objects[Offi], News.Objects[Offi], OffRevs[Offi] = '1',
                       OffPrims.Objects[Offi + 1], News.Objects[Offi + 1], OffRevs[Offi + 1] = '1', OffLeft);
        if OffClosed and (OffPrims.Count > 1) then
            OffJoinTwo(OffPrims.Objects[OffPrims.Count - 1], News.Objects[News.Count - 1],
                       OffRevs[OffRevs.Count - 1] = '1',
                       OffPrims.Objects[0], News.Objects[0], OffRevs[0] = '1', OffLeft);
    finally
        News.Free;
    end;
end;

procedure OffBuildAndOffset;
var
    OffAll, OffUsed, OffChain, OffRevs : TStringList;
    Offi, OffIdx, OffGuard : Integer;
    OffPrim : IPCB_Primitive;
    OffAN : IPCB_Arc;
    OffRev, OffClosed : Boolean;
    SX, SY, EX, EY, HeadX, HeadY : TCoord;
begin
    OffAll := TStringList.Create;
    OffUsed := TStringList.Create;
    OffSkipR := False;
    try
        for Offi := 0 to OffBoard.SelectecObjectCount - 1 do
        begin
            OffPrim := OffBoard.SelectecObject(Offi);
            if (OffPrim.ObjectId = eTrackObject) or (OffPrim.ObjectId = eArcObject) then
            begin
                OffAll.AddObject('P', OffPrim);
                OffUsed.Add('0');
            end;
        end;
        { Окружности — отдельно, концентрически. }
        for Offi := 0 to OffAll.Count - 1 do
        begin
            OffPrim := OffAll.Objects[Offi];
            if OffPrim.ObjectId <> eArcObject then Continue;
            if not OffIsCircle(OffPrim) then Continue;
            OffUsed[Offi] := '1';
            OffOffsetCircle(OffPrim, OffOutward, OffAN);
        end;
        for Offi := 0 to OffAll.Count - 1 do
        begin
            if OffUsed[Offi] = '1' then Continue;
            OffChain := TStringList.Create;
            OffRevs := TStringList.Create;
            try
                OffUsed[Offi] := '1';
                OffChain.AddObject('P', OffAll.Objects[Offi]);
                OffRevs.Add('0');
                OffPrimEnd(OffAll.Objects[Offi], False, HeadX, HeadY);
                OffGuard := 0;
                while OffGuard < OffAll.Count + 2 do
                begin
                    Inc(OffGuard);
                    if not OffFindMate(OffUsed, OffAll, HeadX, HeadY, OffIdx, OffRev) then Break;
                    OffUsed[OffIdx] := '1';
                    OffChain.AddObject('P', OffAll.Objects[OffIdx]);
                    if OffRev then OffRevs.Add('1') else OffRevs.Add('0');
                    OffPrimEnd(OffAll.Objects[OffIdx], OffRev, HeadX, HeadY);
                end;
                OffPrimStart(OffChain.Objects[0], OffRevs[0] = '1', SX, SY);
                OffPrimEnd(OffChain.Objects[OffChain.Count - 1], OffRevs[OffRevs.Count - 1] = '1', EX, EY);
                OffClosed := OffSamePt(SX, SY, EX, EY) and (OffChain.Count > 1);
                OffOffsetChain(OffChain, OffRevs, OffClosed);
            finally
                OffChain.Free;
                OffRevs.Free;
            end;
        end;
    finally
        OffUsed.Free;
        OffAll.Free;
    end;
    if OffSkipR then
        OffShowBox(LabelWarnR.Caption, 48);
end;

procedure OffDeleteSelected;
var
    Offi : Integer;
    OffPrim : IPCB_Primitive;
    OffKill : TStringList;
begin
    OffKill := TStringList.Create;
    try
        for Offi := 0 to OffBoard.SelectecObjectCount - 1 do
        begin
            OffPrim := OffBoard.SelectecObject(Offi);
            if (OffPrim.ObjectId = eTrackObject) or (OffPrim.ObjectId = eArcObject) then
                OffKill.AddObject('K', OffPrim);
        end;
        for Offi := 0 to OffKill.Count - 1 do
        begin
            OffBoard.BeginModify;
            OffBoard.RemovePCBObject(OffKill.Objects[Offi]);
            OffBoard.DispatchMessage(OffBoard.I_ObjectAddress, c_BroadCast, PCBM_BoardRegisteration, OffKill.Objects[Offi].I_ObjectAddress);
            OffBoard.EndModify;
            Inc(OffRemoved);
        end;
    finally
        OffKill.Free;
    end;
end;

procedure DoOffsetWork;
var
    Offi, Offn : Integer;
    OffPrim : IPCB_Primitive;
begin
    Offn := 0;
    for Offi := 0 to OffBoard.SelectecObjectCount - 1 do
    begin
        OffPrim := OffBoard.SelectecObject(Offi);
        if (OffPrim.ObjectId = eTrackObject) or (OffPrim.ObjectId = eArcObject) then
            Inc(Offn);
    end;
    if Offn = 0 then
    begin
        OffShowBox(LabelWarnNone.Caption, 48);
        Exit;
    end;
    OffCreated := 0;
    OffRemoved := 0;
    PCBServer.PreProcess;
    try
        OffBuildAndOffset;
        if OffReplace then
            OffDeleteSelected;
    finally
        PCBServer.PostProcess;
    end;
    OffBoard.ViewManager_FullUpdate;
    OffShowBox(LabelInfoDone.Caption + IntToStr(OffCreated) + sLineBreak +
               LabelInfoDel.Caption + IntToStr(OffRemoved), 64);
end;

function OffCS_ScriptFolder : String;
var
    OffWS  : IWorkspace;
    OffPrj : IProject;
    Offi   : Integer;
    OffP, OffName : String;
begin
    Result := '';
    try
        OffWS := GetWorkspace;
        if OffWS = nil then Exit;
        for Offi := 0 to OffWS.DM_ProjectCount - 1 do
        begin
            OffPrj := OffWS.DM_Projects(Offi);
            if OffPrj = nil then Continue;
            OffP := OffPrj.DM_ProjectFullPath;
            OffName := UpperCase(ExtractFileName(OffP));
            if OffName = 'OFFSET.PRJSCR' then
            begin
                Result := ExtractFilePath(OffP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function OffCS_FindImageFile(const OffFileName : String) : String;
var
    OffDir, OffP : String;
begin
    Result := '';
    OffDir := OffCS_ScriptFolder;
    if OffDir <> '' then
    begin
        OffP := OffDir + OffFileName;
        if FileExists(OffP) then begin Result := OffP; Exit; end;
        OffP := OffDir + 'images\' + OffFileName;
        if FileExists(OffP) then begin Result := OffP; Exit; end;
    end;
    if FileExists(OffFileName) then begin Result := OffFileName; Exit; end;
    OffP := 'images\' + OffFileName;
    if FileExists(OffP) then Result := OffP;
end;

procedure OffCS_TryOneHelpFile(const OffName : String; var OffDone : Boolean);
var
    OffP : String;
begin
    if OffDone then Exit;
    OffP := OffCS_FindImageFile(OffName);
    if (OffP = '') or (not FileExists(OffP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(OffP);
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
        OffDone := True;
    except
    end;
end;

procedure OffCS_TryLoadHelpImage(const OffBmpName : String; const OffPngName : String);
var
    OffDone : Boolean;
begin
    OffDone := False;
    OffCS_TryOneHelpFile(OffPngName, OffDone);
    OffCS_TryOneHelpFile(OffBmpName, OffDone);
    OffCS_TryOneHelpFile('Offset.png', OffDone);
    OffCS_TryOneHelpFile('Offset.bmp', OffDone);
    if not OffDone then
        LabelImageHint.Caption := 'No image. Put ' + OffPngName + ' next to the script or in images\.';
end;

procedure TFormOff.FormOffShow(OffSender: TObject);
begin
    try
        OffCS_TryLoadHelpImage('Offset.bmp', 'Offset.png');
    except
    end;
    EditDist.Text := '0.5';
    RadioOut.Checked := True;
    CheckReplace.Checked := False;
end;

procedure TFormOff.ButtonOKClick(OffSender: TObject);
begin
    if not OffParseFloat(EditDist.Text, OffDistMM) then
    begin
        OffShowBox(LabelErrDist.Caption, 16);
        Exit;
    end;
    if OffDistMM <= 0 then
    begin
        OffShowBox(LabelErrDist.Caption, 16);
        Exit;
    end;
    OffOutward := RadioOut.Checked;
    OffReplace := CheckReplace.Checked;
    if PCBServer = nil then
    begin
        OffShowBox(LabelErrNoPcb.Caption, 16);
        Exit;
    end;
    OffBoard := PCBServer.GetCurrentPCBBoard;
    if OffBoard = nil then
    begin
        OffShowBox(LabelErrNoPcb.Caption, 16);
        Exit;
    end;
    FormOff.Close;
    DoOffsetWork;
end;

procedure TFormOff.ButtonCancelClick(OffSender: TObject);
begin
    FormOff.Close;
end;

procedure StartOffset;
begin
    FormOff.ShowModal;
end;

procedure _StartOffset;
begin
    StartOffset;
end;
