object FormZip: TFormZip
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1040#1088#1093#1080#1074' '#1087#1088#1086#1077#1082#1090#1072
  ClientHeight = 320
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormZipShow
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
    Caption = 'images\ProjectZipper.png'
    WordWrap = True
  end
  object LabelPrj: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 12
    Width = 380
    Height = 13
    Caption = #1055#1072#1087#1082#1072' '#1087#1088#1086#1077#1082#1090#1072':'
  end
  object EditPrj: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 28
    Width = 380
    Height = 21
    TabOrder = 0
  end
  object LabelZip: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 60
    Width = 380
    Height = 13
    Caption = #1060#1072#1081#1083' zip ('#1087#1072#1087#1082#1072' OLD):'
  end
  object EditZip: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 76
    Width = 380
    Height = 21
    TabOrder = 1
  end
  object LabelHint: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 108
    Width = 380
    Height = 80
    AutoSize = False
    Caption = #1042#1077#1089#1100' '#1087#1088#1086#1077#1082#1090' '#1088#1103#1076#1086#1084' '#1089' .PrjPcb '#1073#1091#1076#1077#1090' '#1091#1087#1072#1082#1086#1074#1072#1085' '#1074' OLD, '#1082#1088#1086#1084#1077' '#1089#1072#1084#1086#1081' '#1087#1072#1087#1082#1080' OLD.'
    WordWrap = True
  end
  object ButtonOK: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 420
    Top = 270
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
    Left = 530
    Top = 270
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
  object LabelErrPrj: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1077#1090' '#1086#1090#1082#1088#1099#1090#1086#1075#1086' '#1087#1088#1086#1077#1082#1090#1072' (GetWorkspace.DM_FocusedProject).'
  end
  object LabelErrOld: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1077' '#1091#1076#1072#1083#1086#1089#1100' '#1089#1086#1079#1076#1072#1090#1100' '#1087#1072#1087#1082#1091' OLD.'
  end
  object LabelInfoDone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1040#1088#1093#1080#1074': '
  end
  object LabelInfoRc: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = 'Zip.Zip '#1082#1086#1076': '
  end
  object LabelInfoSize: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = 'InstanceSize: '
  end
end
