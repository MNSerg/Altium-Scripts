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
var
    DxfS : String;
    Dxfi : Integer;
    DxfC : Char;
begin
    DxfS := Layer2String(DxfALayer);
    Result := '';
    for Dxfi := 1 to Length(DxfS) do
    begin
        DxfC := DxfS[Dxfi];
        if ((DxfC >= 'A') and (DxfC <= 'Z')) or ((DxfC >= 'a') and (DxfC <= 'z')) or
           ((DxfC >= '0') and (DxfC <= '9')) then
            Result := Result + DxfC
        else
            Result := Result + '_';
    end;
    if Result = '' then Result := 'L' + IntToStr(DxfALayer);
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
        LayerItems.Add(Layer2String(DxfALayer));
        LayerIds.Add(IntToStr(DxfALayer));
    end;
end;

procedure CollectBoardLayers;
var
    DxfLS : IPCB_LayerObject;
    DxfStack : IPCB_LayerStack;
    DxfName : String;
    DxfId : TLayer;
begin
    LayerItems.Clear;
    LayerIds.Clear;
    LayerItems.Add('Отверстия (HOLES) — круги сверловки');
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
            DxfName := Layer2String(DxfId);
            if LayerIds.IndexOf(IntToStr(DxfId)) < 0 then
            begin
                LayerItems.Add(DxfName);
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

procedure ExportTrackOutline(const LName : String; DxfT : IPCB_Track);
var
    Dxfdx, Dxfdy, Len, nx, ny, hw : Double;
    L1x1, L1y1, L1x2, L1y2 : TCoord;
    L2x1, L2y1, L2x2, L2y2 : TCoord;
    Ang : Double;
    StartDeg, EndDeg : Double;
begin
    Dxfdx := DxfT.X2 - DxfT.X1;
    Dxfdy := DxfT.Y2 - DxfT.Y1;
    Len := Sqrt(Dxfdx * Dxfdx + Dxfdy * Dxfdy);
    if Len < 1 then Exit;
    nx := -Dxfdy / Len;
    ny := Dxfdx / Len;
    hw := DxfT.Width / 2.0;

    L1x1 := Round(DxfT.X1 + nx * hw);
    L1y1 := Round(DxfT.Y1 + ny * hw);
    L1x2 := Round(DxfT.X2 + nx * hw);
    L1y2 := Round(DxfT.Y2 + ny * hw);
    L2x1 := Round(DxfT.X1 - nx * hw);
    L2y1 := Round(DxfT.Y1 - ny * hw);
    L2x2 := Round(DxfT.X2 - nx * hw);
    L2y2 := Round(DxfT.Y2 - ny * hw);

    WriteLine(LName, L1x1, L1y1, L1x2, L1y2);
    WriteLine(LName, L2x1, L2y1, L2x2, L2y2);

    { Круглые крышки: полуокружности на концах, перпендикуляр к направлению. }
    Ang := ArcTan2(Dxfdy, Dxfdx) * 180.0 / DxfPiValue;
    { На конце 1 (старт): полукруг с внешней стороны, охватывающий 180°. }
    StartDeg := Ang + 90;
    EndDeg := Ang + 270;
    WriteArc(LName, DxfT.X1, DxfT.Y1, DxfT.Width div 2, StartDeg, EndDeg);
    StartDeg := Ang - 90;
    EndDeg := Ang + 90;
    WriteArc(LName, DxfT.X2, DxfT.Y2, DxfT.Width div 2, StartDeg, EndDeg);
end;

procedure ExportArcOutline(const LName : String; DxfA : IPCB_Arc);
var
    hw, RIn, ROut : TCoord;
    DxfSa, DxfEa : Double;
    C1x, C1y, C2x, C2y : TCoord;
    C3x, C3y, C4x, C4y : TCoord;
begin
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

    { Радиальные соединения на торцах дуги. }
    C1x := Round(DxfA.XCenter + ROut * Cos(DxfSa * DxfPiValue / 180));
    C1y := Round(DxfA.YCenter + ROut * Sin(DxfSa * DxfPiValue / 180));
    C2x := Round(DxfA.XCenter + Max(RIn, 0) * Cos(DxfSa * DxfPiValue / 180));
    C2y := Round(DxfA.YCenter + Max(RIn, 0) * Sin(DxfSa * DxfPiValue / 180));
    C3x := Round(DxfA.XCenter + ROut * Cos(DxfEa * DxfPiValue / 180));
    C3y := Round(DxfA.YCenter + ROut * Sin(DxfEa * DxfPiValue / 180));
    C4x := Round(DxfA.XCenter + Max(RIn, 0) * Cos(DxfEa * DxfPiValue / 180));
    C4y := Round(DxfA.YCenter + Max(RIn, 0) * Sin(DxfEa * DxfPiValue / 180));
    if RIn > 0 then
    begin
        WriteLine(LName, C1x, C1y, C2x, C2y);
        WriteLine(LName, C3x, C3y, C4x, C4y);
    end;
end;

procedure ExportPadOutline(const LName : String; DxfPad : IPCB_Pad; DxfALayer : TLayer);
var
    SX, SY, DxfX, DxfY : TCoord;
    Shape : TShape;
    CR : Integer;
    Dxfi : Integer;
    Ang, DxfR : Double;
    Px, Py, Qx, Qy : TCoord;
begin
    { Размер площадки на данном слое. Для SMT — Top/Bottom size. }
    DxfX := DxfPad.X;
    DxfY := DxfPad.Y;
    try
        SX := DxfPad.TopXSize;
        SY := DxfPad.TopYSize;
        if (DxfALayer = eBottomLayer) or (DxfPad.Layer = eBottomLayer) then
        begin
            SX := DxfPad.BotXSize;
            SY := DxfPad.BotYSize;
        end;
    except
        SX := DxfPad.XSize;
        SY := DxfPad.YSize;
    end;

    if (SX <= 0) or (SY <= 0) then Exit;

    { TShape: eRounded, eRectangular, eOctagonal, eCircleShape, eRoundRectShape. }
    Shape := eRectangular;
    try
        Shape := DxfPad.TopShape;
    except
        try
            Shape := DxfPad.ShapeOnLayer(DxfALayer);
        except
            Shape := eRectangular;
        end;
    end;

    if (Shape = eRounded) or (Shape = eCircleShape) then
    begin
        if Abs(SX - SY) < 10 then
        begin
            WriteCircle(LName, DxfX, DxfY, SX div 2);
            Exit;
        end;
    end;

    CR := 0;
    if Shape = eRoundRectShape then
    begin
        CR := SX div 5;
        if CR > SY div 2 then CR := SY div 2;
        if CR < 1 then CR := 1;
    end;

    if CR > 0 then
    begin
        WriteLine(LName, DxfX - SX div 2 + CR, DxfY - SY div 2, DxfX + SX div 2 - CR, DxfY - SY div 2);
        WriteLine(LName, DxfX + SX div 2, DxfY - SY div 2 + CR, DxfX + SX div 2, DxfY + SY div 2 - CR);
        WriteLine(LName, DxfX + SX div 2 - CR, DxfY + SY div 2, DxfX - SX div 2 + CR, DxfY + SY div 2);
        WriteLine(LName, DxfX - SX div 2, DxfY + SY div 2 - CR, DxfX - SX div 2, DxfY - SY div 2 + CR);
        WriteArc(LName, DxfX - SX div 2 + CR, DxfY - SY div 2 + CR, CR, 180, 270);
        WriteArc(LName, DxfX + SX div 2 - CR, DxfY - SY div 2 + CR, CR, 270, 0);
        WriteArc(LName, DxfX + SX div 2 - CR, DxfY + SY div 2 - CR, CR, 0, 90);
        WriteArc(LName, DxfX - SX div 2 + CR, DxfY + SY div 2 - CR, CR, 90, 180);
        Exit;
    end;

    if Shape = eOctagonal then
    begin
        DxfR := SX / 2.0;
        for Dxfi := 0 to 7 do
        begin
            Ang := (22.5 + Dxfi * 45) * DxfPiValue / 180;
            Px := Round(DxfX + DxfR * Cos(Ang));
            Py := Round(DxfY + DxfR * Sin(Ang));
            Ang := (22.5 + (Dxfi + 1) * 45) * DxfPiValue / 180;
            Qx := Round(DxfX + DxfR * Cos(Ang));
            Qy := Round(DxfY + DxfR * Sin(Ang));
            WriteLine(LName, Px, Py, Qx, Qy);
        end;
        Exit;
    end;

    WriteLine(LName, DxfX - SX div 2, DxfY - SY div 2, DxfX + SX div 2, DxfY - SY div 2);
    WriteLine(LName, DxfX + SX div 2, DxfY - SY div 2, DxfX + SX div 2, DxfY + SY div 2);
    WriteLine(LName, DxfX + SX div 2, DxfY + SY div 2, DxfX - SX div 2, DxfY + SY div 2);
    WriteLine(LName, DxfX - SX div 2, DxfY + SY div 2, DxfX - SX div 2, DxfY - SY div 2);
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

            if DxfSeg.Kind = ePolySegmentArc then
                WriteArc(LName, DxfSeg.cx, DxfSeg.cy, DxfSeg.Radius, DxfSeg.sa1, DxfSeg.sa2)
            else
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
        if (DxfPrim.Layer = eMultiLayer) and IsCopperLayer(DxfALayer) then
            Result := True;
        if (DxfALayer = eMultiLayer) and (DxfPrim.Layer = eMultiLayer) then
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
        for Dxfi := 0 to DxfWS.DM_ProjectCount - 1 do
        begin
            DxfPrj := DxfWS.DM_Projects(Dxfi);
            if DxfPrj = nil then Continue;
            DxfP := DxfPrj.DM_ProjectFullPath;
            if Pos('CUSTOMSCRIPTS', UpperCase(DxfP)) > 0 then
            begin
                Result := ExtractFilePath(DxfP);
                Exit;
            end;
        end;
        DxfPrj := DxfWS.DM_FocusedProject;
        if DxfPrj <> nil then
            Result := ExtractFilePath(DxfPrj.DM_ProjectFullPath);
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
        DxfP := DxfDir + 'images\' + DxfFileName;
        if FileExists(DxfP) then begin Result := DxfP; Exit; end;
        DxfP := DxfDir + DxfFileName;
        if FileExists(DxfP) then begin Result := DxfP; Exit; end;
    end;
    DxfP := 'images\' + DxfFileName;
    if FileExists(DxfP) then begin Result := DxfP; Exit; end;
    if FileExists(DxfFileName) then Result := DxfFileName;
end;

procedure DxfCS_TryLoadHelpImage(const DxfBmpName : String; const DxfPngName : String);
var
    DxfP : String;
    HadPic : Boolean;
begin
    HadPic := False;
    try
        if ImageHelp.Picture.Width > 0 then HadPic := True;
    except
        HadPic := False;
    end;
    try
        DxfP := DxfCS_FindImageFile(DxfBmpName);
        if DxfP = '' then
            DxfP := DxfCS_FindImageFile(DxfPngName);
        if DxfP = '' then
            DxfP := DxfCS_FindImageFile('DxfOutlineExport.bmp');
        if (DxfP <> '') and FileExists(DxfP) then
        begin
            ImageHelp.Picture.LoadFromFile(DxfP);
            LabelImageHint.Caption := '';
            Exit;
        end;
    except
    end;
    if HadPic then
        LabelImageHint.Caption := ''
    else
        LabelImageHint.Caption := 'No image. Put ' + DxfBmpName + ' in images\ next to the scripts.';
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
