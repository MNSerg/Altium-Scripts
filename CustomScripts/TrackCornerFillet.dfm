object FormFillet: TFormFillet
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1082#1088#1091#1075#1083#1077#1085#1080#1077' '#1091#1075#1083#1086#1074' '#1090#1088#1077#1082#1072
  ClientHeight = 280
  ClientWidth = 720
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormFilletShow
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
    Caption = 'images\Fillet.png'
    WordWrap = True
  end
  object LabelInfo: TLabel
    Left = 340
    Top = 12
    Width = 364
    Height = 72
    AutoSize = False
    Caption = #1042#1099#1076#1077#1083#1080#1090#1077' '#1086#1076#1080#1085' '#1089#1077#1075#1084#1077#1085#1090' '#1080#1083#1080' '#1074#1077#1089#1100' '#1087#1091#1090#1100'. '#1050#1074#1072#1076#1088#1072#1090' '#1080#1079' 4 '#1089#1077#1075#1084#1077#1085#1090#1086#1074' '#1087#1086#1083#1091#1095#1080#1090' 4 '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103' ('#1087#1086' '#1091#1075#1083#1091'). '#1045#1089#1083#1080' '#1076#1091#1075#1080' '#1091#1078#1077' '#1077#1089#1090#1100' '#1089#1082#1088#1080#1087#1090' '#1089#1087#1088#1086#1089#1080#1090', '#1087#1077#1088#1077#1076#1077#1083#1072#1090#1100' '#1083#1080'.'
    WordWrap = True
  end
  object LabelRadius: TLabel
    Left = 340
    Top = 100
    Width = 180
    Height = 13
    Caption = #1056#1072#1076#1080#1091#1089' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103', '#1084#1084':'
  end
  object EditRadius: TEdit
    Left = 540
    Top = 96
    Width = 160
    Height = 21
    TabOrder = 0
    Text = '0.5'
  end
  object ButtonOK: TButton
    Left = 400
    Top = 230
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = ButtonOKClick
  end
  object ButtonCancel: TButton
    Left = 510
    Top = 230
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 2
    OnClick = ButtonCancelClick
  end
end
