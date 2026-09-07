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

function OffFindSelAt(OffX, OffY : TCoord; IgnoreAddr : Integer) : IPCB_Track;
var
    Offi : Integer;
    OffPrim : IPCB_Primitive;
begin
    Result := nil;
    for Offi := 0 to OffBoard.SelectecObjectCount - 1 do
    begin
        OffPrim := OffBoard.SelectecObject(Offi);
        if OffPrim.ObjectId <> eTrackObject then Continue;
        if OffPrim.I_ObjectAddress = IgnoreAddr then Continue;
        if OffSamePt(OffX, OffY, OffPrim.X1, OffPrim.Y1) or
           OffSamePt(OffX, OffY, OffPrim.X2, OffPrim.Y2) then
        begin
            Result := OffPrim;
            Exit;
        end;
    end;
end;

function OffUsed(OffUsedList : TStringList; OffAddr : Integer) : Boolean;
begin
    Result := OffUsedList.IndexOf(IntToStr(OffAddr)) >= 0;
end;

procedure OffMark(OffUsedList : TStringList; OffAddr : Integer);
begin
    if not OffUsed(OffUsedList, OffAddr) then
        OffUsedList.Add(IntToStr(OffAddr));
end;

procedure OffOffsetChain(OffChain : TStringList; OffClosed : Boolean; OffDistC : TCoord);
var
    Offn, Offi, Offj : Integer;
    OffT : IPCB_Track;
    OffRev : Boolean;
    PX1, PY1, PX2, PY2 : TCoord;
    QX1, QY1, QX2, QY2 : TCoord;
    Area, InX, InY, OutX, OutY, InLen, OutLen : Double;
    Nx, Ny, Mx, My, CrossZ : Double;
    Ox1, Oy1, Ox2, Oy2 : Double;
    Px, Py, Qx, Qy, Xi, Yi : Double;
    OffLayer : TLayer;
    OffW : TCoord;
    OffSa, OffEa : Double;
    DoRight : Boolean;
    DrawX1, DrawY1, DrawX2, DrawY2 : Double;
begin
    Offn := OffChain.Count;
    if Offn < 1 then Exit;
    OffT := OffChain.Objects[0];
    OffLayer := OffT.Layer;
    OffW := OffT.Width;
    if OffW < 1 then OffW := MMsToCoord(0.2);

    Area := 0;
    for Offi := 0 to Offn - 1 do
    begin
        OffT := OffChain.Objects[Offi];
        OffRev := OffChain[Offi] = '1';
        OffGetEnds(OffT, OffRev, PX1, PY1, PX2, PY2);
        Area := Area + (1.0 * PX1 * PY2 - 1.0 * PX2 * PY1);
    end;
    { CCW (Area>0): наружу = справа по ходу. CW: наружу = слева. }
    DoRight := True;
    if OffClosed and (Area < 0) then
        DoRight := False;
    if not OffOutward then
        DoRight := not DoRight;

    for Offi := 0 to Offn - 1 do
    begin
        OffT := OffChain.Objects[Offi];
        OffRev := OffChain[Offi] = '1';
        OffGetEnds(OffT, OffRev, PX1, PY1, PX2, PY2);
        InX := 1.0 * (PX2 - PX1);
        InY := 1.0 * (PY2 - PY1);
        InLen := Sqrt(InX * InX + InY * InY);
        if InLen < 1 then Continue;
        InX := InX / InLen;
        InY := InY / InLen;
        if DoRight then
        begin
            Nx := InY;
            Ny := -InX;
        end
        else
        begin
            Nx := -InY;
            Ny := InX;
        end;
        Ox1 := PX1 + Nx * OffDistC;
        Oy1 := PY1 + Ny * OffDistC;
        Ox2 := PX2 + Nx * OffDistC;
        Oy2 := PY2 + Ny * OffDistC;
        DrawX1 := Ox1; DrawY1 := Oy1; DrawX2 := Ox2; DrawY2 := Oy2;

        if (OffClosed or (Offi < Offn - 1)) then
        begin
            if Offi = Offn - 1 then Offj := 0 else Offj := Offi + 1;
            OffT := OffChain.Objects[Offj];
            OffRev := OffChain[Offj] = '1';
            OffGetEnds(OffT, OffRev, QX1, QY1, QX2, QY2);
            OutX := 1.0 * (QX2 - QX1);
            OutY := 1.0 * (QY2 - QY1);
            OutLen := Sqrt(OutX * OutX + OutY * OutY);
            if OutLen >= 1 then
            begin
                OutX := OutX / OutLen;
                OutY := OutY / OutLen;
                if DoRight then
                begin
                    Mx := OutY;
                    My := -OutX;
                end
                else
                begin
                    Mx := -OutY;
                    My := OutX;
                end;
                Px := QX1 + Mx * OffDistC;
                Py := QY1 + My * OffDistC;
                Qx := QX2 + Mx * OffDistC;
                Qy := QY2 + My * OffDistC;
                CrossZ := InX * OutY - InY * OutX;
                if (DoRight and (CrossZ < -1e-6)) or ((not DoRight) and (CrossZ > 1e-6)) then
                begin
                    OffAddTrack(Round(DrawX1), Round(DrawY1), Round(DrawX2), Round(DrawY2), OffLayer, OffW);
                    OffSa := OffNormDeg(ArcTan2(Oy2 - PY2, Ox2 - PX2) * 180.0 / OffPiValue);
                    OffEa := OffNormDeg(ArcTan2(Py - QY1, Px - QX1) * 180.0 / OffPiValue);
                    if Abs(OffSa - OffEa) > 0.5 then
                        OffAddArc(PX2, PY2, OffDistC, OffSa, OffEa, OffLayer, OffW);
                end
                else if OffIntersect(Ox1, Oy1, Ox2, Oy2, Px, Py, Qx, Qy, Xi, Yi) then
                    OffAddTrack(Round(Ox1), Round(Oy1), Round(Xi), Round(Yi), OffLayer, OffW)
                else
                    OffAddTrack(Round(DrawX1), Round(DrawY1), Round(DrawX2), Round(DrawY2), OffLayer, OffW);
            end
            else
                OffAddTrack(Round(DrawX1), Round(DrawY1), Round(DrawX2), Round(DrawY2), OffLayer, OffW);
        end
        else
            OffAddTrack(Round(DrawX1), Round(DrawY1), Round(DrawX2), Round(DrawY2), OffLayer, OffW);
    end;
end;

procedure OffBuildAndOffset;
var
    OffUsedList, OffChain, OffHead, OffTmp : TStringList;
    Offi, Offj : Integer;
    OffPrim : IPCB_Primitive;
    OffT, OffNext : IPCB_Track;
    OffX1, OffY1, OffX2, OffY2 : TCoord;
    OffHX, OffHY : TCoord;
    OffClosed : Boolean;
    OffDistC : TCoord;
    OffGrow : Boolean;
begin
    OffDistC := MMsToCoord(OffDistMM);
    if OffDistC < 1 then OffDistC := 1;
    OffUsedList := TStringList.Create;
    OffChain := TStringList.Create;
    try
        for Offi := 0 to OffBoard.SelectecObjectCount - 1 do
        begin
            OffPrim := OffBoard.SelectecObject(Offi);
            if OffPrim.ObjectId <> eTrackObject then Continue;
            if OffUsed(OffUsedList, OffPrim.I_ObjectAddress) then Continue;
            OffChain.Clear;
            OffT := OffPrim;
            OffChain.AddObject('0', OffT);
            OffMark(OffUsedList, OffT.I_ObjectAddress);
            OffGetEnds(OffT, False, OffX1, OffY1, OffX2, OffY2);
            OffGrow := True;
            while OffGrow do
            begin
                OffNext := OffFindSelAt(OffX2, OffY2, OffT.I_ObjectAddress);
                if (OffNext = nil) or OffUsed(OffUsedList, OffNext.I_ObjectAddress) then
                    OffGrow := False
                else
                begin
                    if OffSamePt(OffX2, OffY2, OffNext.X1, OffNext.Y1) then
                    begin
                        OffChain.AddObject('0', OffNext);
                        OffX2 := OffNext.X2; OffY2 := OffNext.Y2;
                    end
                    else
                    begin
                        OffChain.AddObject('1', OffNext);
                        OffX2 := OffNext.X1; OffY2 := OffNext.Y1;
                    end;
                    OffMark(OffUsedList, OffNext.I_ObjectAddress);
                    OffT := OffNext;
                end;
            end;
            OffT := OffChain.Objects[0];
            OffGetEnds(OffT, OffChain[0] = '1', OffX1, OffY1, OffHX, OffHY);
            OffGrow := True;
            OffHead := TStringList.Create;
            OffTmp := TStringList.Create;
            try
                while OffGrow do
                begin
                    OffNext := OffFindSelAt(OffX1, OffY1, OffT.I_ObjectAddress);
                    if (OffNext = nil) or OffUsed(OffUsedList, OffNext.I_ObjectAddress) then
                        OffGrow := False
                    else
                    begin
                        if OffSamePt(OffX1, OffY1, OffNext.X2, OffNext.Y2) then
                        begin
                            OffHead.AddObject('0', OffNext);
                            OffX1 := OffNext.X1; OffY1 := OffNext.Y1;
                        end
                        else
                        begin
                            OffHead.AddObject('1', OffNext);
                            OffX1 := OffNext.X2; OffY1 := OffNext.Y2;
                        end;
                        OffMark(OffUsedList, OffNext.I_ObjectAddress);
                        OffT := OffNext;
                    end;
                end;
                for Offj := OffHead.Count - 1 downto 0 do
                    OffTmp.AddObject(OffHead[Offj], OffHead.Objects[Offj]);
                for Offj := 0 to OffChain.Count - 1 do
                    OffTmp.AddObject(OffChain[Offj], OffChain.Objects[Offj]);
                OffChain.Clear;
                for Offj := 0 to OffTmp.Count - 1 do
                    OffChain.AddObject(OffTmp[Offj], OffTmp.Objects[Offj]);
            finally
                OffTmp.Free;
                OffHead.Free;
            end;
            OffT := OffChain.Objects[0];
            OffGetEnds(OffT, OffChain[0] = '1', OffX1, OffY1, OffHX, OffHY);
            OffT := OffChain.Objects[OffChain.Count - 1];
            OffGetEnds(OffT, OffChain[OffChain.Count - 1] = '1', OffHX, OffHY, OffX2, OffY2);
            OffClosed := OffSamePt(OffX1, OffY1, OffX2, OffY2) and (OffChain.Count > 2);
            OffOffsetChain(OffChain, OffClosed, OffDistC);
        end;
    finally
        OffChain.Free;
        OffUsedList.Free;
    end;
end;

procedure OffDeleteSelectedTracks;
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
            if OffPrim.ObjectId = eTrackObject then
                OffKill.AddObject(IntToStr(OffPrim.I_ObjectAddress), OffPrim);
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
        if OffPrim.ObjectId = eTrackObject then
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
            OffDeleteSelectedTracks;
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
