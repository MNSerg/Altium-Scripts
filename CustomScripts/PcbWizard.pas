{..............................................................................}
{ PcbWizard.pas                                                                 }
{ Новая плата: размер, keep-out контур со скруглениями, крепёж, опции.         }
{..............................................................................}

var
    WizBoard : IPCB_Board;
    Wmm, Hmm, FilletMM, HoleMM, PadMM, MarginMM, GridMM : Double;
    FourHoles, MakeGnd, MakeMask, NewDoc : Boolean;
    CopperCount : Integer;

{ Run Script: choose procedure StartPcbWizard (project compiles only this .pas). }
procedure StartPcbWizard; forward;
procedure _StartPcbWizard; forward;
procedure TFormWizard.ButtonOKClick(WizSender: TObject); forward;
procedure TFormWizard.ButtonCancelClick(WizSender: TObject); forward;
procedure TFormWizard.FormWizardShow(WizSender: TObject); forward;

procedure WizShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

function WizParseFloat(const WizS : String; var WizV : Double) : Boolean;
var
    WizT : String;
    Wizi : Integer;
    WizCh : Char;
    WizSign : Double;
    WizScale : Double;
    WizSeenDigit : Boolean;
    WizFrac : Boolean;
begin
    Result := False;
    WizV := 0;
    WizT := WizS;
    while (Length(WizT) > 0) and (WizT[1] = ' ') do
        WizT := Copy(WizT, 2, Length(WizT));
    while (Length(WizT) > 0) and (WizT[Length(WizT)] = ' ') do
        WizT := Copy(WizT, 1, Length(WizT) - 1);
    if WizT = '' then Exit;
    WizSign := 1;
    Wizi := 1;
    if WizT[1] = '-' then
    begin
        WizSign := -1;
        Wizi := 2;
    end
    else if WizT[1] = '+' then
        Wizi := 2;
    WizSeenDigit := False;
    WizFrac := False;
    WizScale := 1;
    while Wizi <= Length(WizT) do
    begin
        WizCh := WizT[Wizi];
        if (WizCh = '.') or (WizCh = ',') then
        begin
            if WizFrac then Exit;
            WizFrac := True;
        end
        else if (WizCh >= '0') and (WizCh <= '9') then
        begin
            WizSeenDigit := True;
            if not WizFrac then
                WizV := WizV * 10 + (Ord(WizCh) - Ord('0'))
            else
            begin
                WizScale := WizScale * 10;
                WizV := WizV + (Ord(WizCh) - Ord('0')) / WizScale;
            end;
        end
        else
            Exit;
        Wizi := Wizi + 1;
    end;
    if not WizSeenDigit then Exit;
    WizV := WizV * WizSign;
    Result := True;
end;

function AddTrackL(WizX1, WizY1, WizX2, WizY2 : TCoord; WizALayer : TLayer; Width : TCoord) : IPCB_Track;
begin
    Result := PCBServer.PCBObjectFactory(eTrackObject, eNoDimension, eCreate_Default);
    Result.X1 := WizX1; Result.Y1 := WizY1;
    Result.X2 := WizX2; Result.Y2 := WizY2;
    Result.Layer := WizALayer;
    Result.Width := Width;
    WizBoard.AddPCBObject(Result);
    Result.Selected := True;
end;

function AddArcL(WizCX, WizCY, WizR : TCoord; WizSa, WizEa : Double; WizALayer : TLayer; Width : TCoord) : IPCB_Arc;
begin
    Result := PCBServer.PCBObjectFactory(eArcObject, eNoDimension, eCreate_Default);
    Result.XCenter := WizCX; Result.YCenter := WizCY;
    Result.Radius := WizR;
    Result.StartAngle := WizSa; Result.EndAngle := WizEa;
    Result.Layer := WizALayer;
    Result.LineWidth := Width;
    WizBoard.AddPCBObject(Result);
    Result.Selected := True;
end;

procedure DrawRoundedKeepout(WizX0, WizY0, WizX1, WizY1, WizR, Width : TCoord);
var
    WizL : TLayer;
begin
    WizL := eKeepOutLayer;
    if WizR <= 0 then
    begin
        AddTrackL(WizX0, WizY0, WizX1, WizY0, WizL, Width);
        AddTrackL(WizX1, WizY0, WizX1, WizY1, WizL, Width);
        AddTrackL(WizX1, WizY1, WizX0, WizY1, WizL, Width);
        AddTrackL(WizX0, WizY1, WizX0, WizY0, WizL, Width);
        Exit;
    end;
    AddTrackL(WizX0 + WizR, WizY0, WizX1 - WizR, WizY0, WizL, Width);
    AddTrackL(WizX1, WizY0 + WizR, WizX1, WizY1 - WizR, WizL, Width);
    AddTrackL(WizX1 - WizR, WizY1, WizX0 + WizR, WizY1, WizL, Width);
    AddTrackL(WizX0, WizY1 - WizR, WizX0, WizY0 + WizR, WizL, Width);
    AddArcL(WizX0 + WizR, WizY0 + WizR, WizR, 180, 270, WizL, Width);
    AddArcL(WizX1 - WizR, WizY0 + WizR, WizR, 270, 0, WizL, Width);
    AddArcL(WizX1 - WizR, WizY1 - WizR, WizR, 0, 90, WizL, Width);
    AddArcL(WizX0 + WizR, WizY1 - WizR, WizR, 90, 180, WizL, Width);
end;

procedure PlaceHole(WizX, WizY, Hole, WizPad : TCoord);
var
    WizP : IPCB_Pad;
begin
    WizP := PCBServer.PCBObjectFactory(ePadObject, eNoDimension, eCreate_Default);
    WizP.X := WizX;
    WizP.Y := WizY;
    WizP.HoleSize := Hole;
    WizP.TopXSize := WizPad;
    WizP.TopYSize := WizPad;
    WizP.BotXSize := WizPad;
    WizP.BotYSize := WizPad;
    WizP.Layer := eMultiLayer;
    try
        WizP.Name := 'MH';
    except
    end;
    WizBoard.AddPCBObject(WizP);
end;

procedure PlaceMountingHoles(WizX0, WizY0, WizX1, WizY1, WizMargin, Hole, WizPad : TCoord);
begin
    if FourHoles then
    begin
        PlaceHole(WizX0 + WizMargin, WizY0 + WizMargin, Hole, WizPad);
        PlaceHole(WizX1 - WizMargin, WizY0 + WizMargin, Hole, WizPad);
        PlaceHole(WizX1 - WizMargin, WizY1 - WizMargin, Hole, WizPad);
        PlaceHole(WizX0 + WizMargin, WizY1 - WizMargin, Hole, WizPad);
    end
    else
        PlaceHole(WizX0 + WizMargin, WizY0 + WizMargin, Hole, WizPad);
end;

procedure TrySetGrid(Grid : TCoord);
begin
    try
        WizBoard.SnapGridSize := Grid;
    except
        try
            WizBoard.SetState_SnapGridSize(Grid);
        except
        end;
    end;
end;

function FindNetGnd : IPCB_Net;
var
    WizIter : IPCB_BoardIterator;
    WizN : IPCB_Net;
begin
    Result := nil;
    WizIter := WizBoard.BoardIterator_Create;
    WizIter.AddFilter_ObjectSet(MkSet(eNetObject));
    WizIter.AddFilter_LayerSet(AllLayers);
    WizIter.AddFilter_Method(eProcessAll);
    WizN := WizIter.FirstPCBObject;
    while WizN <> nil do
    begin
        if UpperCase(WizN.Name) = 'GND' then
        begin
            Result := WizN;
            Break;
        end;
        WizN := WizIter.NextPCBObject;
    end;
    WizBoard.BoardIterator_Destroy(WizIter);
end;

procedure AddGndPoly(WizALayer : TLayer; WizX0, WizY0, WizX1, WizY1 : TCoord);
var
    WizPoly : IPCB_Polygon;
    WizSeg : TPolySegment;
    WizN : IPCB_Net;
begin
    WizPoly := PCBServer.PCBObjectFactory(ePolyObject, eNoDimension, eCreate_Default);
    WizPoly.Layer := WizALayer;
    WizPoly.PolyHatchStyle := ePolySolid;
    WizN := FindNetGnd;
    if WizN <> nil then WizPoly.Net := WizN;
    { Зазоры полигона — из правил проектирования, не из скрипта. }
    WizPoly.PointCount := 4;
    WizSeg.Kind := ePolySegmentLine;
    WizSeg.vx := WizX0; WizSeg.vy := WizY0; WizPoly.Segments[0] := WizSeg;
    WizSeg.vx := WizX1; WizSeg.vy := WizY0; WizPoly.Segments[1] := WizSeg;
    WizSeg.vx := WizX1; WizSeg.vy := WizY1; WizPoly.Segments[2] := WizSeg;
    WizSeg.vx := WizX0; WizSeg.vy := WizY1; WizPoly.Segments[3] := WizSeg;
    WizBoard.AddPCBObject(WizPoly);
    try
        WizPoly.Rebuild;
    except
    end;
end;

procedure AddMaskOpening(WizALayer : TLayer; WizX0, WizY0, WizX1, WizY1 : TCoord);
var
    WizFill : IPCB_Fill;
begin
    WizFill := PCBServer.PCBObjectFactory(eFillObject, eNoDimension, eCreate_Default);
    WizFill.X1Location := WizX0;
    WizFill.Y1Location := WizY0;
    WizFill.X2Location := WizX1;
    WizFill.Y2Location := WizY1;
    WizFill.Layer := WizALayer;
    WizBoard.AddPCBObject(WizFill);
end;

procedure BuildBoard;
var
    WizX0, WizY0, WizX1, WizY1, WizR, Width : TCoord;
    WizWS : IWorkspace;
begin
    if NewDoc then
    begin
        WizWS := GetWorkspace;
        if WizWS = nil then Exit;
        WizWS.DM_CreateNewDocument('PCB');
    end;
    if PCBServer = nil then
    begin
        WizShowBox(LabelErrNoSrv.Caption, 16);
        Exit;
    end;
    WizBoard := PCBServer.GetCurrentPCBBoard;
    if WizBoard = nil then
    begin
        WizShowBox(LabelErrNoPcb.Caption, 16);
        Exit;
    end;

    try
        WizBoard.XOrigin := 0;
        WizBoard.YOrigin := 0;
    except
    end;
    WizX0 := 0;
    WizY0 := 0;
    WizX1 := MMsToCoord(Wmm);
    WizY1 := MMsToCoord(Hmm);
    WizR := MMsToCoord(FilletMM);
    Width := MMsToCoord(0.2);

    PCBServer.PreProcess;
    try
        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        DrawRoundedKeepout(WizX0, WizY0, WizX1, WizY1, WizR, Width);

        ResetParameters;
        AddStringParameter('MODE', 'BOARDOUTLINE_FROM_SEL_PRIMS');
        RunProcess('PCB:PlaceBoardOutline');

        ResetParameters;
        AddStringParameter('Scope', 'All');
        RunProcess('PCB:DeSelect');

        PlaceMountingHoles(WizX0, WizY0, WizX1, WizY1, MMsToCoord(MarginMM), MMsToCoord(HoleMM), MMsToCoord(PadMM));
        TrySetGrid(MMsToCoord(GridMM));

        if MakeGnd then
        begin
            AddGndPoly(eTopLayer, WizX0, WizY0, WizX1, WizY1);
            AddGndPoly(eBottomLayer, WizX0, WizY0, WizX1, WizY1);
            if CopperCount >= 4 then
            begin
                try
                    AddGndPoly(eMidLayer1, WizX0, WizY0, WizX1, WizY1);
                    AddGndPoly(eMidLayer2, WizX0, WizY0, WizX1, WizY1);
                except
                end;
            end;
            if CopperCount >= 6 then
            begin
                try
                    AddGndPoly(eMidLayer3, WizX0, WizY0, WizX1, WizY1);
                    AddGndPoly(eMidLayer4, WizX0, WizY0, WizX1, WizY1);
                except
                end;
            end;
        end;

        if MakeMask then
        begin
            AddMaskOpening(eTopSolder, WizX0, WizY0, WizX1, WizY1);
            AddMaskOpening(eBottomSolder, WizX0, WizY0, WizX1, WizY1);
        end;
    finally
        PCBServer.PostProcess;
    end;

    Client.SendMessage('PCB:Zoom', 'Action=All', 255, Client.CurrentView);
    WizShowBox(LabelInfoDone.Caption + FormatFloat('0.##', Wmm) + ' x ' +
               FormatFloat('0.##', Hmm) + sLineBreak + LabelInfoHint.Caption, 64);
end;

function ReadPositive(const WizS : String; var WizV : Double) : Boolean;
begin
    Result := WizParseFloat(WizS, WizV) and (WizV > 0);
end;

function ReadNonNeg(const WizS : String; var WizV : Double) : Boolean;
begin
    Result := WizParseFloat(WizS, WizV) and (WizV >= 0);
end;

procedure TFormWizard.ButtonOKClick(WizSender: TObject);
begin
    if not ReadPositive(EditW.Text, Wmm) then begin WizShowBox(LabelErrW.Caption, 16); Exit; end;
    if not ReadPositive(EditH.Text, Hmm) then begin WizShowBox(LabelErrH.Caption, 16); Exit; end;
    if not ReadNonNeg(EditFillet.Text, FilletMM) then begin WizShowBox(LabelErrFillet.Caption, 16); Exit; end;
    if FilletMM < 0 then begin WizShowBox(LabelErrFilletNeg.Caption, 16); Exit; end;
    if not ReadPositive(EditHole.Text, HoleMM) then begin WizShowBox(LabelErrHole.Caption, 16); Exit; end;
    if not ReadPositive(EditPad.Text, PadMM) then begin WizShowBox(LabelErrPad.Caption, 16); Exit; end;
    if not ReadPositive(EditMargin.Text, MarginMM) then begin WizShowBox(LabelErrMargin.Caption, 16); Exit; end;
    if not ReadPositive(EditGrid.Text, GridMM) then begin WizShowBox(LabelErrGrid.Caption, 16); Exit; end;
    FourHoles := CheckFourHoles.Checked;
    MakeGnd := CheckGnd.Checked;
    MakeMask := CheckMask.Checked;
    NewDoc := CheckNewDoc.Checked;
    try
        CopperCount := StrToInt(ComboLayers.Text);
    except
        CopperCount := 4;
    end;
    if FilletMM * 2 >= Wmm then begin WizShowBox(LabelErrFilletW.Caption, 16); Exit; end;
    if FilletMM * 2 >= Hmm then begin WizShowBox(LabelErrFilletH.Caption, 16); Exit; end;
    FormWizard.Close;
    BuildBoard;
end;

procedure TFormWizard.ButtonCancelClick(WizSender: TObject);
begin
    FormWizard.Close;
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function WizCS_ScriptFolder : String;
var
    WizWS  : IWorkspace;
    WizPrj : IProject;
    Wizi   : Integer;
    WizP, WizName : String;
begin
    Result := '';
    try
        WizWS := GetWorkspace;
        if WizWS = nil then Exit;
        for Wizi := 0 to WizWS.DM_ProjectCount - 1 do
        begin
            WizPrj := WizWS.DM_Projects(Wizi);
            if WizPrj = nil then Continue;
            WizP := WizPrj.DM_ProjectFullPath;
            WizName := UpperCase(ExtractFileName(WizP));
            if WizName = 'PCBWIZARD.PRJSCR' then
            begin
                Result := ExtractFilePath(WizP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function WizCS_FindImageFile(const WizFileName : String) : String;
var
    WizDir, WizP : String;
begin
    Result := '';
    WizDir := WizCS_ScriptFolder;
    if WizDir <> '' then
    begin
        WizP := WizDir + WizFileName;
        if FileExists(WizP) then begin Result := WizP; Exit; end;
        WizP := WizDir + 'images\' + WizFileName;
        if FileExists(WizP) then begin Result := WizP; Exit; end;
    end;
    if FileExists(WizFileName) then begin Result := WizFileName; Exit; end;
    WizP := 'images\' + WizFileName;
    if FileExists(WizP) then Result := WizP;
end;

procedure WizCS_TryOneHelpFile(const WizName : String; var WizDone : Boolean);
var
    WizP : String;
begin
    if WizDone then Exit;
    WizP := WizCS_FindImageFile(WizName);
    if (WizP = '') or (not FileExists(WizP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(WizP);
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
        WizDone := True;
    except
    end;
end;

procedure WizCS_TryLoadHelpImage(const WizBmpName : String; const WizPngName : String);
var
    WizDone : Boolean;
begin
    WizDone := False;
    WizCS_TryOneHelpFile(WizPngName, WizDone);
    WizCS_TryOneHelpFile(WizBmpName, WizDone);
    WizCS_TryOneHelpFile('PcbWizard.png', WizDone);
    WizCS_TryOneHelpFile('PcbWizard.bmp', WizDone);
    if not WizDone then
        LabelImageHint.Caption := 'No image. Put ' + WizPngName + ' next to the script or in images\.';
end;


procedure TFormWizard.FormWizardShow(WizSender: TObject);
begin
    try
        WizCS_TryLoadHelpImage('PcbWizard.bmp', 'PcbWizard.png');
    except
    end;
    EditGrid.Text := '0.1';
    ComboLayers.ItemIndex := 1; { 4 медных слоя }
    ComboLayers.Text := '4';
    CheckFourHoles.Checked := True;
end;

procedure StartPcbWizard;
begin
    FormWizard.ShowModal;
end;

procedure _StartPcbWizard;
begin
    StartPcbWizard;
end;
