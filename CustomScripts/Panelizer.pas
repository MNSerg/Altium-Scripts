{..............................................................................}
{ Panelizer.pas                                                                 }
{ Массив плат 4×2 (столбцы×ряды) + перемычки mouse-bite БЕЗ отверстий          }
{ и общий внешний контур на механическом слое.                                  }
{..............................................................................}

const
    cOutlineWidthMM = 0.2;
    PanPiValue         = 3.141592653589793;

var
    SourceBoard : IPCB_Board;
    PanelBoard  : IPCB_Board;
    SourcePath  : String;
    Rows, Cols  : Integer;
    GapX, GapY, PanMargin, TabW, FilletR : Double;
    MechIndex   : Integer;
    BoardW, BoardH : Double;
    PanelW, PanelH : Double;
    MechLayer   : TLayer;
    LineW       : TCoord;

{ Run Script: choose procedure StartPanelizer (project compiles only this .pas). }
procedure StartPanelizer; forward;
procedure _StartPanelizer; forward;
procedure TFormPanel.ButtonBrowseClick(PanSender: TObject); forward;
procedure TFormPanel.ButtonOKClick(PanSender: TObject); forward;
procedure TFormPanel.ButtonCancelClick(PanSender: TObject); forward;
procedure TFormPanel.FormPanelShow(PanSender: TObject); forward;

function ParsePositive(const PanS : String; var PanV : Double) : Boolean;
begin
    Result := False;
    try
        PanV := StrToFloat(PanS);
        Result := PanV > 0;
    except
        Result := False;
    end;
end;

function ParsePositiveInt(const PanS : String; var PanV : Integer) : Boolean;
begin
    Result := False;
    try
        PanV := StrToInt(PanS);
        Result := PanV > 0;
    except
        Result := False;
    end;
end;

function AddTrack(ABoard : IPCB_Board; PanX1, PanY1, PanX2, PanY2 : TCoord; PanALayer : TLayer) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := PanX1;
    Result.Y1 := PanY1;
    Result.X2 := PanX2;
    Result.Y2 := PanY2;
    Result.Layer := PanALayer;
    Result.Width := LineW;
    ABoard.AddPCBObject(Result);
end;

function AddArc(ABoard : IPCB_Board; PanCX, PanCY, PanRadius : TCoord; PanSa, PanEa : Double; PanALayer : TLayer) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := PanCX;
    Result.YCenter := PanCY;
    Result.Radius := PanRadius;
    Result.StartAngle := PanSa;
    Result.EndAngle := PanEa;
    Result.Layer := PanALayer;
    Result.LineWidth := LineW;
    ABoard.AddPCBObject(Result);
end;

procedure DrawRoundedRect(ABoard : IPCB_Board; PanX0, PanY0, PanX1, PanY1, PanR : TCoord; PanALayer : TLayer);
begin
    if PanR <= 0 then
    begin
        AddTrack(ABoard, PanX0, PanY0, PanX1, PanY0, PanALayer);
        AddTrack(ABoard, PanX1, PanY0, PanX1, PanY1, PanALayer);
        AddTrack(ABoard, PanX1, PanY1, PanX0, PanY1, PanALayer);
        AddTrack(ABoard, PanX0, PanY1, PanX0, PanY0, PanALayer);
        Exit;
    end;
    AddTrack(ABoard, PanX0 + PanR, PanY0, PanX1 - PanR, PanY0, PanALayer);
    AddTrack(ABoard, PanX1, PanY0 + PanR, PanX1, PanY1 - PanR, PanALayer);
    AddTrack(ABoard, PanX1 - PanR, PanY1, PanX0 + PanR, PanY1, PanALayer);
    AddTrack(ABoard, PanX0, PanY1 - PanR, PanX0, PanY0 + PanR, PanALayer);
    AddArc(ABoard, PanX0 + PanR, PanY0 + PanR, PanR, 180, 270, PanALayer);
    AddArc(ABoard, PanX1 - PanR, PanY0 + PanR, PanR, 270, 0, PanALayer);
    AddArc(ABoard, PanX1 - PanR, PanY1 - PanR, PanR, 0, 90, PanALayer);
    AddArc(ABoard, PanX0 + PanR, PanY1 - PanR, PanR, 90, 180, PanALayer);
end;

{ Перемычка mouse-bite: узкая перемычка БЕЗ отверстий, со скруглением стыка. }
procedure DrawHTab(ABoard : IPCB_Board; GapLeft, GapRight, MidY, HalfTab, PanR : TCoord; PanALayer : TLayer);
var
    PanY1, PanY2 : TCoord;
begin
    PanY1 := MidY - HalfTab;
    PanY2 := MidY + HalfTab;
    { Две горизонтали перемычки и скругления у стыка с контуром платы. }
    AddTrack(ABoard, GapLeft, PanY1 + PanR, GapRight, PanY1 + PanR, PanALayer);
    AddTrack(ABoard, GapLeft, PanY2 - PanR, GapRight, PanY2 - PanR, PanALayer);
    if PanR > 0 then
    begin
        AddArc(ABoard, GapLeft, PanY1 + PanR, PanR, 90, 180, PanALayer);
        AddArc(ABoard, GapLeft, PanY2 - PanR, PanR, 180, 270, PanALayer);
        AddArc(ABoard, GapRight, PanY1 + PanR, PanR, 0, 90, PanALayer);
        AddArc(ABoard, GapRight, PanY2 - PanR, PanR, 270, 0, PanALayer);
    end
    else
    begin
        AddTrack(ABoard, GapLeft, PanY1, GapLeft, PanY2, PanALayer);
        AddTrack(ABoard, GapRight, PanY1, GapRight, PanY2, PanALayer);
    end;
end;

procedure DrawVTab(ABoard : IPCB_Board; GapBottom, GapTop, MidX, HalfTab, PanR : TCoord; PanALayer : TLayer);
var
    PanX1, PanX2 : TCoord;
begin
    PanX1 := MidX - HalfTab;
    PanX2 := MidX + HalfTab;
    AddTrack(ABoard, PanX1 + PanR, GapBottom, PanX1 + PanR, GapTop, PanALayer);
    AddTrack(ABoard, PanX2 - PanR, GapBottom, PanX2 - PanR, GapTop, PanALayer);
    if PanR > 0 then
    begin
        AddArc(ABoard, PanX1 + PanR, GapBottom, PanR, 180, 270, PanALayer);
        AddArc(ABoard, PanX2 - PanR, GapBottom, PanR, 270, 0, PanALayer);
        AddArc(ABoard, PanX1 + PanR, GapTop, PanR, 90, 180, PanALayer);
        AddArc(ABoard, PanX2 - PanR, GapTop, PanR, 0, 90, PanALayer);
    end;
end;

function BoardOriginX(Col : Integer) : TCoord;
begin
    Result := MMsToCoord(PanMargin + Col * (BoardW + GapX));
end;

function BoardOriginY(Row : Integer) : TCoord;
begin
    Result := MMsToCoord(PanMargin + Row * (BoardH + GapY));
end;

procedure DrawBoardRect(ABoard : IPCB_Board; Col, Row : Integer; PanALayer : TLayer);
var
    PanX0, PanY0, PanX1, PanY1 : TCoord;
begin
    PanX0 := BoardOriginX(Col);
    PanY0 := BoardOriginY(Row);
    PanX1 := PanX0 + MMsToCoord(BoardW);
    PanY1 := PanY0 + MMsToCoord(BoardH);
    DrawRoundedRect(ABoard, PanX0, PanY0, PanX1, PanY1, 0, PanALayer);
end;

procedure DrawAllTabs(ABoard : IPCB_Board; PanALayer : TLayer);
var
    r, c : Integer;
    PanX0, PanY0, PanX1, PanY1 : TCoord;
    GapL, GapR, GapB, GapT : TCoord;
    Mid : TCoord;
    HalfTab, PanR : TCoord;
begin
    HalfTab := MMsToCoord(TabW) div 2;
    PanR := MMsToCoord(FilletR);

    { Горизонтальные перемычки между столбцами. }
    for r := 0 to Rows - 1 do
        for c := 0 to Cols - 2 do
        begin
            PanX1 := BoardOriginX(c) + MMsToCoord(BoardW);
            GapL := PanX1;
            GapR := BoardOriginX(c + 1);
            PanY0 := BoardOriginY(r);
            Mid := PanY0 + MMsToCoord(BoardH / 2);
            DrawHTab(ABoard, GapL, GapR, Mid, HalfTab, PanR, PanALayer);
        end;

    { Вертикальные перемычки между рядами. }
    for c := 0 to Cols - 1 do
        for r := 0 to Rows - 2 do
        begin
            PanY1 := BoardOriginY(r) + MMsToCoord(BoardH);
            GapB := PanY1;
            GapT := BoardOriginY(r + 1);
            PanX0 := BoardOriginX(c);
            Mid := PanX0 + MMsToCoord(BoardW / 2);
            DrawVTab(ABoard, GapB, GapT, Mid, HalfTab, PanR, PanALayer);
        end;

    { Перемычки от крайних плат к рамке панели. }
    for c := 0 to Cols - 1 do
    begin
        PanX0 := BoardOriginX(c);
        Mid := PanX0 + MMsToCoord(BoardW / 2);
        { вниз к Y=0 }
        DrawVTab(ABoard, 0, BoardOriginY(0), Mid, HalfTab, PanR, PanALayer);
        { вверх к PanelH }
        DrawVTab(ABoard, BoardOriginY(Rows - 1) + MMsToCoord(BoardH), MMsToCoord(PanelH), Mid, HalfTab, PanR, PanALayer);
    end;
    for r := 0 to Rows - 1 do
    begin
        PanY0 := BoardOriginY(r);
        Mid := PanY0 + MMsToCoord(BoardH / 2);
        DrawHTab(ABoard, 0, BoardOriginX(0), Mid, HalfTab, PanR, PanALayer);
        DrawHTab(ABoard, BoardOriginX(Cols - 1) + MMsToCoord(BoardW), MMsToCoord(PanelW), Mid, HalfTab, PanR, PanALayer);
    end;
end;

{ Общий внешний контур вокруг ВСЕХ плат с учётом перемычек к рамке. }
procedure DrawCommonOuterContour(ABoard : IPCB_Board; PanALayer : TLayer);
var
    PanR : TCoord;
begin
    PanR := MMsToCoord(FilletR);
    DrawRoundedRect(ABoard, 0, 0, MMsToCoord(PanelW), MMsToCoord(PanelH), PanR, PanALayer);
end;

procedure PlaceEmbeddedArray(ABoard : IPCB_Board);
var
    Emb : IPCB_EmbeddedBoard;
    PanX0, PanY0 : TCoord;
begin
    Emb := PCBServer.PCBObjectFactory(eEmbeddedBoardObject, eNoDimension, eCreate_Default);
    Emb.DocumentPath := SourcePath;
    Emb.RowCount := Rows;
    Emb.ColCount := Cols;
    Emb.ColSpacing := MMsToCoord(BoardW + GapX);
    Emb.RowSpacing := MMsToCoord(BoardH + GapY);
    PanX0 := BoardOriginX(0);
    PanY0 := BoardOriginY(0);
    Emb.XLocation := PanX0;
    Emb.YLocation := PanY0;
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
    PanIter : IPCB_BoardIterator;
    PanPrim : IPCB_Primitive;
begin
    { Выделить рамку панели и сделать из неё board outline. }
    PanIter := ABoard.BoardIterator_Create;
    PanIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    PanIter.AddFilter_LayerSet(MkSet(MechLayer));
    PanIter.AddFilter_Method(eProcessAll);
    PanPrim := PanIter.FirstPCBObject;
    while PanPrim <> nil do
    begin
        PanPrim.Selected := False;
        PanPrim := PanIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PanIter);

    ResetParameters;
    AddStringParameter('Scope', 'All');
    RunProcess('PCB:DeSelect');
end;

procedure BuildPanel;
var
    PanWS : IWorkspace;
    PanRect : TCoordRect;
begin
    PanRect := SourceBoard.BoardOutline.BoundingRectangle;
    BoardW := CoordToMMs(PanRect.Right - PanRect.Left);
    BoardH := CoordToMMs(PanRect.Top - PanRect.Bottom);
    if (BoardW <= 0) or (BoardH <= 0) then
    begin
        ShowError('Не удалось определить размер исходной платы.');
        Exit;
    end;

    PanelW := PanMargin * 2 + Cols * BoardW + (Cols - 1) * GapX;
    PanelH := PanMargin * 2 + Rows * BoardH + (Rows - 1) * GapY;
    LineW := MMsToCoord(cOutlineWidthMM);
    MechLayer := LayerUtils.MechanicalLayer(MechIndex);

    PanWS := GetWorkspace;
    if PanWS = nil then Exit;
    PanWS.DM_CreateNewDocument('PCB');
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

procedure TFormPanel.ButtonBrowseClick(PanSender: TObject);
var
    PanDlg : TOpenDialog;
    PanWS : IWorkspace;
begin
    PanDlg := TOpenDialog.Create(nil);
    try
        PanDlg.Title := 'Выберите исходную плату';
        PanDlg.Filter := 'PCB (*.PcbDoc)|*.PcbDoc';
        if PanDlg.Execute then
        begin
            SourcePath := PanDlg.FileName;
            EditFile.Text := SourcePath;
            PanWS := GetWorkspace;
            if PanWS <> nil then
                PanWS.DM_OpenProject(SourcePath, False);
            SourceBoard := PCBServer.GetPCBBoardByPath(SourcePath);
            if SourceBoard = nil then
                SourceBoard := PCBServer.GetCurrentPCBBoard;
            if SourceBoard = nil then
                ShowWarning('Не удалось открыть выбранный PCB.');
        end;
    finally
        PanDlg.Free;
    end;
end;

procedure TFormPanel.ButtonOKClick(PanSender: TObject);
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
    if not ParsePositive(EditMargin.Text, PanMargin) then begin ShowError('Некорректное поле.'); Exit; end;
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

procedure TFormPanel.ButtonCancelClick(PanSender: TObject);
begin
    FormPanel.Close;
end;

{ ScriptBoot.inc — safe help-image load. Never call ParamStr (AV in Altium). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function PanCS_ScriptFolder : String;
var
    PanWS  : IWorkspace;
    PanPrj : IProject;
    Pani   : Integer;
    PanP   : String;
begin
    Result := '';
    try
        PanWS := GetWorkspace;
        if PanWS = nil then Exit;
        PanPrj := PanWS.DM_FocusedProject;
        if PanPrj <> nil then
        begin
            PanP := ExtractFilePath(PanPrj.DM_ProjectFullPath);
            if PanP <> '' then
            begin
                Result := PanP;
                Exit;
            end;
        end;
        for Pani := 0 to PanWS.DM_ProjectCount - 1 do
        begin
            PanPrj := PanWS.DM_Projects(Pani);
            if PanPrj <> nil then
            begin
                PanP := PanPrj.DM_ProjectFullPath;
                if Pos('CustomScripts', PanP) > 0 then
                begin
                    Result := ExtractFilePath(PanP);
                    Exit;
                end;
            end;
        end;
    except
        Result := '';
    end;
end;

function PanCS_FindImageFile(const PanFileName : String) : String;
var
    PanDir, PanP : String;
begin
    Result := '';
    PanDir := PanCS_ScriptFolder;
    if PanDir <> '' then
    begin
        PanP := PanDir + 'images\' + PanFileName;
        if FileExists(PanP) then
        begin
            Result := PanP;
            Exit;
        end;
        PanP := PanDir + PanFileName;
        if FileExists(PanP) then
        begin
            Result := PanP;
            Exit;
        end;
    end;
    PanP := 'images\' + PanFileName;
    if FileExists(PanP) then Result := PanP;
end;

procedure PanCS_TryLoadHelpImage(const PanBmpName : String; const PanPngName : String);
var
    PanP : String;
begin
    try
        PanP := PanCS_FindImageFile(PanBmpName);
        if PanP = '' then
            PanP := PanCS_FindImageFile(PanPngName);
        if (PanP <> '') and FileExists(PanP) then
        begin
            ImageHelp.Picture.LoadFromFile(PanP);
            LabelImageHint.Caption := 'Replace image: images\' + PanBmpName;
        end
        else
            LabelImageHint.Caption := 'No image. Put ' + PanBmpName + ' in images\ next to the scripts.';
    except
        try
            LabelImageHint.Caption := 'Image not loaded.';
        except
        end;
    end;
end;


procedure TFormPanel.FormPanelShow(PanSender: TObject);
begin
    try
        PanCS_TryLoadHelpImage('Panelizer.bmp', 'Panelizer.png');
    except
    end;
    EditCols.Text := '4';
    EditRows.Text := '2';
    EditGapX.Text := '2';
    EditGapY.Text := '2';
    EditMargin.Text := '10';
    EditTab.Text := '4';
    EditFillet.Text := '1';
    try
        if PCBServer <> nil then
            SourceBoard := PCBServer.GetCurrentPCBBoard
        else
            SourceBoard := nil;
        if SourceBoard <> nil then
        begin
            SourcePath := SourceBoard.FileName;
            EditFile.Text := SourcePath;
        end;
    except
    end;
end;

procedure StartPanelizer;
begin
    FormPanel.ShowModal;
end;

procedure _StartPanelizer;
begin
    StartPanelizer;
end;
