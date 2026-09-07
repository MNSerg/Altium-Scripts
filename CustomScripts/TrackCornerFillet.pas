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
    PiValue          = 3.141592653589793;

var
    Board          : IPCB_Board;
    RadiusCoord    : TCoord;
    ReplaceFillets : Boolean;
    AskedReplace   : Boolean;
    CreatedCount   : Integer;
    SkippedCount   : Integer;
    TooLargeCount  : Integer;

procedure Start; forward;
procedure _Start; forward;
procedure TFormFillet.ButtonOKClick(Sender: TObject); forward;
procedure TFormFillet.ButtonCancelClick(Sender: TObject); forward;
procedure TFormFillet.FormFilletShow(Sender: TObject); forward;
procedure DoFilletWork; forward;
procedure ExpandConnectedPath; forward;

function Distance(X1, Y1, X2, Y2 : TCoord) : Double;
begin
    Result := Sqrt(Sqr(1.0 * (X2 - X1)) + Sqr(1.0 * (Y2 - Y1)));
end;

function SamePoint(X1, Y1, X2, Y2 : TCoord) : Boolean;
begin
    Result := Distance(X1, Y1, X2, Y2) <= cJoinTol;
end;

function IsNumericMM(Text : String) : Boolean;
var
    V : Double;
begin
    Result := False;
    if Text = '' then Exit;
    try
        V := StrToFloat(Text);
        Result := V >= 0;
    except
        Result := False;
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

function SameNetAndLayer(A, B : IPCB_Primitive) : Boolean;
begin
    Result := False;
    if (A = nil) or (B = nil) then Exit;
    if A.Layer <> B.Layer then Exit;
    if A.InNet and B.InNet then
    begin
        if A.Net <> B.Net then Exit;
    end;
    Result := True;
end;

{ Найти примитив (трек или дугу), стыкующийся с концом EndIdx объекта Prim. }
function FindConnectedAtEnd(Prim : IPCB_Primitive; EndIdx : Integer; SelectedOnly : Boolean) : IPCB_Primitive;
var
    SIter : IPCB_SpatialIterator;
    Other : IPCB_Primitive;
    Xp, Yp : TCoord;
    i : Integer;
begin
    Result := nil;
    if Prim.ObjectId = eTrackObject then
    begin
        Xp := TrackEndX(Prim, EndIdx);
        Yp := TrackEndY(Prim, EndIdx);
    end
    else if Prim.ObjectId = eArcObject then
    begin
        Xp := ArcEndX(Prim, EndIdx);
        Yp := ArcEndY(Prim, EndIdx);
    end
    else Exit;

    SIter := Board.SpatialIterator_Create;
    SIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    SIter.AddFilter_LayerSet(MkSet(Prim.Layer));
    SIter.AddFilter_Area(Xp - cJoinTol, Yp - cJoinTol, Xp + cJoinTol, Yp + cJoinTol);

    Other := SIter.FirstPCBObject;
    while Other <> nil do
    begin
        if Other.I_ObjectAddress <> Prim.I_ObjectAddress then
        begin
            if (not SelectedOnly) or Other.Selected then
            begin
                if SameNetAndLayer(Prim, Other) then
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
    Board.SpatialIterator_Destroy(SIter);

    { Запасной обход выделения, если spatial iterator не нашёл стык. }
    if Result = nil then
    begin
        for i := 0 to Board.SelectecObjectCount - 1 do
        begin
            Other := Board.SelectecObject(i);
            if Other.I_ObjectAddress = Prim.I_ObjectAddress then Continue;
            if not SameNetAndLayer(Prim, Other) then Continue;
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

{ Сколько выделенных треков/дуг сходятся в точке. T-стык: >= 3. }
function CountAllAtPoint(Xp, Yp : TCoord; ALayer : TLayer) : Integer;
var
    SIter : IPCB_SpatialIterator;
    Other : IPCB_Primitive;
begin
    Result := 0;
    SIter := Board.SpatialIterator_Create;
    SIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    SIter.AddFilter_LayerSet(MkSet(ALayer));
    SIter.AddFilter_Area(Xp - cJoinTol, Yp - cJoinTol, Xp + cJoinTol, Yp + cJoinTol);
    Other := SIter.FirstPCBObject;
    while Other <> nil do
    begin
        if Other.ObjectId = eTrackObject then
        begin
            if SamePoint(Other.X1, Other.Y1, Xp, Yp) or SamePoint(Other.X2, Other.Y2, Xp, Yp) then
                Inc(Result);
        end
        else if Other.ObjectId = eArcObject then
        begin
            if SamePoint(Other.StartX, Other.StartY, Xp, Yp) or SamePoint(Other.EndX, Other.EndY, Xp, Yp) then
                Inc(Result);
        end;
        Other := SIter.NextPCBObject;
    end;
    Board.SpatialIterator_Destroy(SIter);
end;

{ Добирает состыкованный путь той же цепи/слоя (квадрат из 1 сегмента → 4). T-стыки не трогаем. }
procedure ExpandConnectedPath;
var
    Changed : Boolean;
    Guard, i, EndIdx : Integer;
    Prim, Other : IPCB_Primitive;
    Xp, Yp : TCoord;
begin
    Guard := 0;
    repeat
        Changed := False;
        Inc(Guard);
        i := 0;
        while i < Board.SelectecObjectCount do
        begin
            Prim := Board.SelectecObject(i);
            if (Prim.ObjectId = eTrackObject) or (Prim.ObjectId = eArcObject) then
            begin
                for EndIdx := 1 to 2 do
                begin
                    if Prim.ObjectId = eTrackObject then
                    begin
                        if EndIdx = 1 then begin Xp := Prim.X1; Yp := Prim.Y1; end
                        else begin Xp := Prim.X2; Yp := Prim.Y2; end;
                    end
                    else
                    begin
                        if EndIdx = 1 then begin Xp := Prim.StartX; Yp := Prim.StartY; end
                        else begin Xp := Prim.EndX; Yp := Prim.EndY; end;
                    end;
                    if CountAllAtPoint(Xp, Yp, Prim.Layer) = 2 then
                    begin
                        Other := FindConnectedAtEnd(Prim, EndIdx, False);
                        if (Other <> nil) and (not Other.Selected) then
                        begin
                            Other.Selected := True;
                            Changed := True;
                        end;
                    end;
                end;
            end;
            Inc(i);
        end;
    until (not Changed) or (Guard > 8000);
end;

{ ScriptBoot.inc — safe help-image load. Never call ParamStr (AV in Altium). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function CS_ScriptFolder : String;
var
    WS  : IWorkspace;
    Prj : IProject;
    i   : Integer;
    P   : String;
begin
    Result := '';
    try
        WS := GetWorkspace;
        if WS = nil then Exit;
        Prj := WS.DM_FocusedProject;
        if Prj <> nil then
        begin
            P := ExtractFilePath(Prj.DM_ProjectFullPath);
            if P <> '' then
            begin
                Result := P;
                Exit;
            end;
        end;
        for i := 0 to WS.DM_ProjectCount - 1 do
        begin
            Prj := WS.DM_Projects(i);
            if Prj <> nil then
            begin
                P := Prj.DM_ProjectFullPath;
                if Pos('CustomScripts', P) > 0 then
                begin
                    Result := ExtractFilePath(P);
                    Exit;
                end;
            end;
        end;
    except
        Result := '';
    end;
end;

function CS_FindImageFile(const FileName : String) : String;
var
    Dir, P : String;
begin
    Result := '';
    Dir := CS_ScriptFolder;
    if Dir <> '' then
    begin
        P := Dir + 'images\' + FileName;
        if FileExists(P) then
        begin
            Result := P;
            Exit;
        end;
        P := Dir + FileName;
        if FileExists(P) then
        begin
            Result := P;
            Exit;
        end;
    end;
    P := 'images\' + FileName;
    if FileExists(P) then Result := P;
end;

procedure CS_TryLoadHelpImage(const BmpName : String; const PngName : String);
var
    P : String;
begin
    try
        P := CS_FindImageFile(BmpName);
        if P = '' then
            P := CS_FindImageFile(PngName);
        if (P <> '') and FileExists(P) then
        begin
            ImageHelp.Picture.LoadFromFile(P);
            LabelImageHint.Caption := 'Replace image: images\' + BmpName;
        end
        else
            LabelImageHint.Caption := 'No image. Put ' + BmpName + ' in images\ next to the scripts.';
    except
        try
            LabelImageHint.Caption := 'Image not loaded.';
        except
        end;
    end;
end;


function CountSelectedAtPoint(Xp, Yp : TCoord; IgnoreAddr : Integer) : Integer;
var
    i : Integer;
    Prim : IPCB_Primitive;
begin
    Result := 0;
    for i := 0 to Board.SelectecObjectCount - 1 do
    begin
        Prim := Board.SelectecObject(i);
        if Prim.I_ObjectAddress = IgnoreAddr then Continue;
        if Prim.ObjectId = eTrackObject then
        begin
            if SamePoint(Prim.X1, Prim.Y1, Xp, Yp) or SamePoint(Prim.X2, Prim.Y2, Xp, Yp) then
                Inc(Result);
        end
        else if Prim.ObjectId = eArcObject then
        begin
            if SamePoint(Prim.StartX, Prim.StartY, Xp, Yp) or SamePoint(Prim.EndX, Prim.EndY, Xp, Yp) then
                Inc(Result);
        end;
    end;
end;

function TrackAngleFromEnd(ATrack : IPCB_Track; CommonEnd : Integer) : Double;
var
    dx, dy : Double;
begin
    { Угол направления ОТ общей точки вдоль трека. }
    if CommonEnd = 1 then
    begin
        dx := ATrack.X2 - ATrack.X1;
        dy := ATrack.Y2 - ATrack.Y1;
    end
    else
    begin
        dx := ATrack.X1 - ATrack.X2;
        dy := ATrack.Y1 - ATrack.Y2;
    end;
    Result := ArcTan2(dy, dx);
    if Result < 0 then Result := Result + 2 * PiValue;
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
    Board.BeginModify;
    Board.RemovePCBObject(AnArc);
    Board.DispatchMessage(Board.I_ObjectAddress, c_BroadCast, PCBM_BoardRegisteration, AnArc.I_ObjectAddress);
    Board.EndModify;
end;

function IntersectTracks(T1, T2 : IPCB_Track; var Xp, Yp : TCoord) : Boolean;
var
    X1, Y1, X2, Y2, X3, Y3, X4, Y4 : Double;
    Den : Double;
begin
    Result := False;
    X1 := CoordToMMs(T1.X1); Y1 := CoordToMMs(T1.Y1);
    X2 := CoordToMMs(T1.X2); Y2 := CoordToMMs(T1.Y2);
    X3 := CoordToMMs(T2.X1); Y3 := CoordToMMs(T2.Y1);
    X4 := CoordToMMs(T2.X2); Y4 := CoordToMMs(T2.Y2);
    Den := (X1 - X2) * (Y3 - Y4) - (Y1 - Y2) * (X3 - X4);
    if Abs(Den) < 1e-12 then Exit;
    Xp := MMsToCoord((((X1 * Y2 - Y1 * X2) * (X3 - X4) - (X1 - X2) * (X3 * Y4 - Y3 * X4)) / Den));
    Yp := MMsToCoord((((X1 * Y2 - Y1 * X2) * (Y3 - Y4) - (Y1 - Y2) * (X3 * Y4 - Y3 * X4)) / Den));
    Result := True;
end;

function CreateFilletBetweenTracks(FirstTrack, SecondTrack : IPCB_Track) : Boolean;
var
    Common1, Common2 : Integer;
    Angle1, Angle2   : Double;
    StartAngle, StopAngle, HalfAngle : Double;
    RemovedLength    : Double;
    X1, Y1, X2, Y2, Xc, Yc : Double;
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
    if Abs(Abs(Angle1 - Angle2) - PiValue) < 1e-6 then Exit;

    if (Angle1 > Angle2) and (Angle1 - Angle2 < PiValue) then
    begin
        StartAngle := PiValue / 2 + Angle1;
        StopAngle  := 3 * PiValue / 2 + Angle2;
    end
    else if (Angle1 > Angle2) and (Angle1 - Angle2 > PiValue) then
    begin
        StartAngle := PiValue / 2 + Angle2;
        StopAngle  := Angle1 - PiValue / 2;
    end
    else if (Angle1 < Angle2) and (Angle2 - Angle1 < PiValue) then
    begin
        StartAngle := PiValue / 2 + Angle2;
        StopAngle  := 3 * PiValue / 2 + Angle1;
    end
    else
    begin
        StartAngle := PiValue / 2 + Angle1;
        StopAngle  := Angle2 - PiValue / 2;
    end;

    HalfAngle := (StopAngle - StartAngle) / 2;
    if Abs(HalfAngle) < 1e-6 then Exit;

    if (Abs(HalfAngle - PiValue / 2) < 1e-6) or (Abs(HalfAngle - 3 * PiValue / 2) < 1e-6) then
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
        X1 := FirstTrack.X1;
        Y1 := FirstTrack.Y1;
    end
    else
    begin
        FirstTrack.X2 := FirstTrack.X2 + Round(RemovedLength * Cos(Angle1));
        FirstTrack.Y2 := FirstTrack.Y2 + Round(RemovedLength * Sin(Angle1));
        X1 := FirstTrack.X2;
        Y1 := FirstTrack.Y2;
    end;
    FirstTrack.EndModify;
    FirstTrack.GraphicallyInvalidate;

    SecondTrack.BeginModify;
    if Common2 = 1 then
    begin
        SecondTrack.X1 := SecondTrack.X1 + Round(RemovedLength * Cos(Angle2));
        SecondTrack.Y1 := SecondTrack.Y1 + Round(RemovedLength * Sin(Angle2));
        X2 := SecondTrack.X1;
        Y2 := SecondTrack.Y1;
    end
    else
    begin
        SecondTrack.X2 := SecondTrack.X2 + Round(RemovedLength * Cos(Angle2));
        SecondTrack.Y2 := SecondTrack.Y2 + Round(RemovedLength * Sin(Angle2));
        X2 := SecondTrack.X2;
        Y2 := SecondTrack.Y2;
    end;
    SecondTrack.EndModify;
    SecondTrack.GraphicallyInvalidate;

    if (Abs(Angle1) < 1e-6) or (Abs(Angle1 - PiValue) < 1e-6) then
        Xc := X1
    else if (Abs(Angle2) < 1e-6) or (Abs(Angle2 - PiValue) < 1e-6) then
        Xc := X2
    else
    begin
        A1 := Tan(PiValue / 2 + Angle1);
        A2 := Tan(PiValue / 2 + Angle2);
        if Abs(A1 - A2) < 1e-12 then Exit;
        Xc := (Y2 - Y1 + A1 * X1 - A2 * X2) / (A1 - A2);
    end;

    if (Abs(Angle1 - PiValue / 2) < 1e-6) or (Abs(Angle1 - 3 * PiValue / 2) < 1e-6) then
        Yc := Y1
    else if (Abs(Angle2 - PiValue / 2) < 1e-6) or (Abs(Angle2 - 3 * PiValue / 2) < 1e-6) then
        Yc := Y2
    else if (Abs(Angle1) > 1e-6) and (Abs(Angle1 - PiValue) > 1e-6) then
        Yc := Tan(PiValue / 2 + Angle1) * (Xc - X1) + Y1
    else
        Yc := Tan(PiValue / 2 + Angle2) * (Xc - X2) + Y2;

    AnArc := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    AnArc.XCenter := Round(Xc);
    AnArc.YCenter := Round(Yc);
    AnArc.Radius := Round(Sqrt(Sqr(X1 - Xc) + Sqr(Y1 - Yc)));
    AnArc.LineWidth := FirstTrack.Width;
    AnArc.StartAngle := StartAngle * 180 / PiValue;
    AnArc.EndAngle := StopAngle * 180 / PiValue;
    AnArc.Layer := FirstTrack.Layer;
    if FirstTrack.InNet then AnArc.Net := FirstTrack.Net;
    Board.AddPCBObject(AnArc);
    Board.DispatchMessage(Board.I_ObjectAddress, c_BroadCast, PCBM_BoardRegisteration, AnArc.I_ObjectAddress);
    AnArc.Selected := True;
    Inc(CreatedCount);
    Result := True;
end;

procedure EnsureReplaceAsked;
var
    Ans : Boolean;
begin
    if AskedReplace then Exit;
    AskedReplace := True;
    Ans := ConfirmNoYes('На выбранном треке уже есть скругления. Переделать их?');
    ReplaceFillets := Ans;
end;

procedure ProcessTrackPair(T1, T2 : IPCB_Track);
begin
    if T1.I_ObjectAddress = T2.I_ObjectAddress then Exit;
    if T1.Layer <> T2.Layer then Exit;
    CreateFilletBetweenTracks(T1, T2);
end;

procedure ProcessExistingFillet(AnArc : IPCB_Arc);
var
    T1, T2 : IPCB_Primitive;
    OtherEnd : Integer;
begin
    T1 := FindConnectedAtEnd(AnArc, 1, True);
    T2 := FindConnectedAtEnd(AnArc, 2, True);
    if (T1 = nil) or (T2 = nil) then Exit;
    if (T1.ObjectId <> eTrackObject) or (T2.ObjectId <> eTrackObject) then Exit;

    EnsureReplaceAsked;
    if not ReplaceFillets then
    begin
        Inc(SkippedCount);
        Exit;
    end;

    { Вернуть концы треков к пересечению и поставить новую дугу. }
    RemoveArcUndoSafe(AnArc);
    CreateFilletBetweenTracks(T1, T2);
end;

procedure DoFilletWork;
var
    i : Integer;
    Prim, Other : IPCB_Primitive;
    T1, T2 : IPCB_Track;
    Xp, Yp : TCoord;
    EndIdx : Integer;
    ConnCount : Integer;
    PairDone : TStringList;
    Key : String;
    Addr1, Addr2 : Integer;
begin
    if PCBServer = nil then
    begin
        ShowError('PCB-server is not available.');
        Exit;
    end;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = nil then
    begin
        ShowError('Open a PCB document.');
        Exit;
    end;

    i := 0;
    while i < Board.SelectecObjectCount do
    begin
        Prim := Board.SelectecObject(i);
        if (Prim.ObjectId = eTrackObject) or (Prim.ObjectId = eArcObject) then
            Inc(i)
        else
            Prim.SetState_Selected(False);
    end;
    ExpandConnectedPath;
    if Board.SelectecObjectCount = 0 then
    begin
        ShowWarning('Select one track segment or a path (a square of 4 segments gets 4 fillets).');
        Exit;
    end;

    CreatedCount := 0;
    SkippedCount := 0;
    TooLargeCount := 0;
    AskedReplace := False;
    ReplaceFillets := False;
    PairDone := TStringList.Create;
    PairDone.Sorted := True;
    PairDone.Duplicates := dupIgnore;

    PCBServer.PreProcess;
    try
        { Сначала существующие выделенные дуги-скругления. }
        i := 0;
        while i < Board.SelectecObjectCount do
        begin
            Prim := Board.SelectecObject(i);
            if Prim.ObjectId = eArcObject then
            begin
                ProcessExistingFillet(Prim);
                { После удаления дуги индексы выделения сдвигаются — не увеличиваем i. }
            end;
            Inc(i);
        end;

        { Затем пары треков с общей вершиной (ровно 2 выделенных сегмента). }
        for i := 0 to Board.SelectecObjectCount - 1 do
        begin
            Prim := Board.SelectecObject(i);
            if Prim.ObjectId <> eTrackObject then Continue;
            T1 := Prim;
            for EndIdx := 1 to 2 do
            begin
                if EndIdx = 1 then
                begin
                    Xp := T1.X1; Yp := T1.Y1;
                end
                else
                begin
                    Xp := T1.X2; Yp := T1.Y2;
                end;

                ConnCount := CountSelectedAtPoint(Xp, Yp, 0);
                { Сам трек + ровно один сосед = 2. Больше — T-стык, пропускаем. }
                if ConnCount <> 2 then Continue;

                Other := FindConnectedAtEnd(T1, EndIdx, True);
                if Other = nil then Continue;
                if Other.ObjectId = eArcObject then
                begin
                    { Уже есть дуга — обработано выше или пользователь отказался. }
                    Continue;
                end;
                if Other.ObjectId <> eTrackObject then Continue;
                T2 := Other;

                Addr1 := T1.I_ObjectAddress;
                Addr2 := T2.I_ObjectAddress;
                if Addr1 < Addr2 then
                    Key := IntToStr(Addr1) + '-' + IntToStr(Addr2)
                else
                    Key := IntToStr(Addr2) + '-' + IntToStr(Addr1);
                if PairDone.IndexOf(Key) >= 0 then Continue;
                PairDone.Add(Key);

                ProcessTrackPair(T1, T2);
            end;
        end;
    finally
        PCBServer.PostProcess;
        PairDone.Free;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);

    if CreatedCount = 0 then
        ShowWarning('Скругления не созданы. Выделите состыкованные сегменты трека, проверьте радиус.')
    else
        ShowInfo('Создано/обновлено скруглений: ' + IntToStr(CreatedCount) + sLineBreak +
                 'Пропущено (уже есть / отказ): ' + IntToStr(SkippedCount) + sLineBreak +
                 'Пропущено (радиус слишком большой): ' + IntToStr(TooLargeCount),
                 'Скругление углов');
end;

procedure TFormFillet.ButtonOKClick(Sender: TObject);
var
    MM : Double;
begin
    if not IsNumericMM(EditRadius.Text) then
    begin
        ShowError('Введите неотрицательный радиус в миллиметрах.');
        Exit;
    end;
    MM := StrToFloat(EditRadius.Text);
    if MM < 0 then
    begin
        ShowError('Радиус не может быть отрицательным.');
        Exit;
    end;
    if MM = 0 then
    begin
        ShowError('Радиус должен быть больше нуля.');
        Exit;
    end;
    RadiusCoord := MMsToCoord(MM);
    FormFillet.Close;
    DoFilletWork;
end;

procedure TFormFillet.ButtonCancelClick(Sender: TObject);
begin
    FormFillet.Close;
end;

procedure TFormFillet.FormFilletShow(Sender: TObject);
begin
    try
        CS_TryLoadHelpImage('Fillet.bmp', 'Fillet.png');
    except
    end;
    EditRadius.Text := FloatToStr(cDefaultRadiusMM);
end;

procedure Start;
begin
    FormFillet.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
