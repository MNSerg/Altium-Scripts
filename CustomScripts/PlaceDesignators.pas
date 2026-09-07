{..............................................................................}
{ PlaceDesignators.pas                                                          }
{ Авторасстановка шелкографических десигнаторов у компонентов.                 }
{ Кандидаты: сверху/снизу/слева/справа от courtyard, оценка коллизий.          }
{..............................................................................}

const
    cGapMM = 0.2;
    cSilkClear = 10000; { ~1 mil extra }

var
    SilBoard : IPCB_Board;
    SkipHidden : Boolean;
    FixedHeight : TCoord;
    MovedCnt, FailCnt, SkipCnt : Integer;

{ Run Script: choose procedure StartPlaceDesignators (project compiles only this .pas). }
procedure StartPlaceDesignators; forward;
procedure _StartPlaceDesignators; forward;
procedure TFormSilk.ButtonOKClick(SilSender: TObject); forward;
procedure TFormSilk.ButtonCancelClick(SilSender: TObject); forward;
procedure TFormSilk.FormSilkShow(SilSender: TObject); forward;

procedure SilShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

{ DelphiScript: rfReplaceAll in square brackets is an Array Variant, not a set. }
function SilReplaceChar(const SilS : String; SilA, SilB : Char) : String;
var
    Sili : Integer;
    SilCh : Char;
begin
    Result := '';
    for Sili := 1 to Length(SilS) do
    begin
        SilCh := SilS[Sili];
        if SilCh = SilA then
            Result := Result + SilB
        else
            Result := Result + SilCh;
    end;
end;

function SilParseFloat(const SilS : String; var SilV : Double) : Boolean;
var
    SilT : String;
    SilCode : Integer;
begin
    Result := False;
    SilT := SilS;
    while (Length(SilT) > 0) and (SilT[1] = ' ') do
        SilT := Copy(SilT, 2, Length(SilT));
    while (Length(SilT) > 0) and (SilT[Length(SilT)] = ' ') do
        SilT := Copy(SilT, 1, Length(SilT) - 1);
    SilT := SilReplaceChar(SilT, ',', '.');
    if SilT = '' then Exit;
    Val(SilT, SilV, SilCode);
    Result := (SilCode = 0);
end;

function RectsOverlap(L1, B1, R1, SilT1, L2, B2, R2, SilT2 : TCoord) : Boolean;
begin
    Result := not ((R1 < L2) or (R2 < L1) or (SilT1 < B2) or (SilT2 < B1));
end;

function OverlayLayer(SilCmp : IPCB_Component) : TLayer;
begin
    if SilCmp.Layer = eBottomLayer then
        Result := eBottomOverlay
    else
        Result := eTopOverlay;
end;

function IsHiddenName(SilCmp : IPCB_Component) : Boolean;
var
    Txt : IPCB_Text;
begin
    Result := False;
    try
        Txt := SilCmp.Name;
        if Txt <> nil then
        begin
            if Txt.IsHidden then
            begin
                Result := True;
                Exit;
            end;
        end;
    except
    end;
    try
        if SilCmp.NameOn = False then Result := True;
    except
    end;
end;

function GetCourtyard(SilCmp : IPCB_Component) : TCoordRect;
begin
    try
        Result := SilCmp.BoundingRectangleNoNameCommentForSignals;
    except
        try
            Result := SilCmp.BoundingRectangleNoNameComment;
        except
            Result := SilCmp.BoundingRectangle;
        end;
    end;
end;

function CollisionScore(SilL, SilB, SilR, SilT : TCoord; SkipCmp : IPCB_Component; SilkLayer : TLayer) : Integer;
var
    SilIter : IPCB_SpatialIterator;
    SilPrim : IPCB_Primitive;
    RR : TCoordRect;
    Extra : TCoord;
begin
    Result := 0;
    Extra := MMsToCoord(cGapMM);
    SilL := SilL - Extra; SilB := SilB - Extra; SilR := SilR + Extra; SilT := SilT + Extra;

    SilIter := SilBoard.SpatialIterator_Create;
    SilIter.AddFilter_ObjectSet(MkSet(ePadObject, eViaObject, eTrackObject, eArcObject, eTextObject, eComponentBodyObject));
    SilIter.AddFilter_LayerSet(MkSet(SilkLayer, eMultiLayer, eTopLayer, eBottomLayer));
    SilIter.AddFilter_Area(SilL, SilB, SilR, SilT);
    SilPrim := SilIter.FirstPCBObject;
    while SilPrim <> nil do
    begin
        if (SkipCmp <> nil) and (SilPrim.I_ObjectAddress = SkipCmp.I_ObjectAddress) then
        begin
            SilPrim := SilIter.NextPCBObject;
            Continue;
        end;
        if SilPrim.ObjectId = eTextObject then
        begin
            if SilPrim.Component = SkipCmp then
            begin
                SilPrim := SilIter.NextPCBObject;
                Continue;
            end;
        end;
        RR := SilPrim.BoundingRectangle;
        if RectsOverlap(SilL, SilB, SilR, SilT, RR.Left, RR.Bottom, RR.Right, RR.Top) then
            Inc(Result);
        SilPrim := SilIter.NextPCBObject;
    end;
    SilBoard.SpatialIterator_Destroy(SilIter);

    { Край платы. }
    RR := SilBoard.BoardOutline.BoundingRectangle;
    if (SilL < RR.Left) or (SilB < RR.Bottom) or (SilR > RR.Right) or (SilT > RR.Top) then
        Result := Result + 50;
end;

procedure ApplyRotationForReadability(Txt : IPCB_Text; SilCmp : IPCB_Component; Use90 : Boolean);
var
    SilRot : Double;
begin
    if Use90 then SilRot := 90 else SilRot := 0;
    if SilCmp.Layer = eBottomLayer then
    begin
        { На нижней шелкографии текст зеркален слоем; угол 0/90 сохраняем читаемым. }
        Txt.MirrorFlag := True;
    end
    else
        Txt.MirrorFlag := False;
    Txt.Rotation := SilRot;
end;

procedure PlaceOne(SilCmp : IPCB_Component);
var
    Txt : IPCB_Text;
    Court : TCoordRect;
    BestScore, Score, Sili : Integer;
    BestX, BestY : TCoord;
    Best90 : Boolean;
    TW, TH : TCoord;
    SilL, SilB, SilR, SilT : TCoord;
    Gap : TCoord;
    SilCX, SilCY : TCoord;
    CandsX, CandsY : array[0..7] of TCoord;
    Cands90 : array[0..7] of Boolean;
    SilkLayer : TLayer;
begin
    Txt := SilCmp.Name;
    if Txt = nil then Exit;
    if SkipHidden and IsHiddenName(SilCmp) then
    begin
        Inc(SkipCnt);
        Exit;
    end;

    SilkLayer := OverlayLayer(SilCmp);
    Txt.Layer := SilkLayer;

    if FixedHeight > 0 then
    begin
        Txt.Size := FixedHeight;
        try
            Txt.Width := FixedHeight div 10;
        except
        end;
    end;

    Court := GetCourtyard(SilCmp);
    Gap := MMsToCoord(cGapMM);
    TW := Txt.BoundingRectangle.Right - Txt.BoundingRectangle.Left;
    TH := Txt.BoundingRectangle.Top - Txt.BoundingRectangle.Bottom;
    if TW < 1 then TW := MMsToCoord(1);
    if TH < 1 then TH := MMsToCoord(0.8);

    SilCX := (Court.Left + Court.Right) div 2;
    SilCY := (Court.Bottom + Court.Top) div 2;

    { 0: сверху 0°, 1: снизу 0°, 2: слева 90°, 3: справа 90°,
      4..7 те же со сдвигом. }
    CandsX[0] := SilCX; CandsY[0] := Court.Top + Gap + TH div 2; Cands90[0] := False;
    CandsX[1] := SilCX; CandsY[1] := Court.Bottom - Gap - TH div 2; Cands90[1] := False;
    CandsX[2] := Court.Left - Gap - TH div 2; CandsY[2] := SilCY; Cands90[2] := True;
    CandsX[3] := Court.Right + Gap + TH div 2; CandsY[3] := SilCY; Cands90[3] := True;
    CandsX[4] := Court.Left + TW div 2; CandsY[4] := Court.Top + Gap + TH div 2; Cands90[4] := False;
    CandsX[5] := Court.Right - TW div 2; CandsY[5] := Court.Bottom - Gap - TH div 2; Cands90[5] := False;
    CandsX[6] := Court.Left - Gap - TH div 2; CandsY[6] := Court.Top - TH; Cands90[6] := True;
    CandsX[7] := Court.Right + Gap + TH div 2; CandsY[7] := Court.Bottom + TH; Cands90[7] := True;

    BestScore := 100000;
    BestX := Txt.XLocation;
    BestY := Txt.YLocation;
    Best90 := False;

    for Sili := 0 to 7 do
    begin
        SilL := CandsX[Sili] - TW div 2;
        SilR := CandsX[Sili] + TW div 2;
        SilB := CandsY[Sili] - TH div 2;
        SilT := CandsY[Sili] + TH div 2;
        if Cands90[Sili] then
        begin
            SilL := CandsX[Sili] - TH div 2;
            SilR := CandsX[Sili] + TH div 2;
            SilB := CandsY[Sili] - TW div 2;
            SilT := CandsY[Sili] + TW div 2;
        end;
        Score := CollisionScore(SilL, SilB, SilR, SilT, SilCmp, SilkLayer);
        { Предпочитаем верх/право при равенстве. }
        if Score < BestScore then
        begin
            BestScore := Score;
            BestX := CandsX[Sili];
            BestY := CandsY[Sili];
            Best90 := Cands90[Sili];
        end;
    end;

    Txt.BeginModify;
    SilCmp.ChangeNameAutoposition := eAutoPos_Manual;
    ApplyRotationForReadability(Txt, SilCmp, Best90);
    Txt.MoveToXY(BestX, BestY);
    Txt.EndModify;
    Txt.GraphicallyInvalidate;
    Inc(MovedCnt);
    if BestScore >= 50 then Inc(FailCnt);
end;

procedure DoPlace;
var
    SilIter : IPCB_BoardIterator;
    SilCmp : IPCB_Component;
    AnySelected : Boolean;
    Sili : Integer;
    SilPrim : IPCB_Primitive;
begin
    MovedCnt := 0;
    FailCnt := 0;
    SkipCnt := 0;

    { Если выделены компоненты — только они; иначе все. }
    AnySelected := False;
    for Sili := 0 to SilBoard.SelectecObjectCount - 1 do
    begin
        SilPrim := SilBoard.SelectecObject(Sili);
        if SilPrim.ObjectId = eComponentObject then
            AnySelected := True;
    end;

    PCBServer.PreProcess;
    try
        if AnySelected then
        begin
            for Sili := 0 to SilBoard.SelectecObjectCount - 1 do
            begin
                SilPrim := SilBoard.SelectecObject(Sili);
                if SilPrim.ObjectId = eComponentObject then
                    PlaceOne(SilPrim);
            end;
        end
        else
        begin
            SilIter := SilBoard.BoardIterator_Create;
            SilIter.AddFilter_ObjectSet(MkSet(eComponentObject));
            SilIter.AddFilter_LayerSet(AllLayers);
            SilIter.AddFilter_Method(eProcessAll);
            SilCmp := SilIter.FirstPCBObject;
            while SilCmp <> nil do
            begin
                PlaceOne(SilCmp);
                SilCmp := SilIter.NextPCBObject;
            end;
            SilBoard.BoardIterator_Destroy(SilIter);
        end;
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
    SilShowBox(LabelInfoMoved.Caption + IntToStr(MovedCnt) + sLineBreak +
               LabelInfoWarn.Caption + IntToStr(FailCnt) + sLineBreak +
               LabelInfoSkip.Caption + IntToStr(SkipCnt), 64);
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function SilCS_ScriptFolder : String;
var
    SilWS  : IWorkspace;
    SilPrj : IProject;
    Sili   : Integer;
    SilP, SilName : String;
begin
    Result := '';
    try
        SilWS := GetWorkspace;
        if SilWS = nil then Exit;
        for Sili := 0 to SilWS.DM_ProjectCount - 1 do
        begin
            SilPrj := SilWS.DM_Projects(Sili);
            if SilPrj = nil then Continue;
            SilP := SilPrj.DM_ProjectFullPath;
            SilName := UpperCase(ExtractFileName(SilP));
            if SilName = 'PLACEDESIGNATORS.PRJSCR' then
            begin
                Result := ExtractFilePath(SilP);
                Exit;
            end;
        end;
        for Sili := 0 to SilWS.DM_ProjectCount - 1 do
        begin
            SilPrj := SilWS.DM_Projects(Sili);
            if SilPrj = nil then Continue;
            SilP := SilPrj.DM_ProjectFullPath;
            if Pos('CUSTOMSCRIPTS', UpperCase(SilP)) > 0 then
            begin
                Result := ExtractFilePath(SilP);
                Exit;
            end;
        end;
        SilPrj := SilWS.DM_FocusedProject;
        if SilPrj <> nil then
            Result := ExtractFilePath(SilPrj.DM_ProjectFullPath);
    except
        Result := '';
    end;
end;

function SilCS_FindImageFile(const SilFileName : String) : String;
var
    SilDir, SilP : String;
begin
    Result := '';
    SilDir := SilCS_ScriptFolder;
    if SilDir <> '' then
    begin
        SilP := SilDir + 'images\' + SilFileName;
        if FileExists(SilP) then begin Result := SilP; Exit; end;
        SilP := SilDir + SilFileName;
        if FileExists(SilP) then begin Result := SilP; Exit; end;
    end;
    SilP := 'images\' + SilFileName;
    if FileExists(SilP) then begin Result := SilP; Exit; end;
    if FileExists(SilFileName) then Result := SilFileName;
end;

procedure SilCS_TryLoadHelpImage(const SilBmpName : String; const SilPngName : String);
var
    SilP : String;
    HadPic : Boolean;
begin
    HadPic := False;
    try
        if ImageHelp.Picture.Width > 0 then HadPic := True;
    except
        HadPic := False;
    end;
    try
        SilP := SilCS_FindImageFile(SilBmpName);
        if SilP = '' then
            SilP := SilCS_FindImageFile(SilPngName);
        if SilP = '' then
            SilP := SilCS_FindImageFile('PlaceDesignators.bmp');
        if (SilP <> '') and FileExists(SilP) then
        begin
            ImageHelp.Picture.LoadFromFile(SilP);
            LabelImageHint.Caption := '';
            Exit;
        end;
    except
    end;
    if HadPic then
        LabelImageHint.Caption := ''
    else
        LabelImageHint.Caption := 'No image. Put ' + SilBmpName + ' in images\ next to the scripts.';
end;


procedure TFormSilk.FormSilkShow(SilSender: TObject);
begin
    try
        SilCS_TryLoadHelpImage('PlaceDesignators.bmp', 'PlaceDesignators.png');
    except
    end;
    EditH.Text := '0';
    CheckSkipHidden.Checked := True;
end;

procedure TFormSilk.ButtonOKClick(SilSender: TObject);
var
    SilH : Double;
begin
    SkipHidden := CheckSkipHidden.Checked;
    if not SilParseFloat(EditH.Text, SilH) then
    begin
        SilShowBox(LabelErrH.Caption, 16);
        Exit;
    end;
    if SilH < 0 then
    begin
        SilShowBox(LabelErrHNeg.Caption, 16);
        Exit;
    end;
    if SilH = 0 then FixedHeight := 0 else FixedHeight := MMsToCoord(SilH);
    if PCBServer = nil then
    begin
        SilShowBox(LabelErrNoSrv.Caption, 16);
        Exit;
    end;
    SilBoard := PCBServer.GetCurrentPCBBoard;
    if SilBoard = nil then
    begin
        SilShowBox(LabelErrNoPcb.Caption, 16);
        Exit;
    end;
    FormSilk.Close;
    DoPlace;
end;

procedure TFormSilk.ButtonCancelClick(SilSender: TObject);
begin
    FormSilk.Close;
end;

procedure StartPlaceDesignators;
begin
    FormSilk.ShowModal;
end;

procedure _StartPlaceDesignators;
begin
    StartPlaceDesignators;
end;
