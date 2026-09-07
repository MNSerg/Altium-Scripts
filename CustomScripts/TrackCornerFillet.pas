{..............................................................................}
{ TrackCornerFillet.pas                                                         }
{ Скругления всех углов выделенного трека (IPCB_Track + IPCB_Arc).             }
{ Если скругления уже есть — спрашивает, переделать ли их.                      }
{ Altium Designer 20+. Единицы диалога: мм, внутри — TCoord.                    }
{..............................................................................}

const
    cDefaultRadiusMM = 0.5;
    cJoinTol         = 50;      // допуск стыковки концов, Coord (~0.005 mil * 10)
    cMinLength       = 10;
    FilPiValue          = 3.141592653589793;

var
    FilBoard          : IPCB_Board;
    RadiusCoord    : TCoord;
    ReplaceFillets : Boolean;
    AskedReplace   : Boolean;
    CreatedCount   : Integer;
    SkippedCount   : Integer;
    TooLargeCount  : Integer;
    RemovedCount   : Integer;

{ Run Script: choose procedure StartTrackCornerFillet (project compiles only this .pas). }
procedure StartTrackCornerFillet; forward;
procedure _StartTrackCornerFillet; forward;
procedure TFormFillet.ButtonOKClick(FilSender: TObject); forward;
procedure TFormFillet.ButtonCancelClick(FilSender: TObject); forward;
procedure TFormFillet.FormFilletShow(FilSender: TObject); forward;
procedure DoFilletWork; forward;
procedure RestoreTracksToCorner(FirstTrack, SecondTrack : IPCB_Track); forward;

function Distance(FilX1, FilY1, FilX2, FilY2 : TCoord) : Double;
begin
    Result := Sqrt(Sqr(1.0 * (FilX2 - FilX1)) + Sqr(1.0 * (FilY2 - FilY1)));
end;

function SamePoint(FilX1, FilY1, FilX2, FilY2 : TCoord) : Boolean;
begin
    Result := Distance(FilX1, FilY1, FilX2, FilY2) <= cJoinTol;
end;

{ DelphiScript: rfReplaceAll in square brackets is an Array Variant, not a set. }
function FilReplaceChar(const FilS : String; FilA, FilB : Char) : String;
var
    Fili : Integer;
    FilCh : Char;
begin
    Result := '';
    for Fili := 1 to Length(FilS) do
    begin
        FilCh := FilS[Fili];
        if FilCh = FilA then
            Result := Result + FilB
        else
            Result := Result + FilCh;
    end;
end;

function FilParseFloat(const FilS : String; var FilV : Double) : Boolean;
var
    FilT : String;
    FilCode : Integer;
begin
    Result := False;
    FilT := FilS;
    while (Length(FilT) > 0) and (FilT[1] = ' ') do
        FilT := Copy(FilT, 2, Length(FilT));
    while (Length(FilT) > 0) and (FilT[Length(FilT)] = ' ') do
        FilT := Copy(FilT, 1, Length(FilT) - 1);
    FilT := FilReplaceChar(FilT, ',', '.');
    if FilT = '' then Exit;
    Val(FilT, FilV, FilCode);
    Result := (FilCode = 0);
end;

function IsNumericMM(Text : String) : Boolean;
var
    FilV : Double;
begin
    Result := FilParseFloat(Text, FilV) and (FilV >= 0);
end;

procedure FilShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

function FilAskYesNo(const Msg : String) : Boolean;
begin
    Result := False;
    try
        Result := MessageBox(0, Msg, FormFillet.Caption, 36) = 6;
    except
        try Result := ConfirmNoYes(Msg); except end;
    end;
end;

function TrackEndX(ATrack : IPCB_Track; EndIdx : Integer) : TCoord;
begin
    if EndIdx = 1 then Result := ATrack.X1 else Result := ATrack.X2;
end;

function TrackEndY(ATrack : IPCB_Track; EndIdx : Integer) : TCoord;
begin
    if EndIdx = 1 then Result := ATrack.Y1 else Result := ATrack.Y2;
end;

function ArcEndX(AnArc : IPCB_Arc; EndIdx : Integer) : TCoord;
begin
    if EndIdx = 1 then Result := AnArc.StartX else Result := AnArc.EndX;
end;

function ArcEndY(AnArc : IPCB_Arc; EndIdx : Integer) : TCoord;
begin
    if EndIdx = 1 then Result := AnArc.StartY else Result := AnArc.EndY;
end;

function SameNetAndLayer(FilA, FilB : IPCB_Primitive) : Boolean;
begin
    Result := False;
    if (FilA = nil) or (FilB = nil) then Exit;
    if FilA.Layer <> FilB.Layer then Exit;
    if FilA.InNet and FilB.InNet then
    begin
        if FilA.Net <> FilB.Net then Exit;
    end;
    Result := True;
end;

{ Найти примитив (трек или дугу), стыкующийся с концом EndIdx объекта Prim. }
function FindConnectedAtEnd(FilPrim : IPCB_Primitive; EndIdx : Integer; SelectedOnly : Boolean) : IPCB_Primitive;
var
    SIter : IPCB_SpatialIterator;
    Other : IPCB_Primitive;
    Xp, Yp : TCoord;
    Fili : Integer;
begin
    Result := nil;
    if FilPrim.ObjectId = eTrackObject then
    begin
        Xp := TrackEndX(FilPrim, EndIdx);
        Yp := TrackEndY(FilPrim, EndIdx);
    end
    else if FilPrim.ObjectId = eArcObject then
    begin
        Xp := ArcEndX(FilPrim, EndIdx);
        Yp := ArcEndY(FilPrim, EndIdx);
    end
    else Exit;

    SIter := FilBoard.SpatialIterator_Create;
    SIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    SIter.AddFilter_LayerSet(MkSet(FilPrim.Layer));
    SIter.AddFilter_Area(Xp - cJoinTol, Yp - cJoinTol, Xp + cJoinTol, Yp + cJoinTol);

    Other := SIter.FirstPCBObject;
    while Other <> nil do
    begin
        if Other.I_ObjectAddress <> FilPrim.I_ObjectAddress then
        begin
            if (not SelectedOnly) or Other.Selected then
            begin
                if SameNetAndLayer(FilPrim, Other) then
                begin
                    if Other.ObjectId = eTrackObject then
                    begin
                        if SamePoint(Other.X1, Other.Y1, Xp, Yp) or SamePoint(Other.X2, Other.Y2, Xp, Yp) then
                        begin
                            Result := Other;
                            Break;
                        end;
                    end
                    else if Other.ObjectId = eArcObject then
                    begin
                        if SamePoint(Other.StartX, Other.StartY, Xp, Yp) or SamePoint(Other.EndX, Other.EndY, Xp, Yp) then
                        begin
                            Result := Other;
                            Break;
                        end;
                    end;
                end;
            end;
        end;
        Other := SIter.NextPCBObject;
    end;
    FilBoard.SpatialIterator_Destroy(SIter);

    { Запасной обход выделения, если spatial iterator не нашёл стык. }
    if Result = nil then
    begin
        for Fili := 0 to FilBoard.SelectecObjectCount - 1 do
        begin
            Other := FilBoard.SelectecObject(Fili);
            if Other.I_ObjectAddress = FilPrim.I_ObjectAddress then Continue;
            if not SameNetAndLayer(FilPrim, Other) then Continue;
            if Other.ObjectId = eTrackObject then
            begin
                if SamePoint(Other.X1, Other.Y1, Xp, Yp) or SamePoint(Other.X2, Other.Y2, Xp, Yp) then
                begin
                    Result := Other;
                    Exit;
                end;
            end
            else if Other.ObjectId = eArcObject then
            begin
                if SamePoint(Other.StartX, Other.StartY, Xp, Yp) or SamePoint(Other.EndX, Other.EndY, Xp, Yp) then
                begin
                    Result := Other;
                    Exit;
                end;
            end;
        end;
    end;
end;

{ Дуга угла: между двумя треками, и угол выбран (дуга или оба сегмента). }
procedure RememberCornerArc(AnArc : IPCB_Primitive; ArcList : TStringList);
var
    FilKey : String;
    FilT1, FilT2 : IPCB_Primitive;
begin
    if (AnArc = nil) or (AnArc.ObjectId <> eArcObject) then Exit;
    FilKey := IntToStr(AnArc.I_ObjectAddress);
    if ArcList.IndexOf(FilKey) >= 0 then Exit;
    FilT1 := FindConnectedAtEnd(AnArc, 1, False);
    FilT2 := FindConnectedAtEnd(AnArc, 2, False);
    if (FilT1 = nil) or (FilT2 = nil) then Exit;
    if (FilT1.ObjectId <> eTrackObject) or (FilT2.ObjectId <> eTrackObject) then Exit;
    if AnArc.Selected or (FilT1.Selected and FilT2.Selected) then
        ArcList.AddObject(FilKey, AnArc);
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function FilCS_ScriptFolder : String;
var
    FilWS  : IWorkspace;
    FilPrj : IProject;
    Fili   : Integer;
    FilP, FilName : String;
begin
    Result := '';
    try
        FilWS := GetWorkspace;
        if FilWS = nil then Exit;
        for Fili := 0 to FilWS.DM_ProjectCount - 1 do
        begin
            FilPrj := FilWS.DM_Projects(Fili);
            if FilPrj = nil then Continue;
            FilP := FilPrj.DM_ProjectFullPath;
            FilName := UpperCase(ExtractFileName(FilP));
            if FilName = 'TRACKCORNERFILLET.PRJSCR' then
            begin
                Result := ExtractFilePath(FilP);
                Exit;
            end;
        end;
        for Fili := 0 to FilWS.DM_ProjectCount - 1 do
        begin
            FilPrj := FilWS.DM_Projects(Fili);
            if FilPrj = nil then Continue;
            FilP := FilPrj.DM_ProjectFullPath;
            if Pos('CUSTOMSCRIPTS', UpperCase(FilP)) > 0 then
            begin
                Result := ExtractFilePath(FilP);
                Exit;
            end;
        end;
        FilPrj := FilWS.DM_FocusedProject;
        if FilPrj <> nil then
            Result := ExtractFilePath(FilPrj.DM_ProjectFullPath);
    except
        Result := '';
    end;
end;

function FilCS_FindImageFile(const FilFileName : String) : String;
var
    FilDir, FilP : String;
begin
    Result := '';
    FilDir := FilCS_ScriptFolder;
    if FilDir <> '' then
    begin
        FilP := FilDir + 'images\' + FilFileName;
        if FileExists(FilP) then begin Result := FilP; Exit; end;
        FilP := FilDir + FilFileName;
        if FileExists(FilP) then begin Result := FilP; Exit; end;
    end;
    FilP := 'images\' + FilFileName;
    if FileExists(FilP) then begin Result := FilP; Exit; end;
    if FileExists(FilFileName) then Result := FilFileName;
end;

procedure FilCS_TryLoadHelpImage(const FilBmpName : String; const FilPngName : String);
var
    FilP : String;
    HadPic : Boolean;
begin
    HadPic := False;
    try
        if ImageHelp.Picture.Width > 0 then HadPic := True;
    except
        HadPic := False;
    end;
    try
        FilP := FilCS_FindImageFile(FilBmpName);
        if FilP = '' then
            FilP := FilCS_FindImageFile(FilPngName);
        if FilP = '' then
            FilP := FilCS_FindImageFile('TrackCornerFillet.bmp');
        if (FilP <> '') and FileExists(FilP) then
        begin
            ImageHelp.Picture.LoadFromFile(FilP);
            LabelImageHint.Caption := '';
            Exit;
        end;
    except
    end;
    if HadPic then
        LabelImageHint.Caption := ''
    else
        LabelImageHint.Caption := 'No image. Put ' + FilBmpName + ' in images\ next to the scripts.';
end;


function CountSelectedAtPoint(Xp, Yp : TCoord; IgnoreAddr : Integer) : Integer;
var
    Fili : Integer;
    FilPrim : IPCB_Primitive;
begin
    Result := 0;
    for Fili := 0 to FilBoard.SelectecObjectCount - 1 do
    begin
        FilPrim := FilBoard.SelectecObject(Fili);
        if FilPrim.I_ObjectAddress = IgnoreAddr then Continue;
        if FilPrim.ObjectId = eTrackObject then
        begin
            if SamePoint(FilPrim.X1, FilPrim.Y1, Xp, Yp) or SamePoint(FilPrim.X2, FilPrim.Y2, Xp, Yp) then
                Inc(Result);
        end
        else if FilPrim.ObjectId = eArcObject then
        begin
            if SamePoint(FilPrim.StartX, FilPrim.StartY, Xp, Yp) or SamePoint(FilPrim.EndX, FilPrim.EndY, Xp, Yp) then
                Inc(Result);
        end;
    end;
end;

function TrackAngleFromEnd(ATrack : IPCB_Track; CommonEnd : Integer) : Double;
var
    Fildx, Fildy : Double;
begin
    { Угол направления ОТ общей точки вдоль трека. }
    if CommonEnd = 1 then
    begin
        Fildx := ATrack.X2 - ATrack.X1;
        Fildy := ATrack.Y2 - ATrack.Y1;
    end
    else
    begin
        Fildx := ATrack.X1 - ATrack.X2;
        Fildy := ATrack.Y1 - ATrack.Y2;
    end;
    Result := ArcTan2(Fildy, Fildx);
    if Result < 0 then Result := Result + 2 * FilPiValue;
end;

function CommonEndOfTrack(ATrack : IPCB_Track; Xp, Yp : TCoord) : Integer;
begin
    if SamePoint(ATrack.X1, ATrack.Y1, Xp, Yp) then Result := 1
    else if SamePoint(ATrack.X2, ATrack.Y2, Xp, Yp) then Result := 2
    else Result := 0;
end;

procedure ExtendTrackToPoint(ATrack : IPCB_Track; Xp, Yp : TCoord);
var
    D1, D2 : Double;
begin
    D1 := Distance(ATrack.X1, ATrack.Y1, Xp, Yp);
    D2 := Distance(ATrack.X2, ATrack.Y2, Xp, Yp);
    ATrack.BeginModify;
    if D1 < D2 then
    begin
        ATrack.X1 := Xp;
        ATrack.Y1 := Yp;
    end
    else
    begin
        ATrack.X2 := Xp;
        ATrack.Y2 := Yp;
    end;
    ATrack.EndModify;
    ATrack.GraphicallyInvalidate;
end;

procedure RemoveArcUndoSafe(AnArc : IPCB_Arc);
begin
    FilBoard.BeginModify;
    FilBoard.RemovePCBObject(AnArc);
    FilBoard.DispatchMessage(FilBoard.I_ObjectAddress, c_BroadCast, PCBM_BoardRegisteration, AnArc.I_ObjectAddress);
    FilBoard.EndModify;
end;

function IntersectTracks(FilT1, FilT2 : IPCB_Track; var Xp, Yp : TCoord) : Boolean;
var
    FilX1, FilY1, FilX2, FilY2, X3, Y3, X4, Y4 : Double;
    Den : Double;
begin
    Result := False;
    FilX1 := CoordToMMs(FilT1.X1); FilY1 := CoordToMMs(FilT1.Y1);
    FilX2 := CoordToMMs(FilT1.X2); FilY2 := CoordToMMs(FilT1.Y2);
    X3 := CoordToMMs(FilT2.X1); Y3 := CoordToMMs(FilT2.Y1);
    X4 := CoordToMMs(FilT2.X2); Y4 := CoordToMMs(FilT2.Y2);
    Den := (FilX1 - FilX2) * (Y3 - Y4) - (FilY1 - FilY2) * (X3 - X4);
    if Abs(Den) < 1e-12 then Exit;
    Xp := MMsToCoord((((FilX1 * FilY2 - FilY1 * FilX2) * (X3 - X4) - (FilX1 - FilX2) * (X3 * Y4 - Y3 * X4)) / Den));
    Yp := MMsToCoord((((FilX1 * FilY2 - FilY1 * FilX2) * (Y3 - Y4) - (FilY1 - FilY2) * (X3 * Y4 - Y3 * X4)) / Den));
    Result := True;
end;

function CreateFilletBetweenTracks(FirstTrack, SecondTrack : IPCB_Track) : Boolean;
var
    Common1, Common2 : Integer;
    Angle1, Angle2   : Double;
    StartAngle, StopAngle, HalfAngle : Double;
    RemovedLength    : Double;
    FilX1, FilY1, FilX2, FilY2, Xc, Yc : Double;
    A1, A2           : Double;
    AnArc            : IPCB_Arc;
    Xp, Yp           : TCoord;
    MaxLen           : Double;
    NeedLen          : Double;
begin
    Result := False;
    if (FirstTrack = nil) or (SecondTrack = nil) then Exit;
    if FirstTrack.Layer <> SecondTrack.Layer then Exit;

    if not IntersectTracks(FirstTrack, SecondTrack, Xp, Yp) then
    begin
        { Параллельны или не пересекаются — ищем общую точку. }
        if SamePoint(FirstTrack.X1, FirstTrack.Y1, SecondTrack.X1, SecondTrack.Y1) or
           SamePoint(FirstTrack.X1, FirstTrack.Y1, SecondTrack.X2, SecondTrack.Y2) then
        begin
            Xp := FirstTrack.X1; Yp := FirstTrack.Y1;
        end
        else if SamePoint(FirstTrack.X2, FirstTrack.Y2, SecondTrack.X1, SecondTrack.Y1) or
                SamePoint(FirstTrack.X2, FirstTrack.Y2, SecondTrack.X2, SecondTrack.Y2) then
        begin
            Xp := FirstTrack.X2; Yp := FirstTrack.Y2;
        end
        else
            Exit;
    end;

    Common1 := CommonEndOfTrack(FirstTrack, Xp, Yp);
    Common2 := CommonEndOfTrack(SecondTrack, Xp, Yp);
    if (Common1 = 0) or (Common2 = 0) then
    begin
        { Подтянуть концы к пересечению, если они рядом. }
        ExtendTrackToPoint(FirstTrack, Xp, Yp);
        ExtendTrackToPoint(SecondTrack, Xp, Yp);
        Common1 := CommonEndOfTrack(FirstTrack, Xp, Yp);
        Common2 := CommonEndOfTrack(SecondTrack, Xp, Yp);
        if (Common1 = 0) or (Common2 = 0) then Exit;
    end;

    Angle1 := TrackAngleFromEnd(FirstTrack, Common1);
    Angle2 := TrackAngleFromEnd(SecondTrack, Common2);

    if Abs(Angle1 - Angle2) < 1e-6 then Exit;
    if Abs(Abs(Angle1 - Angle2) - FilPiValue) < 1e-6 then Exit;

    if (Angle1 > Angle2) and (Angle1 - Angle2 < FilPiValue) then
    begin
        StartAngle := FilPiValue / 2 + Angle1;
        StopAngle  := 3 * FilPiValue / 2 + Angle2;
    end
    else if (Angle1 > Angle2) and (Angle1 - Angle2 > FilPiValue) then
    begin
        StartAngle := FilPiValue / 2 + Angle2;
        StopAngle  := Angle1 - FilPiValue / 2;
    end
    else if (Angle1 < Angle2) and (Angle2 - Angle1 < FilPiValue) then
    begin
        StartAngle := FilPiValue / 2 + Angle2;
        StopAngle  := 3 * FilPiValue / 2 + Angle1;
    end
    else
    begin
        StartAngle := FilPiValue / 2 + Angle1;
        StopAngle  := Angle2 - FilPiValue / 2;
    end;

    HalfAngle := (StopAngle - StartAngle) / 2;
    if Abs(HalfAngle) < 1e-6 then Exit;

    if (Abs(HalfAngle - FilPiValue / 2) < 1e-6) or (Abs(HalfAngle - 3 * FilPiValue / 2) < 1e-6) then
        RemovedLength := RadiusCoord
    else
        RemovedLength := RadiusCoord * Tan(HalfAngle);

    MaxLen := Distance(FirstTrack.X1, FirstTrack.Y1, FirstTrack.X2, FirstTrack.Y2);
    if Distance(SecondTrack.X1, SecondTrack.Y1, SecondTrack.X2, SecondTrack.Y2) < MaxLen then
        MaxLen := Distance(SecondTrack.X1, SecondTrack.Y1, SecondTrack.X2, SecondTrack.Y2);
    NeedLen := Abs(RemovedLength);
    if NeedLen + cMinLength > MaxLen then
    begin
        Inc(TooLargeCount);
        Exit;
    end;

    FirstTrack.BeginModify;
    if Common1 = 1 then
    begin
        FirstTrack.X1 := FirstTrack.X1 + Round(RemovedLength * Cos(Angle1));
        FirstTrack.Y1 := FirstTrack.Y1 + Round(RemovedLength * Sin(Angle1));
        FilX1 := FirstTrack.X1;
        FilY1 := FirstTrack.Y1;
    end
    else
    begin
        FirstTrack.X2 := FirstTrack.X2 + Round(RemovedLength * Cos(Angle1));
        FirstTrack.Y2 := FirstTrack.Y2 + Round(RemovedLength * Sin(Angle1));
        FilX1 := FirstTrack.X2;
        FilY1 := FirstTrack.Y2;
    end;
    FirstTrack.EndModify;
    FirstTrack.GraphicallyInvalidate;

    SecondTrack.BeginModify;
    if Common2 = 1 then
    begin
        SecondTrack.X1 := SecondTrack.X1 + Round(RemovedLength * Cos(Angle2));
        SecondTrack.Y1 := SecondTrack.Y1 + Round(RemovedLength * Sin(Angle2));
        FilX2 := SecondTrack.X1;
        FilY2 := SecondTrack.Y1;
    end
    else
    begin
        SecondTrack.X2 := SecondTrack.X2 + Round(RemovedLength * Cos(Angle2));
        SecondTrack.Y2 := SecondTrack.Y2 + Round(RemovedLength * Sin(Angle2));
        FilX2 := SecondTrack.X2;
        FilY2 := SecondTrack.Y2;
    end;
    SecondTrack.EndModify;
    SecondTrack.GraphicallyInvalidate;

    if (Abs(Angle1) < 1e-6) or (Abs(Angle1 - FilPiValue) < 1e-6) then
        Xc := FilX1
    else if (Abs(Angle2) < 1e-6) or (Abs(Angle2 - FilPiValue) < 1e-6) then
        Xc := FilX2
    else
    begin
        A1 := Tan(FilPiValue / 2 + Angle1);
        A2 := Tan(FilPiValue / 2 + Angle2);
        if Abs(A1 - A2) < 1e-12 then Exit;
        Xc := (FilY2 - FilY1 + A1 * FilX1 - A2 * FilX2) / (A1 - A2);
    end;

    if (Abs(Angle1 - FilPiValue / 2) < 1e-6) or (Abs(Angle1 - 3 * FilPiValue / 2) < 1e-6) then
        Yc := FilY1
    else if (Abs(Angle2 - FilPiValue / 2) < 1e-6) or (Abs(Angle2 - 3 * FilPiValue / 2) < 1e-6) then
        Yc := FilY2
    else if (Abs(Angle1) > 1e-6) and (Abs(Angle1 - FilPiValue) > 1e-6) then
        Yc := Tan(FilPiValue / 2 + Angle1) * (Xc - FilX1) + FilY1
    else
        Yc := Tan(FilPiValue / 2 + Angle2) * (Xc - FilX2) + FilY2;

    AnArc := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    AnArc.XCenter := Round(Xc);
    AnArc.YCenter := Round(Yc);
    AnArc.Radius := Round(Sqrt(Sqr(FilX1 - Xc) + Sqr(FilY1 - Yc)));
    AnArc.LineWidth := FirstTrack.Width;
    AnArc.StartAngle := StartAngle * 180 / FilPiValue;
    AnArc.EndAngle := StopAngle * 180 / FilPiValue;
    AnArc.Layer := FirstTrack.Layer;
    if FirstTrack.InNet then AnArc.Net := FirstTrack.Net;
    FilBoard.AddPCBObject(AnArc);
    FilBoard.DispatchMessage(FilBoard.I_ObjectAddress, c_BroadCast, PCBM_BoardRegisteration, AnArc.I_ObjectAddress);
    AnArc.Selected := True;
    Inc(CreatedCount);
    Result := True;
end;

procedure RestoreTracksToCorner(FirstTrack, SecondTrack : IPCB_Track);
var
    Xp, Yp : TCoord;
begin
    if (FirstTrack = nil) or (SecondTrack = nil) then Exit;
    if not IntersectTracks(FirstTrack, SecondTrack, Xp, Yp) then Exit;
    ExtendTrackToPoint(FirstTrack, Xp, Yp);
    ExtendTrackToPoint(SecondTrack, Xp, Yp);
end;

procedure EnsureReplaceAsked;
var
    FilAns : Boolean;
begin
    if AskedReplace then Exit;
    AskedReplace := True;
    FilAns := FilAskYesNo(LabelAskRedo.Caption);
    ReplaceFillets := FilAns;
end;

procedure ProcessTrackPair(FilT1, FilT2 : IPCB_Track);
begin
    if RadiusCoord <= 0 then Exit;
    if FilT1.I_ObjectAddress = FilT2.I_ObjectAddress then Exit;
    if FilT1.Layer <> FilT2.Layer then Exit;
    CreateFilletBetweenTracks(FilT1, FilT2);
end;

procedure ProcessExistingFillet(AnArc : IPCB_Arc);
var
    FilT1, FilT2 : IPCB_Primitive;
    OtherEnd : Integer;
begin
    FilT1 := FindConnectedAtEnd(AnArc, 1, False);
    FilT2 := FindConnectedAtEnd(AnArc, 2, False);
    if (FilT1 = nil) or (FilT2 = nil) then Exit;
    if (FilT1.ObjectId <> eTrackObject) or (FilT2.ObjectId <> eTrackObject) then Exit;

    { R=0 всегда снимает скругление; при R>0 спрашиваем один раз. }
    if RadiusCoord > 0 then
    begin
        EnsureReplaceAsked;
        if not ReplaceFillets then
        begin
            Inc(SkippedCount);
            Exit;
        end;
    end;

    { Вернуть концы треков к пересечению; при R>0 поставить новую дугу. }
    RemoveArcUndoSafe(AnArc);
    if RadiusCoord <= 0 then
    begin
        RestoreTracksToCorner(FilT1, FilT2);
        Inc(RemovedCount);
    end
    else
        CreateFilletBetweenTracks(FilT1, FilT2);
end;

procedure DoFilletWork;
var
    Fili : Integer;
    FilPrim, Other : IPCB_Primitive;
    FilT1, FilT2 : IPCB_Track;
    Xp, Yp : TCoord;
    EndIdx : Integer;
    ConnCount : Integer;
    PairDone : TStringList;
    ArcList : TStringList;
    FilKey : String;
    Addr1, Addr2 : Integer;
begin
    if PCBServer = nil then
    begin
        FilShowBox(LabelErrNoSrv.Caption, 16);
        Exit;
    end;
    FilBoard := PCBServer.GetCurrentPCBBoard;
    if FilBoard = nil then
    begin
        FilShowBox(LabelErrNoPcb.Caption, 16);
        Exit;
    end;

    Fili := 0;
    while Fili < FilBoard.SelectecObjectCount do
    begin
        FilPrim := FilBoard.SelectecObject(Fili);
        if (FilPrim.ObjectId = eTrackObject) or (FilPrim.ObjectId = eArcObject) then
            Inc(Fili)
        else
            FilPrim.SetState_Selected(False);
    end;
    { Не расширяем выделение на весь контур: только явно выбранные сегменты. }
    if FilBoard.SelectecObjectCount = 0 then
    begin
        FilShowBox(LabelWarnNone.Caption, 48);
        Exit;
    end;

    CreatedCount := 0;
    SkippedCount := 0;
    TooLargeCount := 0;
    RemovedCount := 0;
    AskedReplace := False;
    ReplaceFillets := False;
    PairDone := TStringList.Create;
    PairDone.Sorted := True;
    PairDone.Duplicates := dupIgnore;
    ArcList := TStringList.Create;

    PCBServer.PreProcess;
    try
        { Снимок дуг выбранных углов (выделенная дуга или оба сегмента).
          Не расширяем контур: два ребра квадрата = один угол. }
        for Fili := 0 to FilBoard.SelectecObjectCount - 1 do
        begin
            FilPrim := FilBoard.SelectecObject(Fili);
            if FilPrim.ObjectId = eArcObject then
                RememberCornerArc(FilPrim, ArcList)
            else if FilPrim.ObjectId = eTrackObject then
            begin
                for EndIdx := 1 to 2 do
                begin
                    Other := FindConnectedAtEnd(FilPrim, EndIdx, False);
                    if (Other <> nil) and (Other.ObjectId = eArcObject) then
                        RememberCornerArc(Other, ArcList);
                end;
            end;
        end;
        for Fili := 0 to ArcList.Count - 1 do
            ProcessExistingFillet(ArcList.Objects[Fili]);

        { Пары явно выделенных треков: угол только если оба сегмента выбраны. }
        for Fili := 0 to FilBoard.SelectecObjectCount - 1 do
        begin
            FilPrim := FilBoard.SelectecObject(Fili);
            if FilPrim.ObjectId <> eTrackObject then Continue;
            FilT1 := FilPrim;
            for EndIdx := 1 to 2 do
            begin
                if EndIdx = 1 then
                begin
                    Xp := FilT1.X1; Yp := FilT1.Y1;
                end
                else
                begin
                    Xp := FilT1.X2; Yp := FilT1.Y2;
                end;

                ConnCount := CountSelectedAtPoint(Xp, Yp, 0);
                if ConnCount <> 2 then Continue;

                Other := FindConnectedAtEnd(FilT1, EndIdx, True);
                if Other = nil then Continue;
                if Other.ObjectId = eArcObject then Continue;
                if Other.ObjectId <> eTrackObject then Continue;
                FilT2 := Other;

                Addr1 := FilT1.I_ObjectAddress;
                Addr2 := FilT2.I_ObjectAddress;
                if Addr1 < Addr2 then
                    FilKey := IntToStr(Addr1) + '-' + IntToStr(Addr2)
                else
                    FilKey := IntToStr(Addr2) + '-' + IntToStr(Addr1);
                if PairDone.IndexOf(FilKey) >= 0 then Continue;
                PairDone.Add(FilKey);

                ProcessTrackPair(FilT1, FilT2);
            end;
        end;
    finally
        PCBServer.PostProcess;
        PairDone.Free;
        ArcList.Free;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);

    if (CreatedCount = 0) and (RemovedCount = 0) then
        FilShowBox(LabelWarnNone.Caption, 48)
    else
        FilShowBox(LabelInfoDone.Caption + IntToStr(CreatedCount) + sLineBreak +
                   LabelInfoRemoved.Caption + IntToStr(RemovedCount) + sLineBreak +
                   LabelInfoSkip.Caption + IntToStr(SkippedCount) + sLineBreak +
                   LabelInfoLarge.Caption + IntToStr(TooLargeCount), 64);
end;

procedure TFormFillet.ButtonOKClick(FilSender: TObject);
var
    MM : Double;
begin
    if not FilParseFloat(EditRadius.Text, MM) then
    begin
        FilShowBox(LabelErrRadius.Caption, 16);
        Exit;
    end;
    if MM < 0 then
    begin
        FilShowBox(LabelErrNeg.Caption, 16);
        Exit;
    end;
    RadiusCoord := MMsToCoord(MM);
    FormFillet.Close;
    DoFilletWork;
end;

procedure TFormFillet.ButtonCancelClick(FilSender: TObject);
begin
    FormFillet.Close;
end;

procedure TFormFillet.FormFilletShow(FilSender: TObject);
begin
    try
        FilCS_TryLoadHelpImage('Fillet.bmp', 'Fillet.png');
    except
    end;
    EditRadius.Text := '0.5';
end;

procedure StartTrackCornerFillet;
begin
    FormFillet.ShowModal;
end;

procedure _StartTrackCornerFillet;
begin
    StartTrackCornerFillet;
end;
