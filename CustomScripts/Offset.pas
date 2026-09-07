{..............................................................................}
{ Offset.pas                                                                    }
{ Параллельный offset выделенных треков (открытая цепь или замкнутый контур). }
{ Наружу = справа по ходу для CCW-контура; внутрь — наоборот.                 }
{..............................................................................}

const
    OffPiValue = 3.141592653589793;
    OffJoinTol = 50;

var
    OffBoard     : IPCB_Board;
    OffDistMM    : Double;
    OffOutward   : Boolean;
    OffReplace   : Boolean;
    OffCreated   : Integer;
    OffRemoved   : Integer;

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

function OffIntersect(X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Double; var Xi, Yi : Double) : Boolean;
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

procedure OffGetEnds(OffT : IPCB_Track; Rev : Boolean; var OffX1, OffY1, OffX2, OffY2 : TCoord);
begin
    if Rev then
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

procedure OffArcXY(OffA : IPCB_Arc; OffDeg : Double; var OffX, OffY : TCoord);
var
    OffRmm : Double;
begin
    OffRmm := CoordToMMs(OffA.Radius);
    OffX := OffA.XCenter + MMsToCoord(OffRmm * Cos(OffDeg * OffPiValue / 180.0));
    OffY := OffA.YCenter + MMsToCoord(OffRmm * Sin(OffDeg * OffPiValue / 180.0));
end;

function OffNewRadius(OffOld : TCoord) : TCoord;
var
    OffRmm, OffD : Double;
begin
    OffRmm := CoordToMMs(OffOld);
    OffD := OffDistMM;
    if OffOutward then
        OffRmm := OffRmm + OffD
    else
        OffRmm := OffRmm - OffD;
    if OffRmm <= 0 then
        Result := 0
    else
        Result := MMsToCoord(OffRmm);
end;

procedure OffOffsetArc(OffA : IPCB_Arc; var OffNew : IPCB_Arc);
var
    OffNR, OffW : TCoord;
begin
    OffNew := nil;
    OffNR := OffNewRadius(OffA.Radius);
    if OffNR < 1 then
    begin
        OffShowBox(LabelWarnR.Caption, 48);
        Exit;
    end;
    OffW := OffA.LineWidth;
    if OffW < 1 then OffW := MMsToCoord(0.2);
    OffNew := OffAddArc(OffA.XCenter, OffA.YCenter, OffNR,
                        OffA.StartAngle, OffA.EndAngle, OffA.Layer, OffW);
    if OffA.InNet then OffNew.Net := OffA.Net;
end;

procedure OffOffsetTrack(OffT : IPCB_Track; var OffNew : IPCB_Track);
var
    Dxfdx, Dxfdy, Len, Nx, Ny, OffD : Double;
    OffW : TCoord;
begin
    OffNew := nil;
    Dxfdx := CoordToMMs(OffT.X2 - OffT.X1);
    Dxfdy := CoordToMMs(OffT.Y2 - OffT.Y1);
    Len := Sqrt(Dxfdx * Dxfdx + Dxfdy * Dxfdy);
    if Len < 0.0001 then Exit;
    { Справа по ходу; внутрь — слева. }
    Nx := Dxfdy / Len;
    Ny := -Dxfdx / Len;
    OffD := OffDistMM;
    if not OffOutward then
    begin
        Nx := -Nx;
        Ny := -Ny;
    end;
    OffW := OffT.Width;
    if OffW < 1 then OffW := MMsToCoord(0.2);
    OffNew := OffAddTrack(
        OffT.X1 + MMsToCoord(Nx * OffD),
        OffT.Y1 + MMsToCoord(Ny * OffD),
        OffT.X2 + MMsToCoord(Nx * OffD),
        OffT.Y2 + MMsToCoord(Ny * OffD),
        OffT.Layer, OffW);
    if OffT.InNet then OffNew.Net := OffT.Net;
end;

procedure OffSnapTrackToArc(OffT0 : IPCB_Track; OffTn : IPCB_Track; OffA0 : IPCB_Arc; OffAn : IPCB_Arc);
var
    SX, SY, EX, EY, NSX, NSY, NEX, NEY : TCoord;
begin
    if (OffT0 = nil) or (OffTn = nil) or (OffA0 = nil) or (OffAn = nil) then Exit;
    OffArcXY(OffA0, OffA0.StartAngle, SX, SY);
    OffArcXY(OffA0, OffA0.EndAngle, EX, EY);
    OffArcXY(OffAn, OffAn.StartAngle, NSX, NSY);
    OffArcXY(OffAn, OffAn.EndAngle, NEX, NEY);
    OffTn.BeginModify;
    if OffSamePt(OffT0.X1, OffT0.Y1, SX, SY) then
    begin
        OffTn.X1 := NSX; OffTn.Y1 := NSY;
    end
    else if OffSamePt(OffT0.X1, OffT0.Y1, EX, EY) then
    begin
        OffTn.X1 := NEX; OffTn.Y1 := NEY;
    end;
    if OffSamePt(OffT0.X2, OffT0.Y2, SX, SY) then
    begin
        OffTn.X2 := NSX; OffTn.Y2 := NSY;
    end
    else if OffSamePt(OffT0.X2, OffT0.Y2, EX, EY) then
    begin
        OffTn.X2 := NEX; OffTn.Y2 := NEY;
    end;
    OffTn.EndModify;
    OffTn.GraphicallyInvalidate;
end;

procedure OffBuildAndOffset;
var
    OffTracks0, OffTracksN, OffArcs0, OffArcsN : TStringList;
    Offi, Offj : Integer;
    OffPrim : IPCB_Primitive;
    OffT, OffTn : IPCB_Track;
    OffA, OffAn : IPCB_Arc;
begin
    OffTracks0 := TStringList.Create;
    OffTracksN := TStringList.Create;
    OffArcs0 := TStringList.Create;
    OffArcsN := TStringList.Create;
    try
        for Offi := 0 to OffBoard.SelectecObjectCount - 1 do
        begin
            OffPrim := OffBoard.SelectecObject(Offi);
            if OffPrim.ObjectId = eTrackObject then
                OffTracks0.AddObject('T', OffPrim)
            else if OffPrim.ObjectId = eArcObject then
                OffArcs0.AddObject('A', OffPrim);
        end;
        for Offi := 0 to OffArcs0.Count - 1 do
        begin
            OffOffsetArc(OffArcs0.Objects[Offi], OffAn);
            OffArcsN.AddObject('A', OffAn);
        end;
        for Offi := 0 to OffTracks0.Count - 1 do
        begin
            OffOffsetTrack(OffTracks0.Objects[Offi], OffTn);
            OffTracksN.AddObject('T', OffTn);
        end;
        for Offi := 0 to OffTracks0.Count - 1 do
        begin
            OffT := OffTracks0.Objects[Offi];
            OffTn := OffTracksN.Objects[Offi];
            if OffTn = nil then Continue;
            for Offj := 0 to OffArcs0.Count - 1 do
            begin
                OffA := OffArcs0.Objects[Offj];
                OffAn := OffArcsN.Objects[Offj];
                OffSnapTrackToArc(OffT, OffTn, OffA, OffAn);
            end;
        end;
    finally
        OffTracks0.Free;
        OffTracksN.Free;
        OffArcs0.Free;
        OffArcsN.Free;
    end;
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
