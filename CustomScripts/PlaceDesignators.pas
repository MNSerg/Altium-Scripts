{..............................................................................}
{ PlaceDesignators.pas                                                          }
{ Авторасстановка шелкографических десигнаторов у компонентов.                 }
{ Кандидаты: сверху/снизу/слева/справа от courtyard, оценка коллизий.          }
{..............................................................................}

const
    cGapMM = 0.2;
    cSilkClear = 10000; { ~1 mil extra }

var
    Board : IPCB_Board;
    SkipHidden : Boolean;
    FixedHeight : TCoord;
    MovedCnt, FailCnt, SkipCnt : Integer;

procedure Start; forward;
procedure _Start; forward;
procedure TFormSilk.ButtonOKClick(Sender: TObject); forward;
procedure TFormSilk.ButtonCancelClick(Sender: TObject); forward;
procedure TFormSilk.FormSilkShow(Sender: TObject); forward;
procedure LoadHelpImage(Img : TImage; Hint : TLabel; const FileName : String); forward;

function RectsOverlap(L1, B1, R1, T1, L2, B2, R2, T2 : TCoord) : Boolean;
begin
    Result := not ((R1 < L2) or (R2 < L1) or (T1 < B2) or (T2 < B1));
end;

function OverlayLayer(Cmp : IPCB_Component) : TLayer;
begin
    if Cmp.Layer = eBottomLayer then
        Result := eBottomOverlay
    else
        Result := eTopOverlay;
end;

function IsHiddenName(Cmp : IPCB_Component) : Boolean;
begin
    Result := False;
    try
        if Cmp.NameOn = False then Result := True;
    except
    end;
end;

function GetCourtyard(Cmp : IPCB_Component) : TCoordRect;
begin
    try
        Result := Cmp.BoundingRectangleNoNameCommentForSignals;
    except
        try
            Result := Cmp.BoundingRectangleNoNameComment;
        except
            Result := Cmp.BoundingRectangle;
        end;
    end;
end;

function CollisionScore(L, B, R, T : TCoord; SkipCmp : IPCB_Component; SilkLayer : TLayer) : Integer;
var
    Iter : IPCB_SpatialIterator;
    Prim : IPCB_Primitive;
    RR : TCoordRect;
    Extra : TCoord;
begin
    Result := 0;
    Extra := MMsToCoord(cGapMM);
    L := L - Extra; B := B - Extra; R := R + Extra; T := T + Extra;

    Iter := Board.SpatialIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(ePadObject, eViaObject, eTrackObject, eArcObject, eTextObject, eComponentBodyObject));
    Iter.AddFilter_LayerSet(MkSet(SilkLayer, eMultiLayer, eTopLayer, eBottomLayer));
    Iter.AddFilter_Area(L, B, R, T);
    Prim := Iter.FirstPCBObject;
    while Prim <> nil do
    begin
        if (SkipCmp <> nil) and (Prim.I_ObjectAddress = SkipCmp.I_ObjectAddress) then
        begin
            Prim := Iter.NextPCBObject;
            Continue;
        end;
        if Prim.ObjectId = eTextObject then
        begin
            if Prim.Component = SkipCmp then
            begin
                Prim := Iter.NextPCBObject;
                Continue;
            end;
        end;
        RR := Prim.BoundingRectangle;
        if RectsOverlap(L, B, R, T, RR.Left, RR.Bottom, RR.Right, RR.Top) then
            Inc(Result);
        Prim := Iter.NextPCBObject;
    end;
    Board.SpatialIterator_Destroy(Iter);

    { Край платы. }
    RR := Board.BoardOutline.BoundingRectangle;
    if (L < RR.Left) or (B < RR.Bottom) or (R > RR.Right) or (T > RR.Top) then
        Result := Result + 50;
end;

procedure ApplyRotationForReadability(Txt : IPCB_Text; Cmp : IPCB_Component; Use90 : Boolean);
var
    Rot : Double;
begin
    if Use90 then Rot := 90 else Rot := 0;
    if Cmp.Layer = eBottomLayer then
    begin
        { На нижней шелкографии текст зеркален слоем; угол 0/90 сохраняем читаемым. }
        Txt.MirrorFlag := True;
    end
    else
        Txt.MirrorFlag := False;
    Txt.Rotation := Rot;
end;

procedure PlaceOne(Cmp : IPCB_Component);
var
    Txt : IPCB_Text;
    Court : TCoordRect;
    BestScore, Score, i : Integer;
    BestX, BestY : TCoord;
    Best90 : Boolean;
    TW, TH : TCoord;
    L, B, R, T : TCoord;
    Gap : TCoord;
    CX, CY : TCoord;
    CandsX, CandsY : array[0..7] of TCoord;
    Cands90 : array[0..7] of Boolean;
    SilkLayer : TLayer;
begin
    Txt := Cmp.Name;
    if Txt = nil then Exit;
    if SkipHidden and IsHiddenName(Cmp) then
    begin
        Inc(SkipCnt);
        Exit;
    end;

    SilkLayer := OverlayLayer(Cmp);
    Txt.Layer := SilkLayer;

    if FixedHeight > 0 then
    begin
        Txt.Size := FixedHeight;
        try
            Txt.Width := FixedHeight div 10;
        except
        end;
    end;

    Court := GetCourtyard(Cmp);
    Gap := MMsToCoord(cGapMM);
    TW := Txt.BoundingRectangle.Right - Txt.BoundingRectangle.Left;
    TH := Txt.BoundingRectangle.Top - Txt.BoundingRectangle.Bottom;
    if TW < 1 then TW := MMsToCoord(1);
    if TH < 1 then TH := MMsToCoord(0.8);

    CX := (Court.Left + Court.Right) div 2;
    CY := (Court.Bottom + Court.Top) div 2;

    { 0: сверху 0°, 1: снизу 0°, 2: слева 90°, 3: справа 90°,
      4..7 те же со сдвигом. }
    CandsX[0] := CX; CandsY[0] := Court.Top + Gap + TH div 2; Cands90[0] := False;
    CandsX[1] := CX; CandsY[1] := Court.Bottom - Gap - TH div 2; Cands90[1] := False;
    CandsX[2] := Court.Left - Gap - TH div 2; CandsY[2] := CY; Cands90[2] := True;
    CandsX[3] := Court.Right + Gap + TH div 2; CandsY[3] := CY; Cands90[3] := True;
    CandsX[4] := Court.Left + TW div 2; CandsY[4] := Court.Top + Gap + TH div 2; Cands90[4] := False;
    CandsX[5] := Court.Right - TW div 2; CandsY[5] := Court.Bottom - Gap - TH div 2; Cands90[5] := False;
    CandsX[6] := Court.Left - Gap - TH div 2; CandsY[6] := Court.Top - TH; Cands90[6] := True;
    CandsX[7] := Court.Right + Gap + TH div 2; CandsY[7] := Court.Bottom + TH; Cands90[7] := True;

    BestScore := 100000;
    BestX := Txt.XLocation;
    BestY := Txt.YLocation;
    Best90 := False;

    for i := 0 to 7 do
    begin
        L := CandsX[i] - TW div 2;
        R := CandsX[i] + TW div 2;
        B := CandsY[i] - TH div 2;
        T := CandsY[i] + TH div 2;
        if Cands90[i] then
        begin
            L := CandsX[i] - TH div 2;
            R := CandsX[i] + TH div 2;
            B := CandsY[i] - TW div 2;
            T := CandsY[i] + TW div 2;
        end;
        Score := CollisionScore(L, B, R, T, Cmp, SilkLayer);
        { Предпочитаем верх/право при равенстве. }
        if Score < BestScore then
        begin
            BestScore := Score;
            BestX := CandsX[i];
            BestY := CandsY[i];
            Best90 := Cands90[i];
        end;
    end;

    Txt.BeginModify;
    Cmp.ChangeNameAutoposition := eAutoPos_Manual;
    ApplyRotationForReadability(Txt, Cmp, Best90);
    Txt.XLocation := BestX;
    Txt.YLocation := BestY;
    Txt.EndModify;
    Txt.GraphicallyInvalidate;
    Inc(MovedCnt);
    if BestScore >= 50 then Inc(FailCnt);
end;

procedure DoPlace;
var
    Iter : IPCB_BoardIterator;
    Cmp : IPCB_Component;
    AnySelected : Boolean;
    i : Integer;
    Prim : IPCB_Primitive;
begin
    MovedCnt := 0;
    FailCnt := 0;
    SkipCnt := 0;

    { Если выделены компоненты — только они; иначе все. }
    AnySelected := False;
    for i := 0 to Board.SelectecObjectCount - 1 do
    begin
        Prim := Board.SelectecObject(i);
        if Prim.ObjectId = eComponentObject then
            AnySelected := True;
    end;

    PCBServer.PreProcess;
    try
        if AnySelected then
        begin
            for i := 0 to Board.SelectecObjectCount - 1 do
            begin
                Prim := Board.SelectecObject(i);
                if Prim.ObjectId = eComponentObject then
                    PlaceOne(Prim);
            end;
        end
        else
        begin
            Iter := Board.BoardIterator_Create;
            Iter.AddFilter_ObjectSet(MkSet(eComponentObject));
            Iter.AddFilter_LayerSet(AllLayers);
            Iter.AddFilter_Method(eProcessAll);
            Cmp := Iter.FirstPCBObject;
            while Cmp <> nil do
            begin
                PlaceOne(Cmp);
                Cmp := Iter.NextPCBObject;
            end;
            Board.BoardIterator_Destroy(Iter);
        end;
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
    ShowInfo('Расставлено: ' + IntToStr(MovedCnt) + sLineBreak +
             'С предупреждением (край платы / плотно): ' + IntToStr(FailCnt) + sLineBreak +
             'Пропущено скрытых: ' + IntToStr(SkipCnt),
             'Десигнаторы');
end;

procedure LoadHelpImage(Img : TImage; Hint : TLabel; const FileName : String);
var
    Cands : TStringList;
    i : Integer;
    P : String;
    WS : IWorkspace;
    Prj : IProject;
begin
    if Img = nil then Exit;
    Cands := TStringList.Create;
    try
        try Cands.Add(ExtractFilePath(ParamStr(0)) + 'images\' + FileName); except end;
        try
            WS := GetWorkspace;
            if WS <> nil then
                for i := 0 to WS.DM_ProjectCount - 1 do
                begin
                    Prj := WS.DM_Projects(i);
                    if Prj <> nil then
                        Cands.Add(ExtractFilePath(Prj.DM_ProjectFullPath) + 'images\' + FileName);
                end;
        except
        end;
        Cands.Add('images\' + FileName);
        Cands.Add('CustomScripts\images\' + FileName);
        for i := 0 to Cands.Count - 1 do
        begin
            P := Cands[i];
            if (P <> '') and FileExists(P) then
            begin
                try
                    Img.Picture.LoadFromFile(P);
                    if Hint <> nil then Hint.Caption := 'Замените картинку: images\' + FileName;
                    Exit;
                except
                end;
            end;
        end;
        if Hint <> nil then
            Hint.Caption := 'Нет картинки. Положите ' + FileName + ' в images\ рядом со скриптами.';
    finally
        Cands.Free;
    end;
end;

procedure TFormSilk.FormSilkShow(Sender: TObject);
begin
    LoadHelpImage(ImageHelp, LabelImageHint, 'PlaceDesignators.png');
    EditH.Text := '0';
    CheckSkipHidden.Checked := True;
end;

procedure TFormSilk.ButtonOKClick(Sender: TObject);
var
    H : Double;
begin
    SkipHidden := CheckSkipHidden.Checked;
    try
        H := StrToFloat(EditH.Text);
    except
        ShowError('Некорректная высота текста.');
        Exit;
    end;
    if H < 0 then
    begin
        ShowError('Высота не может быть отрицательной.');
        Exit;
    end;
    if H = 0 then FixedHeight := 0 else FixedHeight := MMsToCoord(H);
    FormSilk.Close;
    DoPlace;
end;

procedure TFormSilk.ButtonCancelClick(Sender: TObject);
begin
    FormSilk.Close;
end;

procedure Start;
begin
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = nil then
    begin
        ShowError('Нет открытого PCB-документа.');
        Exit;
    end;
    FormSilk.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
