{..............................................................................}
{ DxfOutlineExport.pas                                                          }
{ Экспорт слоёв PCB в ASCII DXF R12: контуры меди LINE/ARC, шелкография,       }
{ отверстия CIRCLE на отдельном слое HOLES. Без ExportDXF Altium.              }
{..............................................................................}

const
    DxfPiValue = 3.141592653589793;

var
    DxfBoard       : IPCB_Board;
    DxfLines    : TStringList;
    HandleCount : Integer;
    LayerItems  : TStringList; { имя для чеклиста = Layer2String }
    LayerIds    : TStringList; { параллельный список IntToStr(TLayer) }

{ Run Script: choose procedure StartDxfOutlineExport (project compiles only this .pas). }
procedure StartDxfOutlineExport; forward;
procedure _StartDxfOutlineExport; forward;
procedure TFormDxf.FormDxfShow(DxfSender: TObject); forward;
procedure TFormDxf.ButtonOKClick(DxfSender: TObject); forward;
procedure TFormDxf.ButtonCancelClick(DxfSender: TObject); forward;
procedure TFormDxf.ButtonAllClick(DxfSender: TObject); forward;
procedure TFormDxf.ButtonNoneClick(DxfSender: TObject); forward;
procedure TFormDxf.ButtonCopperClick(DxfSender: TObject); forward;
procedure DxfShowBox(const Msg : String; Flags : Integer); forward;

function MMX(DxfX : TCoord) : String;
begin
    Result := FormatFloat('0.######', CoordToMMs(DxfX - DxfBoard.XOrigin));
end;

function MMY(DxfY : TCoord) : String;
begin
    Result := FormatFloat('0.######', CoordToMMs(DxfY - DxfBoard.YOrigin));
end;

function MMR(DxfR : TCoord) : String;
begin
    Result := FormatFloat('0.######', CoordToMMs(DxfR));
end;

function DxfLayerName(DxfALayer : TLayer) : String;
begin
    { DXF is ASCII — no UTF-8 Russian (garbles in AutoCAD). }
    if DxfALayer = eTopLayer then Result := 'TOP_COPPER'
    else if DxfALayer = eBottomLayer then Result := 'BOTTOM_COPPER'
    else if DxfALayer = eTopOverlay then Result := 'TOP_SILK'
    else if DxfALayer = eBottomOverlay then Result := 'BOTTOM_SILK'
    else if DxfALayer = eTopSolder then Result := 'TOP_MASK'
    else if DxfALayer = eBottomSolder then Result := 'BOTTOM_MASK'
    else if DxfALayer = eTopPaste then Result := 'TOP_PASTE'
    else if DxfALayer = eBottomPaste then Result := 'BOTTOM_PASTE'
    else if DxfALayer = eKeepOutLayer then Result := 'KEEPOUT'
    else if DxfALayer = eMultiLayer then Result := 'MULTI'
    else if DxfALayer = eMechanical1 then Result := 'MECH1'
    else if DxfALayer = eMechanical2 then Result := 'MECH2'
    else if DxfALayer = eMechanical3 then Result := 'MECH3'
    else if DxfALayer = eMechanical4 then Result := 'MECH4'
    else if DxfALayer = eMechanical13 then Result := 'MECH13'
    else if DxfALayer = eMechanical15 then Result := 'MECH15'
    else if (DxfALayer >= eMidLayer1) and (DxfALayer <= eMidLayer30) then
        Result := 'MID_' + IntToStr(DxfALayer - eMidLayer1 + 1)
    else
        Result := 'LAYER_' + IntToStr(DxfALayer);
end;

function NextHandle : String;
begin
    Inc(HandleCount);
    Result := IntToHex(HandleCount, 2);
end;

procedure DxfAdd(const DxfS : String);
begin
    DxfLines.Add(DxfS);
end;

procedure DxfPair(Code : Integer; const DxfVal : String);
begin
    DxfAdd(IntToStr(Code));
    DxfAdd(DxfVal);
end;

procedure WriteLine(const LName : String; DxfX1, DxfY1, DxfX2, DxfY2 : TCoord);
begin
    DxfPair(0, 'LINE');
    DxfPair(5, NextHandle);
    DxfPair(8, LName);
    DxfPair(10, MMX(DxfX1));
    DxfPair(20, MMY(DxfY1));
    DxfPair(30, '0.0');
    DxfPair(11, MMX(DxfX2));
    DxfPair(21, MMY(DxfY2));
    DxfPair(31, '0.0');
end;

procedure WriteArc(const LName : String; DxfCX, DxfCY, DxfRadius : TCoord; StartDeg, EndDeg : Double);
begin
    if DxfRadius <= 0 then Exit;
    DxfPair(0, 'ARC');
    DxfPair(5, NextHandle);
    DxfPair(8, LName);
    DxfPair(10, MMX(DxfCX));
    DxfPair(20, MMY(DxfCY));
    DxfPair(30, '0.0');
    DxfPair(40, MMR(DxfRadius));
    DxfPair(50, FormatFloat('0.######', StartDeg));
    DxfPair(51, FormatFloat('0.######', EndDeg));
end;

procedure WriteCircle(const LName : String; DxfCX, DxfCY, DxfRadius : TCoord);
begin
    if DxfRadius <= 0 then Exit;
    DxfPair(0, 'CIRCLE');
    DxfPair(5, NextHandle);
    DxfPair(8, LName);
    DxfPair(10, MMX(DxfCX));
    DxfPair(20, MMY(DxfCY));
    DxfPair(30, '0.0');
    DxfPair(40, MMR(DxfRadius));
end;

function IsCopperLayer(DxfALayer : TLayer) : Boolean;
begin
    Result := (DxfALayer = eTopLayer) or (DxfALayer = eBottomLayer) or
              ((DxfALayer >= eMidLayer1) and (DxfALayer <= eMidLayer30));
end;

function IsDefaultChecked(DxfALayer : TLayer) : Boolean;
begin
    Result := IsCopperLayer(DxfALayer) or
              (DxfALayer = eTopOverlay) or (DxfALayer = eBottomOverlay);
end;

procedure AddLayerIfMissing(DxfALayer : TLayer);
begin
    if LayerIds.IndexOf(IntToStr(DxfALayer)) < 0 then
    begin
        LayerItems.Add(DxfLayerName(DxfALayer));
        LayerIds.Add(IntToStr(DxfALayer));
    end;
end;

procedure CollectBoardLayers;
var
    DxfLS : IPCB_LayerObject;
    DxfStack : IPCB_LayerStack;
    DxfId : TLayer;
begin
    LayerItems.Clear;
    LayerIds.Clear;
    LayerItems.Add('HOLES');
    LayerIds.Add('HOLES');

    { Сигнальные / плоскости через V7 stack, если есть. }
    try
        DxfStack := DxfBoard.LayerStack_V7;
    except
        DxfStack := nil;
    end;

    if DxfStack <> nil then
    begin
        DxfLS := DxfStack.First(eLayerClass_Electrical);
        while DxfLS <> nil do
        begin
            DxfId := DxfLS.LayerID;
            if LayerIds.IndexOf(IntToStr(DxfId)) < 0 then
            begin
                LayerItems.Add(DxfLayerName(DxfId));
                LayerIds.Add(IntToStr(DxfId));
            end;
            DxfLS := DxfStack.Next(eLayerClass_Electrical, DxfLS);
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

{ Смещение в мм, затем обратно в TCoord — без Round(абсолютная координата) (32-bit overflow). }
function DxfOff(Base : TCoord; OffMM : Double) : TCoord;
begin
    Result := Base + MMsToCoord(OffMM);
end;

function DxfAtan2(DxfY, DxfX : Double) : Double;
begin
    if (DxfX = 0) and (DxfY = 0) then
        Result := 0
    else
        Result := ArcTan2(DxfY, DxfX);
end;

procedure ExportTrackOutline(const LName : String; DxfT : IPCB_Track);
var
    Dxfdx, Dxfdy, Len, nx, ny, HwMM, Ang : Double;
    CapR : TCoord;
    L1x1, L1y1, L1x2, L1y2 : TCoord;
    L2x1, L2y1, L2x2, L2y2 : TCoord;
begin
    { Только контур ширины: две параллели ±W/2 и круглые крышки (как у отверстия). }
    if DxfT.Width < 1 then Exit;
    Dxfdx := CoordToMMs(DxfT.X2 - DxfT.X1);
    Dxfdy := CoordToMMs(DxfT.Y2 - DxfT.Y1);
    Len := Sqrt(Dxfdx * Dxfdx + Dxfdy * Dxfdy);
    if Len < 0.0001 then Exit;
    nx := -Dxfdy / Len;
    ny := Dxfdx / Len;
    HwMM := CoordToMMs(DxfT.Width) / 2.0;
    if HwMM <= 0 then Exit;

    L1x1 := DxfOff(DxfT.X1, nx * HwMM);
    L1y1 := DxfOff(DxfT.Y1, ny * HwMM);
    L1x2 := DxfOff(DxfT.X2, nx * HwMM);
    L1y2 := DxfOff(DxfT.Y2, ny * HwMM);
    L2x1 := DxfOff(DxfT.X1, -nx * HwMM);
    L2y1 := DxfOff(DxfT.Y1, -ny * HwMM);
    L2x2 := DxfOff(DxfT.X2, -nx * HwMM);
    L2y2 := DxfOff(DxfT.Y2, -ny * HwMM);

    WriteLine(LName, L1x1, L1y1, L1x2, L1y2);
    WriteLine(LName, L2x1, L2y1, L2x2, L2y2);

    CapR := DxfT.Width div 2;
    if CapR < 1 then Exit;
    Ang := DxfAtan2(Dxfdy, Dxfdx) * 180.0 / DxfPiValue;
    WriteArc(LName, DxfT.X1, DxfT.Y1, CapR, Ang + 90, Ang + 270);
    WriteArc(LName, DxfT.X2, DxfT.Y2, CapR, Ang - 90, Ang + 90);
end;

procedure ExportArcOutline(const LName : String; DxfA : IPCB_Arc);
var
    hw, RIn, ROut : TCoord;
    DxfSa, DxfEa, Ca, Sa : Double;
    C1x, C1y, C2x, C2y : TCoord;
    C3x, C3y, C4x, C4y : TCoord;
    RoutMM, RinMM : Double;
begin
    if DxfA.LineWidth < 1 then Exit;
    hw := DxfA.LineWidth div 2;
    if hw < 0 then hw := 0;
    ROut := DxfA.Radius + hw;
    RIn := DxfA.Radius - hw;
    DxfSa := DxfA.StartAngle;
    DxfEa := DxfA.EndAngle;

    WriteArc(LName, DxfA.XCenter, DxfA.YCenter, ROut, DxfSa, DxfEa);
    if RIn > 0 then
        WriteArc(LName, DxfA.XCenter, DxfA.YCenter, RIn, DxfSa, DxfEa)
    else
        WriteCircle(LName, DxfA.XCenter, DxfA.YCenter, hw);

    if RIn <= 0 then Exit;
    RoutMM := CoordToMMs(ROut);
    RinMM := CoordToMMs(RIn);
    Ca := Cos(DxfSa * DxfPiValue / 180);
    Sa := Sin(DxfSa * DxfPiValue / 180);
    C1x := DxfOff(DxfA.XCenter, RoutMM * Ca);
    C1y := DxfOff(DxfA.YCenter, RoutMM * Sa);
    C2x := DxfOff(DxfA.XCenter, RinMM * Ca);
    C2y := DxfOff(DxfA.YCenter, RinMM * Sa);
    Ca := Cos(DxfEa * DxfPiValue / 180);
    Sa := Sin(DxfEa * DxfPiValue / 180);
    C3x := DxfOff(DxfA.XCenter, RoutMM * Ca);
    C3y := DxfOff(DxfA.YCenter, RoutMM * Sa);
    C4x := DxfOff(DxfA.XCenter, RinMM * Ca);
    C4y := DxfOff(DxfA.YCenter, RinMM * Sa);
    WriteLine(LName, C1x, C1y, C2x, C2y);
    WriteLine(LName, C3x, C3y, C4x, C4y);
end;

procedure ExportPadOutline(const LName : String; DxfPad : IPCB_Pad; DxfALayer : TLayer);
var
    RR : TCoordRect;
    SX, SY, DxfX, DxfY : TCoord;
begin
    { Не XSize/YSize/TopXSize — в этом диалекте нет. Контур = BoundingRectangle (как у шелкографии). }
    if DxfALayer = eMultiLayer then Exit;
    try
        RR := DxfPad.BoundingRectangle;
    except
        Exit;
    end;
    SX := RR.Right - RR.Left;
    SY := RR.Top - RR.Bottom;
    if (SX <= 0) or (SY <= 0) then Exit;
    DxfX := (RR.Left + RR.Right) div 2;
    DxfY := (RR.Bottom + RR.Top) div 2;
    if Abs(SX - SY) < MMsToCoord(0.05) then
    begin
        WriteCircle(LName, DxfX, DxfY, SX div 2);
        Exit;
    end;
    WriteLine(LName, RR.Left, RR.Bottom, RR.Right, RR.Bottom);
    WriteLine(LName, RR.Right, RR.Bottom, RR.Right, RR.Top);
    WriteLine(LName, RR.Right, RR.Top, RR.Left, RR.Top);
    WriteLine(LName, RR.Left, RR.Top, RR.Left, RR.Bottom);
end;

procedure ExportViaOutline(const LName : String; DxfVia : IPCB_Via; DxfALayer : TLayer);
var
    Outer : TCoord;
begin
    try
        Outer := DxfVia.Size;
    except
        Outer := DxfVia.HoleSize + MMsToCoord(0.3);
    end;
    WriteCircle(LName, DxfVia.X, DxfVia.Y, Outer div 2);
end;

procedure ExportFillOutline(const LName : String; DxfFill : IPCB_Fill);
begin
    WriteLine(LName, DxfFill.X1Location, DxfFill.Y1Location, DxfFill.X2Location, DxfFill.Y1Location);
    WriteLine(LName, DxfFill.X2Location, DxfFill.Y1Location, DxfFill.X2Location, DxfFill.Y2Location);
    WriteLine(LName, DxfFill.X2Location, DxfFill.Y2Location, DxfFill.X1Location, DxfFill.Y2Location);
    WriteLine(LName, DxfFill.X1Location, DxfFill.Y2Location, DxfFill.X1Location, DxfFill.Y1Location);
end;

procedure ExportContour(const LName : String; Contour : IPCB_Contour);
var
    Dxfi, Dxfn : Integer;
    DxfX1, DxfY1, DxfX2, DxfY2 : TCoord;
begin
    if Contour = nil then Exit;
    try
        Dxfn := Contour.Count;
    except
        Dxfn := 0;
    end;
    if Dxfn < 2 then Exit;
    for Dxfi := 0 to Dxfn - 1 do
    begin
        try
            DxfX1 := Contour.X[Dxfi];
            DxfY1 := Contour.Y[Dxfi];
            if Dxfi = Dxfn - 1 then
            begin
                DxfX2 := Contour.X[0];
                DxfY2 := Contour.Y[0];
            end
            else
            begin
                DxfX2 := Contour.X[Dxfi + 1];
                DxfY2 := Contour.Y[Dxfi + 1];
            end;
            WriteLine(LName, DxfX1, DxfY1, DxfX2, DxfY2);
        except
        end;
    end;
end;

procedure ExportRegionOutline(const LName : String; Rgn : IPCB_Region);
var
    G : IPCB_GeometricPolygon;
    Dxfi : Integer;
begin
    try
        G := Rgn.GetGeometricPolygon;
        if G <> nil then
        begin
            for Dxfi := 0 to G.Count - 1 do
                ExportContour(LName, G.Contour[Dxfi]);
            Exit;
        end;
    except
    end;
    try
        ExportContour(LName, Rgn.MainContour);
    except
    end;
end;

procedure ExportPolygonOutline(const LName : String; DxfPoly : IPCB_Polygon);
var
    Dxfi, Dxfn : Integer;
    DxfSeg : TPolySegment;
    PrevX, PrevY, NX, NY : TCoord;
begin
    try
        Dxfn := DxfPoly.PointCount;
    except
        Dxfn := 0;
    end;
    if Dxfn < 2 then Exit;

    for Dxfi := 0 to Dxfn - 1 do
    begin
        try
            DxfSeg := DxfPoly.Segments[Dxfi];
            if Dxfi = 0 then
            begin
                PrevX := DxfSeg.vx;
                PrevY := DxfSeg.vy;
            end;

            if Dxfi = Dxfn - 1 then
            begin
                NX := DxfPoly.Segments[0].vx;
                NY := DxfPoly.Segments[0].vy;
            end
            else
            begin
                NX := DxfPoly.Segments[Dxfi + 1].vx;
                NY := DxfPoly.Segments[Dxfi + 1].vy;
            end;

            WriteLine(LName, DxfSeg.vx, DxfSeg.vy, NX, NY);
        except
            { Сегмент недоступен — пропускаем. }
        end;
    end;
end;

function PrimitiveOnLayer(DxfPrim : IPCB_Primitive; DxfALayer : TLayer) : Boolean;
begin
    Result := False;
    if DxfPrim = nil then Exit;
    if DxfPrim.Layer = DxfALayer then
    begin
        Result := True;
        Exit;
    end;
    if DxfPrim.ObjectId = ePadObject then
    begin
        if DxfALayer = eMultiLayer then
        begin
            Result := False;
            Exit;
        end;
        if (DxfPrim.Layer = eMultiLayer) and IsCopperLayer(DxfALayer) then
            Result := True;
        if (DxfPrim.Layer = DxfALayer) then
            Result := True;
    end;
    if DxfPrim.ObjectId = eViaObject then
    begin
        if IsCopperLayer(DxfALayer) or (DxfALayer = eMultiLayer) then
        begin
            try
                Result := DxfPrim.IntersectLayer(DxfALayer);
            except
                Result := True;
            end;
        end;
    end;
end;

procedure ExportHolesLayer;
var
    DxfIter : IPCB_BoardIterator;
    DxfPrim : IPCB_Primitive;
    LName : String;
begin
    LName := 'HOLES';
    { PCB iterator: Board.BoardIterator_Create — AutoPlaceSilkscreen.pas:374, Auto_Panelizer.pas:112. }
    DxfIter := DxfBoard.BoardIterator_Create;
    DxfIter.AddFilter_ObjectSet(MkSet(ePadObject, eViaObject));
    DxfIter.AddFilter_LayerSet(AllLayers);
    DxfIter.AddFilter_Method(eProcessAll);
    DxfPrim := DxfIter.FirstPCBObject;
    while DxfPrim <> nil do
    begin
        if DxfPrim.HoleSize > 0 then
        begin
            if DxfPrim.ObjectId = ePadObject then
                WriteCircle(LName, DxfPrim.X, DxfPrim.Y, DxfPrim.HoleSize div 2)
            else
                WriteCircle(LName, DxfPrim.X, DxfPrim.Y, DxfPrim.HoleSize div 2);
        end;
        DxfPrim := DxfIter.NextPCBObject;
    end;
    DxfBoard.BoardIterator_Destroy(DxfIter);
end;

procedure ExportLayer(DxfALayer : TLayer);
var
    DxfIter : IPCB_BoardIterator;
    DxfPrim : IPCB_Primitive;
    LName : String;
begin
    LName := DxfLayerName(DxfALayer);
    DxfIter := DxfBoard.BoardIterator_Create;
    DxfIter.AddFilter_ObjectSet(MkSet(eTrackObject, eArcObject, ePadObject, eViaObject,
                                   eFillObject, eRegionObject, ePolyObject));
    DxfIter.AddFilter_LayerSet(AllLayers);
    DxfIter.AddFilter_Method(eProcessAll);

    DxfPrim := DxfIter.FirstPCBObject;
    while DxfPrim <> nil do
    begin
        if PrimitiveOnLayer(DxfPrim, DxfALayer) then
        begin
            case DxfPrim.ObjectId of
                eTrackObject  : ExportTrackOutline(LName, DxfPrim);
                eArcObject    : ExportArcOutline(LName, DxfPrim);
                ePadObject    : ExportPadOutline(LName, DxfPrim, DxfALayer);
                eViaObject    : ExportViaOutline(LName, DxfPrim, DxfALayer);
                eFillObject   : ExportFillOutline(LName, DxfPrim);
                eRegionObject : ExportRegionOutline(LName, DxfPrim);
                ePolyObject   : ExportPolygonOutline(LName, DxfPrim);
            end;
        end;
        DxfPrim := DxfIter.NextPCBObject;
    end;
    DxfBoard.BoardIterator_Destroy(DxfIter);
end;

procedure WriteDxfHeader(SelectedNames : TStringList);
var
    Dxfi : Integer;
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
    for Dxfi := 0 to SelectedNames.Count - 1 do
    begin
        DxfPair(0, 'LAYER');
        DxfPair(2, SelectedNames[Dxfi]);
        DxfPair(70, '0');
        DxfPair(62, IntToStr((Dxfi mod 6) + 1));
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

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function DxfCS_ScriptFolder : String;
var
    DxfWS  : IWorkspace;
    DxfPrj : IProject;
    Dxfi   : Integer;
    DxfP, DxfName : String;
begin
    Result := '';
    try
        DxfWS := GetWorkspace;
        if DxfWS = nil then Exit;
        for Dxfi := 0 to DxfWS.DM_ProjectCount - 1 do
        begin
            DxfPrj := DxfWS.DM_Projects(Dxfi);
            if DxfPrj = nil then Continue;
            DxfP := DxfPrj.DM_ProjectFullPath;
            DxfName := UpperCase(ExtractFileName(DxfP));
            if DxfName = 'DXFOUTLINEEXPORT.PRJSCR' then
            begin
                Result := ExtractFilePath(DxfP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function DxfCS_FindImageFile(const DxfFileName : String) : String;
var
    DxfDir, DxfP : String;
begin
    Result := '';
    DxfDir := DxfCS_ScriptFolder;
    if DxfDir <> '' then
    begin
        DxfP := DxfDir + DxfFileName;
        if FileExists(DxfP) then begin Result := DxfP; Exit; end;
        DxfP := DxfDir + 'images\' + DxfFileName;
        if FileExists(DxfP) then begin Result := DxfP; Exit; end;
    end;
    if FileExists(DxfFileName) then begin Result := DxfFileName; Exit; end;
    DxfP := 'images\' + DxfFileName;
    if FileExists(DxfP) then Result := DxfP;
end;

procedure DxfCS_TryOneHelpFile(const DxfName : String; var DxfDone : Boolean);
var
    DxfP : String;
begin
    if DxfDone then Exit;
    DxfP := DxfCS_FindImageFile(DxfName);
    if (DxfP = '') or (not FileExists(DxfP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(DxfP);
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
        DxfDone := True;
    except
    end;
end;

procedure DxfCS_TryLoadHelpImage(const DxfBmpName : String; const DxfPngName : String);
var
    DxfDone : Boolean;
begin
    DxfDone := False;
    DxfCS_TryOneHelpFile(DxfPngName, DxfDone);
    DxfCS_TryOneHelpFile(DxfBmpName, DxfDone);
    DxfCS_TryOneHelpFile('DxfOutlineExport.png', DxfDone);
    DxfCS_TryOneHelpFile('DxfOutlineExport.bmp', DxfDone);
    if not DxfDone then
        LabelImageHint.Caption := 'No image. Put ' + DxfPngName + ' next to the script or in images\.';
end;


procedure DoExport(DxfFileName : String);
var
    Dxfi : Integer;
    DxfALayer : TLayer;
    DxfNames : TStringList;
begin
    DxfLines := TStringList.Create;
    DxfNames := TStringList.Create;
    try
        for Dxfi := 0 to CheckListLayers.Items.Count - 1 do
            if CheckListLayers.Checked[Dxfi] then
            begin
                if LayerIds[Dxfi] = 'HOLES' then
                    DxfNames.Add('HOLES')
                else
                    DxfNames.Add(DxfLayerName(StrToInt(LayerIds[Dxfi])));
            end;

        WriteDxfHeader(DxfNames);

        for Dxfi := 0 to CheckListLayers.Items.Count - 1 do
        begin
            if CheckListLayers.Checked[Dxfi] then
            begin
                if LayerIds[Dxfi] = 'HOLES' then
                    ExportHolesLayer
                else
                begin
                    DxfALayer := StrToInt(LayerIds[Dxfi]);
                    ExportLayer(DxfALayer);
                end;
            end;
        end;

        WriteDxfFooter;
        DxfLines.SaveToFile(DxfFileName);
        DxfShowBox(LabelInfoSaved.Caption + sLineBreak + DxfFileName, 64);
    finally
        DxfNames.Free;
        DxfLines.Free;
    end;
end;

procedure DxfShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

procedure TFormDxf.FormDxfShow(DxfSender: TObject);
var
    Dxfi : Integer;
    DxfALayer : TLayer;
begin
    try
        DxfCS_TryLoadHelpImage('DxfExport.bmp', 'DxfExport.png');
    except
    end;
    CheckListLayers.Items.Clear;
    DxfBoard := nil;
    try
        if PCBServer <> nil then
            DxfBoard := PCBServer.GetCurrentPCBBoard;
    except
        DxfBoard := nil;
    end;
    if (DxfBoard = nil) or (LayerItems = nil) then Exit;
    CollectBoardLayers;
    for Dxfi := 0 to LayerItems.Count - 1 do
    begin
        CheckListLayers.Items.Add(LayerItems[Dxfi]);
        if LayerIds[Dxfi] = 'HOLES' then
            CheckListLayers.Checked[Dxfi] := True
        else
        begin
            DxfALayer := StrToInt(LayerIds[Dxfi]);
            CheckListLayers.Checked[Dxfi] := IsDefaultChecked(DxfALayer);
        end;
    end;
end;

procedure TFormDxf.ButtonAllClick(DxfSender: TObject);
var
    Dxfi : Integer;
begin
    for Dxfi := 0 to CheckListLayers.Items.Count - 1 do
        CheckListLayers.Checked[Dxfi] := True;
end;

procedure TFormDxf.ButtonNoneClick(DxfSender: TObject);
var
    Dxfi : Integer;
begin
    for Dxfi := 0 to CheckListLayers.Items.Count - 1 do
        CheckListLayers.Checked[Dxfi] := False;
end;

procedure TFormDxf.ButtonCopperClick(DxfSender: TObject);
var
    Dxfi : Integer;
    DxfALayer : TLayer;
begin
    for Dxfi := 0 to CheckListLayers.Items.Count - 1 do
    begin
        if LayerIds[Dxfi] = 'HOLES' then
            CheckListLayers.Checked[Dxfi] := False
        else
        begin
            DxfALayer := StrToInt(LayerIds[Dxfi]);
            CheckListLayers.Checked[Dxfi] := IsCopperLayer(DxfALayer);
        end;
    end;
end;

procedure TFormDxf.ButtonOKClick(DxfSender: TObject);
var
    SaveDlg : TSaveDialog;
    Dxfi, Dxfn : Integer;
begin
    if DxfBoard = nil then
    begin
        DxfShowBox(LabelErrNoPcb.Caption, 16);
        Exit;
    end;
    Dxfn := 0;
    for Dxfi := 0 to CheckListLayers.Items.Count - 1 do
        if CheckListLayers.Checked[Dxfi] then Inc(Dxfn);
    if Dxfn = 0 then
    begin
        DxfShowBox(LabelWarnNone.Caption, 48);
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

procedure TFormDxf.ButtonCancelClick(DxfSender: TObject);
begin
    FormDxf.Close;
end;

procedure StartDxfOutlineExport;
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

procedure _StartDxfOutlineExport;
begin
    StartDxfOutlineExport;
end;
