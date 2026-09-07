{..............................................................................}
{ GroundPolygons.pas                                                            }
{ Полигоны GND по контуру платы на всех сигнальных медных слоях.               }
{ Зазоры не задаются скриптом — действуют правила проектирования.               }
{..............................................................................}

var
    GndBoard     : IPCB_Board;
    NetName   : String;
    UseSolid  : Boolean;
    ReplaceAll: Integer; { -1 не спрашивали, 0 skip, 1 replace }
    Created   : Integer;
    Skipped   : Integer;

{ Run Script: choose procedure StartGroundPolygons (project compiles only this .pas). }
procedure StartGroundPolygons; forward;
procedure _StartGroundPolygons; forward;
procedure TFormGnd.ButtonOKClick(GndSender: TObject); forward;
procedure TFormGnd.ButtonCancelClick(GndSender: TObject); forward;
procedure TFormGnd.FormGndShow(GndSender: TObject); forward;

function FindNet(const GndName : String) : IPCB_Net;
var
    GndIter : IPCB_BoardIterator;
    GndN : IPCB_Net;
begin
    Result := nil;
    GndIter := GndBoard.BoardIterator_Create;
    GndIter.AddFilter_ObjectSet(MkSet(eNetObject));
    GndIter.AddFilter_LayerSet(AllLayers);
    GndIter.AddFilter_Method(eProcessAll);
    GndN := GndIter.FirstPCBObject;
    while GndN <> nil do
    begin
        if UpperCase(GndN.Name) = UpperCase(GndName) then
        begin
            Result := GndN;
            Break;
        end;
        GndN := GndIter.NextPCBObject;
    end;
    GndBoard.BoardIterator_Destroy(GndIter);
end;

function ExistingPourOnLayer(GndALayer : TLayer; ANet : IPCB_Net) : IPCB_Polygon;
var
    GndIter : IPCB_BoardIterator;
    GndP : IPCB_Polygon;
begin
    Result := nil;
    GndIter := GndBoard.BoardIterator_Create;
    GndIter.AddFilter_ObjectSet(MkSet(ePolyObject));
    GndIter.AddFilter_LayerSet(MkSet(GndALayer));
    GndIter.AddFilter_Method(eProcessAll);
    GndP := GndIter.FirstPCBObject;
    while GndP <> nil do
    begin
        if GndP.InNet and (ANet <> nil) then
        begin
            if GndP.Net = ANet then
            begin
                Result := GndP;
                Break;
            end;
        end;
        GndP := GndIter.NextPCBObject;
    end;
    GndBoard.BoardIterator_Destroy(GndIter);
end;

procedure CopyOutlineToPolygon(GndPoly : IPCB_Polygon);
var
    Gndi, Gndn : Integer;
    GndSeg : TPolySegment;
    GndRect : TCoordRect;
begin
    try
        Gndn := GndBoard.BoardOutline.PointCount;
        if Gndn > 1 then
        begin
            GndPoly.PointCount := Gndn;
            for Gndi := 0 to Gndn - 1 do
            begin
                GndSeg := GndBoard.BoardOutline.Segments[Gndi];
                GndPoly.Segments[Gndi] := GndSeg;
            end;
            Exit;
        end;
    except
    end;
    GndRect := GndBoard.BoardOutline.BoundingRectangle;
    GndPoly.PointCount := 4;
    { Прямоугольник по bounding box. }
    GndSeg.Kind := ePolySegmentLine;
    GndSeg.vx := GndRect.Left;  GndSeg.vy := GndRect.Bottom; GndPoly.Segments[0] := GndSeg;
    GndSeg.vx := GndRect.Right; GndSeg.vy := GndRect.Bottom; GndPoly.Segments[1] := GndSeg;
    GndSeg.vx := GndRect.Right; GndSeg.vy := GndRect.Top;    GndPoly.Segments[2] := GndSeg;
    GndSeg.vx := GndRect.Left;  GndSeg.vy := GndRect.Top;    GndPoly.Segments[3] := GndSeg;
end;

procedure CollectCopperLayers(GndList : TStringList);
var
    GndStack : IPCB_LayerStack;
    GndLS : IPCB_LayerObject;
    GndId : TLayer;
begin
    GndList.Clear;
    try
        GndStack := GndBoard.LayerStack_V7;
    except
        GndStack := nil;
    end;
    if GndStack <> nil then
    begin
        try
            GndLS := GndStack.First(eLayerClass_Signal);
            while GndLS <> nil do
            begin
                GndId := GndLS.LayerID;
                GndList.Add(IntToStr(GndId));
                GndLS := GndStack.Next(eLayerClass_Signal, GndLS);
            end;
        except
        end;
    end;
    if GndList.Count = 0 then
    begin
        GndList.Add(IntToStr(eTopLayer));
        GndList.Add(IntToStr(eBottomLayer));
    end;
end;

procedure CreatePour(GndALayer : TLayer; ANet : IPCB_Net);
var
    GndPoly : IPCB_Polygon;
    Old : IPCB_Polygon;
    GndAns : Boolean;
begin
    Old := ExistingPourOnLayer(GndALayer, ANet);
    if Old <> nil then
    begin
        if ReplaceAll < 0 then
        begin
            GndAns := ConfirmNoYes('На слое ' + Layer2String(GndALayer) +
                ' уже есть полигон цепи ' + NetName + '. Заменять существующие? (Да = все заменить, Нет = пропускать)');
            if GndAns then ReplaceAll := 1 else ReplaceAll := 0;
        end;
        if ReplaceAll = 0 then
        begin
            Inc(Skipped);
            Exit;
        end;
        GndBoard.RemovePCBObject(Old);
    end;

    GndPoly := PCBServer.PCBObjectFactory(ePolyObject, eNoDimension, eCreate_Default);
    GndPoly.Layer := GndALayer;
    if ANet <> nil then GndPoly.Net := ANet;
    if UseSolid then
        GndPoly.PolyHatchStyle := ePolySolid
    else
        GndPoly.PolyHatchStyle := ePoly90;
    try
        GndPoly.RemoveDead := True;
    except
    end;
    try
        GndPoly.RestoreUndersizedPolygons := True;
    except
    end;
    { ClearanceGap не задаём: зазоры полигона — из правил проектирования. }
    try
        GndPoly.MinPrimLength := MMsToCoord(0.1);
    except
    end;
    CopyOutlineToPolygon(GndPoly);
    GndBoard.AddPCBObject(GndPoly);
    try
        GndPoly.Rebuild;
    except
    end;
    Inc(Created);
end;

procedure DoCreate;
var
    Layers : TStringList;
    Gndi : Integer;
    GndALayer : TLayer;
    ANet : IPCB_Net;
begin
    ANet := FindNet(NetName);
    if ANet = nil then
    begin
        if not ConfirmNoYes('Цепь «' + NetName + '» не найдена. Создать полигоны без цепи?') then
            Exit;
    end;

    ReplaceAll := -1;
    Created := 0;
    Skipped := 0;
    Layers := TStringList.Create;
    PCBServer.PreProcess;
    try
        CollectCopperLayers(Layers);
        for Gndi := 0 to Layers.Count - 1 do
        begin
            GndALayer := StrToInt(Layers[Gndi]);
            CreatePour(GndALayer, ANet);
        end;
    finally
        PCBServer.PostProcess;
        Layers.Free;
    end;
    Client.SendMessage('PCB:Zoom', 'Action=Redraw', 255, Client.CurrentView);
    ShowInfo('Создано полигонов: ' + IntToStr(Created) + sLineBreak +
             'Пропущено: ' + IntToStr(Skipped) + sLineBreak +
             'Проверьте Repour All, если заливки не пересчитались.',
             'Полигоны GND');
end;

{ ScriptBoot.inc — safe help-image load. Never call ParamStr (AV in Altium). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function GndCS_ScriptFolder : String;
var
    GndWS  : IWorkspace;
    GndPrj : IProject;
    Gndi   : Integer;
    GndP   : String;
begin
    Result := '';
    try
        GndWS := GetWorkspace;
        if GndWS = nil then Exit;
        GndPrj := GndWS.DM_FocusedProject;
        if GndPrj <> nil then
        begin
            GndP := ExtractFilePath(GndPrj.DM_ProjectFullPath);
            if GndP <> '' then
            begin
                Result := GndP;
                Exit;
            end;
        end;
        for Gndi := 0 to GndWS.DM_ProjectCount - 1 do
        begin
            GndPrj := GndWS.DM_Projects(Gndi);
            if GndPrj <> nil then
            begin
                GndP := GndPrj.DM_ProjectFullPath;
                if Pos('CustomScripts', GndP) > 0 then
                begin
                    Result := ExtractFilePath(GndP);
                    Exit;
                end;
            end;
        end;
    except
        Result := '';
    end;
end;

function GndCS_FindImageFile(const GndFileName : String) : String;
var
    GndDir, GndP : String;
begin
    Result := '';
    GndDir := GndCS_ScriptFolder;
    if GndDir <> '' then
    begin
        GndP := GndDir + 'images\' + GndFileName;
        if FileExists(GndP) then
        begin
            Result := GndP;
            Exit;
        end;
        GndP := GndDir + GndFileName;
        if FileExists(GndP) then
        begin
            Result := GndP;
            Exit;
        end;
    end;
    GndP := 'images\' + GndFileName;
    if FileExists(GndP) then Result := GndP;
end;

procedure GndCS_TryLoadHelpImage(const GndBmpName : String; const GndPngName : String);
var
    GndP : String;
begin
    try
        GndP := GndCS_FindImageFile(GndBmpName);
        if GndP = '' then
            GndP := GndCS_FindImageFile(GndPngName);
        if (GndP <> '') and FileExists(GndP) then
        begin
            ImageHelp.Picture.LoadFromFile(GndP);
            LabelImageHint.Caption := 'Replace image: images\' + GndBmpName;
        end
        else
            LabelImageHint.Caption := 'No image. Put ' + GndBmpName + ' in images\ next to the scripts.';
    except
        try
            LabelImageHint.Caption := 'Image not loaded.';
        except
        end;
    end;
end;


procedure TFormGnd.FormGndShow(GndSender: TObject);
begin
    try
        GndCS_TryLoadHelpImage('GroundPolygons.bmp', 'GroundPolygons.png');
    except
    end;
    EditNet.Text := 'GND';
    CheckSolid.Checked := True;
end;

procedure TFormGnd.ButtonOKClick(GndSender: TObject);
begin
    if PCBServer = nil then
    begin
        ShowError('PCB-server is not available.');
        Exit;
    end;
    GndBoard := PCBServer.GetCurrentPCBBoard;
    if GndBoard = nil then
    begin
        ShowError('Open a PCB document.');
        Exit;
    end;
    NetName := EditNet.Text;
    if NetName = '' then NetName := 'GND';
    UseSolid := CheckSolid.Checked;
    FormGnd.Close;
    DoCreate;
end;

procedure TFormGnd.ButtonCancelClick(GndSender: TObject);
begin
    FormGnd.Close;
end;

procedure StartGroundPolygons;
begin
    FormGnd.ShowModal;
end;

procedure _StartGroundPolygons;
begin
    StartGroundPolygons;
end;
