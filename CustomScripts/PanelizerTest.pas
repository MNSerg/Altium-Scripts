{..............................................................................}
{ PanelizerTest.pas                                                             }
{ Чистый mill+tab: контур платы, offset наружу, объединение каналов,           }
{ перемычки inward-only (горизонтальные = те же, что вертикальные, оси раз).   }
{..............................................................................}

const
    PTstOutlineW = 0.2;
    PTstPiValue         = 3.141592653589793;

var
    PTstSourceBoard : IPCB_Board;
    PTstPanelBoard  : IPCB_Board;
    PTstSourcePath  : String;
    PTstRows, PTstCols  : Integer;
    PTstGapX, PTstGapY, PTstMargin, PTstTabW, PTstFilletR, PTstOffMM : Double;
    PTstMechIndex   : Integer;
    PTstBoardW, PTstBoardH : Double;
    PTstPanelW, PTstPanelH : Double;
    PTstMechLayer   : TLayer;
    PTstLineW       : TCoord;

{ Run Script: choose procedure StartPanelizerTest (project compiles only this .pas). }
procedure StartPanelizerTest; forward;
procedure _StartPanelizerTest; forward;
procedure TFormPTst.ButtonBrowseClick(PTstSender: TObject); forward;
procedure TFormPTst.ButtonOKClick(PTstSender: TObject); forward;
procedure TFormPTst.ButtonCancelClick(PTstSender: TObject); forward;
procedure TFormPTst.FormPTstShow(PTstSender: TObject); forward;
function PTstBoardOriginX(Col : Integer) : TCoord; forward;
function PTstBoardOriginY(Row : Integer) : TCoord; forward;

function PTstParseFloat(const PTstS : String; var PTstV : Double) : Boolean;
var
    PTstT : String;
    PTsti : Integer;
    PTstCh : Char;
    PTstSign : Double;
    PTstScale : Double;
    PTstSeenDigit : Boolean;
    PTstFrac : Boolean;
begin
    Result := False;
    PTstV := 0;
    PTstT := PTstS;
    while (Length(PTstT) > 0) and (PTstT[1] = ' ') do
        PTstT := Copy(PTstT, 2, Length(PTstT));
    while (Length(PTstT) > 0) and (PTstT[Length(PTstT)] = ' ') do
        PTstT := Copy(PTstT, 1, Length(PTstT) - 1);
    if PTstT = '' then Exit;
    PTstSign := 1;
    PTsti := 1;
    if PTstT[1] = '-' then
    begin
        PTstSign := -1;
        PTsti := 2;
    end
    else if PTstT[1] = '+' then
        PTsti := 2;
    PTstSeenDigit := False;
    PTstFrac := False;
    PTstScale := 1;
    while PTsti <= Length(PTstT) do
    begin
        PTstCh := PTstT[PTsti];
        if (PTstCh = '.') or (PTstCh = ',') then
        begin
            if PTstFrac then Exit;
            PTstFrac := True;
        end
        else if (PTstCh >= '0') and (PTstCh <= '9') then
        begin
            PTstSeenDigit := True;
            if not PTstFrac then
                PTstV := PTstV * 10 + (Ord(PTstCh) - Ord('0'))
            else
            begin
                PTstScale := PTstScale * 10;
                PTstV := PTstV + (Ord(PTstCh) - Ord('0')) / PTstScale;
            end;
        end
        else
            Exit;
        PTsti := PTsti + 1;
    end;
    if not PTstSeenDigit then Exit;
    PTstV := PTstV * PTstSign;
    Result := True;
end;

function PTstParsePositive(const PTstS : String; var PTstV : Double) : Boolean;
begin
    Result := PTstParseFloat(PTstS, PTstV) and (PTstV > 0);
end;

function PTstParseNonNeg(const PTstS : String; var PTstV : Double) : Boolean;
begin
    Result := PTstParseFloat(PTstS, PTstV) and (PTstV >= 0);
end;

function PTstParsePositiveInt(const PTstS : String; var PTstV : Integer) : Boolean;
begin
    Result := False;
    try
        PTstV := StrToInt(PTstS);
        Result := PTstV > 0;
    except
        Result := False;
    end;
end;

function PTstAddTrack(ABoard : IPCB_Board; PTstX1, PTstY1, PTstX2, PTstY2 : TCoord; PTstALayer : TLayer) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := PTstX1;
    Result.Y1 := PTstY1;
    Result.X2 := PTstX2;
    Result.Y2 := PTstY2;
    Result.Layer := PTstALayer;
    Result.Width := PTstLineW;
    ABoard.AddPCBObject(Result);
end;

function PTstAddArc(ABoard : IPCB_Board; PTstCX, PTstCY, PTstRadius : TCoord; PTstSa, PTstEa : Double; PTstALayer : TLayer) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := PTstCX;
    Result.YCenter := PTstCY;
    Result.Radius := PTstRadius;
    Result.StartAngle := PTstSa;
    Result.EndAngle := PTstEa;
    Result.Layer := PTstALayer;
    Result.LineWidth := PTstLineW;
    ABoard.AddPCBObject(Result);
end;

procedure PTstDrawRoundedRect(ABoard : IPCB_Board; PTstX0, PTstY0, PTstX1, PTstY1, PTstR : TCoord; PTstALayer : TLayer);
begin
    if PTstR <= 0 then
    begin
        PTstAddTrack(ABoard, PTstX0, PTstY0, PTstX1, PTstY0, PTstALayer);
        PTstAddTrack(ABoard, PTstX1, PTstY0, PTstX1, PTstY1, PTstALayer);
        PTstAddTrack(ABoard, PTstX1, PTstY1, PTstX0, PTstY1, PTstALayer);
        PTstAddTrack(ABoard, PTstX0, PTstY1, PTstX0, PTstY0, PTstALayer);
        Exit;
    end;
    PTstAddTrack(ABoard, PTstX0 + PTstR, PTstY0, PTstX1 - PTstR, PTstY0, PTstALayer);
    PTstAddTrack(ABoard, PTstX1, PTstY0 + PTstR, PTstX1, PTstY1 - PTstR, PTstALayer);
    PTstAddTrack(ABoard, PTstX1 - PTstR, PTstY1, PTstX0 + PTstR, PTstY1, PTstALayer);
    PTstAddTrack(ABoard, PTstX0, PTstY1 - PTstR, PTstX0, PTstY0 + PTstR, PTstALayer);
    PTstAddArc(ABoard, PTstX0 + PTstR, PTstY0 + PTstR, PTstR, 180, 270, PTstALayer);
    PTstAddArc(ABoard, PTstX1 - PTstR, PTstY0 + PTstR, PTstR, 270, 0, PTstALayer);
    PTstAddArc(ABoard, PTstX1 - PTstR, PTstY1 - PTstR, PTstR, 0, 90, PTstALayer);
    PTstAddArc(ABoard, PTstX0 + PTstR, PTstY1 - PTstR, PTstR, 90, 180, PTstALayer);
end;

{ Вырез как Panelizer 50c84c3; общий вертикальный канал — один раз (SkipWest). }

procedure PTstDrawBoardCell(ABoard : IPCB_Board; Col, Row : Integer; PTstALayer : TLayer);
var
    L, B, Rgt, Tp : TCoord;
begin
    L := PTstBoardOriginX(Col);
    B := PTstBoardOriginY(Row);
    Rgt := L + MMsToCoord(PTstBoardW);
    Tp := B + MMsToCoord(PTstBoardH);
    PTstDrawRoundedRect(ABoard, L, B, Rgt, Tp, 0, PTstALayer);
end;

procedure PTstDrawMillAroundBoard(ABoard : IPCB_Board; Col, Row : Integer; PTstALayer : TLayer);
var
    L, B, Rgt, Tp, D, RR, HalfNeck, MidX, MidY : TCoord;
    Mx0, Mx1, My0, My1 : TCoord;
    SkipWest : Boolean;
begin
    { Mill как Panelizer 50c84c3: верх/право те же углы. Col>0 — не дублировать запад. }
    L := PTstBoardOriginX(Col);
    B := PTstBoardOriginY(Row);
    Rgt := L + MMsToCoord(PTstBoardW);
    Tp := B + MMsToCoord(PTstBoardH);
    RR := MMsToCoord(PTstFilletR);
    D := MMsToCoord(PTstOffMM);
    if D < 1 then D := RR + RR;
    if D < 1 then Exit;
    HalfNeck := MMsToCoord(PTstTabW) div 2;
    if HalfNeck < 1 then HalfNeck := 1;
    MidX := (L + Rgt) div 2;
    MidY := (B + Tp) div 2;
    Mx0 := MidX - HalfNeck - RR;
    Mx1 := MidX + HalfNeck + RR;
    My0 := MidY - HalfNeck - RR;
    My1 := MidY + HalfNeck + RR;
    if (Mx0 <= L) or (Mx1 >= Rgt) or (My0 <= B) or (My1 >= Tp) then Exit;
    if (Mx0 >= Mx1) or (My0 >= My1) then Exit;
    SkipWest := Col > 0;

    if not SkipWest then
    begin
        PTstAddTrack(ABoard, L, B, L, My0, PTstALayer);
        PTstAddArc(ABoard, L - RR, My0, RR, 0, 180, PTstALayer);
        PTstAddTrack(ABoard, L - D, My0, L - D, B - D, PTstALayer);
    end;
    PTstAddTrack(ABoard, L - D, B - D, Mx0, B - D, PTstALayer);
    PTstAddArc(ABoard, Mx0, B - RR, RR, 270, 90, PTstALayer);
    PTstAddTrack(ABoard, Mx0, B, L, B, PTstALayer);

    PTstAddTrack(ABoard, Rgt, B, Mx1, B, PTstALayer);
    PTstAddArc(ABoard, Mx1, B - RR, RR, 90, 270, PTstALayer);
    PTstAddTrack(ABoard, Mx1, B - D, Rgt + D, B - D, PTstALayer);
    PTstAddTrack(ABoard, Rgt + D, B - D, Rgt + D, My0, PTstALayer);
    PTstAddArc(ABoard, Rgt + RR, My0, RR, 0, 180, PTstALayer);
    PTstAddTrack(ABoard, Rgt, My0, Rgt, B, PTstALayer);

    PTstAddTrack(ABoard, Rgt, Tp, Rgt, My1, PTstALayer);
    PTstAddArc(ABoard, Rgt + RR, My1, RR, 180, 0, PTstALayer);
    PTstAddTrack(ABoard, Rgt + D, My1, Rgt + D, Tp + D, PTstALayer);
    PTstAddTrack(ABoard, Rgt + D, Tp + D, Mx1, Tp + D, PTstALayer);
    PTstAddArc(ABoard, Mx1, Tp + RR, RR, 270, 90, PTstALayer);
    PTstAddTrack(ABoard, Mx1, Tp, Rgt, Tp, PTstALayer);

    PTstAddTrack(ABoard, L, Tp, Mx0, Tp, PTstALayer);
    PTstAddArc(ABoard, Mx0, Tp + RR, RR, 90, 270, PTstALayer);
    PTstAddTrack(ABoard, Mx0, Tp + D, L - D, Tp + D, PTstALayer);
    if not SkipWest then
    begin
        PTstAddTrack(ABoard, L - D, Tp + D, L - D, My1, PTstALayer);
        PTstAddArc(ABoard, L - RR, My1, RR, 180, 0, PTstALayer);
        PTstAddTrack(ABoard, L, My1, L, Tp, PTstALayer);
    end;
end;

procedure PTstDrawAllMillPaths(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    r, c : Integer;
begin
    for r := 0 to PTstRows - 1 do
        for c := 0 to PTstCols - 1 do
        begin
            PTstDrawBoardCell(ABoard, c, r, PTstALayer);
            PTstDrawMillAroundBoard(ABoard, c, r, PTstALayer);
        end;
end;

procedure PTstDrawCommonOuterContour(ABoard : IPCB_Board; PTstALayer : TLayer);
var
    X0, Y0, X1, Y1 : TCoord;
begin
    X0 := PTstBoardOriginX(0) - MMsToCoord(PTstMargin);
    Y0 := PTstBoardOriginY(0) - MMsToCoord(PTstMargin);
    X1 := PTstBoardOriginX(PTstCols - 1) + MMsToCoord(PTstBoardW) + MMsToCoord(PTstMargin);
    Y1 := PTstBoardOriginY(PTstRows - 1) + MMsToCoord(PTstBoardH) + MMsToCoord(PTstMargin);
    PTstAddTrack(ABoard, X0, Y0, X1, Y0, PTstALayer);
    PTstAddTrack(ABoard, X1, Y0, X1, Y1, PTstALayer);
    PTstAddTrack(ABoard, X1, Y1, X0, Y1, PTstALayer);
    PTstAddTrack(ABoard, X0, Y1, X0, Y0, PTstALayer);
end;

function PTstBoardOriginX(Col : Integer) : TCoord;
begin
    Result := MMsToCoord(PTstMargin + Col * (PTstBoardW + PTstGapX));
end;

function PTstBoardOriginY(Row : Integer) : TCoord;
begin
    Result := MMsToCoord(PTstMargin + Row * (PTstBoardH + PTstGapY));
end;

procedure PTstPlaceEmbeddedArray(ABoard : IPCB_Board);
var
    Emb : IPCB_EmbeddedBoard;
    PTstX0, PTstY0 : TCoord;
begin
    Emb := PCBServer.PCBObjectFactory(eEmbeddedBoardObject, eNoDimension, eCreate_Default);
    Emb.DocumentPath := PTstSourcePath;
    Emb.RowCount := PTstRows;
    Emb.ColCount := PTstCols;
    Emb.ColSpacing := MMsToCoord(PTstBoardW + PTstGapX);
    Emb.RowSpacing := MMsToCoord(PTstBoardH + PTstGapY);
    PTstX0 := PTstBoardOriginX(0);
    PTstY0 := PTstBoardOriginY(0);
    Emb.XLocation := PTstX0;
    Emb.YLocation := PTstY0;
    ABoard.AddPCBObject(Emb);
end;

procedure PTstShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

procedure ApplyPTstPanelBoardOutline(ABoard : IPCB_Board);
var
    PTstIter : IPCB_BoardIterator;
    PTstPrim : IPCB_Primitive;
begin
    { Выделить рамку панели и сделать из неё board outline. }
    PTstIter := ABoard.BoardIterator_Create;
    PTstIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject));
    PTstIter.AddFilter_LayerSet(MkSet(PTstMechLayer));
    PTstIter.AddFilter_Method(eProcessAll);
    PTstPrim := PTstIter.FirstPCBObject;
    while PTstPrim <> nil do
    begin
        PTstPrim.Selected := False;
        PTstPrim := PTstIter.NextPCBObject;
    end;
    ABoard.BoardIterator_Destroy(PTstIter);

    ResetParameters;
    AddStringParameter('Scope', 'All');
    RunProcess('PCB:DeSelect');
end;

procedure PTstBuildPanel;
var
    PTstWS : IWorkspace;
    PTstRect : TCoordRect;
begin
    PTstRect := PTstSourceBoard.BoardOutline.BoundingRectangle;
    PTstBoardW := CoordToMMs(PTstRect.Right - PTstRect.Left);
    PTstBoardH := CoordToMMs(PTstRect.Top - PTstRect.Bottom);
    if (PTstBoardW <= 0) or (PTstBoardH <= 0) then
    begin
        PTstShowBox(LabelErrSize.Caption, 16);
        Exit;
    end;

    PTstPanelW := PTstMargin * 2 + PTstCols * PTstBoardW + (PTstCols - 1) * PTstGapX;
    PTstPanelH := PTstMargin * 2 + PTstRows * PTstBoardH + (PTstRows - 1) * PTstGapY;
    PTstLineW := MMsToCoord(PTstOutlineW);
    PTstMechLayer := LayerUtils.MechanicalLayer(PTstMechIndex);

    PTstWS := GetWorkspace;
    if PTstWS = nil then Exit;
    PTstWS.DM_CreateNewDocument('PCB');
    PTstPanelBoard := PCBServer.GetCurrentPCBBoard;
    if PTstPanelBoard = nil then
    begin
        PTstShowBox(LabelErrNew.Caption, 16);
        Exit;
    end;

    PCBServer.PreProcess;
    try
        PTstPlaceEmbeddedArray(PTstPanelBoard);
        PTstDrawAllMillPaths(PTstPanelBoard, PTstMechLayer);
        PTstDrawCommonOuterContour(PTstPanelBoard, PTstMechLayer);

        PTstPanelBoard.LayerIsDisplayed[PTstMechLayer] := True;

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
    PTstShowBox(LabelInfoDone.Caption + IntToStr(PTstCols) + 'x' + IntToStr(PTstRows) + sLineBreak +
               LabelInfoSize.Caption + FormatFloat('0.##', PTstPanelW) + ' x ' + FormatFloat('0.##', PTstPanelH) + sLineBreak +
               LabelInfoLayer.Caption + Layer2String(PTstMechLayer), 64);
end;

procedure TFormPTst.ButtonBrowseClick(PTstSender: TObject);
var
    PTstDlg : TOpenDialog;
    PTstWS : IWorkspace;
begin
    PTstDlg := TOpenDialog.Create(nil);
    try
        PTstDlg.Title := LabelDlgTitle.Caption;
        PTstDlg.Filter := 'PCB (*.PcbDoc)|*.PcbDoc';
        if PTstDlg.Execute then
        begin
            PTstSourcePath := PTstDlg.FileName;
            EditFile.Text := PTstSourcePath;
            PTstWS := GetWorkspace;
            if PTstWS <> nil then
                PTstWS.DM_OpenProject(PTstSourcePath, False);
            PTstSourceBoard := PCBServer.GetPCBBoardByPath(PTstSourcePath);
            if PTstSourceBoard = nil then
                PTstSourceBoard := PCBServer.GetCurrentPCBBoard;
            if PTstSourceBoard = nil then
                PTstShowBox(LabelWarnOpen.Caption, 48);
        end;
    finally
        PTstDlg.Free;
    end;
end;

procedure TFormPTst.ButtonOKClick(PTstSender: TObject);
begin
    PTstSourcePath := EditFile.Text;
    if (PTstSourcePath = '') or (not FileExists(PTstSourcePath)) then
    begin
        PTstShowBox(LabelErrFile.Caption, 16);
        Exit;
    end;
    if not PTstParsePositiveInt(EditRows.Text, PTstRows) then
    begin
        PTstShowBox(LabelErrRows.Caption, 16);
        Exit;
    end;
    if not PTstParsePositiveInt(EditCols.Text, PTstCols) then
    begin
        PTstShowBox(LabelErrCols.Caption, 16);
        Exit;
    end;
    if not PTstParsePositive(EditGapX.Text, PTstGapX) then begin PTstShowBox(LabelErrGapX.Caption, 16); Exit; end;
    if not PTstParsePositive(EditGapY.Text, PTstGapY) then begin PTstShowBox(LabelErrGapY.Caption, 16); Exit; end;
    if not PTstParsePositive(EditMargin.Text, PTstMargin) then begin PTstShowBox(LabelErrMargin.Caption, 16); Exit; end;
    if not PTstParsePositive(EditTab.Text, PTstTabW) then begin PTstShowBox(LabelErrTab.Caption, 16); Exit; end;
    if not PTstParseNonNeg(EditFillet.Text, PTstFilletR) then begin PTstShowBox(LabelErrMill.Caption, 16); Exit; end;
    if not PTstParsePositive(EditOff.Text, PTstOffMM) then begin PTstShowBox(LabelErrOff.Caption, 16); Exit; end;
    if not PTstParsePositiveInt(EditMech.Text, PTstMechIndex) then
    begin
        PTstShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;
    if (PTstMechIndex < 1) or (PTstMechIndex > 32) then
    begin
        PTstShowBox(LabelErrMech.Caption, 16);
        Exit;
    end;

    if PTstSourceBoard = nil then
        PTstSourceBoard := PCBServer.GetPCBBoardByPath(PTstSourcePath);
    if PTstSourceBoard = nil then
    begin
        PTstShowBox(LabelErrLoad.Caption, 16);
        Exit;
    end;

    FormPTst.Close;
    PTstBuildPanel;
end;

procedure TFormPTst.ButtonCancelClick(PTstSender: TObject);
begin
    FormPTst.Close;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function PTstCS_ScriptFolder : String;
var
    PTstWS  : IWorkspace;
    PTstPrj : IProject;
    PTsti   : Integer;
    PTstP, PTstName : String;
begin
    Result := '';
    try
        PTstWS := GetWorkspace;
        if PTstWS = nil then Exit;
        for PTsti := 0 to PTstWS.DM_ProjectCount - 1 do
        begin
            PTstPrj := PTstWS.DM_Projects(PTsti);
            if PTstPrj = nil then Continue;
            PTstP := PTstPrj.DM_ProjectFullPath;
            PTstName := UpperCase(ExtractFileName(PTstP));
            if PTstName = 'PANELIZERTEST.PRJSCR' then
            begin
                Result := ExtractFilePath(PTstP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function PTstCS_FindImageFile(const PTstFileName : String) : String;
var
    PTstDir, PTstP : String;
begin
    Result := '';
    PTstDir := PTstCS_ScriptFolder;
    if PTstDir <> '' then
    begin
        PTstP := PTstDir + PTstFileName;
        if FileExists(PTstP) then begin Result := PTstP; Exit; end;
        PTstP := PTstDir + 'images\' + PTstFileName;
        if FileExists(PTstP) then begin Result := PTstP; Exit; end;
    end;
    if FileExists(PTstFileName) then begin Result := PTstFileName; Exit; end;
    PTstP := 'images\' + PTstFileName;
    if FileExists(PTstP) then Result := PTstP;
end;

procedure PTstCS_TryOneHelpFile(const PTstName : String; var PTstDone : Boolean);
var
    PTstP : String;
begin
    if PTstDone then Exit;
    PTstP := PTstCS_FindImageFile(PTstName);
    if (PTstP = '') or (not FileExists(PTstP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(PTstP);
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
        PTstDone := True;
    except
    end;
end;

procedure PTstCS_TryLoadHelpImage(const PTstBmpName : String; const PTstPngName : String);
var
    PTstDone : Boolean;
begin
    PTstDone := False;
    PTstCS_TryOneHelpFile(PTstPngName, PTstDone);
    PTstCS_TryOneHelpFile(PTstBmpName, PTstDone);
    PTstCS_TryOneHelpFile('PanelizerTest.png', PTstDone);
    PTstCS_TryOneHelpFile('PanelizerTest.bmp', PTstDone);
    if not PTstDone then
        LabelImageHint.Caption := 'No image. Put ' + PTstPngName + ' next to the script or in images\.';
end;


procedure TFormPTst.FormPTstShow(PTstSender: TObject);
begin
    try
        PTstCS_TryLoadHelpImage('PanelizerTest.bmp', 'PanelizerTest.png');
    except
    end;
    EditCols.Text := '4';
    EditRows.Text := '2';
    EditGapX.Text := '2';
    EditGapY.Text := '2';
    EditMargin.Text := '10';
    EditTab.Text := '4';
    EditFillet.Text := '1';
    EditOff.Text := '2';
    try
        if PCBServer <> nil then
            PTstSourceBoard := PCBServer.GetCurrentPCBBoard
        else
            PTstSourceBoard := nil;
        if PTstSourceBoard <> nil then
        begin
            PTstSourcePath := PTstSourceBoard.FileName;
            EditFile.Text := PTstSourcePath;
        end;
    except
    end;
end;

procedure StartPanelizerTest;
begin
    FormPTst.ShowModal;
end;

procedure _StartPanelizerTest;
begin
    StartPanelizerTest;
end;
