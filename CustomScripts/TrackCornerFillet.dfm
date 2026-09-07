object FormFillet: TFormFillet
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1057#1082#1088#1091#1075#1083#1077#1085#1080#1077' '#1091#1075#1083#1086#1074' '#1090#1088#1077#1082#1072
  ClientHeight = 280
  ClientWidth = 720
  Color = $001E1A1A
  Font.Charset = DEFAULT_CHARSET
  Font.Color = $00F0F0F0
  Font.Height = -12
  Font.Name = 'Segoe UI'
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
    Font.Charset = DEFAULT_CHARSET
    Font.Color = $00F0F0F0
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 8
    Top = 226
    Width = 320
    Height = 40
    AutoSize = False
    Caption = 'images\Fillet.png'
    WordWrap = True
  end
  object LabelInfo: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = $00F0F0F0
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 12
    Width = 364
    Height = 72
    AutoSize = False
    Caption = #1042#1099#1076#1077#1083#1080#1090#1077' '#1086#1073#1072' '#1089#1077#1075#1084#1077#1085#1090#1072' '#1091#1075#1083#1072'. '#1053#1077#1074#1099#1076#1077#1083#1077#1085#1085#1099#1077' '#1089#1090#1086#1088#1086#1085#1099' '#1085#1077' '#1090#1088#1086#1075#1072#1102#1090#1089#1103'. '#1056#1072#1076#1080#1091#1089' 0 '#1091#1076#1072#1083#1103#1077#1090' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103'. '#1045#1089#1083#1080' '#1076#1091#1075#1080' '#1091#1078#1077' '#1077#1089#1090#1100' '#8212' '#1089#1087#1088#1086#1089' '#1087#1077#1088#1077#1076#1077#1083#1072#1090#1100' '#1083#1080'.'
    WordWrap = True
  end
  object LabelRadius: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = $00F0F0F0
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 100
    Width = 180
    Height = 13
    Caption = #1056#1072#1076#1080#1091#1089' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103', '#1084#1084':'
  end
  object EditRadius: TEdit
    Color = $00383333
    Font.Charset = DEFAULT_CHARSET
    Font.Color = $00F0F0F0
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 540
    Top = 96
    Width = 160
    Height = 21
    TabOrder = 0
    Text = '0.5'
  end
  object ButtonOK: TButton
    Color = $00383333
    Font.Charset = DEFAULT_CHARSET
    Font.Color = $00F0F0F0
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
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
    Color = $00383333
    Font.Charset = DEFAULT_CHARSET
    Font.Color = $00F0F0F0
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 510
    Top = 230
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 2
    OnClick = ButtonCancelClick
  end
  object LabelAskRedo: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1072' '#1074#1099#1073#1088#1072#1085#1085#1086#1084' '#1087#1091#1090#1080' '#1091#1078#1077' '#1077#1089#1090#1100' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103'. '#1055#1077#1088#1077#1076#1077#1083#1072#1090#1100' '#1080#1093'?'
  end
  object LabelErrRadius: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1042#1074#1077#1076#1080#1090#1077' '#1085#1077#1086#1090#1088#1080#1094#1072#1090#1077#1083#1100#1085#1099#1081' '#1088#1072#1076#1080#1091#1089' '#1074' '#1084#1080#1083#1083#1080#1084#1077#1090#1088#1072#1093' (0 '#1091#1076#1072#1083#1103#1077#1090' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1103').'
  end
  object LabelErrNeg: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1056#1072#1076#1080#1091#1089' '#1085#1077' '#1084#1086#1078#1077#1090' '#1073#1099#1090#1100' '#1086#1090#1088#1080#1094#1072#1090#1077#1083#1100#1085#1099#1084'.'
  end
  object LabelWarnNone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1080#1095#1077#1075#1086' '#1085#1077' '#1089#1076#1077#1083#1072#1085#1086'. '#1042#1099#1076#1077#1083#1080#1090#1077' '#1086#1073#1072' '#1089#1077#1075#1084#1077#1085#1090#1072' '#1082#1072#1078#1076#1086#1075#1086' '#1091#1075#1083#1072' ('#1080' '#1076#1091#1075#1091', '#1077#1089#1083#1080' '#1086#1085#1072' '#1091#1078#1077' '#1077#1089#1090#1100').'
  end
  object LabelInfoDone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1057#1086#1079#1076#1072#1085#1086'/'#1086#1073#1085#1086#1074#1083#1077#1085#1086' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1081': '
  end
  object LabelInfoRemoved: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1059#1076#1072#1083#1077#1085#1086' '#1089#1082#1088#1091#1075#1083#1077#1085#1080#1081': '
  end
  object LabelInfoSkip: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1088#1086#1087#1091#1097#1077#1085#1086' ('#1091#1078#1077' '#1077#1089#1090#1100' / '#1086#1090#1082#1072#1079'): '
  end
  object LabelInfoLarge: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1088#1086#1087#1091#1097#1077#1085#1086' ('#1088#1072#1076#1080#1091#1089' '#1089#1083#1080#1096#1082#1086#1084' '#1073#1086#1083#1100#1096#1086#1081'): '
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
