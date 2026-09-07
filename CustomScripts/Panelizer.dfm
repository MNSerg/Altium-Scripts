object FormPanel: TFormPanel
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1055#1072#1085#1077#1083#1080#1079#1072#1094#1080#1103' PCB'
  ClientHeight = 500
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormPanelShow
  PixelsPerInch = 96
  TextHeight = 13
  object ImageHelp: TImage
    Left = 8
    Top = 8
    Width = 320
    Height = 214
  end
  object LabelImageHint: TLabel
    Left = 8
    Top = 226
    Width = 320
    Height = 40
    AutoSize = False
    Caption = 'images\Panelizer.png'
    WordWrap = True
  end
  object LabelFile: TLabel
    Left = 340
    Top = 8
    Width = 200
    Height = 13
    Caption = #1048#1089#1093#1086#1076#1085#1099#1081' PcbDoc:'
  end
  object EditFile: TEdit
    Left = 340
    Top = 24
    Width = 300
    Height = 21
    TabOrder = 0
  end
  object ButtonBrowse: TButton
    Left = 646
    Top = 22
    Width = 90
    Height = 25
    Caption = #1054#1073#1079#1086#1088'...'
    TabOrder = 1
    OnClick = ButtonBrowseClick
  end
  object LabelCols: TLabel
    Left = 340
    Top = 60
    Width = 200
    Height = 13
    Caption = #1057#1090#1086#1083#1073#1094#1099' (X), '#1084#1072#1089#1089#1080#1074' 4x2:'
  end
  object EditCols: TEdit
    Left = 560
    Top = 56
    Width = 80
    Height = 21
    TabOrder = 2
    Text = '4'
  end
  object LabelRows: TLabel
    Left = 340
    Top = 88
    Width = 200
    Height = 13
    Caption = #1056#1103#1076#1099' (Y):'
  end
  object EditRows: TEdit
    Left = 560
    Top = 84
    Width = 80
    Height = 21
    TabOrder = 3
    Text = '2'
  end
  object LabelGapX: TLabel
    Left = 340
    Top = 116
    Width = 210
    Height = 13
    Caption = #1047#1072#1079#1086#1088' '#1087#1083#1072#1090#1072'-'#1087#1083#1072#1090#1072' X, '#1084#1084':'
  end
  object EditGapX: TEdit
    Left = 560
    Top = 112
    Width = 80
    Height = 21
    TabOrder = 4
    Text = '2'
  end
  object LabelGapY: TLabel
    Left = 340
    Top = 144
    Width = 210
    Height = 13
    Caption = #1047#1072#1079#1086#1088' '#1087#1083#1072#1090#1072'-'#1087#1083#1072#1090#1072' Y, '#1084#1084':'
  end
  object EditGapY: TEdit
    Left = 560
    Top = 140
    Width = 80
    Height = 21
    TabOrder = 5
    Text = '2'
  end
  object LabelMargin: TLabel
    Left = 340
    Top = 172
    Width = 210
    Height = 13
    Caption = #1055#1086#1083#1077' '#1076#1086' '#1082#1088#1072#1103' '#1087#1072#1085#1077#1083#1080', '#1084#1084':'
  end
  object EditMargin: TEdit
    Left = 560
    Top = 168
    Width = 80
    Height = 21
    TabOrder = 6
    Text = '10'
  end
  object LabelTab: TLabel
    Left = 340
    Top = 200
    Width = 210
    Height = 13
    Caption = #1064#1080#1088#1080#1085#1072' '#1087#1077#1088#1077#1084#1099#1095#1082#1080' (web), '#1084#1084':'
  end
  object EditTab: TEdit
    Left = 560
    Top = 196
    Width = 80
    Height = 21
    TabOrder = 7
    Text = '4'
  end
  object LabelFillet: TLabel
    Left = 340
    Top = 228
    Width = 210
    Height = 13
    Caption = #1056#1072#1076#1080#1091#1089' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103' '#1087#1077#1088#1077#1084#1099#1095#1077#1082', '#1084#1084':'
  end
  object EditFillet: TEdit
    Left = 560
    Top = 224
    Width = 80
    Height = 21
    TabOrder = 8
    Text = '1'
  end
  object LabelMech: TLabel
    Left = 340
    Top = 256
    Width = 210
    Height = 13
    Caption = #1052#1077#1093#1072#1085#1080#1095#1077#1089#1082#1080#1081' '#1089#1083#1086#1081' '#1082#1086#1085#1090#1091#1088#1072' (1..32):'
  end
  object EditMech: TEdit
    Left = 560
    Top = 252
    Width = 80
    Height = 21
    TabOrder = 9
    Text = '1'
  end
  object LabelHint: TLabel
    Left = 340
    Top = 288
    Width = 400
    Height = 80
    AutoSize = False
    Caption = #1055#1077#1088#1077#1084#1099#1095#1082#1080' '#1082#1072#1082' mouse-bite: '#1091#1079#1082#1080#1077' '#1087#1077#1088#1077#1084#1099#1095#1082#1080' '#1073#1077#1079' '#1086#1090#1074#1077#1088#1089#1090#1080#1081'. '#1054#1073#1097#1080#1081' '#1082#1086#1085#1090#1091#1088' '#1074#1086#1082#1088#1091#1075' '#1074#1089#1077#1093' '#1087#1083#1072#1090' '#1089' '#1087#1077#1088#1077#1084#1099#1095#1082#1072#1084#1080' '#1085#1072' '#1084#1077#1093#1072#1085#1080#1095#1077#1089#1082#1086#1084' '#1089#1083#1086#1077'.'
    WordWrap = True
  end
  object ButtonOK: TButton
    Left = 420
    Top = 456
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 10
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 530
    Top = 456
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 11
    OnClick = ButtonCancelClick
  end
end
