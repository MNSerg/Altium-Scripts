{..............................................................................}
{ Panelizer.pas                                                                 }
{ Массив плат (Embedded Board Array) + контур заготовки + перемычки под фрезу  }
{ и общий внешний контур на механическом слое.                                  }
{..............................................................................}

const
    cOutlineWidthMM = 0.2;
    PiValue         = 3.141592653589793;

var
    SourceBoard : IPCB_Board;
    PanelBoard  : IPCB_Board;
    SourcePath  : String;
    Rows, Cols  : Integer;
    GapX, GapY, Margin, TabW, FilletR : Double;
    MechIndex   : Integer;
    BoardW, BoardH : Double;
    PanelW, PanelH : Double;
    MechLayer   : TLayer;
    LineW       : TCoord;

procedure Start; forward;
procedure _Start; forward;
procedure TFormPanel.ButtonBrowseClick(Sender: TObject); forward;
procedure TFormPanel.ButtonOKClick(Sender: TObject); forward;
procedure TFormPanel.ButtonCancelClick(Sender: TObject); forward;

function ParsePositive(const S : String; var V : Double) : Boolean;
begin
    Result := False;
    try
        V := StrToFloat(S);
        Result := V > 0;
    except
        Result := False;
    end;
end;

function ParsePositiveInt(const S : String; var V : Integer) : Boolean;
begin
    Result := False;
    try
        V := StrToInt(S);
        Result := V > 0;
    except
        Result := False;
    end;
end;

function AddTrack(ABoard : IPCB_Board; X1, Y1, X2, Y2 : TCoord; ALayer : TLayer) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := X1;
    Result.Y1 := Y1;
    Result.X2 := X2;
    Result.Y2 := Y2;
    Result.Layer := ALayer;
    Result.Width := LineW;
    ABoard.AddPCBObject(Result);
end;

function AddArc(ABoard : IPCB_Board; CX, CY, Radius : TCoord; Sa, Ea : Double; ALayer : TLayer) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := CX;
    Result.YCenter := CY;
    Result.Radius := Radius;
    Result.StartAngle := Sa;
    Result.EndAngle := Ea;
    Result.Layer := ALayer;
    Result.LineWidth := LineW;
    ABoard.AddPCBObject(Result);
end;

procedure DrawRoundedRect(ABoard : IPCB_Board; X0, Y0, X1, Y1, R : TCoord; ALayer : TLayer);
begin
    if R <= 0 then
    begin
        AddTrack(ABoard, X0, Y0, X1, Y0, ALayer);
        AddTrack(ABoard, X1, Y0, X1, Y1, ALayer);
        AddTrack(ABoard, X1, Y1, X0, Y1, ALayer);
        AddTrack(ABoard, X0, Y1, X0, Y0, ALayer);
        Exit;
    end;
    AddTrack(ABoard, X0 + R, Y0, X1 - R, Y0, ALayer);
    AddTrack(ABoard, X1, Y0 + R, X1, Y1 - R, ALayer);
    AddTrack(ABoard, X1 - R, Y1, X0 + R, Y1, ALayer);
    AddTrack(ABoard, X0, Y1 - R, X0, Y0 + R, ALayer);
    AddArc(ABoard, X0 + R, Y0 + R, R, 180, 270, ALayer);
    AddArc(ABoard, X1 - R, Y0 + R, R, 270, 0, ALayer);
    AddArc(ABoard, X1 - R, Y1 - R, R, 0, 90, ALayer);
    AddArc(ABoard, X0 + R, Y1 - R, R, 90, 180, ALayer);
end;

{ Перемычка между двумя горизонтально соседними платами (в зазоре). }
procedure DrawHTab(ABoard : IPCB_Board; GapLeft, GapRight, MidY, HalfTab, R : TCoord; ALayer : TLayer);
var
    Y1, Y2 : TCoord;
begin
    Y1 := MidY - HalfTab;
    Y2 := MidY + HalfTab;
    { Две горизонтали перемычки и скругления у стыка с контуром платы. }
    AddTrack(ABoard, GapLeft, Y1 + R, GapRight, Y1 + R, ALayer);
    AddTrack(ABoard, GapLeft, Y2 - R, GapRight, Y2 - R, ALayer);
    if R > 0 then
    begin
        AddArc(ABoard, GapLeft, Y1 + R, R, 90, 180, ALayer);
        AddArc(ABoard, GapLeft, Y2 - R, R, 180, 270, ALayer);
        AddArc(ABoard, GapRight, Y1 + R, R, 0, 90, ALayer);
        AddArc(ABoard, GapRight, Y2 - R, R, 270, 0, ALayer);
    end
    else
    begin
        AddTrack(ABoard, GapLeft, Y1, GapLeft, Y2, ALayer);
        AddTrack(ABoard, GapRight, Y1, GapRight, Y2, ALayer);
    end;
end;

procedure DrawVTab(ABoard : IPCB_Board; GapBottom, GapTop, MidX, HalfTab, R : TCoord; ALayer : TLayer);
var
    X1, X2 : TCoord;
begin
    X1 := MidX - HalfTab;
    X2 := MidX + HalfTab;
    AddTrack(ABoard, X1 + R, GapBottom, X1 + R, GapTop, ALayer);
    AddTrack(ABoard, X2 - R, GapBottom, X2 - R, GapTop, ALayer);
    if R > 0 then
    begin
        AddArc(ABoard, X1 + R, GapBottom, R, 180, 270, ALayer);
        AddArc(ABoard, X2 - R, GapBottom, R, 270, 0, ALayer);
        AddArc(ABoard, X1 + R, GapTop, R, 90, 180, ALayer);
        AddArc(ABoard, X2 - R, GapTop, R, 0, 90, ALayer);
    end;
end;

function BoardOriginX(Col : Integer) : TCoord;
begin
    Result := MMsToCoord(Margin + Col * (BoardW + GapX));
end;

function BoardOriginY(Row : Integer) : TCoord;
begin
    Result := MMsToCoord(Margin + Row * (BoardH + GapY));
end;

procedure DrawBoardRect(ABoard : IPCB_Board; Col, Row : Integer; ALayer : TLayer);
var
    X0, Y0, X1, Y1 : TCoord;
begin
    X0 := BoardOriginX(Col);
    Y0 := BoardOriginY(Row);
    X1 := X0 + MMsToCoord(BoardW);
    Y1 := Y0 + MMsToCoord(BoardH);
    DrawRoundedRect(ABoard, X0, Y0, X1, Y1, 0, ALayer);
end;

procedure DrawAllTabs(ABoard : IPCB_Board; ALayer : TLayer);
var
    r, c : Integer;
    X0, Y0, X1, Y1 : TCoord;
    GapL, GapR, GapB, GapT : TCoord;
    Mid : TCoord;
    HalfTab, R : TCoord;
begin
    HalfTab := MMsToCoord(TabW) div 2;
    R := MMsToCoord(FilletR);

    { Горизонтальные перемычки между столбцами. }
    for r := 0 to Rows - 1 do
        for c := 0 to Cols - 2 do
        begin
            X1 := BoardOriginX(c) + MMsToCoord(BoardW);
            GapL := X1;
            GapR := BoardOriginX(c + 1);
            Y0 := BoardOriginY(r);
            Mid := Y0 + MMsToCoord(BoardH / 2);
            DrawHTab(ABoard, GapL, GapR, Mid, HalfTab, R, ALayer);
        end;

    { Вертикальные перемычки между рядами. }
    for c := 0 to Cols - 1 do
        for r := 0 to Rows - 2 do
        begin
            Y1 := BoardOriginY(r) + MMsToCoord(BoardH);
            GapB := Y1;
            GapT := BoardOriginY(r + 1);
            X0 := BoardOriginX(c);
            Mid := X0 + MMsToCoord(BoardW / 2);
            DrawVTab(ABoard, GapB, GapT, Mid, HalfTab, R, ALayer);
        end;

    { Перемычки от крайних плат к рамке панели. }
    for c := 0 to Cols - 1 do
    begin
        X0 := BoardOriginX(c);
        Mid := X0 + MMsToCoord(BoardW / 2);
        { вниз к Y=0 }
        DrawVTab(ABoard, 0, BoardOriginY(0), Mid, HalfTab, R, ALayer);
        { вверх к PanelH }
        DrawVTab(ABoard, BoardOriginY(Rows - 1) + MMsToCoord(BoardH), MMsToCoord(PanelH), Mid, HalfTab, R, ALayer);
    end;
    for r := 0 to Rows - 1 do
    begin
        Y0 := BoardOriginY(r);
        Mid := Y0 + MMsToCoord(BoardH / 2);
        DrawHTab(ABoard, 0, BoardOriginX(0), Mid, HalfTab, R, ALayer);
        DrawHTab(ABoard, BoardOriginX(Cols - 1) + MMsToCoord(BoardW), MMsToCoord(PanelW), Mid, HalfTab, R, ALayer);
    end;
end;

{ Общий внешний контур вокруг ВСЕХ плат с учётом перемычек к рамке. }
procedure DrawCommonOuterContour(ABoard : IPCB_Board; ALayer : TLayer);
var
    R : TCoord;
begin
    R := MMsToCoord(FilletR);
    DrawRoundedRect(ABoard, 0, 0, MMsToCoord(PanelW), MMsToCoord(PanelH), R, ALayer);
end;

procedure PlaceEmbeddedArray(ABoard : IPCB_Board);
var
    Emb : IPCB_EmbeddedBoard;
    X0, Y0 : TCoord;
begin
    Emb := PCBServer.PCBObjectFactory(eEmbeddedBoardObject, eNoDimension, eCreate_Default);
    Emb.DocumentPath := SourcePath;
    Emb.RowCount := Rows;
    Emb.ColCount := Cols;
    Emb.ColSpacing := MMsToCoord(BoardW + GapX);
    Emb.RowSpacing := MMsToCoord(BoardH + GapY);
    X0 := BoardOriginX(0);
    Y0 := BoardOriginY(0);
    Emb.XLocation := X0;
    Emb.YLocation := Y0;
    ABoard.AddPCBObject(Emb);
end;

procedure CopySourceOutlineAsMech(ABoard : IPCB_Board);
var
    c, r : Integer;
begin
    for r := 0 to Rows - 1 do
        for c := 0 to Cols - 1 do
            DrawBoardRect(ABoard, c, r, MechLayer);
end;

procedure ApplyPanelBoardOutline(ABoard : IPCB_Board);
var
    Iter : IPCB_BoardIterator;
    Prim : IPCB_Primitive;
begin
    { Выделить рамку панели и сделать из неё board outline. }
    Iter := ABoard.BoardIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    Iter.AddFilter_LayerSet(MkSet(MechLayer));
    Iter.AddFilter_Method(eProcessAll);
    Prim := Iter.FirstPCBObject;
    while Prim <> nil do
    begin
        Prim.Selected := False;
        Prim := Iter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(Iter);

    ResetParameters;
    AddStringParameter('Scope', 'All');
    RunProcess('PCB:DeSelect');
end;

procedure BuildPanel;
var
    WS : IWorkspace;
    Rect : TCoordRect;
begin
    Rect := SourceBoard.BoardOutline.BoundingRectangle;
    BoardW := CoordToMMs(Rect.Right - Rect.Left);
    BoardH := CoordToMMs(Rect.Top - Rect.Bottom);
    if (BoardW <= 0) or (BoardH <= 0) then
    begin
        ShowError('Не удалось определить размер исходной платы.');
        Exit;
    end;

    PanelW := Margin * 2 + Cols * BoardW + (Cols - 1) * GapX;
    PanelH := Margin * 2 + Rows * BoardH + (Rows - 1) * GapY;
    LineW := MMsToCoord(cOutlineWidthMM);
    MechLayer := LayerUtils.MechanicalLayer(MechIndex);

    WS := GetWorkspace;
    if WS = nil then Exit;
    WS.DM_CreateNewDocument('PCB');
    PanelBoard := PCBServer.GetCurrentPCBBoard;
    if PanelBoard = nil then
    begin
        ShowError('Не удалось создать новый PCB-документ.');
        Exit;
    end;

    PCBServer.PreProcess;
    try
        PlaceEmbeddedArray(PanelBoard);
        DrawCommonOuterContour(PanelBoard, MechLayer);
        CopySourceOutlineAsMech(PanelBoard);
        DrawAllTabs(PanelBoard, MechLayer);

        PanelBoard.LayerIsDisplayed[MechLayer] := True;

        { Board outline панели из внешнего контура. }
        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        { Выделить только внешнюю рамку сложно; задаём outline из примитивов на mech, если пользователь подтвердит.
          Делаем outline из четырёх сторон панели через PlaceBoardOutline. }
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=All', 255, Client.CurrentView);
    ShowInfo('Панель создана: ' + IntToStr(Cols) + '×' + IntToStr(Rows) + sLineBreak +
             'Размер заготовки: ' + FormatFloat('0.##', PanelW) + ' × ' + FormatFloat('0.##', PanelH) + ' мм' + sLineBreak +
             'Общий контур и перемычки — слой ' + Layer2String(MechLayer) + '.' + sLineBreak + sLineBreak +
             'Проверьте Embedded Board Array и при необходимости задайте Board Outline из рамки.',
             'Панелизация');
end;

procedure TFormPanel.ButtonBrowseClick(Sender: TObject);
var
    Dlg : TOpenDialog;
    WS : IWorkspace;
begin
    Dlg := TOpenDialog.Create(nil);
    try
        Dlg.Title := 'Выберите исходную плату';
        Dlg.Filter := 'PCB (*.PcbDoc)|*.PcbDoc';
        if Dlg.Execute then
        begin
            SourcePath := Dlg.FileName;
            EditFile.Text := SourcePath;
            WS := GetWorkspace;
            if WS <> nil then
                WS.DM_OpenProject(SourcePath, False);
            SourceBoard := PCBServer.GetPCBBoardByPath(SourcePath);
            if SourceBoard = nil then
                SourceBoard := PCBServer.GetCurrentPCBBoard;
            if SourceBoard = nil then
                ShowWarning('Не удалось открыть выбранный PCB.');
        end;
    finally
        Dlg.Free;
    end;
end;

procedure TFormPanel.ButtonOKClick(Sender: TObject);
begin
    SourcePath := EditFile.Text;
    if (SourcePath = '') or (not FileExists(SourcePath)) then
    begin
        ShowError('Укажите существующий файл .PcbDoc.');
        Exit;
    end;
    if not ParsePositiveInt(EditRows.Text, Rows) then
    begin
        ShowError('Число рядов должно быть целым > 0.');
        Exit;
    end;
    if not ParsePositiveInt(EditCols.Text, Cols) then
    begin
        ShowError('Число столбцов должно быть целым > 0.');
        Exit;
    end;
    if not ParsePositive(EditGapX.Text, GapX) then begin ShowError('Некорректный зазор X.'); Exit; end;
    if not ParsePositive(EditGapY.Text, GapY) then begin ShowError('Некорректный зазор Y.'); Exit; end;
    if not ParsePositive(EditMargin.Text, Margin) then begin ShowError('Некорректное поле.'); Exit; end;
    if not ParsePositive(EditTab.Text, TabW) then begin ShowError('Некорректная ширина перемычки.'); Exit; end;
    if not ParsePositive(EditFillet.Text, FilletR) then begin ShowError('Некорректный радиус фрезы.'); Exit; end;
    if not ParsePositiveInt(EditMech.Text, MechIndex) then
    begin
        ShowError('Номер механического слоя: целое 1..32.');
        Exit;
    end;
    if (MechIndex < 1) or (MechIndex > 32) then
    begin
        ShowError('Номер механического слоя: 1..32.');
        Exit;
    end;

    if SourceBoard = nil then
        SourceBoard := PCBServer.GetPCBBoardByPath(SourcePath);
    if SourceBoard = nil then
    begin
        ShowError('Не удалось загрузить исходную плату.');
        Exit;
    end;

    FormPanel.Close;
    BuildPanel;
end;

procedure TFormPanel.ButtonCancelClick(Sender: TObject);
begin
    FormPanel.Close;
end;

procedure Start;
begin
    if PCBServer = nil then
    begin
        ShowError('PCB-сервер недоступен.');
        Exit;
    end;
    SourceBoard := PCBServer.GetCurrentPCBBoard;
    if SourceBoard <> nil then
    begin
        SourcePath := SourceBoard.FileName;
        EditFile.Text := SourcePath;
    end
    else
        EditFile.Text := '';
    FormPanel.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
