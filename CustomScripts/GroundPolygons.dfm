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
  Font.Height = -11
  Font.Name = 'Tahoma'
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
    Caption = 'images\GroundPolygons.png'
    WordWrap = True
  end
  object LabelNet: TLabel
    Left = 340
    Top = 20
    Width = 70
    Height = 13
    Caption = #1048#1084#1103' '#1094#1077#1087#1080':'
  end
  object EditNet: TEdit
    Left = 480
    Top = 16
    Width = 220
    Height = 21
    TabOrder = 0
    Text = 'GND'
  end
  object CheckSolid: TCheckBox
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
    Left = 340
    Top = 88
    Width = 380
    Height = 80
    AutoSize = False
    Caption = #1050#1086#1085#1090#1091#1088' '#1087#1086#1083#1080#1075#1086#1085#1072' = '#1082#1086#1085#1090#1091#1088' '#1087#1083#1072#1090#1099'. '#1047#1072#1079#1086#1088#1099' '#1085#1077' '#1079#1072#1076#1072#1102#1090#1089#1103' '#1089#1082#1088#1080#1087#1090#1086#1084' '#1080' '#1073#1077#1088#1091#1090#1089#1103' '#1080#1079' '#1087#1088#1072#1074#1080#1083' '#1087#1088#1086#1077#1082#1090#1080#1088#1086#1074#1072#1085#1080#1103'.'
    WordWrap = True
  end
  object ButtonOK: TButton
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
    Left = 510
    Top = 290
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 3
    OnClick = ButtonCancelClick
  end
end
