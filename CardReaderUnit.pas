unit CardReaderUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, WD05Unit, CardUMEx,
  System.Actions, Vcl.ActnList, Vcl.StdCtrls, DataPortCom, System.StrUtils;

type
  TfrmReadCard = class(TForm)
    pnlTools: TPanel;
    pnlButtons: TPanel;
    lblResult: TLabel;
    btnOk: TButton;
    btnClose: TButton;
    actlst1: TActionList;
    lblComPort: TLabel;
    cbbComPorts: TComboBox;
    btnSetActive: TButton;
    btnStartFinding: TButton;
    tmrFindingCard: TTimer;
    actSetActive: TAction;
    actStartFinding: TAction;
    actOk: TAction;
    actClose: TAction;
    procedure FormCreate(Sender: TObject);
    procedure tmrFindingCardTimer(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure actOkExecute(Sender: TObject);
    procedure actOkUpdate(Sender: TObject);
    procedure actStartFindingExecute(Sender: TObject);
    procedure actStartFindingUpdate(Sender: TObject);
    procedure actSetActiveExecute(Sender: TObject);
    procedure actSetActiveUpdate(Sender: TObject);
  private
    { Private declarations }
    FDataPortSerial: TDataPortCom;
    FCardUmEx: TCardUMEx;
    FCardData: TCardDataClass;
    procedure OnCardUmExAfterReadBase( Sender : TObject; ReadStatus : TReadStatus; cardData: TCardData );
  public
    { Public declarations }
    property CardData: TCardDataClass read FCardData;
  end;


function ReadCardFromReader():TWD05CardUid;

implementation

const
  tab_zam : TCardUMExchangeTable =
    ((14,13,1,9,8,3,2,5,10,7,0,12,11,6,4,15),
    (8,6,9,13,14,15,2,3,10,1,5,11,12,7,0,4),
    (7,4,8,13,9,0,5,11,15,3,12,2,1,10,6,14),
    (9,8,3,0,11,5,4,6,14,12,7,15,1,2,10,13),
    (5,1,2,8,14,3,7,0,12,4,11,10,15,9,13,6),
    (0,5,8,15,11,4,14,12,1,2,9,10,13,7,6,3),
    (10,7,11,1,2,12,6,4,5,14,13,3,15,0,8,9),
    (12,3,0,4,6,13,10,14,8,7,11,15,9,5,2,1));

  key_tab : TCardUMKeyTable =
    (
    $7b0c3495, $c28704b3,  $da95f236, $8fd59acb,
    $30f21768,  $a860bc74,  $523da8c6, $4cb7f80a
    );

  cReadStatusStr : array [TReadStatus] of String =
    ( 'Unknown status',    'Ok',         'Bad CRC',   'CardReader is died',
      'Finding card...',     'Bad Shersh',  'Autentification Error', 'Read Error',
      'Bad Send Data',    'Bad Port'
    );

{$R *.dfm}

function ReadCardFromReader():TWD05CardUid;
var
  frmDlg: TfrmReadCard;
begin
  Result:= TWD05CardUid.Create;
  frmDlg:= TfrmReadCard.Create(Application.MainForm);
  try
    frmDlg.Position:= poMainFormCenter;
    frmDlg.BorderStyle:= bsDialog;
    if frmDlg.ShowModal = mrOk then
    begin
      Result.FromString(frmDlg.CardData.sMifareID);
    end;
  finally
    frmDlg.Free;
  end;
end;

procedure TfrmReadCard.actCloseExecute(Sender: TObject);
begin
  ModalResult:= mrClose;
end;

procedure TfrmReadCard.actOkExecute(Sender: TObject);
begin
  if not actOk.Enabled then Exit;

  ModalResult:= mrOk;
end;

procedure TfrmReadCard.actOkUpdate(Sender: TObject);
begin
  actOk.Enabled:= Assigned(FCardData);
end;

procedure TfrmReadCard.actSetActiveExecute(Sender: TObject);
var
  i: Integer;
begin
  if FCardUmEx.Connected then
  begin
    FCardUmEx.DataPort.Active:= False;
    EnumComPorts(cbbComPorts.Items);
    cbbComPorts.ItemIndex:= cbbComPorts.Items.IndexOf(FDataPortSerial.Port);
  end else
  begin
    i:= cbbComPorts.ItemIndex;
    if i < 0 then
    begin
      MessageDlg('Com port is not selected', mtError, [mbOk], 0);
      Exit;
    end;
    FDataPortSerial.Port:= cbbComPorts.Items[i];
    FCardUmEx.DataPort.Active:= True;
    actStartFinding.Execute;
  end;
end;

procedure TfrmReadCard.actSetActiveUpdate(Sender: TObject);
begin
  actSetActive.Caption:= IfThen(FCardUmEx.DataPort.Active, 'Close', 'Open port');
end;

procedure TfrmReadCard.actStartFindingExecute(Sender: TObject);
begin
  if Assigned(FCardData) then
    FreeAndNil(FCardData);
  tmrFindingCard.Enabled:= True;
end;

procedure TfrmReadCard.actStartFindingUpdate(Sender: TObject);
begin
  actStartFinding.Enabled:= FCardUmEx.Connected and not tmrFindingCard.Enabled;
end;

procedure TfrmReadCard.FormCreate(Sender: TObject);
begin
  cbbComPorts.Clear;
  EnumComPorts(cbbComPorts.Items);
  FDataPortSerial:= TDataPortCom.Create( Self );

  FCardUmEx:= TCardUMEx.Create( Self );
  FDataPortSerial.Port:= 'COM1';
  FCardUmEx.DataPort:= FDataPortSerial;
  FCardUmEx.SetKeys(@tab_zam, @key_tab);
  FCardUmEx.AfterReadBaseData:= OnCardUmExAfterReadBase;
end;

procedure TfrmReadCard.OnCardUmExAfterReadBase(Sender: TObject;
  ReadStatus: TReadStatus; cardData: TCardData);
begin
  if ReadStatus = TReadStatus.rsOk then
  begin
    tmrFindingCard.Enabled:= False;
    FCardData:= TCardDataClass.Create(cardData);

    lblResult.Alignment:= taLeftJustify;
    lblResult.Caption:= sLineBreak +
      Format(#09+#09+'%-.20s: %s', ['CardUID', FCardData.sMifareID]) + sLineBreak +
      Format(#09+#09+'%-.20s: %s', ['Type', FCardData.sCardType])    + sLineBreak +
      Format(#09+#09+'%-.20s: %s', ['Kind', FCardData.sCardKind])    + sLineBreak +
      Format(#09+#09+'%-.20s: %s', ['Color', FCardData.sCardColor])  + sLineBreak +
      Format(#09+#09+'%-.20s: %s', ['Manufacture by', IfThen(FCardData.bIsOurCard, 'ClassCard', 'Unknown')])
      ;
  end else
  begin
    lblResult.Alignment:= taCenter;
    lblResult.Layout:= tlCenter;
    lblResult.Caption:= cReadStatusStr[ReadStatus];
  end;
end;

procedure TfrmReadCard.tmrFindingCardTimer(Sender: TObject);
begin
  if FCardUmEx.Connected then
    FCardUmEx.ReadBaseData()
  else
    tmrFindingCard.Enabled:= False;
end;

end.
