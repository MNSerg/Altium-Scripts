{..............................................................................}
{ PcbWizard.pas                                                                 }
{ Новая плата: размер, keep-out контур со скруглениями, крепёж, опции.         }
{..............................................................................}

var
    Board : IPCB_Board;
    Wmm, Hmm, FilletMM, HoleMM, PadMM, MarginMM, GridMM : Double;
    FourHoles, MakeGnd, MakeMask, NewDoc : Boolean;
    CopperCount : Integer;

procedure Start; forward;
procedure _Start; forward;
procedure TFormWizard.ButtonOKClick(Sender: TObject); forward;
procedure TFormWizard.ButtonCancelClick(Sender: TObject); forward;
procedure TFormWizard.FormWizardShow(Sender: TObject); forward;

function AddTrackL(X1, Y1, X2, Y2 : TCoord; ALayer : TLayer; Width : TCoord) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := X1; Result.Y1 := Y1;
    Result.X2 := X2; Result.Y2 := Y2;
    Result.Layer := ALayer;
    Result.Width := Width;
    Board.AddPCBObject(Result);
    Result.Selected := True;
end;

function AddArcL(CX, CY, R : TCoord; Sa, Ea : Double; ALayer : TLayer; Width : TCoord) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := CX; Result.YCenter := CY;
    Result.Radius := R;
    Result.StartAngle := Sa; Result.EndAngle := Ea;
    Result.Layer := ALayer;
    Result.LineWidth := Width;
    Board.AddPCBObject(Result);
    Result.Selected := True;
end;

procedure DrawRoundedKeepout(X0, Y0, X1, Y1, R, Width : TCoord);
var
    L : TLayer;
begin
    L := eKeepOutLayer;
    if R <= 0 then
    begin
        AddTrackL(X0, Y0, X1, Y0, L, Width);
        AddTrackL(X1, Y0, X1, Y1, L, Width);
        AddTrackL(X1, Y1, X0, Y1, L, Width);
        AddTrackL(X0, Y1, X0, Y0, L, Width);
        Exit;
    end;
    AddTrackL(X0 + R, Y0, X1 - R, Y0, L, Width);
    AddTrackL(X1, Y0 + R, X1, Y1 - R, L, Width);
    AddTrackL(X1 - R, Y1, X0 + R, Y1, L, Width);
    AddTrackL(X0, Y1 - R, X0, Y0 + R, L, Width);
    AddArcL(X0 + R, Y0 + R, R, 180, 270, L, Width);
    AddArcL(X1 - R, Y0 + R, R, 270, 0, L, Width);
    AddArcL(X1 - R, Y1 - R, R, 0, 90, L, Width);
    AddArcL(X0 + R, Y1 - R, R, 90, 180, L, Width);
end;

procedure PlaceHole(X, Y, Hole, Pad : TCoord);
var
    P : IPCB_Pad;
begin
    P := PCBServer.PCBObjectFactory(ePadObject, eNoDimension, eCreate_Default);
    P.X := X;
    P.Y := Y;
    P.HoleSize := Hole;
    P.TopXSize := Pad;
    P.TopYSize := Pad;
    P.BotXSize := Pad;
    P.BotYSize := Pad;
    P.Layer := eMultiLayer;
    try
        P.Name := 'MH';
    except
    end;
    Board.AddPCBObject(P);
end;

procedure PlaceMountingHoles(X0, Y0, X1, Y1, Margin, Hole, Pad : TCoord);
begin
    if FourHoles then
    begin
        PlaceHole(X0 + Margin, Y0 + Margin, Hole, Pad);
        PlaceHole(X1 - Margin, Y0 + Margin, Hole, Pad);
        PlaceHole(X1 - Margin, Y1 - Margin, Hole, Pad);
        PlaceHole(X0 + Margin, Y1 - Margin, Hole, Pad);
    end
    else
        PlaceHole(X0 + Margin, Y0 + Margin, Hole, Pad);
end;

procedure TrySetGrid(Grid : TCoord);
begin
    try
        Board.SnapGridSize := Grid;
    except
        try
            Board.SetState_SnapGridSize(Grid);
        except
        end;
    end;
end;

function FindNetGnd : IPCB_Net;
var
    Iter : IPCB_BoardIterator;
    N : IPCB_Net;
begin
    Result := nil;
    Iter := Board.BoardIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(eNetObject));
    Iter.AddFilter_LayerSet(AllLayers);
    Iter.AddFilter_Method(eProcessAll);
    N := Iter.FirstPCBObject;
    while N <> nil do
    begin
        if UpperCase(N.Name) = 'GND' then
        begin
            Result := N;
            Break;
        end;
        N := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

procedure AddGndPoly(ALayer : TLayer; X0, Y0, X1, Y1 : TCoord);
var
    Poly : IPCB_Polygon;
    Seg : TPolySegment;
    N : IPCB_Net;
begin
    Poly := PCBServer.PCBObjectFactory(ePolyObject, eNoDimension, eCreate_Default);
    Poly.Layer := ALayer;
    Poly.PolyHatchStyle := ePolySolid;
    N := FindNetGnd;
    if N <> nil then Poly.Net := N;
    { Зазоры полигона — из правил проектирования, не из скрипта. }
    Poly.PointCount := 4;
    Seg.Kind := ePolySegmentLine;
    Seg.vx := X0; Seg.vy := Y0; Poly.Segments[0] := Seg;
    Seg.vx := X1; Seg.vy := Y0; Poly.Segments[1] := Seg;
    Seg.vx := X1; Seg.vy := Y1; Poly.Segments[2] := Seg;
    Seg.vx := X0; Seg.vy := Y1; Poly.Segments[3] := Seg;
    Board.AddPCBObject(Poly);
    try
        Poly.Rebuild;
    except
    end;
end;

procedure AddMaskOpening(ALayer : TLayer; X0, Y0, X1, Y1 : TCoord);
var
    Fill : IPCB_Fill;
begin
    Fill := PCBServer.PCBObjectFactory(eFillObject, eNoDimension, eCreate_Default);
    Fill.X1Location := X0;
    Fill.Y1Location := Y0;
    Fill.X2Location := X1;
    Fill.Y2Location := Y1;
    Fill.Layer := ALayer;
    Board.AddPCBObject(Fill);
end;

procedure BuildBoard;
var
    X0, Y0, X1, Y1, R, Width : TCoord;
    OriginOff : TCoord;
    WS : IWorkspace;
begin
    if NewDoc then
    begin
        WS := GetWorkspace;
        if WS = nil then Exit;
        WS.DM_CreateNewDocument('PCB');
    end;
    if PCBServer = nil then
    begin
        ShowError('PCB-server is not available.');
        Exit;
    end;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = nil then
    begin
        ShowError('Нет PCB-документа для записи.');
        Exit;
    end;

    OriginOff := MMsToCoord(10);
    X0 := OriginOff;
    Y0 := OriginOff;
    X1 := OriginOff + MMsToCoord(Wmm);
    Y1 := OriginOff + MMsToCoord(Hmm);
    R := MMsToCoord(FilletMM);
    Width := MMsToCoord(0.2);

    PCBServer.PreProcess;
    try
        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        DrawRoundedKeepout(X0, Y0, X1, Y1, R, Width);

        ResetParameters;
        AddStringParameter('MODE', 'BOARDOUTLINE_FROM_SEL_PRIMS');
        RunProcess('PCB:PlaceBoardOutline');

        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        PlaceMountingHoles(X0, Y0, X1, Y1, MMsToCoord(MarginMM), MMsToCoord(HoleMM), MMsToCoord(PadMM));
        TrySetGrid(MMsToCoord(GridMM));

        if MakeGnd then
        begin
            AddGndPoly(eTopLayer, X0, Y0, X1, Y1);
            AddGndPoly(eBottomLayer, X0, Y0, X1, Y1);
            if CopperCount >= 4 then
            begin
                try
                    AddGndPoly(eMidLayer1, X0, Y0, X1, Y1);
                    AddGndPoly(eMidLayer2, X0, Y0, X1, Y1);
                except
                end;
            end;
            if CopperCount >= 6 then
            begin
                try
                    AddGndPoly(eMidLayer3, X0, Y0, X1, Y1);
                    AddGndPoly(eMidLayer4, X0, Y0, X1, Y1);
                except
                end;
            end;
        end;

        if MakeMask then
        begin
            AddMaskOpening(eTopSolder, X0, Y0, X1, Y1);
            AddMaskOpening(eBottomSolder, X0, Y0, X1, Y1);
        end;
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=All', 255, Client.CurrentView);
    ShowInfo('Плата создана: ' + FormatFloat('0.##', Wmm) + '×' + FormatFloat('0.##', Hmm) + ' мм.' + sLineBreak +
             'Контур на Keep-Out, board outline из примитивов.' + sLineBreak +
             'Стек слоёв 4/6 задайте в Layer Stack Manager, если слои ещё не добавлены.',
             'Мастер PCB');
end;

function ReadPositive(const S : String; var V : Double) : Boolean;
begin
    Result := False;
    try
        V := StrToFloat(S);
        Result := V > 0;
    except
    end;
end;

procedure TFormWizard.ButtonOKClick(Sender: TObject);
begin
    if not ReadPositive(EditW.Text, Wmm) then begin ShowError('Некорректная ширина.'); Exit; end;
    if not ReadPositive(EditH.Text, Hmm) then begin ShowError('Некорректная высота.'); Exit; end;
    try FilletMM := StrToFloat(EditFillet.Text); except ShowError('Некорректное скругление.'); Exit; end;
    if FilletMM < 0 then begin ShowError('Скругление не может быть < 0.'); Exit; end;
    if not ReadPositive(EditHole.Text, HoleMM) then begin ShowError('Некорректное отверстие.'); Exit; end;
    if not ReadPositive(EditPad.Text, PadMM) then begin ShowError('Некорректная площадка.'); Exit; end;
    if not ReadPositive(EditMargin.Text, MarginMM) then begin ShowError('Некорректный отступ.'); Exit; end;
    if not ReadPositive(EditGrid.Text, GridMM) then begin ShowError('Некорректная сетка.'); Exit; end;
    FourHoles := CheckFourHoles.Checked;
    MakeGnd := CheckGnd.Checked;
    MakeMask := CheckMask.Checked;
    NewDoc := CheckNewDoc.Checked;
    try
        CopperCount := StrToInt(ComboLayers.Text);
    except
        CopperCount := 4;
    end;
    if FilletMM * 2 >= Wmm then begin ShowError('Радиус скругления слишком большой для ширины.'); Exit; end;
    if FilletMM * 2 >= Hmm then begin ShowError('Радиус скругления слишком большой для высоты.'); Exit; end;
    FormWizard.Close;
    BuildBoard;
end;

procedure TFormWizard.ButtonCancelClick(Sender: TObject);
begin
    FormWizard.Close;
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


procedure TFormWizard.FormWizardShow(Sender: TObject);
begin
    try
        CS_TryLoadHelpImage('PcbWizard.bmp', 'PcbWizard.png');
    except
    end;
    EditGrid.Text := '0.1';
    ComboLayers.ItemIndex := 1; { 4 медных слоя }
    ComboLayers.Text := '4';
    CheckFourHoles.Checked := True;
end;

procedure Start;
begin
    FormWizard.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
