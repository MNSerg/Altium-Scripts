{..............................................................................}
{ DxfOutlineExport.pas                                                          }
{ Экспорт слоёв PCB в ASCII DXF R12: контуры меди LINE/ARC, шелкография,       }
{ отверстия CIRCLE на отдельном слое HOLES. Без ExportDXF Altium.              }
{..............................................................................}

const
    PiValue = 3.141592653589793;

var
    Board       : IPCB_Board;
    DxfLines    : TStringList;
    HandleCount : Integer;
    LayerItems  : TStringList; { имя для чеклиста = Layer2String }
    LayerIds    : TStringList; { параллельный список IntToStr(TLayer) }

procedure Start; forward;
procedure _Start; forward;
procedure TFormDxf.FormDxfShow(Sender: TObject); forward;
procedure TFormDxf.ButtonOKClick(Sender: TObject); forward;
procedure TFormDxf.ButtonCancelClick(Sender: TObject); forward;
procedure TFormDxf.ButtonAllClick(Sender: TObject); forward;
procedure TFormDxf.ButtonNoneClick(Sender: TObject); forward;
procedure TFormDxf.ButtonCopperClick(Sender: TObject); forward;

function MMX(X : TCoord) : String;
begin
    Result := FormatFloat('0.######', CoordToMMs(X - Board.XOrigin));
end;

function MMY(Y : TCoord) : String;
begin
    Result := FormatFloat('0.######', CoordToMMs(Y - Board.YOrigin));
end;

function MMR(R : TCoord) : String;
begin
    Result := FormatFloat('0.######', CoordToMMs(R));
end;

function DxfLayerName(ALayer : TLayer) : String;
var
    S : String;
    i : Integer;
    C : Char;
begin
    S := Layer2String(ALayer);
    Result := '';
    for i := 1 to Length(S) do
    begin
        C := S[i];
        if ((C >= 'A') and (C <= 'Z')) or ((C >= 'a') and (C <= 'z')) or
           ((C >= '0') and (C <= '9')) then
            Result := Result + C
        else
            Result := Result + '_';
    end;
    if Result = '' then Result := 'L' + IntToStr(ALayer);
end;

function NextHandle : String;
begin
    Inc(HandleCount);
    Result := IntToHex(HandleCount, 2);
end;

procedure DxfAdd(const S : String);
begin
    DxfLines.Add(S);
end;

procedure DxfPair(Code : Integer; const Val : String);
begin
    DxfAdd(IntToStr(Code));
    DxfAdd(Val);
end;

procedure WriteLine(const LName : String; X1, Y1, X2, Y2 : TCoord);
begin
    DxfPair(0, 'LINE');
    DxfPair(5, NextHandle);
    DxfPair(8, LName);
    DxfPair(10, MMX(X1));
    DxfPair(20, MMY(Y1));
    DxfPair(30, '0.0');
    DxfPair(11, MMX(X2));
    DxfPair(21, MMY(Y2));
    DxfPair(31, '0.0');
end;

procedure WriteArc(const LName : String; CX, CY, Radius : TCoord; StartDeg, EndDeg : Double);
begin
    if Radius <= 0 then Exit;
    DxfPair(0, 'ARC');
    DxfPair(5, NextHandle);
    DxfPair(8, LName);
    DxfPair(10, MMX(CX));
    DxfPair(20, MMY(CY));
    DxfPair(30, '0.0');
    DxfPair(40, MMR(Radius));
    DxfPair(50, FormatFloat('0.######', StartDeg));
    DxfPair(51, FormatFloat('0.######', EndDeg));
end;

procedure WriteCircle(const LName : String; CX, CY, Radius : TCoord);
begin
    if Radius <= 0 then Exit;
    DxfPair(0, 'CIRCLE');
    DxfPair(5, NextHandle);
    DxfPair(8, LName);
    DxfPair(10, MMX(CX));
    DxfPair(20, MMY(CY));
    DxfPair(30, '0.0');
    DxfPair(40, MMR(Radius));
end;

function IsCopperLayer(ALayer : TLayer) : Boolean;
begin
    Result := (ALayer = eTopLayer) or (ALayer = eBottomLayer) or
              ((ALayer >= eMidLayer1) and (ALayer <= eMidLayer30));
end;

function IsDefaultChecked(ALayer : TLayer) : Boolean;
begin
    Result := IsCopperLayer(ALayer) or
              (ALayer = eTopOverlay) or (ALayer = eBottomOverlay);
end;

procedure AddLayerIfMissing(ALayer : TLayer);
begin
    if LayerIds.IndexOf(IntToStr(ALayer)) < 0 then
    begin
        LayerItems.Add(Layer2String(ALayer));
        LayerIds.Add(IntToStr(ALayer));
    end;
end;

procedure CollectBoardLayers;
var
    LS : IPCB_LayerObject;
    Stack : IPCB_LayerStack;
    Name : String;
    Id : TLayer;
begin
    LayerItems.Clear;
    LayerIds.Clear;
    LayerItems.Add('Отверстия (HOLES) — круги сверловки');
    LayerIds.Add('HOLES');

    { Сигнальные / плоскости через V7 stack, если есть. }
    try
        Stack := Board.LayerStack_V7;
    except
        Stack := nil;
    end;

    if Stack <> nil then
    begin
        LS := Stack.First(eLayerClass_Electrical);
        while LS <> nil do
        begin
            Id := LS.LayerID;
            Name := Layer2String(Id);
            if LayerIds.IndexOf(IntToStr(Id)) < 0 then
            begin
                LayerItems.Add(Name);
                LayerIds.Add(IntToStr(Id));
            end;
            LS := Stack.Next(eLayerClass_Electrical, LS);
        end;
    end;

    AddLayerIfMissing(eTopLayer);
    AddLayerIfMissing(eBottomLayer);
    AddLayerIfMissing(eTopOverlay);
    AddLayerIfMissing(eBottomOverlay);
    AddLayerIfMissing(eTopSolder);
    AddLayerIfMissing(eBottomSolder);
    AddLayerIfMissing(eTopPaste);
    AddLayerIfMissing(eBottomPaste);
    AddLayerIfMissing(eKeepOutLayer);
    AddLayerIfMissing(eMultiLayer);
    AddLayerIfMissing(eMechanical1);
    AddLayerIfMissing(eMechanical2);
    AddLayerIfMissing(eMechanical3);
    AddLayerIfMissing(eMechanical4);
    AddLayerIfMissing(eMechanical13);
    AddLayerIfMissing(eMechanical15);
end;

procedure ExportTrackOutline(const LName : String; T : IPCB_Track);
var
    dx, dy, Len, nx, ny, hw : Double;
    L1x1, L1y1, L1x2, L1y2 : TCoord;
    L2x1, L2y1, L2x2, L2y2 : TCoord;
    Ang : Double;
    StartDeg, EndDeg : Double;
begin
    dx := T.X2 - T.X1;
    dy := T.Y2 - T.Y1;
    Len := Sqrt(dx * dx + dy * dy);
    if Len < 1 then Exit;
    nx := -dy / Len;
    ny := dx / Len;
    hw := T.Width / 2.0;

    L1x1 := Round(T.X1 + nx * hw);
    L1y1 := Round(T.Y1 + ny * hw);
    L1x2 := Round(T.X2 + nx * hw);
    L1y2 := Round(T.Y2 + ny * hw);
    L2x1 := Round(T.X1 - nx * hw);
    L2y1 := Round(T.Y1 - ny * hw);
    L2x2 := Round(T.X2 - nx * hw);
    L2y2 := Round(T.Y2 - ny * hw);

    WriteLine(LName, L1x1, L1y1, L1x2, L1y2);
    WriteLine(LName, L2x1, L2y1, L2x2, L2y2);

    { Круглые крышки: полуокружности на концах, перпендикуляр к направлению. }
    Ang := ArcTan2(dy, dx) * 180.0 / PiValue;
    { На конце 1 (старт): полукруг с внешней стороны, охватывающий 180°. }
    StartDeg := Ang + 90;
    EndDeg := Ang + 270;
    WriteArc(LName, T.X1, T.Y1, T.Width div 2, StartDeg, EndDeg);
    StartDeg := Ang - 90;
    EndDeg := Ang + 90;
    WriteArc(LName, T.X2, T.Y2, T.Width div 2, StartDeg, EndDeg);
end;

procedure ExportArcOutline(const LName : String; A : IPCB_Arc);
var
    hw, RIn, ROut : TCoord;
    Sa, Ea : Double;
    C1x, C1y, C2x, C2y : TCoord;
    C3x, C3y, C4x, C4y : TCoord;
begin
    hw := A.LineWidth div 2;
    if hw < 0 then hw := 0;
    ROut := A.Radius + hw;
    RIn := A.Radius - hw;
    Sa := A.StartAngle;
    Ea := A.EndAngle;

    WriteArc(LName, A.XCenter, A.YCenter, ROut, Sa, Ea);
    if RIn > 0 then
        WriteArc(LName, A.XCenter, A.YCenter, RIn, Sa, Ea)
    else
        WriteCircle(LName, A.XCenter, A.YCenter, hw);

    { Радиальные соединения на торцах дуги. }
    C1x := Round(A.XCenter + ROut * Cos(Sa * PiValue / 180));
    C1y := Round(A.YCenter + ROut * Sin(Sa * PiValue / 180));
    C2x := Round(A.XCenter + Max(RIn, 0) * Cos(Sa * PiValue / 180));
    C2y := Round(A.YCenter + Max(RIn, 0) * Sin(Sa * PiValue / 180));
    C3x := Round(A.XCenter + ROut * Cos(Ea * PiValue / 180));
    C3y := Round(A.YCenter + ROut * Sin(Ea * PiValue / 180));
    C4x := Round(A.XCenter + Max(RIn, 0) * Cos(Ea * PiValue / 180));
    C4y := Round(A.YCenter + Max(RIn, 0) * Sin(Ea * PiValue / 180));
    if RIn > 0 then
    begin
        WriteLine(LName, C1x, C1y, C2x, C2y);
        WriteLine(LName, C3x, C3y, C4x, C4y);
    end;
end;

procedure ExportPadOutline(const LName : String; Pad : IPCB_Pad; ALayer : TLayer);
var
    SX, SY, X, Y : TCoord;
    Shape : TShape;
    CR : Integer;
    i : Integer;
    Ang, R : Double;
    Px, Py, Qx, Qy : TCoord;
    Rot : Double;
begin
    { Размер площадки на данном слое. Для SMT — Top/Bottom size. }
    X := Pad.X;
    Y := Pad.Y;
    try
        SX := Pad.TopXSize;
        SY := Pad.TopYSize;
        if (ALayer = eBottomLayer) or (Pad.Layer = eBottomLayer) then
        begin
            SX := Pad.BotXSize;
            SY := Pad.BotYSize;
        end;
    except
        SX := Pad.XSize;
        SY := Pad.YSize;
    end;

    if (SX <= 0) or (SY <= 0) then Exit;

    try
        Shape := Pad.Mode;
    except
        Shape := eSimple;
    end;

    { Круглая площадка: если размеры равны и форма круглая. }
    try
        if Pad.TopShape = eRounded then
        begin
            if Abs(SX - SY) < 10 then
            begin
                WriteCircle(LName, X, Y, SX div 2);
                Exit;
            end;
        end;
    except
    end;

    try
        if (Pad.TopShape = eRound) or (Pad.Shape = eRound) then
        begin
            WriteCircle(LName, X, Y, SX div 2);
            Exit;
        end;
    except
    end;

    { Прямоугольник / скруглённый прямоугольник — bounding box с опциональными галтелями. }
    CR := 0;
    try
        CR := Pad.CornerRadiusTop;
    except
        CR := 0;
    end;

    if CR > 0 then
    begin
        WriteLine(LName, X - SX div 2 + CR, Y - SY div 2, X + SX div 2 - CR, Y - SY div 2);
        WriteLine(LName, X + SX div 2, Y - SY div 2 + CR, X + SX div 2, Y + SY div 2 - CR);
        WriteLine(LName, X + SX div 2 - CR, Y + SY div 2, X - SX div 2 + CR, Y + SY div 2);
        WriteLine(LName, X - SX div 2, Y + SY div 2 - CR, X - SX div 2, Y - SY div 2 + CR);
        WriteArc(LName, X - SX div 2 + CR, Y - SY div 2 + CR, CR, 180, 270);
        WriteArc(LName, X + SX div 2 - CR, Y - SY div 2 + CR, CR, 270, 0);
        WriteArc(LName, X + SX div 2 - CR, Y + SY div 2 - CR, CR, 0, 90);
        WriteArc(LName, X - SX div 2 + CR, Y + SY div 2 - CR, CR, 90, 180);
    end
    else
    begin
        { Октагон: 8 сторон, иначе прямоугольник. }
        try
            if (Pad.TopShape = eOctagonal) or (Pad.Shape = eOctagonal) then
            begin
                R := SX / 2.0;
                for i := 0 to 7 do
                begin
                    Ang := (22.5 + i * 45) * PiValue / 180;
                    Px := Round(X + R * Cos(Ang));
                    Py := Round(Y + R * Sin(Ang));
                    Ang := (22.5 + (i + 1) * 45) * PiValue / 180;
                    Qx := Round(X + R * Cos(Ang));
                    Qy := Round(Y + R * Sin(Ang));
                    WriteLine(LName, Px, Py, Qx, Qy);
                end;
                Exit;
            end;
        except
        end;

        WriteLine(LName, X - SX div 2, Y - SY div 2, X + SX div 2, Y - SY div 2);
        WriteLine(LName, X + SX div 2, Y - SY div 2, X + SX div 2, Y + SY div 2);
        WriteLine(LName, X + SX div 2, Y + SY div 2, X - SX div 2, Y + SY div 2);
        WriteLine(LName, X - SX div 2, Y + SY div 2, X - SX div 2, Y - SY div 2);
    end;
end;

procedure ExportViaOutline(const LName : String; Via : IPCB_Via; ALayer : TLayer);
var
    Outer : TCoord;
begin
    try
        Outer := Via.Size;
    except
        Outer := Via.HoleSize + MMsToCoord(0.3);
    end;
    WriteCircle(LName, Via.X, Via.Y, Outer div 2);
end;

procedure ExportFillOutline(const LName : String; Fill : IPCB_Fill);
begin
    WriteLine(LName, Fill.X1Location, Fill.Y1Location, Fill.X2Location, Fill.Y1Location);
    WriteLine(LName, Fill.X2Location, Fill.Y1Location, Fill.X2Location, Fill.Y2Location);
    WriteLine(LName, Fill.X2Location, Fill.Y2Location, Fill.X1Location, Fill.Y2Location);
    WriteLine(LName, Fill.X1Location, Fill.Y2Location, Fill.X1Location, Fill.Y1Location);
end;

procedure ExportContour(const LName : String; Contour : IPCB_Contour);
var
    i, n : Integer;
    X1, Y1, X2, Y2 : TCoord;
begin
    if Contour = nil then Exit;
    try
        n := Contour.Count;
    except
        n := 0;
    end;
    if n < 2 then Exit;
    for i := 0 to n - 1 do
    begin
        try
            X1 := Contour.X[i];
            Y1 := Contour.Y[i];
            if i = n - 1 then
            begin
                X2 := Contour.X[0];
                Y2 := Contour.Y[0];
            end
            else
            begin
                X2 := Contour.X[i + 1];
                Y2 := Contour.Y[i + 1];
            end;
            WriteLine(LName, X1, Y1, X2, Y2);
        except
        end;
    end;
end;

procedure ExportRegionOutline(const LName : String; Rgn : IPCB_Region);
var
    G : IPCB_GeometricPolygon;
    i : Integer;
begin
    try
        G := Rgn.GetGeometricPolygon;
        if G <> nil then
        begin
            for i := 0 to G.Count - 1 do
                ExportContour(LName, G.Contour[i]);
            Exit;
        end;
    except
    end;
    try
        ExportContour(LName, Rgn.MainContour);
    except
    end;
end;

procedure ExportPolygonOutline(const LName : String; Poly : IPCB_Polygon);
var
    i, n : Integer;
    Seg : TPolySegment;
    PrevX, PrevY, NX, NY : TCoord;
begin
    try
        n := Poly.PointCount;
    except
        n := 0;
    end;
    if n < 2 then Exit;

    for i := 0 to n - 1 do
    begin
        try
            Seg := Poly.Segments[i];
            if i = 0 then
            begin
                PrevX := Seg.vx;
                PrevY := Seg.vy;
            end;

            if i = n - 1 then
            begin
                NX := Poly.Segments[0].vx;
                NY := Poly.Segments[0].vy;
            end
            else
            begin
                NX := Poly.Segments[i + 1].vx;
                NY := Poly.Segments[i + 1].vy;
            end;

            if Seg.Kind = ePolySegmentArc then
                WriteArc(LName, Seg.cx, Seg.cy, Seg.Radius, Seg.sa1, Seg.sa2)
            else
                WriteLine(LName, Seg.vx, Seg.vy, NX, NY);
        except
            { Сегмент недоступен — пропускаем. }
        end;
    end;
end;

function PrimitiveOnLayer(Prim : IPCB_Primitive; ALayer : TLayer) : Boolean;
begin
    Result := False;
    if Prim = nil then Exit;
    if Prim.Layer = ALayer then
    begin
        Result := True;
        Exit;
    end;
    if Prim.ObjectId = ePadObject then
    begin
        if (Prim.Layer = eMultiLayer) and IsCopperLayer(ALayer) then
            Result := True;
        if (ALayer = eMultiLayer) and (Prim.Layer = eMultiLayer) then
            Result := True;
    end;
    if Prim.ObjectId = eViaObject then
    begin
        if IsCopperLayer(ALayer) or (ALayer = eMultiLayer) then
        begin
            try
                Result := Prim.IntersectLayer(ALayer);
            except
                Result := True;
            end;
        end;
    end;
end;

procedure ExportHolesLayer;
var
    Iter : IPCB_BoardIterator;
    Prim : IPCB_Primitive;
    LName : String;
begin
    LName := 'HOLES';
    Iter := Board.BoardIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(ePadObject, eViaObject));
    Iter.AddFilter_LayerSet(AllLayers);
    Iter.AddFilter_Method(eProcessAll);
    Prim := Iter.FirstPCBObject;
    while Prim <> nil do
    begin
        if Prim.HoleSize > 0 then
        begin
            if Prim.ObjectId = ePadObject then
                WriteCircle(LName, Prim.X, Prim.Y, Prim.HoleSize div 2)
            else
                WriteCircle(LName, Prim.X, Prim.Y, Prim.HoleSize div 2);
        end;
        Prim := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

procedure ExportLayer(ALayer : TLayer);
var
    Iter : IPCB_BoardIterator;
    Prim : IPCB_Primitive;
    LName : String;
begin
    LName := DxfLayerName(ALayer);
    Iter := Board.BoardIterator_Create;
    Iter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject, ePadObject, eViaObject,
                                   eFillObject, eRegionObject, ePolyObject));
    Iter.AddFilter_LayerSet(AllLayers);
    Iter.AddFilter_Method(eProcessAll);

    Prim := Iter.FirstPCBObject;
    while Prim <> nil do
    begin
        if PrimitiveOnLayer(Prim, ALayer) then
        begin
            case Prim.ObjectId of
                eTrackObject  : ExportTrackOutline(LName, Prim);
                eArcObject    : ExportArcOutline(LName, Prim);
                ePadObject    : ExportPadOutline(LName, Prim, ALayer);
                eViaObject    : ExportViaOutline(LName, Prim, ALayer);
                eFillObject   : ExportFillOutline(LName, Prim);
                eRegionObject : ExportRegionOutline(LName, Prim);
                ePolyObject   : ExportPolygonOutline(LName, Prim);
            end;
        end;
        Prim := Iter.NextPCBObject;
    end;
    Board.BoardIterator_Destroy(Iter);
end;

procedure WriteDxfHeader(SelectedNames : TStringList);
var
    i : Integer;
begin
    HandleCount := 100;
    DxfPair(0, 'SECTION');
    DxfPair(2, 'HEADER');
    DxfPair(9, '$ACADVER');
    DxfPair(1, 'AC1009');
    DxfPair(9, '$INSUNITS');
    DxfPair(70, '4'); { миллиметры }
    DxfPair(0, 'ENDSEC');

    DxfPair(0, 'SECTION');
    DxfPair(2, 'TABLES');
    DxfPair(0, 'TABLE');
    DxfPair(2, 'LAYER');
    DxfPair(70, IntToStr(SelectedNames.Count + 1));
    DxfPair(0, 'LAYER');
    DxfPair(2, '0');
    DxfPair(70, '0');
    DxfPair(62, '7');
    DxfPair(6, 'CONTINUOUS');
    for i := 0 to SelectedNames.Count - 1 do
    begin
        DxfPair(0, 'LAYER');
        DxfPair(2, SelectedNames[i]);
        DxfPair(70, '0');
        DxfPair(62, IntToStr((i mod 6) + 1));
        DxfPair(6, 'CONTINUOUS');
    end;
    DxfPair(0, 'ENDTAB');
    DxfPair(0, 'ENDSEC');

    DxfPair(0, 'SECTION');
    DxfPair(2, 'ENTITIES');
end;

procedure WriteDxfFooter;
begin
    DxfPair(0, 'ENDSEC');
    DxfPair(0, 'EOF');
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


procedure DoExport(FileName : String);
var
    i : Integer;
    ALayer : TLayer;
    Names : TStringList;
begin
    DxfLines := TStringList.Create;
    Names := TStringList.Create;
    try
        for i := 0 to CheckListLayers.Items.Count - 1 do
            if CheckListLayers.Checked[i] then
            begin
                if LayerIds[i] = 'HOLES' then
                    Names.Add('HOLES')
                else
                    Names.Add(DxfLayerName(StrToInt(LayerIds[i])));
            end;

        WriteDxfHeader(Names);

        for i := 0 to CheckListLayers.Items.Count - 1 do
        begin
            if CheckListLayers.Checked[i] then
            begin
                if LayerIds[i] = 'HOLES' then
                    ExportHolesLayer
                else
                begin
                    ALayer := StrToInt(LayerIds[i]);
                    ExportLayer(ALayer);
                end;
            end;
        end;

        WriteDxfFooter;
        DxfLines.SaveToFile(FileName);
        ShowInfo('DXF сохранён:' + sLineBreak + FileName + sLineBreak + sLineBreak +
                 'Слоёв: ' + IntToStr(Names.Count) + sLineBreak +
                 'Текст шелкографии не экспортирован (см. README).',
                 'Экспорт DXF');
    finally
        Names.Free;
        DxfLines.Free;
    end;
end;

procedure TFormDxf.FormDxfShow(Sender: TObject);
var
    i : Integer;
    ALayer : TLayer;
begin
    try
        CS_TryLoadHelpImage('DxfExport.bmp', 'DxfExport.png');
    except
    end;
    CheckListLayers.Items.Clear;
    Board := nil;
    try
        if PCBServer <> nil then
            Board := PCBServer.GetCurrentPCBBoard;
    except
        Board := nil;
    end;
    if (Board = nil) or (LayerItems = nil) then Exit;
    CollectBoardLayers;
    for i := 0 to LayerItems.Count - 1 do
    begin
        CheckListLayers.Items.Add(LayerItems[i]);
        if LayerIds[i] = 'HOLES' then
            CheckListLayers.Checked[i] := True
        else
        begin
            ALayer := StrToInt(LayerIds[i]);
            CheckListLayers.Checked[i] := IsDefaultChecked(ALayer);
        end;
    end;
end;

procedure TFormDxf.ButtonAllClick(Sender: TObject);
var
    i : Integer;
begin
    for i := 0 to CheckListLayers.Items.Count - 1 do
        CheckListLayers.Checked[i] := True;
end;

procedure TFormDxf.ButtonNoneClick(Sender: TObject);
var
    i : Integer;
begin
    for i := 0 to CheckListLayers.Items.Count - 1 do
        CheckListLayers.Checked[i] := False;
end;

procedure TFormDxf.ButtonCopperClick(Sender: TObject);
var
    i : Integer;
    ALayer : TLayer;
begin
    for i := 0 to CheckListLayers.Items.Count - 1 do
    begin
        if LayerIds[i] = 'HOLES' then
            CheckListLayers.Checked[i] := False
        else
        begin
            ALayer := StrToInt(LayerIds[i]);
            CheckListLayers.Checked[i] := IsCopperLayer(ALayer);
        end;
    end;
end;

procedure TFormDxf.ButtonOKClick(Sender: TObject);
var
    SaveDlg : TSaveDialog;
    i, n : Integer;
begin
    if Board = nil then
    begin
        ShowError('Open a PCB document.');
        Exit;
    end;
    n := 0;
    for i := 0 to CheckListLayers.Items.Count - 1 do
        if CheckListLayers.Checked[i] then Inc(n);
    if n = 0 then
    begin
        ShowWarning('Выберите хотя бы один слой.');
        Exit;
    end;

    SaveDlg := TSaveDialog.Create(nil);
    try
        SaveDlg.Title := 'Сохранить DXF';
        SaveDlg.Filter := 'DXF (*.dxf)|*.dxf';
        SaveDlg.DefaultExt := 'dxf';
        SaveDlg.FileName := 'board_outlines.dxf';
        if SaveDlg.Execute then
        begin
            FormDxf.Close;
            DoExport(SaveDlg.FileName);
        end;
    finally
        SaveDlg.Free;
    end;
end;

procedure TFormDxf.ButtonCancelClick(Sender: TObject);
begin
    FormDxf.Close;
end;

procedure Start;
begin
    LayerItems := TStringList.Create;
    LayerIds := TStringList.Create;
    try
        FormDxf.ShowModal;
    finally
        LayerItems.Free;
        LayerIds.Free;
        LayerItems := nil;
        LayerIds := nil;
    end;
end;

procedure _Start;
begin
    Start;
end;
