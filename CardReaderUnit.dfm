object frmReadCard: TfrmReadCard
  Left = 0
  Top = 0
  Caption = 'Read card'
  ClientHeight = 204
  ClientWidth = 349
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblResult: TLabel
    Left = 0
    Top = 49
    Width = 349
    Height = 103
    Align = alClient
    Alignment = taCenter
    Caption = 'Finding card...'
    Layout = tlCenter
    ExplicitWidth = 70
    ExplicitHeight = 13
  end
  object pnlTools: TPanel
    Left = 0
    Top = 0
    Width = 349
    Height = 49
    Align = alTop
    Caption = 'pnlTools'
    ShowCaption = False
    TabOrder = 0
    object lblComPort: TLabel
      Left = 11
      Top = 8
      Width = 44
      Height = 26
      Caption = 'Carddex '#13#10'Reader'
    end
    object cbbComPorts: TComboBox
      Left = 58
      Top = 12
      Width = 87
      Height = 21
      TabOrder = 0
      Text = 'cbbComPorts'
    end
    object btnSetActive: TButton
      Left = 156
      Top = 10
      Width = 75
      Height = 25
      Action = actSetActive
      TabOrder = 1
    end
    object btnStartFinding: TButton
      Left = 237
      Top = 10
      Width = 75
      Height = 25
      Action = actStartFinding
      TabOrder = 2
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 152
    Width = 349
    Height = 52
    Align = alBottom
    Caption = 'pnlButtons'
    ShowCaption = False
    TabOrder = 1
    DesignSize = (
      349
      52)
    object btnOk: TButton
      Left = 179
      Top = 16
      Width = 75
      Height = 25
      Action = actOk
      Anchors = [akTop, akRight]
      TabOrder = 0
    end
    object btnClose: TButton
      Left = 267
      Top = 16
      Width = 75
      Height = 25
      Action = actClose
      Anchors = [akTop, akRight]
      TabOrder = 1
    end
  end
  object actlst1: TActionList
    Left = 24
    Top = 48
    object actSetActive: TAction
      Caption = 'actSetActive'
      OnExecute = actSetActiveExecute
      OnUpdate = actSetActiveUpdate
    end
    object actStartFinding: TAction
      Caption = 'Start Finding'
      OnExecute = actStartFindingExecute
      OnUpdate = actStartFindingUpdate
    end
    object actOk: TAction
      Caption = 'Ok'
      OnExecute = actOkExecute
      OnUpdate = actOkUpdate
    end
    object actClose: TAction
      Caption = 'Close'
      OnExecute = actCloseExecute
    end
  end
  object tmrFindingCard: TTimer
    OnTimer = tmrFindingCardTimer
    Left = 64
    Top = 48
  end
end
