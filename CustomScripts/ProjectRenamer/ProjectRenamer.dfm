object FormRen: TFormRen
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077' '#1087#1088#1086#1077#1082#1090#1072
  ClientHeight = 400
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormRenShow
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
    Caption = 'images\ProjectRenamer.png'
    WordWrap = True
  end
  object RenLabelPath: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 12
    Width = 400
    Height = 13
    Caption = #1058#1077#1082#1091#1097#1080#1081' '#1087#1091#1090#1100' '#1087#1088#1086#1077#1082#1090#1072':'
  end
  object RenEditPath: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 28
    Width = 300
    Height = 21
    TabOrder = 0
    ReadOnly = True
  end
  object RenBtnBrowse: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 646
    Top = 26
    Width = 90
    Height = 25
    Caption = #1054#1073#1079#1086#1088'...'
    TabOrder = 1
    OnClick = RenBtnBrowseClick
  end
  object RenLabelOld: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 60
    Width = 400
    Height = 13
    Caption = #1058#1077#1082#1091#1097#1077#1077' '#1080#1084#1103':'
  end
  object RenEditOld: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 76
    Width = 396
    Height = 21
    TabOrder = 2
    ReadOnly = True
  end
  object RenLabelNew: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 108
    Width = 400
    Height = 13
    Caption = #1053#1086#1074#1086#1077' '#1080#1084#1103':'
  end
  object RenEditNew: TEdit
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 124
    Width = 396
    Height = 21
    TabOrder = 3
  end
  object RenCheckDocs: TCheckBox
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 156
    Width = 396
    Height = 17
    Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1090#1100' '#1076#1086#1082#1091#1084#1077#1085#1090#1099' '#1087#1088#1086#1077#1082#1090#1072
    Checked = True
    State = cbChecked
    TabOrder = 4
  end
  object RenCheckFolder: TCheckBox
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 178
    Width = 396
    Height = 17
    Caption = #1047#1072#1084#1077#1085#1080#1090#1100' '#1080#1084#1103' '#1074#1086' '#1074#1089#1077#1093' '#1092#1072#1081#1083#1072#1093' '#1087#1072#1087#1082#1080' '#1087#1088#1086#1077#1082#1090#1072
    TabOrder = 5
  end
  object RenCheckOld: TCheckBox
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 356
    Top = 200
    Width = 380
    Height = 17
    Caption = #1074#1082#1083#1102#1095#1072#1103' OLD'
    TabOrder = 6
  end
  object RenLabelHint: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 224
    Width = 396
    Height = 72
    AutoSize = False
    Caption = #1047#1072#1082#1088#1086#1081#1090#1077' '#1080' '#1089#1086#1093#1088#1072#1085#1080#1090#1077' '#1076#1086#1082#1091#1084#1077#1085#1090#1099'. '#1055#1086#1089#1083#1077' '#1087#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1085#1080#1103' Altium '#1084#1086#1078#1077#1090' '#1087#1086#1090#1088#1077#1073#1086#1074#1072#1090#1100' '#1079#1072#1085#1086#1074#1086' '#1086#1090#1082#1088#1099#1090#1100' '#1087#1088#1086#1077#1082#1090'. '#1057#1085#1072#1095#1072#1083#1072' '#1089#1076#1077#1083#1072#1081#1090#1077' '#1072#1088#1093#1080#1074' ProjectZipper.'
    WordWrap = True
  end
  object RenLabelProg: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 300
    Width = 396
    Height = 16
    Caption = ''
  end
  object ButtonOK: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 440
    Top = 350
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 7
    OnClick = RenButtonOKClick
  end
  object ButtonCancel: TButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 550
    Top = 350
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 8
    OnClick = RenButtonCancelClick
  end
  object RenLabelErrPrj: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1077#1090' '#1086#1090#1082#1088#1099#1090#1086#1075#1086' '#1087#1088#1086#1077#1082#1090#1072' (GetWorkspace.DM_FocusedProject). '#1042#1099#1073#1077#1088#1080#1090#1077' '#1092#1072#1081#1083' '#1054#1073#1079#1086#1088#1086#1084'.'
  end
  object RenLabelErrName: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1086#1074#1086#1077' '#1080#1084#1103' '#1087#1091#1089#1090#1086#1077' '#1080#1083#1080' '#1089#1086#1074#1087#1072#1076#1072#1077#1090' '#1089#1086' '#1089#1090#1072#1088#1099#1084'.'
  end
  object RenLabelErrChars: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1048#1084#1103' '#1089#1086#1076#1077#1088#1078#1080#1090' '#1085#1077#1076#1086#1087#1091#1089#1090#1080#1084#1099#1077' '#1089#1080#1084#1074#1086#1083#1099' Windows.'
  end
  object RenLabelAsk: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1090#1100' '#1087#1088#1086#1077#1082#1090' '#1080' '#1092#1072#1081#1083#1099'?'
  end
  object RenLabelErrSave: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1077' '#1091#1076#1072#1083#1086#1089#1100' '#1089#1086#1093#1088#1072#1085#1080#1090#1100' '#1076#1086#1082#1091#1084#1077#1085#1090#1099'. '#1057#1086#1093#1088#1072#1085#1080#1090#1077' '#1074#1088#1091#1095#1085#1091#1102', '#1079#1072#1090#1077#1084' '#1087#1086#1074#1090#1086#1088#1080#1090#1077'?'
  end
  object RenLabelInfoDone: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1085#1086':'
  end
  object RenLabelInfoErr: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1054#1096#1080#1073#1082#1080':'
  end
  object RenLabelInfoOpen: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1054#1090#1082#1088#1086#1081#1090#1077' '#1085#1086#1074#1099#1081' '#1092#1072#1081#1083' '#1087#1088#1086#1077#1082#1090#1072' '#1074#1088#1091#1095#1085#1091#1102':'
  end
  object RenLabelErrUnsaved: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1088#1086#1077#1082#1090' '#1085#1077' '#1089#1086#1093#1088#1072#1085#1105#1085' '#1085#1072' '#1076#1080#1089#1082' ('#1074' '#1087#1091#1090#1080' '#1077#1089#1090#1100' *). '#1057#1086#1093#1088#1072#1085#1080#1090#1077' '#1087#1088#1086#1077#1082#1090' '#1080' '#1087#1086#1074#1090#1086#1088#1080#1090#1077'.'
  end
  object RenLabelDlgPrj: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1060#1072#1081#1083' '#1087#1088#1086#1077#1082#1090#1072
  end
  object RenLabelBusy: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077'...'
  end
  object RenLabelReady: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1043#1086#1090#1086#1074#1086
  end
  object RenLabelErrMissing: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1060#1072#1081#1083' '#1087#1088#1086#1077#1082#1090#1072' '#1085#1077' '#1085#1072#1081#1076#1077#1085'.'
  end
end
