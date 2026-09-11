object FormRen: TFormRen
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = #1055#1077#1088#1077#1080#1084#1077#1085#1086#1074#1072#1085#1080#1077' '#1087#1088#1086#1077#1082#1090#1072
  ClientHeight = 420
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
    Top = 56
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
    Top = 72
    Width = 396
    Height = 21
    TabOrder = 2
    ReadOnly = True
  end
  object RenRadioInc: TRadioButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 100
    Width = 396
    Height = 17
    Caption = #1059#1074#1077#1083#1080#1095#1080#1090#1100' '#1089#1091#1092#1092#1080#1082#1089' vN / VN'
    Checked = True
    TabOrder = 3
    TabStop = True
    OnClick = RenRadioIncClick
  end
  object RenRadioFull: TRadioButton
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 120
    Width = 396
    Height = 17
    Caption = #1055#1086#1083#1085#1072#1103' '#1079#1072#1084#1077#1085#1072' '#1080#1084#1077#1085#1080
    TabOrder = 4
    OnClick = RenRadioFullClick
  end
  object RenLabelNew: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 144
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
    Top = 160
    Width = 396
    Height = 21
    TabOrder = 5
    OnChange = RenEditNewChange
  end
  object RenLabelPreview: TLabel
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    Left = 340
    Top = 188
    Width = 396
    Height = 32
    AutoSize = False
    Caption = #1041#1091#1076#1077#1090':'
    WordWrap = True
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
    Caption = #1051#1080#1089#1090#1099': NewStem_ShN.SchDoc. '#1058#1086#1083#1100#1082#1086' '#1076#1086#1082#1091#1084#1077#1085#1090#1099' '#1087#1088#1086#1077#1082#1090#1072'. '#1053#1077' History, '#1085#1077' Gerbers, '#1085#1077' OLD. '#1057#1086#1093#1088#1072#1085#1080#1090#1077' '#1080' '#1079#1072#1082#1088#1086#1081#1090#1077'. '#1040#1088#1093#1080#1074' - ProjectZipper.'
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
    Top = 370
    Width = 90
    Height = 25
    Caption = 'OK'
    Default = True
    TabOrder = 6
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
    Top = 370
    Width = 90
    Height = 25
    Cancel = True
    Caption = #1054#1090#1084#1077#1085#1072
    TabOrder = 7
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
  object RenLabelErrNoVN: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1053#1077#1090' '#1089#1091#1092#1092#1080#1082#1089#1072' vN / VN '#1074' '#1080#1084#1077#1085#1080' '#1087#1088#1086#1077#1082#1090#1072'. '#1042#1099#1073#1077#1088#1080#1090#1077' '#1087#1086#1083#1085#1091#1102' '#1079#1072#1084#1077#1085#1091' '#1080#1084#1077#1085#1080'.'
  end
  object RenLabelWill: TLabel
    Left = 0
    Top = 0
    Width = 1
    Height = 1
    Visible = False
    Caption = #1041#1091#1076#1077#1090':'
  end
end
