unit CardUMEx;

interface

uses
  Windows, Messages, SysUtils, Classes, CardUM;

////////////////////////////////////////////////////////////////////////////////
//
type
  TCardUMExchangeTable = CardUM.TCardUMExchangeTable;
  TCardUMKeyTable = CardUM.TCardUMKeyTable;

  TReadStatus = CardUM.TReadStatus;
  TCardData = CardUM.TCardData;
  TCardDataClass = CardUM.TCardDataClass;

  TCardUMEx = class( TCardUMBase )
  private
  protected
    procedure innerAfterRead( Dummy : TObject; ReadStatus : TReadStatus; out_buf : array of Byte ); override;
  public
    procedure ReadBaseData(n: integer = 1); override;
    procedure GetNomDevice; override;
  public
    constructor Create( AOwner : TComponent ); override;
  published
    property Port;
    property Connected;
    property DataPort;
    property AfterNomDevice;
    property AfterReadBaseData;
  end;

////////////////////////////////////////////////////////////////////////////////
//
resourcestring
  rscrtUnknown = 'Н/Д';
  rscrtStudent = 'Ученик';
  rscrtTeacher = 'Учитель';
  rscrtService = 'Служебная';
  rscrtEmployee = 'Сотрудник';


  rsECryptKeysNotSet = 'Попытка чтения с картридера без предварительной установки шифровальных ключей';

const
  g_rgsCardReadableStatus : array[TOwnerType] of String =
    ( rscrtUnknown, rscrtStudent, rscrtTeacher, rscrtService {, rscrtEmployee} );


////////////////////////////////////////////////////////////////////////////////
//
procedure Register;

implementation

////////////////////////////////////////////////////////////////////////////////
//
procedure Register;
begin
  RegisterComponents('StatusLib', [TCardUMEx]);
end;


////////////////////////////////////////////////////////////////////////////////
//
// { TCardUMEx }
//
constructor TCardUMEx.Create(AOwner: TComponent);
begin
  inherited Create( AOwner );
end;

// -----------------------------------------------------------------------------
procedure TCardUMEx.GetNomDevice;
begin
  inherited GetNomDevice;
end;

// -----------------------------------------------------------------------------
procedure TCardUMEx.innerAfterRead( Dummy: TObject; ReadStatus: TReadStatus; out_buf: array of Byte );
var
  s_      : String;
  L_G     : DWord;
  H_G     : DWord;
  crdData : TCardData;
  CustomData: array of byte;
begin
  inherited;
  crdData.ID_GLOB:= 0;
  crdData.sForeignCardId:= '';
  crdData.bIsOurCard:= False;

  if ReadStatus <> rsOk then
  begin
    if Assigned( FAfterReadBaseData ) then
      FAfterReadBaseData( Self, ReadStatus, crdData);
  end
  else
  begin
    crdData.rgsIDBUF[0] := out_buf[48];
    crdData.rgsIDBUF[1] := out_buf[49];
    crdData.rgsIDBUF[2] := out_buf[50];
    crdData.rgsIDBUF[3] := out_buf[51];
    
    crdData.ID_GLOB :=
        crdData.rgsIDBUF[3] shl 24
      + crdData.rgsIDBUF[2] shl 16
      + crdData.rgsIDBUF[1] shl 8
      + crdData.rgsIDBUF[0];

    SetLength(CustomData, 3);
    CustomData[0]:= out_buf[16];
    CustomData[1]:= out_buf[17];
    CustomData[2]:= out_buf[18];

    crdData.sCardGUID := IntToHex( crdData.ID_GLOB, 8);
    crdData.bIsOurCard:= (CustomData[2] xor crdData.rgsIDBUF[1]) = $01;

    L_G := out_buf[11] shl 24 + out_buf[10] shl 16 + out_buf[9]  shl 8 + out_buf[8];
    H_G := out_buf[15] shl 24 + out_buf[14] shl 16 + out_buf[13] shl 8 + out_buf[12];

    MakeGamm( 8, l_g, h_g, out_buf );
    MakeId( crdData.rgsIDBUF, out_buf );

    if ControlCRC( out_buf, 6 ) then
    begin
      crdData.VN_NOM :=
            out_buf[3]
          + out_buf[4] shl 8
          + out_buf[1] shl 16
          + out_buf[2] shl 24;

      s_ := Format( '%.6d', [crdData.VN_NOM] );
      crdData.sCardID := s_;

      crdData.nCardType:= TCardType((out_buf[0] and $0F) shr 1 );
//      case out_buf[0] and $0E of
//      2: crdData.nCardType:= ctBraclet;
//      4: crdData.nCardType:= ctTrinket;
//      else
//        crdData.nCardType:= ctCard;
//      end;
      crdData.nCardKind:= CustomData[0];
      crdData.nCardColor:= TCardColor(((out_buf[0] and $F0) shr 4) or CustomData[1]);

      if Assigned( FAfterReadBaseData ) then
        FAfterReadBaseData(
                            Self,
                            ReadStatus,
                            crdData
                          );
    end
    else
//      raise EReadCardException.Create( 'Карта не инициализирована' );
      if Assigned( FAfterReadBaseData ) then
        FAfterReadBaseData(
                            Self,
                            rsAutentificationError,
                            crdData
                          );
  end;
end;

// -----------------------------------------------------------------------------
procedure TCardUMEx.ReadBaseData(n: integer);
begin
  if not FKeysSetted then
    raise ECryptKeysNotSet.Create( rsECryptKeysNotSet );

  //Connected := True;
  Self.DataPort.Active:=True;

  ReadSektor( n, tkKey_A );

end;

end.
