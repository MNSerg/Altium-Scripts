{..............................................................................}
{ Panelizer.pas                                                                 }
{ Массив плат 4×2 (столбцы×ряды): путь фрезы вокруг плат с разрывами           }
{ под перемычки (без отверстий) и внешняя рамка = bbox массива + поле.         }
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
function BoardOriginX(Col : Integer) : TCoord; forward;
function BoardOriginY(Row : Integer) : TCoord; forward;

function PanParseFloat(const PanS : String; var PanV : Double) : Boolean;
var
    PanT : String;
    Pani : Integer;
    PanCh : Char;
    PanSign : Double;
    PanScale : Double;
    PanSeenDigit : Boolean;
    PanFrac : Boolean;
begin
    Result := False;
    PanV := 0;
    PanT := PanS;
    while (Length(PanT) > 0) and (PanT[1] = ' ') do
        PanT := Copy(PanT, 2, Length(PanT));
    while (Length(PanT) > 0) and (PanT[Length(PanT)] = ' ') do
        PanT := Copy(PanT, 1, Length(PanT) - 1);
    if PanT = '' then Exit;
    PanSign := 1;
    Pani := 1;
    if PanT[1] = '-' then
    begin
        PanSign := -1;
        Pani := 2;
    end
    else if PanT[1] = '+' then
        Pani := 2;
    PanSeenDigit := False;
    PanFrac := False;
    PanScale := 1;
    while Pani <= Length(PanT) do
    begin
        PanCh := PanT[Pani];
        if (PanCh = '.') or (PanCh = ',') then
        begin
            if PanFrac then Exit;
            PanFrac := True;
        end
        else if (PanCh >= '0') and (PanCh <= '9') then
        begin
            PanSeenDigit := True;
            if not PanFrac then
                PanV := PanV * 10 + (Ord(PanCh) - Ord('0'))
            else
            begin
                PanScale := PanScale * 10;
                PanV := PanV + (Ord(PanCh) - Ord('0')) / PanScale;
            end;
        end
        else
            Exit;
        Pani := Pani + 1;
    end;
    if not PanSeenDigit then Exit;
    PanV := PanV * PanSign;
    Result := True;
end;

function ParsePositive(const PanS : String; var PanV : Double) : Boolean;
begin
    Result := PanParseFloat(PanS, PanV) and (PanV > 0);
end;

function ParseNonNeg(const PanS : String; var PanV : Double) : Boolean;
begin
    Result := PanParseFloat(PanS, PanV) and (PanV >= 0);
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

{ Вырез в заготовке: кольцо ширины = диаметр фрезы (2*R), разрывы = перемычки. }
procedure DrawMillAroundBoard(ABoard : IPCB_Board; Col, Row : Integer; PanALayer : TLayer);
var
    L, B, Rgt, Tp, D, HalfTab, Mx0, Mx1, My0, My1 : TCoord;
begin
    L := BoardOriginX(Col);
    B := BoardOriginY(Row);
    Rgt := L + MMsToCoord(BoardW);
    Tp := B + MMsToCoord(BoardH);
    D := MMsToCoord(FilletR + FilletR);
    if D < 1 then Exit;
    HalfTab := MMsToCoord(TabW) div 2;
    if HalfTab < 1 then HalfTab := 1;
    Mx0 := (L + Rgt) div 2 - HalfTab;
    Mx1 := (L + Rgt) div 2 + HalfTab;
    My0 := (B + Tp) div 2 - HalfTab;
    My1 := (B + Tp) div 2 + HalfTab;
    if Mx0 < L + 1 then Mx0 := L + 1;
    if Mx1 > Rgt - 1 then Mx1 := Rgt - 1;
    if My0 < B + 1 then My0 := B + 1;
    if My1 > Tp - 1 then My1 := Tp - 1;

    { SW: внутренний край = контур платы, внешний = смещение на диаметр, дуга снаружи. }
    AddTrack(ABoard, L, B, Mx0, B, PanALayer);
    AddTrack(ABoard, Mx0, B, Mx0, B - D, PanALayer);
    AddTrack(ABoard, Mx0, B - D, L, B - D, PanALayer);
    AddArc(ABoard, L, B, D, 180, 270, PanALayer);
    AddTrack(ABoard, L - D, B, L - D, My0, PanALayer);
    AddTrack(ABoard, L - D, My0, L, My0, PanALayer);
    AddTrack(ABoard, L, My0, L, B, PanALayer);

    { SE }
    AddTrack(ABoard, Mx1, B, Rgt, B, PanALayer);
    AddTrack(ABoard, Mx1, B, Mx1, B - D, PanALayer);
    AddTrack(ABoard, Mx1, B - D, Rgt, B - D, PanALayer);
    AddArc(ABoard, Rgt, B, D, 270, 0, PanALayer);
    AddTrack(ABoard, Rgt + D, B, Rgt + D, My0, PanALayer);
    AddTrack(ABoard, Rgt + D, My0, Rgt, My0, PanALayer);
    AddTrack(ABoard, Rgt, My0, Rgt, B, PanALayer);

    { NE }
    AddTrack(ABoard, Mx1, Tp, Rgt, Tp, PanALayer);
    AddTrack(ABoard, Mx1, Tp, Mx1, Tp + D, PanALayer);
    AddTrack(ABoard, Mx1, Tp + D, Rgt, Tp + D, PanALayer);
    AddArc(ABoard, Rgt, Tp, D, 0, 90, PanALayer);
    AddTrack(ABoard, Rgt + D, Tp, Rgt + D, My1, PanALayer);
    AddTrack(ABoard, Rgt + D, My1, Rgt, My1, PanALayer);
    AddTrack(ABoard, Rgt, My1, Rgt, Tp, PanALayer);

    { NW }
    AddTrack(ABoard, L, Tp, Mx0, Tp, PanALayer);
    AddTrack(ABoard, Mx0, Tp, Mx0, Tp + D, PanALayer);
    AddTrack(ABoard, Mx0, Tp + D, L, Tp + D, PanALayer);
    AddArc(ABoard, L, Tp, D, 90, 180, PanALayer);
    AddTrack(ABoard, L - D, Tp, L - D, My1, PanALayer);
    AddTrack(ABoard, L - D, My1, L, My1, PanALayer);
    AddTrack(ABoard, L, My1, L, Tp, PanALayer);
end;

procedure DrawAllMillPaths(ABoard : IPCB_Board; PanALayer : TLayer);
var
    r, c : Integer;
begin
    for r := 0 to Rows - 1 do
        for c := 0 to Cols - 1 do
            DrawMillAroundBoard(ABoard, c, r, PanALayer);
end;

{ Рамка: bbox массива плат + поле (PanMargin) с каждой стороны. }
procedure DrawCommonOuterContour(ABoard : IPCB_Board; PanALayer : TLayer);
var
    X0, Y0, X1, Y1 : TCoord;
begin
    X0 := BoardOriginX(0) - MMsToCoord(PanMargin);
    Y0 := BoardOriginY(0) - MMsToCoord(PanMargin);
    X1 := BoardOriginX(Cols - 1) + MMsToCoord(BoardW) + MMsToCoord(PanMargin);
    Y1 := BoardOriginY(Rows - 1) + MMsToCoord(BoardH) + MMsToCoord(PanMargin);
    AddTrack(ABoard, X0, Y0, X1, Y0, PanALayer);
    AddTrack(ABoard, X1, Y0, X1, Y1, PanALayer);
    AddTrack(ABoard, X1, Y1, X0, Y1, PanALayer);
    AddTrack(ABoard, X0, Y1, X0, Y0, PanALayer);
end;

function BoardOriginX(Col : Integer) : TCoord;
begin
    Result := MMsToCoord(PanMargin + Col * (BoardW + GapX));
end;

function BoardOriginY(Row : Integer) : TCoord;
begin
    Result := MMsToCoord(PanMargin + Row * (BoardH + GapY));
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

procedure PanShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
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
        PanShowBox(LabelErrSize.Caption, 16);
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
        PanShowBox(LabelErrNew.Caption, 16);
        Exit;
    end;

    PCBServer.PreProcess;
    try
        PlaceEmbeddedArray(PanelBoard);
        DrawAllMillPaths(PanelBoard, MechLayer);
        DrawCommonOuterContour(PanelBoard, MechLayer);

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
    PanShowBox(LabelInfoDone.Caption + IntToStr(Cols) + 'x' + IntToStr(Rows) + sLineBreak +
               LabelInfoSize.Caption + FormatFloat('0.##', PanelW) + ' x ' + FormatFloat('0.##', PanelH) + sLineBreak +
               LabelInfoLayer.Caption + Layer2String(MechLayer), 64);
end;

procedure TFormPanel.ButtonBrowseClick(PanSender: TObject);
var
    PanDlg : TOpenDialog;
    PanWS : IWorkspace;
begin
    PanDlg := TOpenDialog.Create(nil);
    try
        PanDlg.Title := LabelDlgTitle.Caption;
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
                PanShowBox(LabelWarnOpen.Caption, 48);
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
        PanShowBox(LabelErrFile.Caption, 16);
        Exit;
    end;
    if not ParsePositiveInt(EditRows.Text, Rows) then
    begin
        PanShowBox(LabelErrRows.Caption, 16);
        Exit;
    end;
    if not ParsePositiveInt(EditCols.Text, Cols) then
    begin
        PanShowBox(LabelErrCols.Caption, 16);
        Exit;
    end;
    if not ParsePositive(EditGapX.Text, GapX) then begin PanShowBox(LabelErrGapX.Caption, 16); Exit; end;
    if not ParsePositive(EditGapY.Text, GapY) then begin PanShowBox(LabelErrGapY.Caption, 16); Exit; end;
    if not ParsePositive(EditMargin.Text, PanMargin) then begin PanShowBox(LabelErrMargin.Caption, 16); Exit; end;
    if not ParsePositive(EditTab.Text, TabW) then begin PanShowBox(LabelErrTab.Caption, 16); Exit; end;
    if not ParseNonNeg(EditFillet.Text, FilletR) then begin PanShowBox(LabelErrMill.Caption, 16); Exit; end;
    if not ParsePositiveInt(EditMech.Text, MechIndex) then
    begin
        PanShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;
    if (MechIndex < 1) or (MechIndex > 32) then
    begin
        PanShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;

    if SourceBoard = nil then
        SourceBoard := PCBServer.GetPCBBoardByPath(SourcePath);
    if SourceBoard = nil then
    begin
        PanShowBox(LabelErrLoad.Caption, 16);
        Exit;
    end;

    FormPanel.Close;
    BuildPanel;
end;

procedure TFormPanel.ButtonCancelClick(PanSender: TObject);
begin
    FormPanel.Close;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function PanCS_ScriptFolder : String;
var
    PanWS  : IWorkspace;
    PanPrj : IProject;
    Pani   : Integer;
    PanP, PanName : String;
begin
    Result := '';
    try
        PanWS := GetWorkspace;
        if PanWS = nil then Exit;
        for Pani := 0 to PanWS.DM_ProjectCount - 1 do
        begin
            PanPrj := PanWS.DM_Projects(Pani);
            if PanPrj = nil then Continue;
            PanP := PanPrj.DM_ProjectFullPath;
            PanName := UpperCase(ExtractFileName(PanP));
            if PanName = 'PANELIZER.PRJSCR' then
            begin
                Result := ExtractFilePath(PanP);
                Exit;
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
        PanP := PanDir + PanFileName;
        if FileExists(PanP) then begin Result := PanP; Exit; end;
        PanP := PanDir + 'images\' + PanFileName;
        if FileExists(PanP) then begin Result := PanP; Exit; end;
    end;
    if FileExists(PanFileName) then begin Result := PanFileName; Exit; end;
    PanP := 'images\' + PanFileName;
    if FileExists(PanP) then Result := PanP;
end;

procedure PanCS_TryOneHelpFile(const PanName : String; var PanDone : Boolean);
var
    PanP : String;
begin
    if PanDone then Exit;
    PanP := PanCS_FindImageFile(PanName);
    if (PanP = '') or (not FileExists(PanP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(PanP);
        LabelImageHint.Caption := '';
        PanDone := True;
    except
    end;
end;

procedure PanCS_TryLoadHelpImage(const PanBmpName : String; const PanPngName : String);
var
    PanDone : Boolean;
begin
    PanDone := False;
    PanCS_TryOneHelpFile(PanPngName, PanDone);
    PanCS_TryOneHelpFile(PanBmpName, PanDone);
    PanCS_TryOneHelpFile('Panelizer.png', PanDone);
    PanCS_TryOneHelpFile('Panelizer.bmp', PanDone);
    if not PanDone then
        LabelImageHint.Caption := 'No image. Put ' + PanPngName + ' next to the script or in images\.';
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
