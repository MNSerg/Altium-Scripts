{..............................................................................}
{ PlaceDesignators.pas                                                          }
{ Авторасстановка шелкографических десигнаторов у компонентов.                 }
{ Кандидаты: сверху/снизу/слева/справа от courtyard, оценка коллизий.          }
{..............................................................................}

const
    cGapMM = 0.2;
    cPadClearMM = 0.25;
    cSilkClear = 10000; { ~1 mil extra }

var
    SilBoard : IPCB_Board;
    SkipHidden : Boolean;
    FixedHeight : TCoord;
    MovedCnt, FailCnt, SkipCnt : Integer;
    SilPadCache : TStringList;
    SilNameCache : TStringList;

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

function SilParseFloat(const SilS : String; var SilV : Double) : Boolean;
var
    SilT : String;
    Sili : Integer;
    SilCh : Char;
    SilSign : Double;
    SilScale : Double;
    SilSeenDigit : Boolean;
    SilFrac : Boolean;
begin
    Result := False;
    SilV := 0;
    SilT := SilS;
    while (Length(SilT) > 0) and (SilT[1] = ' ') do
        SilT := Copy(SilT, 2, Length(SilT));
    while (Length(SilT) > 0) and (SilT[Length(SilT)] = ' ') do
        SilT := Copy(SilT, 1, Length(SilT) - 1);
    if SilT = '' then Exit;
    SilSign := 1;
    Sili := 1;
    if SilT[1] = '-' then
    begin
        SilSign := -1;
        Sili := 2;
    end
    else if SilT[1] = '+' then
        Sili := 2;
    SilSeenDigit := False;
    SilFrac := False;
    SilScale := 1;
    while Sili <= Length(SilT) do
    begin
        SilCh := SilT[Sili];
        if (SilCh = '.') or (SilCh = ',') then
        begin
            if SilFrac then Exit;
            SilFrac := True;
        end
        else if (SilCh >= '0') and (SilCh <= '9') then
        begin
            SilSeenDigit := True;
            if not SilFrac then
                SilV := SilV * 10 + (Ord(SilCh) - Ord('0'))
            else
            begin
                SilScale := SilScale * 10;
                SilV := SilV + (Ord(SilCh) - Ord('0')) / SilScale;
            end;
        end
        else
            Exit;
        Sili := Sili + 1;
    end;
    if not SilSeenDigit then Exit;
    SilV := SilV * SilSign;
    Result := True;
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

function RectInsideOutline(SilL, SilB, SilR, SilT : TCoord) : Boolean;
var
    RR : TCoordRect;
begin
    { AutoPlaceSilkscreen.pas:355 — BoardOutline.PointInPolygon на все 4 угла. }
    Result := False;
    try
        if not SilBoard.BoardOutline.PointInPolygon(SilL, SilB) then Exit;
        if not SilBoard.BoardOutline.PointInPolygon(SilL, SilT) then Exit;
        if not SilBoard.BoardOutline.PointInPolygon(SilR, SilB) then Exit;
        if not SilBoard.BoardOutline.PointInPolygon(SilR, SilT) then Exit;
        Result := True;
        Exit;
    except
    end;
    try
        RR := SilBoard.BoardOutline.BoundingRectangle;
        Result := (SilL >= RR.Left) and (SilB >= RR.Bottom) and (SilR <= RR.Right) and (SilT <= RR.Top);
    except
        Result := False;
    end;
end;

function NameHitsSilk(SilL, SilB, SilR, SilT : TCoord; SkipCmp : IPCB_Component; SilkLayer : TLayer) : Boolean;
var
    Sili : Integer;
    Txt : IPCB_Text;
    RR : TCoordRect;
    SkipTxt : IPCB_Text;
begin
    Result := False;
    SkipTxt := nil;
    try
        if SkipCmp <> nil then SkipTxt := SkipCmp.Name;
    except
        SkipTxt := nil;
    end;
    if SilNameCache = nil then Exit;
    for Sili := 0 to SilNameCache.Count - 1 do
    begin
        Txt := SilNameCache.Objects[Sili];
        if Txt = nil then Continue;
        if (SkipTxt <> nil) and (Txt = SkipTxt) then Continue;
        RR := Txt.BoundingRectangle;
        if RectsOverlap(SilL, SilB, SilR, SilT, RR.Left, RR.Bottom, RR.Right, RR.Top) then
        begin
            Result := True;
            Exit;
        end;
    end;
end;

function NameHitsPad(SilL, SilB, SilR, SilT : TCoord; SkipCmp : IPCB_Component) : Boolean;
var
    Sili : Integer;
    SilPad : IPCB_Pad;
    RR : TCoordRect;
    Extra : TCoord;
begin
    Result := False;
    if SilPadCache = nil then Exit;
    Extra := MMsToCoord(cPadClearMM);
    for Sili := 0 to SilPadCache.Count - 1 do
    begin
        SilPad := SilPadCache.Objects[Sili];
        if SilPad = nil then Continue;
        RR := SilPad.BoundingRectangle;
        if RectsOverlap(SilL, SilB, SilR, SilT,
            RR.Left - Extra, RR.Bottom - Extra, RR.Right + Extra, RR.Top + Extra) then
        begin
            Result := True;
            Exit;
        end;
    end;
end;

procedure SilCollectObstacles;
var
    SilIter : IPCB_BoardIterator;
    SilPad : IPCB_Pad;
    SilCmp : IPCB_Component;
    Txt : IPCB_Text;
begin
    SilIter := SilBoard.BoardIterator_Create;
    SilIter.AddFilter_ObjectSet(MkSet(ePadObject));
    SilIter.AddFilter_LayerSet(MkSet(eMultiLayer, eTopLayer, eBottomLayer));
    SilIter.AddFilter_Method(eProcessAll);
    SilPad := SilIter.FirstPCBObject;
    while SilPad <> nil do
    begin
        SilPadCache.AddObject('P', SilPad);
        SilPad := SilIter.NextPCBObject;
    end;
    SilBoard.BoardIterator_Destroy(SilIter);

    SilIter := SilBoard.BoardIterator_Create;
    SilIter.AddFilter_ObjectSet(MkSet(eComponentObject));
    SilIter.AddFilter_LayerSet(MkSet(eTopLayer, eBottomLayer));
    SilIter.AddFilter_Method(eProcessAll);
    SilCmp := SilIter.FirstPCBObject;
    while SilCmp <> nil do
    begin
        Txt := SilCmp.Name;
        if Txt <> nil then
            SilNameCache.AddObject('N', Txt);
        SilCmp := SilIter.NextPCBObject;
    end;
    SilBoard.BoardIterator_Destroy(SilIter);
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
    Step, Dir : Integer;
    TW, TH : TCoord;
    SilL, SilB, SilR, SilT : TCoord;
    Gap, Extra : TCoord;
    SilCX, SilCY, CandX, CandY : TCoord;
    Use90 : Boolean;
    SilkLayer : TLayer;
    PadHit : Boolean;
    SilkHit : Boolean;
    Inside : Boolean;
    Legal : Boolean;
    BestLegalScore : Integer;
    BestLegalX, BestLegalY : TCoord;
    BestLegal90 : Boolean;
    HaveLegal : Boolean;
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

    BestLegalScore := 100000;
    BestLegalX := Txt.XLocation;
    BestLegalY := Txt.YLocation;
    BestLegal90 := False;
    HaveLegal := False;

    { Снаружи courtyard. Макс. 8 направлений × 5 шагов — без O(n³) итераторов. }
    for Step := 0 to 4 do
    begin
        Extra := Gap + MMsToCoord(0.3) * Step;
        for Dir := 0 to 7 do
        begin
            Use90 := False;
            CandX := SilCX;
            CandY := SilCY;
            case Dir of
                0: begin CandX := SilCX; CandY := Court.Top + Extra + TH div 2; end;
                1: begin CandX := SilCX; CandY := Court.Bottom - Extra - TH div 2; end;
                2: begin CandX := Court.Right + Extra + TH div 2; CandY := SilCY; Use90 := True; end;
                3: begin CandX := Court.Left - Extra - TH div 2; CandY := SilCY; Use90 := True; end;
                4: begin CandX := Court.Right + Extra + TW div 2; CandY := Court.Top + Extra + TH div 2; end;
                5: begin CandX := Court.Left - Extra - TW div 2; CandY := Court.Top + Extra + TH div 2; end;
                6: begin CandX := Court.Right + Extra + TW div 2; CandY := Court.Bottom - Extra - TH div 2; end;
                7: begin CandX := Court.Left - Extra - TW div 2; CandY := Court.Bottom - Extra - TH div 2; end;
            end;
            if Use90 then
            begin
                SilL := CandX - TH div 2;
                SilR := CandX + TH div 2;
                SilB := CandY - TW div 2;
                SilT := CandY + TW div 2;
            end
            else
            begin
                SilL := CandX - TW div 2;
                SilR := CandX + TW div 2;
                SilB := CandY - TH div 2;
                SilT := CandY + TH div 2;
            end;
            Inside := RectInsideOutline(SilL, SilB, SilR, SilT);
            PadHit := NameHitsPad(SilL, SilB, SilR, SilT, SilCmp);
            SilkHit := NameHitsSilk(SilL, SilB, SilR, SilT, SilCmp, SilkLayer);
            Legal := Inside and (not PadHit) and (not SilkHit);
            if Legal then
            begin
                HaveLegal := True;
                BestLegalScore := Step;
                BestLegalX := CandX;
                BestLegalY := CandY;
                BestLegal90 := Use90;
                Break;
            end;
        end;
        if HaveLegal then Break;
    end;

    if not HaveLegal then
    begin
        Inc(SkipCnt);
        Exit;
    end;

    { AutoPlaceSilkscreen.pas:1488 — BeginModify, ChangeNameAutoposition, MoveToXY, EndModify. }
    Txt.BeginModify;
    SilCmp.ChangeNameAutoposition := eAutoPos_Manual;
    ApplyRotationForReadability(Txt, SilCmp, BestLegal90);
    Txt.MoveToXY(BestLegalX, BestLegalY);
    Txt.EndModify;
    Txt.GraphicallyInvalidate;
    Inc(MovedCnt);
    if BestLegalScore > 0 then Inc(FailCnt);
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
    SilPadCache := TStringList.Create;
    SilNameCache := TStringList.Create;
    SilCollectObstacles;

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
            SilIter.AddFilter_LayerSet(MkSet(eTopLayer, eBottomLayer));
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
        SilPadCache.Free;
        SilNameCache.Free;
        SilPadCache := nil;
        SilNameCache := nil;
    end;

    try
        SilBoard.ViewManager_FullUpdate;
    except
    end;

    try
        SilBoard.DisplayUnit := eMetric;
    except
    end;
    try
        SilBoard.SnapGridUnit := eMetric;
    except
    end;
    try
        SilBoard.SnapGridSize := MMsToCoord(0.1);
    except
        try
            SilBoard.SetState_SnapGridSize(MMsToCoord(0.1));
        except
        end;
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
        SilP := SilDir + SilFileName;
        if FileExists(SilP) then begin Result := SilP; Exit; end;
        SilP := SilDir + 'images\' + SilFileName;
        if FileExists(SilP) then begin Result := SilP; Exit; end;
    end;
    if FileExists(SilFileName) then begin Result := SilFileName; Exit; end;
    SilP := 'images\' + SilFileName;
    if FileExists(SilP) then Result := SilP;
end;

procedure SilCS_TryOneHelpFile(const SilName : String; var SilDone : Boolean);
var
    SilP : String;
begin
    if SilDone then Exit;
    SilP := SilCS_FindImageFile(SilName);
    if (SilP = '') or (not FileExists(SilP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(SilP);
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
        SilDone := True;
    except
    end;
end;

procedure SilCS_TryLoadHelpImage(const SilBmpName : String; const SilPngName : String);
var
    SilDone : Boolean;
begin
    SilDone := False;
    SilCS_TryOneHelpFile(SilPngName, SilDone);
    SilCS_TryOneHelpFile(SilBmpName, SilDone);
    SilCS_TryOneHelpFile('PlaceDesignators.png', SilDone);
    SilCS_TryOneHelpFile('PlaceDesignators.bmp', SilDone);
    if not SilDone then
        LabelImageHint.Caption := 'No image. Put ' + SilPngName + ' next to the script or in images\.';
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
