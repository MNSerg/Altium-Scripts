object FormGnd: TFormGnd
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1047#1077#1084#1083#1103#1085#1099#1077' '#1087#1086#1083#1080#1075#1086#1085#1099' '#1087#1086' '#1082#1086#1085#1090#1091#1088#1091
  ClientHeight = 340
  ClientWidth = 740
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormGndShow
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
    Caption = 'images\GroundPolygons.png'
    WordWrap = True
  end
  object LabelNet: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 20
    Width = 70
    Height = 13
    Caption = #1048#1084#1103' '#1094#1077#1087#1080':'
  end
  object EditNet: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 480
    Top = 16
    Width = 220
    Height = 21
    TabOrder = 0
    Text = 'GND'
  end
  object CheckSolid: TCheckBox
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 56
    Width = 360
    Height = 17
    Caption = #1057#1087#1083#1086#1096#1085#1072#1103' '#1079#1072#1083#1080#1074#1082#1072' (solid)'
    Checked = True
    State = cbChecked
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
    Top = 88
    Width = 380
    Height = 80
    AutoSize = False
    Caption = #1050#1086#1085#1090#1091#1088' '#1087#1086#1083#1080#1075#1086#1085#1072' = '#1082#1086#1085#1090#1091#1088' '#1087#1083#1072#1090#1099'. '#1047#1072#1079#1086#1088#1099' '#1085#1077' '#1079#1072#1076#1072#1102#1090#1089#1103' '#1089#1082#1088#1080#1087#1090#1086#1084' '#1080' '#1073#1077#1088#1091#1090#1089#1103' '#1080#1079' '#1087#1088#1072#1074#1080#1083' '#1087#1088#1086#1077#1082#1090#1080#1088#1086#1074#1072#1085#1080#1103'.'
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
    Top = 290
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
    Top = 290
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
  object LabelAskReplace1: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1072' '#1089#1083#1086#1077' '
  end
  object LabelAskReplace2: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = ' '#1091#1078#1077' '#1077#1089#1090#1100' '#1087#1086#1083#1080#1075#1086#1085' '#1094#1077#1087#1080' '
  end
  object LabelAskReplace3: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = '. '#1047#1072#1084#1077#1085#1103#1090#1100' '#1089#1091#1097#1077#1089#1090#1074#1091#1102#1097#1080#1077'? '#1044#1072' = '#1074#1089#1077' '#1079#1072#1084#1077#1085#1080#1090#1100', '#1053#1077#1090' = '#1087#1088#1086#1087#1091#1089#1082#1072#1090#1100'.'
  end
  object LabelAskNoNet1: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1062#1077#1087#1100' '#171
  end
  object LabelAskNoNet2: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #187' '#1085#1077' '#1085#1072#1081#1076#1077#1085#1072'. '#1057#1086#1079#1076#1072#1090#1100' '#1087#1086#1083#1080#1075#1086#1085#1099' '#1073#1077#1079' '#1094#1077#1087#1080'?'
  end
  object LabelInfoDone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1057#1086#1079#1076#1072#1085#1086' '#1087#1086#1083#1080#1075#1086#1085#1086#1074': '
  end
  object LabelInfoSkip: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1088#1086#1087#1091#1097#1077#1085#1086': '
  end
  object LabelErrNoPcb: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = 'Open a PCB document.'
  end
  object LabelErrNoSrv: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = 'PCB-server is not available.'
  end
end
