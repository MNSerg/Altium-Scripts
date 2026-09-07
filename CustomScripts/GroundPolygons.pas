{..............................................................................}
{ GroundPolygons.pas                                                            }
{ Полигоны GND по контуру платы на всех сигнальных медных слоях.               }
{ Зазоры не задаются скриптом — действуют правила проектирования.               }
{..............................................................................}

var
    Board     : IPCB_Board;
    NetName   : String;
    UseSolid  : Boolean;
    ReplaceAll: Integer; { -1 не спрашивали, 0 skip, 1 replace }
    Created   : Integer;
    Skipped   : Integer;

procedure Start; forward;
procedure _Start; forward;
procedure TFormGnd.ButtonOKClick(Sender: TObject); forward;
procedure TFormGnd.ButtonCancelClick(Sender: TObject); forward;
procedure TFormGnd.FormGndShow(Sender: TObject); forward;

function FindNet(const Name : String) : IPCB_Net;
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
        if UpperCase(N.Name) = UpperCase(Name) then
        begin
            Result := N;
            Break;
        end;
        N := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

function ExistingPourOnLayer(ALayer : TLayer; ANet : IPCB_Net) : IPCB_Polygon;
var
    Iter : IPCB_BoardIterator;
    P : IPCB_Polygon;
begin
    Result := nil;
    Iter := Board.BoardIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(ePolyObject));
    Iter.AddFilter_LayerSet(MkSet(ALayer));
    Iter.AddFilter_Method(eProcessAll);
    P := Iter.FirstPCBObject;
    while P <> nil do
    begin
        if P.InNet and (ANet <> nil) then
        begin
            if P.Net = ANet then
            begin
                Result := P;
                Break;
            end;
        end;
        P := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

procedure CopyOutlineToPolygon(Poly : IPCB_Polygon);
var
    i, n : Integer;
    Seg : TPolySegment;
    Rect : TCoordRect;
begin
    try
        n := Board.BoardOutline.PointCount;
        if n > 1 then
        begin
            Poly.PointCount := n;
            for i := 0 to n - 1 do
            begin
                Seg := Board.BoardOutline.Segments[i];
                Poly.Segments[i] := Seg;
            end;
            Exit;
        end;
    except
    end;
    Rect := Board.BoardOutline.BoundingRectangle;
    Poly.PointCount := 4;
    { Прямоугольник по bounding box. }
    Seg.Kind := ePolySegmentLine;
    Seg.vx := Rect.Left;  Seg.vy := Rect.Bottom; Poly.Segments[0] := Seg;
    Seg.vx := Rect.Right; Seg.vy := Rect.Bottom; Poly.Segments[1] := Seg;
    Seg.vx := Rect.Right; Seg.vy := Rect.Top;    Poly.Segments[2] := Seg;
    Seg.vx := Rect.Left;  Seg.vy := Rect.Top;    Poly.Segments[3] := Seg;
end;

procedure CollectCopperLayers(List : TStringList);
var
    Stack : IPCB_LayerStack;
    LS : IPCB_LayerObject;
    Id : TLayer;
begin
    List.Clear;
    try
        Stack := Board.LayerStack_V7;
    except
        Stack := nil;
    end;
    if Stack <> nil then
    begin
        try
            LS := Stack.First(eLayerClass_Signal);
            while LS <> nil do
            begin
                Id := LS.LayerID;
                List.Add(IntToStr(Id));
                LS := Stack.Next(eLayerClass_Signal, LS);
            end;
        except
        end;
    end;
    if List.Count = 0 then
    begin
        List.Add(IntToStr(eTopLayer));
        List.Add(IntToStr(eBottomLayer));
    end;
end;

procedure CreatePour(ALayer : TLayer; ANet : IPCB_Net);
var
    Poly : IPCB_Polygon;
    Old : IPCB_Polygon;
    Ans : Boolean;
begin
    Old := ExistingPourOnLayer(ALayer, ANet);
    if Old <> nil then
    begin
        if ReplaceAll < 0 then
        begin
            Ans := ConfirmNoYes('На слое ' + Layer2String(ALayer) +
                ' уже есть полигон цепи ' + NetName + '. Заменять существующие? (Да = все заменить, Нет = пропускать)');
            if Ans then ReplaceAll := 1 else ReplaceAll := 0;
        end;
        if ReplaceAll = 0 then
        begin
            Inc(Skipped);
            Exit;
        end;
        Board.RemovePCBObject(Old);
    end;

    Poly := PCBServer.PCBObjectFactory(ePolyObject, eNoDimension, eCreate_Default);
    Poly.Layer := ALayer;
    if ANet <> nil then Poly.Net := ANet;
    if UseSolid then
        Poly.PolyHatchStyle := ePolySolid
    else
        Poly.PolyHatchStyle := ePoly90;
    try
        Poly.RemoveDead := True;
    except
    end;
    try
        Poly.RestoreUndersizedPolygons := True;
    except
    end;
    { ClearanceGap не задаём: зазоры полигона — из правил проектирования. }
    try
        Poly.MinPrimLength := MMsToCoord(0.1);
    except
    end;
    CopyOutlineToPolygon(Poly);
    Board.AddPCBObject(Poly);
    try
        Poly.Rebuild;
    except
    end;
    Inc(Created);
end;

procedure DoCreate;
var
    Layers : TStringList;
    i : Integer;
    ALayer : TLayer;
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
        for i := 0 to Layers.Count - 1 do
        begin
            ALayer := StrToInt(Layers[i]);
            CreatePour(ALayer, ANet);
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


procedure TFormGnd.FormGndShow(Sender: TObject);
begin
    try
        CS_TryLoadHelpImage('GroundPolygons.bmp', 'GroundPolygons.png');
    except
    end;
    EditNet.Text := 'GND';
    CheckSolid.Checked := True;
end;

procedure TFormGnd.ButtonOKClick(Sender: TObject);
begin
    if PCBServer = nil then
    begin
        ShowError('PCB-server is not available.');
        Exit;
    end;
    Board := PCBServer.GetCurrentPCBBoard;
    if Board = nil then
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

procedure TFormGnd.ButtonCancelClick(Sender: TObject);
begin
    FormGnd.Close;
end;

procedure Start;
begin
    FormGnd.ShowModal;
end;

procedure _Start;
begin
    Start;
end;
