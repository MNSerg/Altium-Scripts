object FormBom: TFormBom
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1069#1082#1089#1087#1086#1088#1090' BOM (Excel)'
  ClientHeight = 360
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormBomShow
  PixelsPerInch = 96
  TextHeight = 13
  object ImageHelp: TImage
    Left = 8
    Top = 8
    Width = 320
    Height = 214
    Center = True
    Proportional = True
    Stretch = True
  end
  object LabelImageHint: TLabel
    Left = 8
    Top = 226
    Width = 320
    Height = 40
    AutoSize = False
    Caption = 'images\BomExport.png'
    WordWrap = True
  end
  object LabelPath: TLabel
    Left = 340
    Top = 12
    Width = 200
    Height = 13
    Caption = #1060#1072#1081#1083' Excel (.xls):'
  end
  object EditPath: TEdit
    Left = 340
    Top = 28
    Width = 280
    Height = 21
    TabOrder = 0
  end
  object ButtonBrowse: TButton
    Left = 628
    Top = 26
    Width = 90
    Height = 25
    Caption = #1054#1073#1079#1086#1088'...'
    TabOrder = 1
    OnClick = ButtonBrowseClick
  end
  object LabelCols: TLabel
    Left = 340
    Top = 64
    Width = 380
    Height = 120
    AutoSize = False
    Caption = #1057#1090#1086#1083#1073#1094#1099' '#1090#1086#1095#1085#1086': Comment, Designator, Description, Quantity, Value. '#1042#1089#1077' '#1082#1086#1084#1087#1086#1085#1077#1085#1090#1099' '#1074#1082#1083#1102#1095#1072#1102#1090#1089#1103' (DNP/графика '#1090#1086#1078#1077'). '#1043#1088#1091#1087#1087#1080#1088#1086#1074#1082#1072' Comment+Value+Description. '#1060#1086#1088#1084#1072#1090' SpreadsheetML, '#1086#1090#1082#1088#1099#1074#1072#1077#1090#1089#1103' '#1074' Excel.'
    WordWrap = True
  end
  object ButtonOK: TButton
    Left = 400
    Top = 310
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 2
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 510
    Top = 310
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
end
