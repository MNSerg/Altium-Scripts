object FormGnd: TFormGnd
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1047#1077#1084#1083#1103#1085#1099#1077' '#1087#1086#1083#1080#1075#1086#1085#1099' '#1087#1086' '#1082#1086#1085#1090#1091#1088#1091
  ClientHeight = 260
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object LabelNet: TLabel
    Left = 16
    Top = 20
    Width = 70
    Height = 13
    Caption = #1048#1084#1103' '#1094#1077#1087#1080':'
  end
  object EditNet: TEdit
    Left = 160
    Top = 16
    Width = 220
    Height = 21
    TabOrder = 0
    Text = 'GND'
  end
  object LabelClr: TLabel
    Left = 16
    Top = 56
    Width = 90
    Height = 13
    Caption = #1047#1072#1079#1086#1088', '#1084#1084':'
  end
  object EditClr: TEdit
    Left = 160
    Top = 52
    Width = 220
    Height = 21
    TabOrder = 1
    Text = '0.2'
  end
  object CheckSolid: TCheckBox
    Left = 16
    Top = 92
    Width = 360
    Height = 17
    Caption = #1057#1087#1083#1086#1096#1085#1072#1103' '#1079#1072#1083#1080#1074#1082#1072' (solid), '#1080#1085#1072#1095#1077' hatch'
    Checked = True
    State = cbChecked
    TabOrder = 2
  end
  object LabelHint: TLabel
    Left = 16
    Top = 124
    Width = 368
    Height = 48
    AutoSize = False
    Caption = #1055#1086#1083#1080#1075#1086#1085#1099' '#1089#1086#1079#1076#1072#1102#1090#1089#1103' '#1085#1072' '#1074#1089#1077#1093' '#1089#1080#1075#1085#1072#1083#1100#1085#1099#1093' '#1084#1077#1076#1085#1099#1093' '#1089#1083#1086#1103#1093' '#1087#1086' '#1082#1086#1085#1090#1091#1088#1091' '#1087#1083#1072#1090#1099'. '#1045#1089#1083#1080' '#1087#1086#1083#1080#1075#1086#1085' '#1094#1077#1087#1080' '#1091#1078#1077' '#1077#1089#1090#1100' '#1085#1072' '#1089#1083#1086#1077' '#1089#1087#1088#1086#1089' '#1079#1072#1084#1077#1085#1080#1090#1100'/'#1087#1088#1086#1087#1091#1089#1090#1080#1090#1100'.'
    WordWrap = True
  end
  object ButtonOK: TButton
    Left = 100
    Top = 210
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 210
    Top = 210
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 4
    OnClick = ButtonCancelClick
  end
end
