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

function NameHitsPad(SilL, SilB, SilR, SilT : TCoord; SkipCmp : IPCB_Component) : Boolean;
var
    Extra : TCoord;
    GIter : IPCB_GroupIterator;
    SilPad : IPCB_Pad;
    SIter : IPCB_SpatialIterator;
    SilPrim : IPCB_Primitive;
    RR : TCoordRect;
    PL, PB, PR, PT : TCoord;
begin
    { Площадки — жёсткое препятствие: BoundingRectangle + 0.25 мм. }
    Result := False;
    Extra := MMsToCoord(cPadClearMM);
    SilL := SilL - Extra;
    SilB := SilB - Extra;
    SilR := SilR + Extra;
    SilT := SilT + Extra;

    if SkipCmp <> nil then
    begin
        try
            GIter := SkipCmp.GroupIterator_Create;
            GIter.AddFilter_ObjectSet(MkSet(ePadObject));
            SilPad := GIter.FirstPCBObject;
            while SilPad <> nil do
            begin
                RR := SilPad.BoundingRectangle;
                PL := RR.Left - Extra;
                PB := RR.Bottom - Extra;
                PR := RR.Right + Extra;
                PT := RR.Top + Extra;
                if RectsOverlap(SilL, SilB, SilR, SilT, PL, PB, PR, PT) then
                begin
                    Result := True;
                    SkipCmp.GroupIterator_Destroy(GIter);
                    Exit;
                end;
                SilPad := GIter.NextPCBObject;
            end;
            SkipCmp.GroupIterator_Destroy(GIter);
        except
        end;
    end;

    SIter := SilBoard.SpatialIterator_Create;
    SIter.AddFilter_ObjectSet(MkSet(ePadObject));
    SIter.AddFilter_LayerSet(MkSet(eMultiLayer, eTopLayer, eBottomLayer));
    SIter.AddFilter_Area(SilL, SilB, SilR, SilT);
    SilPrim := SIter.FirstPCBObject;
    while SilPrim <> nil do
    begin
        RR := SilPrim.BoundingRectangle;
        PL := RR.Left - Extra;
        PB := RR.Bottom - Extra;
        PR := RR.Right + Extra;
        PT := RR.Top + Extra;
        if RectsOverlap(SilL, SilB, SilR, SilT, PL, PB, PR, PT) then
        begin
            Result := True;
            SilBoard.SpatialIterator_Destroy(SIter);
            Exit;
        end;
        SilPrim := SIter.NextPCBObject;
    end;
    SilBoard.SpatialIterator_Destroy(SIter);
end;

function CollisionScore(SilL, SilB, SilR, SilT : TCoord; SkipCmp : IPCB_Component; SilkLayer : TLayer) : Integer;
var
    SilIter : IPCB_SpatialIterator;
    SilPrim : IPCB_Primitive;
    RR : TCoordRect;
    Extra : TCoord;
    NameAddr : Integer;
begin
    Result := 0;
    Extra := MMsToCoord(cGapMM);
    SilL := SilL - Extra; SilB := SilB - Extra; SilR := SilR + Extra; SilT := SilT + Extra;
    NameAddr := 0;
    try
        if (SkipCmp <> nil) and (SkipCmp.Name <> nil) then
            NameAddr := SkipCmp.Name.I_ObjectAddress;
    except
        NameAddr := 0;
    end;

    SilIter := SilBoard.SpatialIterator_Create;
    SilIter.AddFilter_ObjectSet(MkSet(ePadObject, eViaObject, eTrackObject, eArcObject, eTextObject, eComponentBodyObject));
    SilIter.AddFilter_LayerSet(MkSet(SilkLayer, eMultiLayer, eTopLayer, eBottomLayer));
    SilIter.AddFilter_Area(SilL, SilB, SilR, SilT);
    SilPrim := SilIter.FirstPCBObject;
    while SilPrim <> nil do
    begin
        if (NameAddr <> 0) and (SilPrim.I_ObjectAddress = NameAddr) then
        begin
            SilPrim := SilIter.NextPCBObject;
            Continue;
        end;
        RR := SilPrim.BoundingRectangle;
        if RectsOverlap(SilL, SilB, SilR, SilT, RR.Left, RR.Bottom, RR.Right, RR.Top) then
        begin
            if SilPrim.ObjectId = ePadObject then
                Result := Result + 12
            else if SilPrim.ObjectId = eViaObject then
                Result := Result + 10
            else if SilPrim.ObjectId = eTextObject then
                Result := Result + 8
            else
                Inc(Result);
        end;
        SilPrim := SilIter.NextPCBObject;
    end;
    SilBoard.SpatialIterator_Destroy(SilIter);

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
    BestScore, Score, Step, Dir : Integer;
    BestX, BestY : TCoord;
    Best90 : Boolean;
    TW, TH : TCoord;
    SilL, SilB, SilR, SilT : TCoord;
    Gap, Extra : TCoord;
    SilCX, SilCY, CandX, CandY : TCoord;
    Use90 : Boolean;
    SilkLayer : TLayer;
    PadHit : Boolean;
    BestFreeScore : Integer;
    BestFreeX, BestFreeY : TCoord;
    BestFree90 : Boolean;
    HaveFree : Boolean;
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

    BestScore := 100000;
    BestX := Txt.XLocation;
    BestY := Txt.YLocation;
    Best90 := False;
    BestFreeScore := 100000;
    BestFreeX := BestX;
    BestFreeY := BestY;
    BestFree90 := False;
    HaveFree := False;

    { Больше смещений; площадки — жёсткий запрет, если есть свободный кандидат. }
    for Step := 0 to 14 do
    begin
        Extra := Gap + MMsToCoord(0.15) * Step;
        for Dir := 0 to 15 do
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
                8: begin CandX := Court.Right - TW div 2; CandY := Court.Top + Extra + TH div 2; end;
                9: begin CandX := Court.Left + TW div 2; CandY := Court.Bottom - Extra - TH div 2; end;
                10: begin CandX := Court.Right + Extra + TH div 2; CandY := Court.Top - TH; Use90 := True; end;
                11: begin CandX := Court.Left - Extra - TH div 2; CandY := Court.Bottom + TH; Use90 := True; end;
                12: begin CandX := SilCX + TW; CandY := Court.Top + Extra + TH div 2; end;
                13: begin CandX := SilCX - TW; CandY := Court.Bottom - Extra - TH div 2; end;
                14: begin CandX := Court.Right + Extra + TH; CandY := SilCY + TH; Use90 := True; end;
                15: begin CandX := Court.Left - Extra - TH; CandY := SilCY - TH; Use90 := True; end;
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
            PadHit := NameHitsPad(SilL, SilB, SilR, SilT, SilCmp);
            Score := CollisionScore(SilL, SilB, SilR, SilT, SilCmp, SilkLayer);
            if PadHit then
                Score := Score + 1000;
            if (not PadHit) then
            begin
                HaveFree := True;
                if Score < BestFreeScore then
                begin
                    BestFreeScore := Score;
                    BestFreeX := CandX;
                    BestFreeY := CandY;
                    BestFree90 := Use90;
                end;
            end;
            if Score < BestScore then
            begin
                BestScore := Score;
                BestX := CandX;
                BestY := CandY;
                Best90 := Use90;
            end;
            if HaveFree and (BestFreeScore = 0) then Break;
        end;
        if HaveFree and (BestFreeScore = 0) then Break;
    end;

    if HaveFree then
    begin
        BestX := BestFreeX;
        BestY := BestFreeY;
        Best90 := BestFree90;
        BestScore := BestFreeScore;
    end;

    Txt.BeginModify;
    SilCmp.ChangeNameAutoposition := eAutoPos_Manual;
    ApplyRotationForReadability(Txt, SilCmp, Best90);
    Txt.MoveToXY(BestX, BestY);
    Txt.EndModify;
    Txt.GraphicallyInvalidate;
    Inc(MovedCnt);
    if BestScore > 0 then Inc(FailCnt);
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
