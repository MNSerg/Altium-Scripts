{..............................................................................}
{ BomExport.pas                                                                 }
{ BOM as OOXML *.xlsx (STORE zip, no compression). Value from parameters.     }
{ sharedStrings/sheet UTF-8 (CP1251 Altium strings mapped to UTF-8 bytes).    }
{ Value = DM_Parameters (Value/Value2/PartValue/Nominal), not DM_Comment.     }
{..............................................................................}

var
    OutPath     : String;
    BomTitle    : String;
    Groups      : TStringList; { grouping key }
    DesLists    : TStringList; { key -> concatenated designators }
    ExtraFields : TStringList; { key -> Comment|Description|Value }
    QtyList     : TStringList; { key -> quantity as decimal string }

{ Run Script: choose procedure StartBomExport (project compiles only this .pas). }
procedure StartBomExport; forward;
procedure _StartBomExport; forward;
procedure TFormBom.ButtonBrowseClick(BomSender: TObject); forward;
procedure TFormBom.ButtonOKClick(BomSender: TObject); forward;
procedure TFormBom.ButtonCancelClick(BomSender: TObject); forward;
procedure TFormBom.FormBomShow(BomSender: TObject); forward;

{ Без set-литерала rfReplaceAll: в DelphiScript скобки дают Array Variant. }
function BomReplaceStr(const BomS, FindStr, Repl : String) : String;
var
    Bomi : Integer;
    Rest : String;
begin
    Result := '';
    Rest := BomS;
    if FindStr = '' then
    begin
        Result := BomS;
        Exit;
    end;
    Bomi := Pos(FindStr, Rest);
    while Bomi > 0 do
    begin
        Result := Result + Copy(Rest, 1, Bomi - 1) + Repl;
        Rest := Copy(Rest, Bomi + Length(FindStr), Length(Rest));
        Bomi := Pos(FindStr, Rest);
    end;
    Result := Result + Rest;
end;

function XmlEsc(const BomS : String) : String;
var
    BomT : String;
begin
    BomT := BomS;
    BomT := BomReplaceStr(BomT, '&', '&amp;');
    BomT := BomReplaceStr(BomT, '<', '&lt;');
    BomT := BomReplaceStr(BomT, '>', '&gt;');
    BomT := BomReplaceStr(BomT, '"', '&quot;');
    Result := BomT;
end;

function BomParamText(BomP) : String;
begin
    Result := '';
    try Result := BomP.DM_Text; except Result := ''; end;
    if Result <> '' then Exit;
    try Result := BomP.DM_CalculatedValue; except Result := ''; end;
    if Result <> '' then Exit;
    try Result := BomP.DM_Data; except Result := ''; end;
    if Result <> '' then Exit;
    try Result := BomP.GetState_Text; except Result := ''; end;
    if Result <> '' then Exit;
    try Result := BomP.Text; except Result := ''; end;
end;

function BomLooksNominal(const BomS : String) : Boolean;
var
    Bomi : Integer;
    HasDigit : Boolean;
begin
    Result := False;
    if (BomS = '') or (Length(BomS) > 16) then Exit;
    HasDigit := False;
    for Bomi := 1 to Length(BomS) do
        if (BomS[Bomi] >= '0') and (BomS[Bomi] <= '9') then
            HasDigit := True;
    Result := HasDigit;
end;

function BomNamedParam(BomComp : IComponent; const BomWant : String) : String;
var
    Bomi, Bomn : Integer;
    BomObj : TObject;
    BomNm, BomTxt, BomW : String;
begin
    Result := '';
    BomW := UpperCase(BomWant);
    try
        Bomn := BomComp.DM_ParameterCount;
    except
        Bomn := 0;
    end;
    for Bomi := 0 to Bomn - 1 do
    begin
        try
            BomObj := BomComp.DM_Parameters(Bomi);
        except
            BomObj := nil;
        end;
        if BomObj = nil then Continue;
        BomNm := '';
        try BomNm := BomObj.DM_Name; except BomNm := ''; end;
        if UpperCase(BomNm) <> BomW then Continue;
        BomTxt := BomParamText(BomObj);
        if BomTxt <> '' then
        begin
            Result := BomTxt;
            Exit;
        end;
    end;
end;

function BomHasParamName(BomComp : IComponent; const BomWant : String) : Boolean;
var
    Bomi, Bomn : Integer;
    BomObj : TObject;
    BomNm : String;
begin
    Result := False;
    try
        Bomn := BomComp.DM_ParameterCount;
    except
        Bomn := 0;
    end;
    for Bomi := 0 to Bomn - 1 do
    begin
        try
            BomObj := BomComp.DM_Parameters(Bomi);
        except
            BomObj := nil;
        end;
        if BomObj = nil then Continue;
        BomNm := '';
        try BomNm := BomObj.DM_Name; except BomNm := ''; end;
        if UpperCase(BomNm) = UpperCase(BomWant) then
        begin
            Result := True;
            Exit;
        end;
    end;
end;

function BomValueFromParams(BomComp : IComponent) : String;
var
    Comment : String;
begin
    Result := BomNamedParam(BomComp, 'Value');
    if Result = '' then Result := BomNamedParam(BomComp, 'Value2');
    if Result = '' then Result := BomNamedParam(BomComp, 'PartValue');
    if Result = '' then Result := BomNamedParam(BomComp, 'Nominal');
    if Result <> '' then Exit;
    if BomHasParamName(BomComp, 'Value') or BomHasParamName(BomComp, 'Value2') then
        Exit;
    Comment := '';
    try Comment := BomComp.DM_Comment; except Comment := ''; end;
    if BomLooksNominal(Comment) then
        Result := Comment;
end;

function FootprintOf(BomComp : IComponent) : String;
begin
    Result := '';
    try Result := BomComp.DM_FootPrint; except Result := ''; end;
end;

procedure AddPart(const BomDes, Comment, Description, Footprint, Value : String);
var
    BomKey, Fields : String;
    BomIdx, Qty : Integer;
begin
    { Ключ: Value (+ Comment/Description/Footprint) — разделение по Value. }
    BomKey := UpperCase(Value) + '||' + UpperCase(Comment) + '||' +
           UpperCase(Description) + '||' + UpperCase(Footprint);
    Fields := Comment + '|' + Description + '|' + Value;

    BomIdx := Groups.IndexOf(BomKey);
    if BomIdx < 0 then
    begin
        Groups.Add(BomKey);
        QtyList.Add('1');
        DesLists.Add(BomDes);
        ExtraFields.Add(Fields);
    end
    else
    begin
        Qty := StrToInt(QtyList[BomIdx]) + 1;
        QtyList[BomIdx] := IntToStr(Qty);
        if DesLists[BomIdx] = '' then
            DesLists[BomIdx] := BomDes
        else if BomDes <> '' then
            DesLists[BomIdx] := DesLists[BomIdx] + ', ' + BomDes;
    end;
end;

procedure HarvestDmDoc(BomLogDoc : IDocument);
var
    Bomi, Bomn : Integer;
    BomComp : IComponent;
    BomDes, Comment, Desc, Fp, BomVal : String;
begin
    { Индексный обход IDocument (тот же DM_, что Auto_Panelizer.pas: DM_FocusedProject).
      В !SCRIPTS нет schematic-итератора — Create не используем. }
    if BomLogDoc = nil then Exit;
    try
        Bomn := BomLogDoc.DM_ComponentCount;
    except
        Bomn := 0;
    end;
    for Bomi := 0 to Bomn - 1 do
    begin
        BomComp := BomLogDoc.DM_Components(Bomi);
        if BomComp = nil then Continue;
        BomDes := '';
        Comment := '';
        Desc := '';
        Fp := '';
        BomVal := '';
        try BomDes := BomComp.DM_PhysicalDesignator; except BomDes := ''; end;
        if BomDes = '' then
        try BomDes := BomComp.DM_LogicalDesignator; except BomDes := ''; end;
        if BomDes = '' then
            BomDes := BomNamedParam(BomComp, 'Designator');
        try Comment := BomComp.DM_Comment; except Comment := ''; end;
        BomVal := BomValueFromParams(BomComp);
        Desc := BomNamedParam(BomComp, 'Description');
        if Desc = '' then
            Desc := BomNamedParam(BomComp, 'LongDescription');
        Fp := FootprintOf(BomComp);
        AddPart(BomDes, Comment, Desc, Fp, BomVal);
    end;
end;

procedure HarvestFromProject;
var
    BomWS : IWorkspace;
    BomProject : IProject;
    Bomi : Integer;
    BomLogDoc : IDocument;
    BomBoard : IPCB_Board;
    BomCmp : IPCB_Component;
    BomIter : IPCB_BoardIterator;
    BomDes, Comment, Fp, BomVal : String;
begin
    BomWS := GetWorkspace;
    if BomWS = nil then Exit;
    BomProject := BomWS.DM_FocusedProject;
    BomTitle := 'BOM';
    try
        if BomProject <> nil then
            BomTitle := ChangeFileExt(ExtractFileName(BomProject.DM_ProjectFullPath), '');
    except
        BomTitle := 'BOM';
    end;
    if BomTitle = '' then BomTitle := 'BOM';

    if BomProject <> nil then
    begin
        try
            BomProject.DM_Compile;
        except
        end;
        for Bomi := 0 to BomProject.DM_LogicalDocumentCount - 1 do
        begin
            BomLogDoc := BomProject.DM_LogicalDocuments(Bomi);
            if (BomLogDoc.DM_DocumentKind = 'SCH') or (BomLogDoc.DM_DocumentKind = 'SCHDOC') then
                HarvestDmDoc(BomLogDoc);
        end;
    end;

    if Groups.Count > 0 then Exit;

    { Fallback: компоненты PCB. }
    if PCBServer = nil then Exit;
    BomBoard := PCBServer.GetCurrentPCBBoard;
    if BomBoard = nil then Exit;
    BomIter := BomBoard.BoardIterator_Create;
    BomIter.AddFilter_ObjectSet(MkSet(eComponentObject));
    BomIter.AddFilter_LayerSet(AllLayers);
    BomIter.AddFilter_Method(eProcessAll);
    BomCmp := BomIter.FirstPCBObject;
    while BomCmp <> nil do
    begin
        BomDes := '';
        Comment := '';
        Fp := '';
        try BomDes := BomCmp.Name.Text; except BomDes := ''; end;
        try Comment := BomCmp.Comment.Text; except Comment := ''; end;
        if Comment = '' then
        try Comment := BomCmp.SourceLibReference; except Comment := ''; end;
        try Fp := BomCmp.Pattern; except Fp := ''; end;
        BomVal := '';
        if BomLooksNominal(Comment) then BomVal := Comment;
        AddPart(BomDes, Comment, '', Fp, BomVal);
        BomCmp := BomIter.NextPCBObject;
    end;
    BomBoard.BoardIterator_Destroy(BomIter);
end;

procedure BomShowBox(const Msg : String; Flags : Integer);
begin
    ShowMessage(Msg);
end;

procedure WriteSettingsXml(const XlsPath : String);
var
    Xml : TStringList;
    XmlPath : String;
begin
    XmlPath := ChangeFileExt(XlsPath, '.bom.settings.xml');
    Xml := TStringList.Create;
    try
        Xml.Add('<?xml version="1.0" encoding="UTF-8"?>');
        Xml.Add('<BomSettings generator="CustomScripts.BomExport" version="1.5">');
        Xml.Add('  <Output>' + XmlEsc(XlsPath) + '</Output>');
        Xml.Add('  <Format>OOXML xlsx STORE zip, sharedStrings UTF-8</Format>');
        Xml.Add('  <GroupBy>Value,Comment,Description,Footprint(internal)</GroupBy>');
        Xml.Add('  <ExcludeParts>None</ExcludeParts>');
        Xml.Add('  <Columns>Comment;Description;Designator;Value;Quantity</Columns>');
        Xml.Add('  <Notes>Value from DM_Parameters DM_Text/DM_CalculatedValue/DM_Data/Text. No DM_Value.</Notes>');
        Xml.Add('</BomSettings>');
        Xml.SaveToFile(XmlPath);
    finally
        Xml.Free;
    end;
end;

function BomUShr1(N : Integer) : Integer;
begin
    if N >= 0 then
        Result := N shr 1
    else
        Result := ((N and $7FFFFFFF) shr 1) or $40000000;
end;

function BomCrc32(const S : String) : Integer;
var
    Bomi, Bomj, C, B : Integer;
begin
    C := -1;
    for Bomi := 1 to Length(S) do
    begin
        B := Ord(S[Bomi]);
        C := C xor B;
        for Bomj := 1 to 8 do
        begin
            if (C and 1) <> 0 then
                C := BomUShr1(C) xor Integer($EDB88320)
            else
                C := BomUShr1(C);
        end;
    end;
    Result := C xor Integer($FFFFFFFF);
end;

function BomLE16(N : Integer) : String;
begin
    Result := Chr(N and 255) + Chr((N shr 8) and 255);
end;

function BomLE32(N : Integer) : String;
begin
    Result := Chr(N and 255) + Chr((N shr 8) and 255) +
              Chr((N shr 16) and 255) + Chr((N shr 24) and 255);
end;

function BomCp1251ToUtf8(const S : String) : String;
var
    Bomi, B, Cp : Integer;
begin
    Result := '';
    for Bomi := 1 to Length(S) do
    begin
        B := Ord(S[Bomi]);
        if B < 128 then
            Result := Result + Chr(B)
        else if B = 168 then
            Result := Result + Chr($D0) + Chr($81)
        else if B = 184 then
            Result := Result + Chr($D1) + Chr($91)
        else if (B >= 192) and (B <= 239) then
        begin
            Cp := 1040 + (B - 192);
            Result := Result + Chr($D0) + Chr($80 + (Cp - $400));
        end
        else if B >= 240 then
        begin
            Cp := 1072 + (B - 224);
            Result := Result + Chr($D0 + ((Cp shr 6) - 16)) + Chr($80 + (Cp and 63));
        end
        else
            Result := Result + Chr($C2) + Chr(B);
    end;
end;

function BomXmlUtf(const S : String) : String;
begin
    Result := XmlEsc(BomCp1251ToUtf8(S));
end;

procedure BomZipAdd(var LocalBuf, CentralBuf : String; var Offs : Integer;
                    const Name, Data : String);
var
    Crc, Sz, Nlen : Integer;
    Lh, Ch : String;
begin
    Crc := BomCrc32(Data);
    Sz := Length(Data);
    Nlen := Length(Name);
    Lh := 'PK' + Chr(3) + Chr(4) + BomLE16(20) + BomLE16(0) + BomLE16(0) +
          BomLE16(0) + BomLE16(0) + BomLE32(Crc) + BomLE32(Sz) + BomLE32(Sz) +
          BomLE16(Nlen) + BomLE16(0) + Name + Data;
    Ch := 'PK' + Chr(1) + Chr(2) + BomLE16(20) + BomLE16(20) + BomLE16(0) +
          BomLE16(0) + BomLE16(0) + BomLE16(0) + BomLE32(Crc) + BomLE32(Sz) +
          BomLE32(Sz) + BomLE16(Nlen) + BomLE16(0) + BomLE16(0) + BomLE16(0) +
          BomLE16(0) + BomLE32(0) + BomLE32(Offs) + Name;
    LocalBuf := LocalBuf + Lh;
    CentralBuf := CentralBuf + Ch;
    Offs := Offs + Length(Lh);
end;

procedure BomWriteBytes(const Path, S : String);
var
    BomF : File;
    Bomi, N : Integer;
begin
    AssignFile(BomF, Path);
    Rewrite(BomF, 1);
    try
        Bomi := 1;
        while Bomi <= Length(S) do
        begin
            N := Length(S) - Bomi + 1;
            if N > 4096 then N := 4096;
            BlockWrite(BomF, S[Bomi], N);
            Bomi := Bomi + N;
        end;
    finally
        CloseFile(BomF);
    end;
end;

procedure BomUniqAdd(Uniq : TStringList; const U : String);
begin
    if Uniq.IndexOf(U) < 0 then
        Uniq.Add(U);
end;

procedure WriteXlsx(const XlsPath : String);
var
    Shared, Sheet, LocalBuf, CentralBuf, Zip : String;
    Offs, Bomi, Nfiles : Integer;
    Uniq : TStringList;
    Parts : TStringList;
    CellC, CellE, CellD, CellV : String;
    Ct, Rels, Wb, WbRels, Styles : String;
begin
    Uniq := TStringList.Create;
    Parts := TStringList.Create;
    Parts.Delimiter := '|';
    Parts.StrictDelimiter := True;
    try
        BomUniqAdd(Uniq, 'Comment');
        BomUniqAdd(Uniq, 'Description');
        BomUniqAdd(Uniq, 'Designator');
        BomUniqAdd(Uniq, 'Value');
        BomUniqAdd(Uniq, 'Quantity');
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            BomUniqAdd(Uniq, BomCp1251ToUtf8(Parts[0]));
            BomUniqAdd(Uniq, BomCp1251ToUtf8(Parts[1]));
            BomUniqAdd(Uniq, BomCp1251ToUtf8(DesLists[Bomi]));
            BomUniqAdd(Uniq, BomCp1251ToUtf8(Parts[2]));
            BomUniqAdd(Uniq, QtyList[Bomi]);
        end;
        Shared := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                  '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="' +
                  IntToStr(Uniq.Count) + '" uniqueCount="' + IntToStr(Uniq.Count) + '">';
        for Bomi := 0 to Uniq.Count - 1 do
            Shared := Shared + '<si><t xml:space="preserve">' + XmlEsc(Uniq[Bomi]) + '</t></si>';
        Shared := Shared + '</sst>';

        Sheet := '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
                 '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
                 '<cols><col min="1" max="5" width="28" bestFit="1" customWidth="1"/></cols>' +
                 '<sheetData>';
        Sheet := Sheet + '<row r="1">';
        Sheet := Sheet + '<c r="A1" t="s" s="2"><v>0</v></c>';
        Sheet := Sheet + '<c r="B1" t="s" s="2"><v>1</v></c>';
        Sheet := Sheet + '<c r="C1" t="s" s="2"><v>2</v></c>';
        Sheet := Sheet + '<c r="D1" t="s" s="2"><v>3</v></c>';
        Sheet := Sheet + '<c r="E1" t="s" s="2"><v>4</v></c></row>';
        for Bomi := 0 to Groups.Count - 1 do
        begin
            Parts.DelimitedText := ExtraFields[Bomi];
            while Parts.Count < 3 do Parts.Add('');
            CellC := BomCp1251ToUtf8(Parts[0]);
            CellE := BomCp1251ToUtf8(Parts[1]);
            CellD := BomCp1251ToUtf8(DesLists[Bomi]);
            CellV := BomCp1251ToUtf8(Parts[2]);
            Sheet := Sheet + '<row r="' + IntToStr(Bomi + 2) + '">';
            Sheet := Sheet + '<c r="A' + IntToStr(Bomi + 2) + '" t="s" s="1"><v>' + IntToStr(Uniq.IndexOf(CellC)) + '</v></c>';
            Sheet := Sheet + '<c r="B' + IntToStr(Bomi + 2) + '" t="s" s="1"><v>' + IntToStr(Uniq.IndexOf(CellE)) + '</v></c>';
            Sheet := Sheet + '<c r="C' + IntToStr(Bomi + 2) + '" t="s" s="1"><v>' + IntToStr(Uniq.IndexOf(CellD)) + '</v></c>';
            Sheet := Sheet + '<c r="D' + IntToStr(Bomi + 2) + '" t="s" s="1"><v>' + IntToStr(Uniq.IndexOf(CellV)) + '</v></c>';
            Sheet := Sheet + '<c r="E' + IntToStr(Bomi + 2) + '" t="s" s="1"><v>' + IntToStr(Uniq.IndexOf(QtyList[Bomi])) + '</v></c>';
            Sheet := Sheet + '</row>';
        end;
        Sheet := Sheet + '</sheetData></worksheet>';

        Ct := '<?xml version="1.0" encoding="UTF-8"?>' +
              '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
              '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
              '<Default Extension="xml" ContentType="application/xml"/>' +
              '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
              '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>' +
              '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' +
              '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
              '</Types>';
        Rels := '<?xml version="1.0" encoding="UTF-8"?>' +
                '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
                '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
                '</Relationships>';
        Wb := '<?xml version="1.0" encoding="UTF-8"?>' +
              '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
              '<sheets><sheet name="BOM" sheetId="1" r:id="rId1"/></sheets></workbook>';
        WbRels := '<?xml version="1.0" encoding="UTF-8"?>' +
                  '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
                  '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>' +
                  '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>' +
                  '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
                  '</Relationships>';
        Styles := '<?xml version="1.0" encoding="UTF-8"?>' +
                  '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
                  '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>' +
                  '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>' +
                  '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>' +
                  '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
                  '<cellStyleXfs count="1"><xf/></cellStyleXfs>' +
                  '<cellXfs count="3"><xf xfId="0"/>' +
                  '<xf xfId="0" applyAlignment="1"><alignment wrapText="1"/></xf>' +
                  '<xf xfId="0" fontId="1" applyFont="1" applyAlignment="1"><alignment wrapText="1"/></xf>' +
                  '</cellXfs></styleSheet>';

        LocalBuf := '';
        CentralBuf := '';
        Offs := 0;
        BomZipAdd(LocalBuf, CentralBuf, Offs, '[Content_Types].xml', Ct);
        BomZipAdd(LocalBuf, CentralBuf, Offs, '_rels/.rels', Rels);
        BomZipAdd(LocalBuf, CentralBuf, Offs, 'xl/workbook.xml', Wb);
        BomZipAdd(LocalBuf, CentralBuf, Offs, 'xl/_rels/workbook.xml.rels', WbRels);
        BomZipAdd(LocalBuf, CentralBuf, Offs, 'xl/worksheets/sheet1.xml', Sheet);
        BomZipAdd(LocalBuf, CentralBuf, Offs, 'xl/sharedStrings.xml', Shared);
        BomZipAdd(LocalBuf, CentralBuf, Offs, 'xl/styles.xml', Styles);
        Nfiles := 7;
        Zip := LocalBuf + CentralBuf +
               'PK' + Chr(5) + Chr(6) + BomLE16(0) + BomLE16(0) +
               BomLE16(Nfiles) + BomLE16(Nfiles) +
               BomLE32(Length(CentralBuf)) + BomLE32(Length(LocalBuf)) + BomLE16(0);
        BomWriteBytes(XlsPath, Zip);
    finally
        Uniq.Free;
        Parts.Free;
    end;
end;

procedure WriteBomFiles;
begin
    if LowerCase(ExtractFileExt(OutPath)) <> '.xlsx' then
        OutPath := ChangeFileExt(OutPath, '.xlsx');
    WriteXlsx(OutPath);
    WriteSettingsXml(OutPath);
    BomShowBox(LabelInfoDone.Caption + OutPath + sLineBreak +
               LabelInfoCount.Caption + IntToStr(Groups.Count), 64);
end;

{ ScriptBoot.inc — safe help-image load. Do not read EXE command-line args (AV). }
{ Form must have components ImageHelp (TImage) and LabelImageHint (TLabel). }

function BomCS_ScriptFolder : String;
var
    BomWS  : IWorkspace;
    BomPrj : IProject;
    Bomi   : Integer;
    BomP, BomName : String;
begin
    Result := '';
    try
        BomWS := GetWorkspace;
        if BomWS = nil then Exit;
        for Bomi := 0 to BomWS.DM_ProjectCount - 1 do
        begin
            BomPrj := BomWS.DM_Projects(Bomi);
            if BomPrj = nil then Continue;
            BomP := BomPrj.DM_ProjectFullPath;
            BomName := UpperCase(ExtractFileName(BomP));
            if BomName = 'BOMEXPORT.PRJSCR' then
            begin
                Result := ExtractFilePath(BomP);
                Exit;
            end;
        end;
    except
        Result := '';
    end;
end;

function BomCS_FindImageFile(const BomFileName : String) : String;
var
    BomDir, BomP : String;
begin
    Result := '';
    BomDir := BomCS_ScriptFolder;
    if BomDir <> '' then
    begin
        BomP := BomDir + BomFileName;
        if FileExists(BomP) then begin Result := BomP; Exit; end;
        BomP := BomDir + 'images\' + BomFileName;
        if FileExists(BomP) then begin Result := BomP; Exit; end;
    end;
    if FileExists(BomFileName) then begin Result := BomFileName; Exit; end;
    BomP := 'images\' + BomFileName;
    if FileExists(BomP) then Result := BomP;
end;

procedure BomCS_TryOneHelpFile(const BomName : String; var BomDone : Boolean);
var
    BomP : String;
begin
    if BomDone then Exit;
    BomP := BomCS_FindImageFile(BomName);
    if (BomP = '') or (not FileExists(BomP)) then Exit;
    try
        ImageHelp.Picture.LoadFromFile(BomP);
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
        BomDone := True;
    except
    end;
end;

procedure BomCS_TryLoadHelpImage(const BomBmpName : String; const BomPngName : String);
var
    BomDone : Boolean;
begin
    BomDone := False;
    BomCS_TryOneHelpFile(BomPngName, BomDone);
    BomCS_TryOneHelpFile(BomBmpName, BomDone);
    BomCS_TryOneHelpFile('BomExport.png', BomDone);
    BomCS_TryOneHelpFile('BomExport.bmp', BomDone);
    if not BomDone then
        LabelImageHint.Caption := 'No image. Put ' + BomPngName + ' next to the script or in images\.';
end;


function BomInitDir : String;
var
    BomWS : IWorkspace;
    BomPrj : IProject;
    BomDoc : IDocument;
    BomP : String;
begin
    Result := '';
    BomWS := GetWorkspace;
    if BomWS <> nil then
    begin
        BomPrj := BomWS.DM_FocusedProject;
        if BomPrj <> nil then
        begin
            BomP := BomPrj.DM_ProjectFullPath;
            if (BomP <> '') and (Pos('*', BomP) = 0) then
                Result := ExtractFilePath(BomP);
        end;
        if Result = '' then
        try
            BomDoc := BomWS.DM_FocusedDocument;
            if BomDoc <> nil then
                Result := ExtractFilePath(BomDoc.DM_FullPath);
        except
        end;
    end;
    if Result = '' then
    try
        Result := GetEnvironmentVariable('USERPROFILE') + '\Documents';
    except
        Result := '';
    end;
end;

function BomPathAllowed(const BomP : String) : Boolean;
var
    BomDir, BomName, BomU : String;
begin
    Result := False;
    if BomP = '' then Exit;
    BomName := ExtractFileName(BomP);
    if BomName = '' then Exit;
    BomDir := ExtractFilePath(BomP);
    BomU := UpperCase(BomP);
    if (BomU = 'C:\') or (BomU = 'C:') or (BomP = '/') or (BomP = '\') then Exit;
    if (BomDir = 'C:\') or (BomDir = '/') or (BomDir = '\') then Exit;
    Result := True;
end;

procedure TFormBom.FormBomShow(BomSender: TObject);
var
    BomDir : String;
begin
    try
        BomCS_TryLoadHelpImage('BomExport.bmp', 'BomExport.png');
    except
    end;
    BomDir := BomInitDir;
    if BomDir = '' then
        EditPath.Text := 'BOM.xlsx'
    else
        EditPath.Text := BomDir + 'BOM.xlsx';
end;

procedure TFormBom.ButtonBrowseClick(BomSender: TObject);
var
    BomDlg : TSaveDialog;
begin
    BomDlg := TSaveDialog.Create(nil);
    try
        BomDlg.Title := LabelDlgSave.Caption;
        BomDlg.Filter := 'Excel (*.xlsx)|*.xlsx|Все файлы (*.*)|*.*';
        BomDlg.DefaultExt := 'xlsx';
        BomDlg.FileName := 'BOM.xlsx';
        BomDlg.InitialDir := BomInitDir;
        if BomDlg.Execute then
            EditPath.Text := BomDlg.FileName;
    finally
        BomDlg.Free;
    end;
end;

procedure TFormBom.ButtonOKClick(BomSender: TObject);
var
    BomDlg : TSaveDialog;
begin
    BomDlg := TSaveDialog.Create(nil);
    try
        BomDlg.Title := LabelDlgSave.Caption;
        BomDlg.Filter := 'Excel (*.xlsx)|*.xlsx|Все файлы (*.*)|*.*';
        BomDlg.DefaultExt := 'xlsx';
        if EditPath.Text <> '' then
            BomDlg.FileName := ExtractFileName(EditPath.Text)
        else
            BomDlg.FileName := 'BOM.xlsx';
        BomDlg.InitialDir := BomInitDir;
        if ExtractFilePath(EditPath.Text) <> '' then
            BomDlg.InitialDir := ExtractFilePath(EditPath.Text);
        if not BomDlg.Execute then
            Exit;
        OutPath := BomDlg.FileName;
    finally
        BomDlg.Free;
    end;
    if not BomPathAllowed(OutPath) then
    begin
        BomShowBox(LabelErrPath.Caption, 16);
        Exit;
    end;
    if LowerCase(ExtractFileExt(OutPath)) <> '.xlsx' then
        OutPath := ChangeFileExt(OutPath, '.xlsx');
    FormBom.Close;

    Groups := TStringList.Create;
    DesLists := TStringList.Create;
    ExtraFields := TStringList.Create;
    QtyList := TStringList.Create;
    try
        HarvestFromProject;
        if Groups.Count = 0 then
            BomShowBox(LabelWarnNone.Caption, 48)
        else
            WriteBomFiles;
    finally
        Groups.Free;
        DesLists.Free;
        ExtraFields.Free;
        QtyList.Free;
    end;
end;

procedure TFormBom.ButtonCancelClick(BomSender: TObject);
begin
    FormBom.Close;
end;

procedure StartBomExport;
begin
    FormBom.ShowModal;
end;

procedure _StartBomExport;
begin
    StartBomExport;
end;
