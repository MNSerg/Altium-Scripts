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
  Font.Height = -12
  Font.Name = 'Segoe UI'
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
  end
  object LabelImageHint: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 8
    Top = 226
    Width = 320
    Height = 40
    AutoSize = False
    Caption = 'images\BomExport.png'
    WordWrap = True
  end
  object LabelPath: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 12
    Width = 200
    Height = 13
    Caption = #1060#1072#1081#1083' Excel (.xlsx):'
  end
  object EditPath: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 28
    Width = 280
    Height = 21
    TabOrder = 0
  end
  object ButtonBrowse: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 628
    Top = 26
    Width = 90
    Height = 25
    Caption = #1054#1073#1079#1086#1088'...'
    TabOrder = 1
    OnClick = ButtonBrowseClick
  end
  object LabelCols: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 64
    Width = 380
    Height = 120
    AutoSize = False
    Caption = #1057#1090#1086#1083#1073#1094#1099' '#1082#1072#1082' BOM_UniBrain.xlsx: Comment, Description, Designator, Value, Quantity. '#1043#1088#1091#1087#1087#1080#1088#1086#1074#1082#1072' '#1087#1086' Value. '#1042#1089#1077' '#1083#1080#1089#1090#1099' '#1087#1088#1086#1077#1082#1090#1072'. '#1060#1072#1081#1083' .xlsx (Excel).'
    WordWrap = True
  end
  object ButtonOK: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
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
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 510
    Top = 310
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
  object LabelErrPath: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1059#1082#1072#1078#1080#1090#1077' '#1087#1091#1090#1100' '#1082' '#1092#1072#1081#1083#1091' .xlsx.'
  end
  object LabelWarnNone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1050#1086#1084#1087#1086#1085#1077#1085#1090#1099' '#1085#1077' '#1085#1072#1081#1076#1077#1085#1099'. '#1054#1090#1082#1088#1086#1081#1090#1077' '#1089#1093#1077#1084#1091' '#1080#1083#1080' PCB '#1087#1088#1086#1077#1082#1090#1072'.'
  end
  object LabelInfoDone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = 'BOM '#1079#1072#1087#1080#1089#1072#1085': '
  end
  object LabelInfoCount: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1043#1088#1091#1087#1087': '
  end
  object LabelWarnXlsx: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #67#83#86#32#1089#1086#1093#1088#1072#1085#1105#1085#44#32#88#76#83#88#32#1085#1077#32#1079#1072#1087#1080#1089#1072#1085#58#32
  end
  object LabelDlgSave: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1057#1086#1093#1088#1072#1085#1080#1090#1100#32#66#79#77
  end
end
