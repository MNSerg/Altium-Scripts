object FormPanel: TFormPanel
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1055#1072#1085#1077#1083#1080#1079#1072#1094#1080#1103' PCB'
  ClientHeight = 420
  ClientWidth = 430
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
  object LabelFile: TLabel
    Left = 16
    Top = 16
    Width = 100
    Height = 13
    Caption = #1048#1089#1093#1086#1076#1085#1099#1081' PcbDoc:'
  end
  object EditFile: TEdit
    Left = 16
    Top = 32
    Width = 300
    Height = 21
    TabOrder = 0
  end
  object ButtonBrowse: TButton
    Left = 324
    Top = 30
    Width = 90
    Height = 25
    Caption = #1054#1073#1079#1086#1088'...'
    TabOrder = 1
    OnClick = ButtonBrowseClick
  end
  object LabelRows: TLabel
    Left = 16
    Top = 72
    Width = 30
    Height = 13
    Caption = #1056#1103#1076#1099':'
  end
  object EditRows: TEdit
    Left = 140
    Top = 68
    Width = 80
    Height = 21
    TabOrder = 2
    Text = '2'
  end
  object LabelCols: TLabel
    Left = 240
    Top = 72
    Width = 60
    Height = 13
    Caption = #1057#1090#1086#1083#1073#1094#1099':'
  end
  object EditCols: TEdit
    Left = 330
    Top = 68
    Width = 80
    Height = 21
    TabOrder = 3
    Text = '2'
  end
  object LabelGapX: TLabel
    Left = 16
    Top = 104
    Width = 110
    Height = 13
    Caption = #1047#1072#1079#1086#1088' X, '#1084#1084':'
  end
  object EditGapX: TEdit
    Left = 140
    Top = 100
    Width = 80
    Height = 21
    TabOrder = 4
    Text = '2'
  end
  object LabelGapY: TLabel
    Left = 240
    Top = 104
    Width = 80
    Height = 13
    Caption = #1047#1072#1079#1086#1088' Y, '#1084#1084':'
  end
  object EditGapY: TEdit
    Left = 330
    Top = 100
    Width = 80
    Height = 21
    TabOrder = 5
    Text = '2'
  end
  object LabelMargin: TLabel
    Left = 16
    Top = 136
    Width = 110
    Height = 13
    Caption = #1055#1086#1083#1077' '#1076#1086' '#1082#1088#1072#1103', '#1084#1084':'
  end
  object EditMargin: TEdit
    Left = 140
    Top = 132
    Width = 80
    Height = 21
    TabOrder = 6
    Text = '5'
  end
  object LabelTab: TLabel
    Left = 16
    Top = 168
    Width = 120
    Height = 13
    Caption = #1064#1080#1088#1080#1085#1072' '#1087#1077#1088#1077#1084#1099#1095#1082#1080', '#1084#1084':'
  end
  object EditTab: TEdit
    Left = 140
    Top = 164
    Width = 80
    Height = 21
    TabOrder = 7
    Text = '3'
  end
  object LabelFillet: TLabel
    Left = 16
    Top = 200
    Width = 120
    Height = 13
    Caption = #1056#1072#1076#1080#1091#1089' '#1092#1088#1077#1079#1099', '#1084#1084':'
  end
  object EditFillet: TEdit
    Left = 140
    Top = 196
    Width = 80
    Height = 21
    TabOrder = 8
    Text = '1'
  end
  object LabelMech: TLabel
    Left = 16
    Top = 232
    Width = 160
    Height = 13
    Caption = #1052#1077#1093#1072#1085#1080#1095#1077#1089#1082#1080#1081' '#1089#1083#1086#1081' (1..32):'
  end
  object EditMech: TEdit
    Left = 200
    Top = 228
    Width = 80
    Height = 21
    TabOrder = 9
    Text = '1'
  end
  object LabelHint: TLabel
    Left = 16
    Top = 268
    Width = 390
    Height = 48
    AutoSize = False
    Caption = #1041#1091#1076#1077#1090' '#1089#1086#1079#1076#1072#1085' '#1085#1086#1074#1099#1081' PcbDoc: '#1084#1072#1089#1089#1080#1074' Embedded Board, '#1082#1086#1085#1090#1091#1088' '#1079#1072#1075#1086#1090#1086#1074#1082#1080', '#1092#1088#1077#1079#1077#1088#1086#1074#1072#1085#1085#1099#1077' '#1087#1077#1088#1077#1084#1099#1095#1082#1080' '#1089#1086' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1077#1084' '#1080' '#1086#1073#1097#1080#1081' '#1074#1085#1077#1096#1085#1080#1081' '#1082#1086#1085#1090#1091#1088'.'
    WordWrap = True
  end
  object ButtonOK: TButton
    Left = 110
    Top = 372
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 10
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 220
    Top = 372
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 11
    OnClick = ButtonCancelClick
  end
end
