unit CardUM;

interface

uses
  SysUtils, Classes, Dialogs, Windows, Math, DataPort, DataPortSerial;

////////////////////////////////////////////////////////////////////////////////
//  
type
  TLastOperation  = ( loUnknown,      loReadSector,   loReadSecData,  loReadSecGam,
                      loWriteSector,  loWriteSecData, loWriteSecGam,  loReadBlok,
                      loGetGamma,     loRecord,       loOprosDevice,  loWriteKey,
                      loSendKey,      loCardKeyQuery, loCardKeySend,  loread8,
                      loread8a,       losendgost,     losendvnid,     loGetNumber
                    );
  TTipKey         = ( tkKey_A, tkKey_B );
  TWrKeyStatus    = ( wkUnknown, wkOk, wkBadKey, wkBadCRC14,
                      wkCardReaderDie, wkWrKeyError, wkBadPort
                    );
  TReadStatus     = ( rsUnknown,    rsOk,         rsBadCRC,               rsCardReaderDie,
                      rsNoCard,     rsBadShersh,  rsAutentificationError, rsReadError,
                      rsBadSend,    rsBadPort
                    );
  TCardType       = ( ctCard = 0,   ctBraclet = 1,    ctTrinket = 2
                    );
  TBracletExecution = (
                        beUnknown = 0, beWithoutLock = 1, beWithLock = 2
                      );
  TTrinketExecution = (
                        teUnknown = 0, tePlastic = 1, teMiniCard = 2
                      );
  TCardColor      = ( ccUnknown = 0,  ccBlue = 1,   ccLightBlue = 2,
                      ccPurple = 3,   ccOrange = 4, ccRed = 5,
                      ccPink = 6,     ccBlack = 7,  ccWhite = 8,
                      ccYellow = 9,   ccLightGreen = 10
                    );
  TCardColorList  = set of TCardColor;

resourcestring
  rsctCard = 'Карта';
  rsctBraclet = 'Браслет';
  rsctTrinket = 'Брелок';

  rs_beWithoutLock  = 'Без застежки';
  rs_beWithLock     = 'C застежкой';
  rs_tePlastic      = 'Пластиковый';
  rs_teMiniCard     = 'Мини-карта';

  rsccUnknown     = '';
  rsccBlue        = 'Синий';
  rsccLigthBlue   = 'Голубой';
  rsccPurple      = 'Фиолетовый';
  rsccOrange      = 'Оранжевый';
  rsccRed         = 'Красный';
  rsccPink        = 'Розовый';
  rsccBlack       = 'Черный';
  rsccWhite       = 'Белый';
  rsccYellow      = 'Желтый';
  rsccLightGreen  = 'Салатовый';

const
  g_ReadStatusStr : array [TReadStatus] of String =
    ( 'rsUnknown',    'rsOk',         'rsBadCRC',               'rsCardReaderDie',
      'rsNoCard',     'rsBadShersh',  'rsAutentificationError', 'rsReadError',
      'rsBadSend',    'rsBadPort'
    );
  g_ReadStatusStrRu : array [TReadStatus] of String =
    ( 'Ошибка чтения',  'Ok',    'CRC не сходится',         'Считыватель неисправен',
      'Карта не обнаружена',     'Ошибка при поиске карты', 'Ошибка аутентификации', 'Ошибка при чтении карты',
      'Параметры чтения заданы пользователем неверно',      'Bad Port'
    );
  g_WrKeyStatus: array [TWrKeyStatus] of string =
    ( 'Unknown', 'Ok', 'Неправильный формат ключа', 'CRC14 не сходится',
      'Считыватель неисправен', 'Ошибка записи ключа', 'Bad Port'
    );

  g_rgsCardReadableType : array[TCardType] of string =
    ( rsctCard, rsctBraclet, rsctTrinket );

  g_ReadBracletExecution : array[TBracletExecution] of string =
    ( '', rs_beWithoutLock, rs_beWithLock
    );
  g_ReadTrinketExecution : array[TTrinketExecution] of string =
    ( '', rs_tePlastic, rs_teMiniCard
    );

  g_rgsCardReadableColor : array[TCardColor] of string =
    ( rsccUnknown, rsccBlue, rsccLigthBlue, rsccPurple, rsccOrange, rsccRed,
      rsccPink, rsccBlack, rsccWhite, rsccYellow, rsccLightGreen );
type
  PTCardData  = ^TCardData;

  TDeviceStatus   = ( dsNo, dsYes, dsBadPort );
  TWriteStatus    = ( wsUnknown,    wsOk,         wsBadCRC,               wsCardReaderDie,
                      wsNoCard,     wsBadShersh,  wsAutentificationError, wsWriteError,
                      wsBadSend,    wsBadID,      wsBadPort
                    );
  TOwnerType       = ( crdtUnknown = -1, crdtStudent = 0, crdtTeacher = 1, crdtService = 2 );

  TCardData   = record
    rgsIDBUF      : array [0..3] of Byte; // BigEndian          Mifare_ID
    sCardGUID     : String; // 8 letters HEX format string      Mifare_ID
    sCardID       : String; // 5 digits                         vnut_number_card
    sCardEmboseer : String; // 48 bytes, filling with Char($20)
    fCardBalance  : Double;
    nCardStatus   : TOwnerType;
    nCardType     : TCardType;
    sCardType     : string;
    nCardKind     : Integer;     // type of kind
    nCardColor    : TCardColor;
    ID_GLOB       : DWord;       // Mifare_ID
    VN_NOM        : Integer;     // vnut_number_card
    sForeignCardId: string;
    bIsOurCard    : Boolean;
  end;

  TCardDataClass = class(TPersistent)
  private
    FrgIDBUFF     : array [0..3] of Byte;  // BigEndian          Mifare_ID
    FMifareID     : DWORD;
    FCardNum      : Integer;
    FCardEmboseer : string;
    FCardBalance  : Double;
    FOwnerType    : TOwnerType;
    FCardType     : TCardType;
    FCardKind     : Integer;
    FCardColor    : TCardColor;
    FIsOurCard    : Boolean;
    FForeignCardId: string;
    function GetRgIDBUFF(Index: Integer): Byte;
    procedure SetCardBalance(const Value: Double);
    procedure SetCardColor(const Value: TCardColor);
    procedure SetCardEmboseer(const Value: string);
    procedure SetCardKind(const Value: Integer);
    procedure SetCardNum(const Value: Integer);
    procedure SetCardType(const Value: TCardType);
    procedure SetMifareID(const Value: DWORD);
    procedure SetOwnerType(const Value: TOwnerType);
    procedure SetRgIDBUFF(Index: Integer; const Value: Byte);
    function GetSCardColor: string;
    function GetSCardKind: string;
    function GetSCardNum: string;
    function GetSCardType: string;
    function GetSMifareID: string;
    procedure SetForeignCardId(const Value: string);
    function GetForeignCardIdF: string;
    procedure SetIsOurCard(const Value: Boolean);
  public
    property rgIDBUFF[Index: Integer]: Byte read GetRgIDBUFF write SetRgIDBUFF;
    property nMifareID: DWORD read FMifareID write SetMifareID;
    property sMifareID: string read GetSMifareID;
    property nCardNum: Integer read FCardNum write SetCardNum;
    property sCardNum: string read GetSCardNum;
    property sCardEmboseer: string read FCardEmboseer write SetCardEmboseer;
    property CardBalance: Double read FCardBalance write SetCardBalance;
    property OwnerType: TOwnerType read FOwnerType write SetOwnerType;
    property nCardType: TCardType read FCardType write SetCardType;
    property sCardType: string read GetSCardType;
    property nCardKind: Integer read FCardKind write SetCardKind;
    property sCardKind: string read GetSCardKind;
    property nCardColor: TCardColor read FCardColor write SetCardColor;
    property sCardColor: string read GetSCardColor;
    property sForeignCardId: string read FForeignCardId write SetForeignCardId;
    property sForeignCardIdF: string read GetForeignCardIdF;
    property bIsOurCard: Boolean read FIsOurCard write SetIsOurCard;
  public
    procedure LoadFromRec(ACardData: TCardData);
    function CompareBase(ASource: TCardDataClass): Boolean;
    function CompareFull(ASource: TCardDataClass): Boolean;
    function CompareNoKind(ASource: TCardDataClass): Boolean;
    procedure Clear;
    procedure Assign(ASource: TPersistent);override;
  public
    constructor Create; overload;
    constructor Create(ACardData: TCardData); overload;
  end;

  TAfterWrKey         = procedure( Sender : TObject; WrKeyStatus : TWrKeyStatus ) of object;
  TDeviceExist        = procedure( Sender : TObject; DeviceStatus : TDeviceStatus ) of object;
  TAfterRead          = procedure( Sender : TObject; ReadStatus : TReadStatus; out_buf : array of Byte ) of object;
  TAfterWrite         = procedure( Sender : TObject; WriteStatus : TWriteStatus ) of object;
  TAfterNomDevice     = procedure( Sender : TObject; Nom_Device : String ) of object;  
  TAfterReadBaseData  = procedure( Sender : TObject; ReadStatus : TReadStatus; cardData: TCardData ) of object;

  //////////////////////////////////////////////////////////////////////////////
  //
  TCardUMExchangeTable  = array [0..7, 0..15] of Byte;
  PTCardUMExchangeTable = ^TCardUMExchangeTable;
  TCardUMKeyTable       = array [0..7] of DWord;  
  PTCardUMKeyTable      = ^TCardUMKeyTable;

  //////////////////////////////////////////////////////////////////////////////
  //
  EReadCardException    = class( Exception );
  ECryptKeysNotSet      = class( Exception );
  
  //////////////////////////////////////////////////////////////////////////////
  //
  TCardUMBase = class( TComponent )
  private
    FLastCard           : String;
    FLastOperation      : TLastOperation;
    FWrKeyStatus        : TWrKeyStatus;
    FReadStatus         : TReadStatus;
    FWriteStatus        : TWriteStatus;
    FAfterWrKey         : TAfterWrKey;
    FExchangeTable      : TCardUMExchangeTable;
    FKeyTable           : TCardUMKeyTable;
    FDataPort           : TDataPort;
    FComPort            : string;
    function FGetActive(): Boolean;
    procedure FSetDataPort(const Value: TDataPort);
    procedure FSetComPort(const Value: string);
    procedure FSetActive(const Value: Boolean);
    procedure MakeGammInner(Col_8 : byte;L_Gamm,H_Gamm:dword;var rx_mas: array of byte);
    procedure UpGammInner(var L_Gamm,H_Gamm:dword);
    procedure OsStep(k,n2,n1:dword; var nn1,nn2:dword);
    procedure DataAppearHandler(Sender: TObject);
    procedure GetData(Sender: TObject; Count: Integer);
    procedure obrabotka;
    procedure WordToAr;
    function StrForKey(c : char): byte;
    function Write(const Buffer; Count: Integer): Integer;
    function WriteStr(Str: AnsiString): Integer;
  protected
    FKeysSetted         : Boolean;
    FDeviceExist        : TDeviceExist;
    FAfterRead          : TAfterRead;
    FAfterWrite         : TAfterWrite;
    FAfterNomDevice     : TAfterNomDevice;
    FAfterReadBaseData  : TAfterReadBaseData;
    procedure ReadBaseData(n: integer = 1); virtual; abstract; // to prevent creation this class objects
    procedure GetNomDevice; virtual;
    procedure innerAfterRead( Dummy : TObject; ReadStatus : TReadStatus; out_buf : array of Byte ); virtual;
  public
    procedure EmulReadSector(arrHexString: string);
    procedure SetKeys( const pexgTbl : PTCardUMExchangeTable; const pkeyTbl : PTCardUMKeyTable );
    procedure MakeGamm(Col_8 : byte; L_Gamm, H_Gamm: dword; var rx_mas: array of byte );
    procedure UpGamm(var L_Gamm, H_Gamm: dword);
    procedure MakeId(ID_buf:array of byte;var rx_buf:array of byte);
    procedure MakeCRC(mas: array of byte; dlina: byte;var bl, bh:byte);
    procedure OprosDevise;
    procedure Wr_Key(n :byte; TipKey : TTipKey; Key : string);
    procedure ReadSektor (n :byte; TipKey : TTipKey);
    procedure WriteSektor (n :byte; TipKey : TTipKey;in_buf:array of byte;in_ID: array of byte);
    procedure ReadBlok (n :byte; TipKey : TTipKey; nb : byte);
    procedure KeyToCard (n :byte; TipKey: TTipKey; in_buf,in_ID: array of byte);
    procedure read8;
    procedure sendkey(nom_CR,k1,k2,k3,k4,k5,k6,k7,k8:dword);
    procedure sendvnid(nom_CR:dword);
    procedure OnLed1;
    procedure OffLed1;
    procedure OnLed2;
    procedure OffLed2;
    procedure OnLed3;
    procedure OffLed3;
    procedure OnLed4;
    procedure OffLed4;
    procedure Signal;
    function ControlCRC(mas: array of byte; dlina: byte): boolean;
  public
    constructor Create( AOwner : TComponent ); override;
    procedure Open();
    procedure Close();
  protected
    //property BaudRate;
    property DeviceExist        : TDeviceExist        read FDeviceExist       write FDeviceExist;
    property AfterWrKey         : TAfterWrKey         read FAfterWrKey        write FAfterWrKey;
    property AfterRead          : TAfterRead          read FAfterRead         write FAfterRead;
    property AfterWrite         : TAfterWrite         read FAfterWrite        write FAfterWrite;
    property AfterNomDevice     : TAfterNomDevice     read FAfterNomDevice    write FAfterNomDevice;
    property AfterReadBaseData  : TAfterReadBaseData  read FAfterReadBaseData write FAfterReadBaseData;
  published
    property DataPort: TDataPort read FDataPort write FSetDataPort;
    property Port: string read FComPort write FSetComPort;
    property Connected: Boolean read FGetActive write FSetActive;
  end;

  //////////////////////////////////////////////////////////////////////////////
  //
  TCardUM = class( TCardUMBase )
  public
    constructor Create( AOwner : TComponent ); override; 
  published
    property DeviceExist;
    property AfterWrKey;
    property AfterRead;
    property AfterWrite;
  end;
 

////////////////////////////////////////////////////////////////////////////////
// TODO:  Attention! - hardcoded pointers to SetKeys routine,
//        use local variables in your own code
(*
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
*) 

////////////////////////////////////////////////////////////////////////////////
//
procedure Register;
procedure StrToByte(s: string; var a, e: byte);

function ReadedCardKind(ACardData: TCardData): string;

implementation

////////////////////////////////////////////////////////////////////////////////
//
var
  rx_mas    : array [0..255]  of Byte;
  gam_mas   : array [0..7]    of Byte;
  key_mas   : array [0..15]   of Byte;
  Write_mas : array [0..55]   of Byte;
  L_Gamm    : DWord;
  H_Gamm    : DWord;
  Cou_RX    : Byte;
  Top_RX    : Byte;

////////////////////////////////////////////////////////////////////////////////
//
procedure Register;
begin
  RegisterComponents('StatusLib', [TCardUM]);
end;

procedure StrToByte(s: string; var a, e: byte);
var
b,c,i:byte;
begin
e:=0; b:=0;
if length(s)<>2 then begin e:=1; exit; end;
s:=uppercase(s);
for i := 1 to 2 do
  if Pos(Copy(s, i, 1), '0123456789ABCDEF')=0 then
    begin
    e:=1; exit;
    end;
for i:=1 to 2 do
      begin
      c:=ord(s[i])-48;
      if c > 9 then c:= c - 7;
      b:= b * 16 + c;
      end;
a:= b;
end;

function ReadedCardKind(ACardData: TCardData): string;
begin
  result:= '';
  case ACardData.nCardType of
  ctTrinket:
  begin
    Result:= g_ReadTrinketExecution[TTrinketExecution(ACardData.nCardKind)]
  end;
  ctBraclet:
  begin
    Result:= g_ReadBracletExecution[TBracletExecution(ACardData.nCardKind)]
  end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//
// { TCardUMEx }
//
constructor TCardUM.Create(AOwner: TComponent);
begin
  inherited Create( AOwner );
end;

////////////////////////////////////////////////////////////////////////////////
//
// { TCardUMBase }
//
constructor TCardUMBase.Create(AOwner: TComponent);
begin
  inherited;
  FLastCard := '';
  //DataPort.OnDataAppear:=DataAppearHandler;
  //OnRxChar := GetData;
  //BaudRate:=br9600;

  FillChar( FKeyTable, SizeOf( TCardUMKeyTable ), 0 );
  FillChar( FExchangeTable, SizeOf( TCardUMExchangeTable ), 0 );

  FKeysSetted := False;
end;

// -----------------------------------------------------------------------------
function TCardUMBase.ControlCRC(mas: array of byte; dlina: byte): boolean;
var
i, j:integer;
w,c_crc,c:word;
b1,b2:byte;
begin
c_crc:=$ffff;
for i:= 0 to dlina-1 do
  begin
  w:=(c_crc xor mas[i])and $ff;
  for j:= 0 to 7 do
    if (w and 1)=1 then
        begin
        w:=w shr 1;
        w:=w xor $8408;
        end else w:=w shr 1;
  c_crc:=w xor (c_crc shr 8);
  end;
c:=$ffff-c_crc;
b1:=c; b2:=c shr 8;
if (b1=mas[dlina])and(b2=mas[dlina+1])then ControlCRC:=true else ControlCRC:=false;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.GetData(Sender: TObject; Count: Integer);
var
  I   : Integer;
  Buf : array[0..10] of Byte;
  s   : AnsiString;
begin
  if FLastOperation = loGetNumber then
  begin
    if Count >= 5 then
    begin
      //ReadStr( s, Count );
      s:=DataPort.Pull(Count);
      I := Ord( s[3] )
       + ( Ord( s[4] ) * $100 )
       + ( Ord( s[5] ) * $10000 )
       + ( Ord( s[6] ) * $1000000 );

      //ClearBuffer( True, True );
      DataPort.Pull();

      FLastOperation := loUnknown;

      if Assigned( FAfterNomDevice ) then
        FAfterNomDevice( Self, IntToStr( I ) );
    end
  end
  else
  begin
    for i:=1 to Count do
    begin
      //Read(Buf,1);
      Buf[0]:=Ord(DataPort.Pull(1)[1]); // Pull 1-byte string and get it's first char as byte
      RX_mas[Cou_RX]:=Buf[0];
      inc (Cou_RX);
      if Cou_RX >= Top_RX then
        obrabotka;
    end;
  end;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.KeyToCard(n: byte;TipKey: TTipKey; in_buf, in_ID: array of byte);
var
  byf:array[0..10] of byte;
  i:byte;
begin
  if n > 15 then
  begin
    FAfterWrite(self,wsBadSend); exit;
  end;
  for i:= 0 to 15 do Write_mas[i]:=in_buf[i];
  for i:= 0 to 3 do Write_mas[i+16]:=in_ID[i];
  Write_mas[20]:=n;
  if TipKey = tkKey_A then Write_mas[21]:= $60 else Write_mas[21]:= $61;
  MakeCRC(Write_mas,22,Write_mas[22],Write_mas[23]);
  FLastOperation := loCardKeyQuery; Cou_RX:=0; Top_RX:=8;
  byf[0]:=$cc;
  byf[1]:=$44;
  Write(byf, 2);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.MakeId(ID_buf: array of byte; var rx_buf: array of byte);
var
  i{, j}:integer;
begin
  for i:=0 to 3 do
  begin
    rx_buf[i] := id_buf[i] xor rx_buf[i];
    rx_buf[i+4] := id_buf[i] xor rx_buf[i+4];
  end;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.MakeCRC(mas: array of byte; dlina: byte; var bl,
  bh: byte);
var
  i, j:integer;
  w,c_crc,c:word;
begin
  c_crc:=$ffff;
  for i:= 0 to dlina-1 do
  begin
    w:=(c_crc xor mas[i])and $ff;
    for j:= 0 to 7 do
    begin
      if (w and 1)=1 then
      begin
        w:=w shr 1;
        w:=w xor $8408;
      end
      else w:=w shr 1;
    end;
    c_crc:=w xor (c_crc shr 8);
  end;
  c:=$ffff-c_crc;
  bl:=c; bh:=c shr 8;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.MakeGammInner(Col_8 : byte; L_Gamm, H_Gamm: dword; var rx_mas: array of byte);
var
  b,i,y,x:byte;
begin
  if Col_8 > 32 then Col_8:= 32;
  i:=0;
  for x:=1 to Col_8 do
  begin
    UpGammInner(L_Gamm,H_Gamm);
    b:=L_Gamm;
    for y:=0 to 3 do
    begin
      rx_mas[i] := rx_mas[i] xor b;
      b := L_Gamm shr ((y+1)*8);
      inc(i);
    end;
    b:=H_Gamm;
    for y:=0 to 3 do
    begin
      rx_mas[i] := rx_mas[i] xor b;
      b := H_Gamm shr ((y+1)*8);
      inc(i);
    end;
  end;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.obrabotka;
var
  i: integer;
  byf: array[0..47] of byte;
begin
  Cou_RX:=0;

  if FLastOperation = loOprosDevice then
  begin
    MakeGammInner(1,L_Gamm,H_Gamm,rx_mas);
    i:=Rx_mas[0]+Rx_mas[1]+Rx_mas[2]+Rx_mas[3]+Rx_mas[4]+Rx_mas[5]+Rx_mas[6]+Rx_mas[7];
    if i=0 then FDeviceExist(self,dsYes) else FDeviceExist(self,dsNo);
    FLastOperation := loUnknown;
    exit;
  end;

  if FLastOperation = loWriteKey then
  begin
    L_Gamm:=RX_mas[0]+RX_mas[1]*$100+RX_mas[2]*$10000+RX_mas[3]*$1000000;
    H_Gamm:=RX_mas[4]+RX_mas[5]*$100+RX_mas[6]*$10000+RX_mas[7]*$1000000;
    for i:=0 to 15 do RX_mas[i]:=key_mas[i];
    MakeGammInner(2, L_Gamm, H_Gamm, rx_mas);
    Write(RX_mas, 16);
    Cou_RX:=0;
    Top_RX:=2;
    FLastOperation := loSendKey;
    exit;
  end;

  if FLastOperation = loSendKey then
  begin
    if (RX_mas[0]=ord('O'))and(RX_mas[1]=ord('K'))then FWrKeyStatus:=wkOk;
    if (RX_mas[0]=$45)and(RX_mas[1]=$E1)then FWrKeyStatus:=wkCardReaderDie;
    if (RX_mas[0]=$45)and(RX_mas[1]=$E7)then FWrKeyStatus:=wkWrKeyError;
    if (RX_mas[0]=$45)and(RX_mas[1]=$14)then FWrKeyStatus:=wkBadCRC14;
    FAfterWrKey(self,FwrKeyStatus);
    FLastOperation := loUnknown;
    exit;
  end;

  if FLastOperation = loReadSector then
  begin
    if (RX_mas[0]=$aa) and (RX_mas[1]=$c4)then
    begin
      Cou_RX:=0; Top_RX:=8;
      FLastOperation := loReadSecGam;
      exit;
    end;
    if (RX_mas[0]=$aa) and (RX_mas[1]=$E1) then FReadStatus:=rsCardReaderDie;
    if (RX_mas[0]=$aa) and (RX_mas[1]=$E2) then FReadStatus:=rsBadShersh;
    if (RX_mas[0]=$aa) and (RX_mas[1]=$42) then FReadStatus:=rsNoCard;
    if (RX_mas[0]=$aa) and (RX_mas[1]=$E3) then FReadStatus:=rsAutentificationError;
    if (RX_mas[0]=$aa) and (RX_mas[1]=$E4) then FReadStatus:=rsReadError;
    if (RX_mas[0]=$aa) and (RX_mas[1]=$14) then FReadStatus:=rsBadCRC;


    FLastOperation := loUnknown;
    innerAfterRead(self,FReadStatus,byf);
    exit;
  end;

  if FLastOperation = loReadSecGam then
  begin
    L_Gamm:=RX_mas[0]+RX_mas[1]*$100+RX_mas[2]*$10000+RX_mas[3]*$1000000;
    H_Gamm:=RX_mas[4]+RX_mas[5]*$100+RX_mas[6]*$10000+RX_mas[7]*$1000000;
    Cou_RX:=0;
    Top_RX:=56;
    FLastOperation := loReadSecData;
    exit;
  end;

  if FLastOperation = loReadSecData then
  begin
    MakeGammInner(7,L_Gamm,H_Gamm,rx_mas);
    FLastOperation := loUnknown;
    if ControlCRC(Rx_mas, 54) then
      innerAfterRead( self, rsOk,     rx_mas )
    else
      innerAfterRead( self, rsBadCRC, rx_mas );

    exit;
  end;

  if FLastOperation = loWriteSector then
  begin
    L_Gamm:=RX_mas[0]+RX_mas[1]*$100+RX_mas[2]*$10000+RX_mas[3]*$1000000;
    H_Gamm:=RX_mas[4]+RX_mas[5]*$100+RX_mas[6]*$10000+RX_mas[7]*$1000000;
    for i:= 0 to 55 do RX_mas[i]:=Write_mas[i];
    Cou_RX:=0;
    Top_RX:=2;
    FLastOperation := loWriteSecData;
    MakeGammInner(7,L_Gamm,H_Gamm,rx_mas);
    Write(RX_mas, 56);
    exit;
  end;

  if (FLastOperation = loWriteSecData)or(FLastOperation = loCardKeySend) then
  begin
    if (RX_mas[0]=$aa) and (RX_mas[1]=$c5) then FWriteStatus:=wsOk;
    if (RX_mas[0]=$45) and (RX_mas[1]=$E1) then FWriteStatus:=wsCardReaderDie;
    if (RX_mas[0]=$45) and (RX_mas[1]=$E2) then FWriteStatus:=wsBadShersh;
    if (RX_mas[0]=$45) and (RX_mas[1]=$42) then FWriteStatus:=wsNoCard;
    if (RX_mas[0]=$45) and (RX_mas[1]=$E3) then FWriteStatus:=wsAutentificationError;
    if (RX_mas[0]=$45) and (RX_mas[1]=$E5) then FWriteStatus:=wsWriteError;
    if (RX_mas[0]=$45) and (RX_mas[1]=$14) then FWriteStatus:=wsBadCRC;
    if (RX_mas[0]=$45) and (RX_mas[1]=$33) then FWriteStatus:=wsBadID;
    FLastOperation := loUnknown;
    FAfterWrite(self,FWriteStatus);
    exit;
  end;

  if FLastOperation = loCardKeyQuery then
  begin
    L_Gamm := RX_mas[0] + RX_mas[1] * $100 + RX_mas[2] * $10000 + RX_mas[3] * $1000000;
    H_Gamm:=RX_mas[4]+RX_mas[5]*$100+RX_mas[6]*$10000+RX_mas[7]*$1000000;
    for i:= 0 to 23 do RX_mas[i]:=Write_mas[i];
    Cou_RX := 0;
    Top_RX := 2;
    FLastOperation := loCardKeySend;
    MakeGammInner( 3, L_Gamm, H_Gamm, rx_mas );
    Write(RX_mas, 24);
    exit;
  end;

  if FLastOperation = loread8 then
  begin
    if (Rx_mas[0]=$aa)and(Rx_mas[1]=$c7) then
    begin
      Cou_RX:=0; Top_RX:=20;FLastOperation := loread8a;
    end
    else FLastOperation := loUnknown;
    exit;
  end;

  if FLastOperation = loread8a then
  begin
    Rx_mas[0]:=Rx_mas[4];Rx_mas[1]:=Rx_mas[5];Rx_mas[2]:=Rx_mas[6];Rx_mas[3]:=Rx_mas[7];
    Rx_mas[4]:=Rx_mas[8];Rx_mas[5]:=Rx_mas[9];Rx_mas[6]:=Rx_mas[10];Rx_mas[7]:=Rx_mas[11];
    MakeGammInner(1,L_Gamm,H_Gamm,rx_mas);
    i:=Rx_mas[0]+Rx_mas[1]+Rx_mas[2]+Rx_mas[3]+Rx_mas[4]+Rx_mas[5]+Rx_mas[6]+Rx_mas[7];
    if i=0 then FDeviceExist(self,dsYes)else FDeviceExist(self,dsNo);
    FLastOperation := loUnknown;
    exit;
  end;

  if FLastOperation = losendgost then
  begin
    if (Rx_mas[0]=$4f)and (Rx_mas[1]=$4b) then FDeviceExist(self,dsYes);
    FLastOperation := loUnknown;
    exit;
  end;

  if FLastOperation = losendvnid then
  begin
    if (Rx_mas[0]=ord('B'))and (Rx_mas[1]=ord('P')) then FDeviceExist(self,dsYes);
    FLastOperation := loUnknown;
    exit;
  end;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OffLed1;
begin
  WriteStr('М1');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OffLed2;
begin
  WriteStr('М2');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OffLed3;
begin
  WriteStr('М3');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OffLed4;
begin
  WriteStr('М4');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OnLed1;
begin
  WriteStr('Мq');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OnLed2;
begin
  WriteStr('Мr');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OnLed3;
begin
  WriteStr('Мs');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OnLed4;
begin
  WriteStr('Мt');
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OprosDevise;
var
  byf:array[0..10] of byte;
begin
  FLastOperation := loOprosDevice; Cou_RX:=0; Top_RX:=8;
  UpGammInner(L_Gamm,H_Gamm);
  WordToAr;
  byf[0]:=$cc;
  byf[1]:=$22;
  Write(byf,2);
  Write(gam_mas,8);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.OsStep(k, n2, n1: dword; var nn1, nn2: dword);
var
  s,so,sb,i:dword;
  b:byte;
begin
  so:=0;
  s:=n1+k;
  sb:=s and $f0000000;
  b:=sb shr 28;
  for i:=0 to 7 do
  begin
    b:=FExchangeTable[7 - i, b]; //tab_zam[7-i,b];
    so:=(so shl 4)+b;
    s:=s shl 4;
    sb:=s and $f0000000;
    b:=sb shr 28;
  end;
  s:=so shr 21;
  so:=so shl 11;
  so:=so or s;
  so:= so xor n2;
  nn2:=n1;
  nn1:=so;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.read8;
var
  byf: array[0..10] of byte;
begin
  FLastOperation := loread8;
  Cou_RX:=0;
  Top_RX:=2;
  UpGammInner(L_Gamm,H_Gamm);
  WordToAr;
  byf[0]:=$cc;
  byf[1]:=$37;
  Write(byf,2);
  Write(gam_mas,8);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.ReadBlok(n: byte; TipKey: TTipKey; nb: byte);
begin

end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.ReadSektor(n: byte; TipKey: TTipKey);
var
  byf : array[0..47] of Byte;
begin
  if n > 15 then
  begin
    innerAfterRead(self,rsBadSend,byf);
    Exit;
  end;

  FLastOperation  := loReadSector;
  Cou_RX          := 0;
  Top_RX          := 2;

  if TipKey = tkKey_A then
    byf[3] := $60
  else
    byf[3] := $61;
    
//Key A
//0xCC 0x66 0x_Номер_Сектора 0x60

//Key B
//0xCC 0x66 0x_Номер_Сектора 0x61

  byf[0]:= $cc;
  byf[1]:= $66;
  byf[2]:= n;

  if Write(byf,4) = 0 then
    innerAfterRead(self,rsBadPort,byf);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.sendkey( nom_CR,k1,k2,k3,k4,k5,k6,k7,k8 :dword );
var
  byf : array[0..47] of Byte;
begin
  FLastOperation := losendgost;
  Cou_RX:=0;
  Top_RX:=2;

  byf[0]:=$cc;
  byf[1]:=$15;
  byf[2]:=$41;
  byf[3]:=$59;
  byf[4]:=$46;
  Write(byf,5);

  byf[0]:=nom_CR;
  byf[1]:=nom_CR shr 8;
  byf[2]:=nom_CR shr 16;
  byf[3]:=nom_CR shr 24;
  Write(byf,4);

  byf[0]:= k1;
  byf[1]:= k1 shr 8;
  byf[2]:= k1 shr 16;
  byf[3]:=k1 shr 24;
  Write(byf,4);

  byf[0]:= k2;
  byf[1]:= k2 shr 8;
  byf[2]:= k2 shr 16;
  byf[3]:=k2 shr 24;
  Write(byf,4);

  byf[0]:= k3;
  byf[1]:= k3 shr 8;
  byf[2]:= k3 shr 16;
  byf[3]:=k3 shr 24;
  Write(byf,4);

  byf[0]:= k4;
  byf[1]:= k4 shr 8;
  byf[2]:= k4 shr 16;
  byf[3]:=k4 shr 24;
  Write(byf,4);

  byf[0]:= k5;
  byf[1]:= k5 shr 8;
  byf[2]:= k5 shr 16;
  byf[3]:=k5 shr 24;
  Write(byf,4);

  byf[0]:= k6;
  byf[1]:= k6 shr 8;
  byf[2]:= k6 shr 16;
  byf[3]:=k6 shr 24;
  Write(byf,4);

  byf[0]:= k7;
  byf[1]:= k7 shr 8;
  byf[2]:= k7 shr 16;
  byf[3]:=k7 shr 24;
  Write(byf,4);

  byf[0]:= k8;
  byf[1]:= k8 shr 8;
  byf[2]:= k8 shr 16;
  byf[3]:=k8 shr 24;
  Write(byf,4);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.sendvnid(nom_CR:dword);
var
  byf:array[0..47] of byte;
begin
  FLastOperation := losendvnid;
  Cou_RX:=0;
  Top_RX:=2;
  WriteStr('QART');
  byf[0]:=nom_CR;
  byf[1]:=nom_CR shr 8;
  byf[2]:=nom_CR shr 16;
  byf[3]:=nom_CR shr 24;
  Write(byf,4);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.Signal;
begin
  WriteStr('М6');
end;

// -----------------------------------------------------------------------------
function TCardUMBase.StrForKey(c: char): byte;
begin
case c of
  '0': StrForKey:=$f0;
  '1': StrForKey:=$e1;
  '2': StrForKey:=$d2;
  '3': StrForKey:=$c3;
  '4': StrForKey:=$b4;
  '5': StrForKey:=$a5;
  '6': StrForKey:=$96;
  '7': StrForKey:=$87;
  '8': StrForKey:=$78;
  '9': StrForKey:=$69;
  'A': StrForKey:=$5a;
  'a': StrForKey:=$5a;
  'B': StrForKey:=$4b;
  'b': StrForKey:=$4b;
  'C': StrForKey:=$3c;
  'c': StrForKey:=$3c;
  'D': StrForKey:=$2d;
  'd': StrForKey:=$2d;
  'E': StrForKey:=$1e;
  'e': StrForKey:=$1e;
  'F': StrForKey:=$0f;
  'f': StrForKey:=$0f;
  else
    StrForKey:=$ee;
  end;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.UpGammInner(var L_Gamm,H_Gamm:dword);
var
  nn1, nn2 : dword;
  y,i : integer;
begin
  L_Gamm:=(L_Gamm+$01010101)mod$100000000;
  H_Gamm:=((H_Gamm+$01010104-1)mod $ffffffff)+1;

  for y:= 1 to 3 do
    for i:= 0 to 7 do
    begin
      OsStep( FKeyTable[i]{key_tab[i]}, H_Gamm, L_Gamm, nn1, nn2 );
      H_Gamm:=nn2;
      L_Gamm:=nn1;
    end;

  for i:= 0 to 7 do
  begin
    OsStep( FKeyTable[7 - i]{key_tab[7-i]}, H_Gamm, L_Gamm, nn1, nn2 );
    H_Gamm:=nn2;
    L_Gamm:=nn1;
  end;

  H_Gamm:=nn1;
  L_Gamm:=nn2;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.WordToAr;
begin
  gam_mas[0]:=L_Gamm;
  gam_mas[1]:=L_Gamm shr 8;
  gam_mas[2]:=L_Gamm shr 16;
  gam_mas[3]:=L_Gamm shr 24;

  gam_mas[4]:=H_Gamm;
  gam_mas[5]:=H_Gamm shr 8;
  gam_mas[6]:=H_Gamm shr 16;
  gam_mas[7]:=H_Gamm shr 24;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.WriteSektor(n: byte; TipKey: TTipKey; in_buf: array of byte;in_ID: array of byte);
var
  byf : array[0..10] of Byte;
  i   : Byte;
begin
  if n > 15 then
  begin
    FAfterWrite(self,wsBadSend);
    Exit;
  end;

  for i:= 0 to 47 do
    Write_mas[i]:=in_buf[i];
  for i:= 0 to 3 do
    Write_mas[i+48]:=in_ID[i];

  Write_mas[52]:=n;

  if TipKey = tkKey_A then
    Write_mas[53]:= $60
  else Write_mas[53]:= $61;

  MakeCRC(Write_mas,54,Write_mas[54],Write_mas[55]);
  FLastOperation := loWriteSector;
  Cou_RX:=0;
  Top_RX:=8;

  byf[0]:=$cc;
  byf[1]:=$55;
  Write(byf,2);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.Wr_Key(n: byte; TipKey : TTipKey; Key : string);
var
  byf : Array[0..10] of byte;
  i   : Byte;
begin
  if (n > 15) or (length(Key)<>12)then
  begin
    FAfterWrKey(self,wkBadKey);
    exit;
  end;
  for i:=0 to 11 do
  begin
    key_mas[i]:= StrForKey(Key[i+1]);
    if key_mas[i]=$ee then
    begin
      FAfterWrKey(self,wkBadKey); exit;
    end;
  end;
  key_mas[12]:= n;
  if TipKey = tkKey_A then key_mas[13]:= $0 else key_mas[13]:= $1;
  MakeCRC(key_mas,14,key_mas[14],key_mas[15]);
  FLastOperation := loWriteKey; Cou_RX:=0; Top_RX:=8;

  byf[0]:=$cc;
  byf[1]:=$11;
  Write(byf,2);
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.MakeGamm(Col_8: byte; L_Gamm, H_Gamm: dword; var rx_mas: array of byte);
begin
  Assert( FKeysSetted );
  MakeGammInner( Col_8, L_Gamm, H_Gamm, rx_mas );
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.UpGamm(var L_Gamm, H_Gamm: dword);
begin
  Assert( FKeysSetted );
  UpGammInner( L_Gamm, H_Gamm );
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.SetKeys( const pexgTbl: PTCardUMExchangeTable; const pkeyTbl: PTCardUMKeyTable);
begin
  Assert( Assigned( pexgTbl ) and Assigned( pkeyTbl ) );

  CopyMemory( @(FExchangeTable[0]), pexgTbl, SizeOf( TCardUMExchangeTable ) );
  CopyMemory( @(FKeyTable[0]), pkeyTbl, SizeOf( TCardUMKeyTable ) );

  FKeysSetted := True;
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.innerAfterRead( Dummy: TObject; ReadStatus: TReadStatus; out_buf: array of Byte );
begin
  if Assigned( FAfterRead ) then
    FAfterRead( Self, ReadStatus, out_buf );
end;

// -----------------------------------------------------------------------------
procedure TCardUMBase.GetNomDevice;
begin
  FLastOperation := loGetNumber;
  //Connected := True;
  DataPort.Active:=True;
  WriteStr( 'QN' );
end;

procedure TCardUMBase.DataAppearHandler(Sender: TObject);
begin
  GetData(Sender, DataPort.PeekSize());
end;

procedure TCardUMBase.EmulReadSector(arrHexString: string);
var
  i, count: Integer;
  Buf: array of Byte;
begin
  FLastOperation  := loReadSector;
  Cou_RX          := 0;
  Top_RX          := 2;

  i:= 1;
  while i < Length(arrHexString) do
  begin
    count:= Length(Buf);
    SetLength(Buf, count + 1);
//    Buf[count]:= StrToUInt('$'+arrHexString[i]+arrHexString[I+1]) and $FF;
    inc(i, 2);
  end;
  count:= Length(Buf);

    for i:=0 to Count do
    begin
      //Read(Buf,1);
//      Buf[0]:=Ord(DataPort.Pull(1)[1]); // Pull 1-byte string and get it's first char as byte
      RX_mas[Cou_RX]:=Buf[i];
      inc (Cou_RX);
      if Cou_RX >= Top_RX then
        obrabotka;
    end;
end;

function TCardUMBase.Write(const Buffer; Count: Integer): Integer;
var
  s: AnsiString;
begin
  Result:=0;
  try
    s:= '';
    SetString(s, PAnsiChar(@Buffer), Count);
    DataPort.Push(s);
    Result:=Count;
  except
    DataPort.Active:=False;
    FAfterWrKey(self, wkBadPort);
  end;
end;

function TCardUMBase.WriteStr(Str: AnsiString): Integer;
begin
  Result:=0;
  try
    DataPort.Push(Str);
    Result:=Length(str);
  except
    DataPort.Active:=False;
    FAfterWrKey(self, wkBadPort);
  end;
end;

procedure TCardUMBase.FSetDataPort(const Value: TDataPort);
begin
  Self.FDataPort:=Value;
  if Assigned(Self.FDataPort) then Self.FDataPort.OnDataAppear:=DataAppearHandler;
end;

procedure TCardUMBase.FSetComPort(const Value: string);
begin
  FComPort:=Value;
  if not Assigned(DataPort) then DataPort:=TDataPortSerial.Create(self);
  if (DataPort is TDataPortSerial) then
  begin
    (DataPort as TDataPortSerial).Port:=Value;
  end;
end;

procedure TCardUMBase.Close();
begin
  if Assigned(DataPort) then DataPort.Active:=False;
end;

procedure TCardUMBase.Open();
begin
  if Assigned(DataPort) then DataPort.Active:=True;
end;

function TCardUMBase.FGetActive: Boolean;
begin
  Result:=False;
  if Assigned(DataPort) then Result:=DataPort.Active;
end;

procedure TCardUMBase.FSetActive(const Value: Boolean);
begin
  if Value then
    Open()
  else
    Close;
end;

{ TCardDataClass }

procedure TCardDataClass.Assign(ASource: TPersistent);  
var
  i: Integer;
begin
  Self.Clear;
  if not (ASource is TCardDataClass) then Exit;
  for i:= 0 to 3 do
    Self.rgIDBUFF[i]:= (ASource as TCardDataClass).rgIDBUFF[i];
  Self.nMifareID     := (ASource as TCardDataClass).nMifareID;
  Self.nCardNum      := (ASource as TCardDataClass).nCardNum;
  Self.sCardEmboseer := (ASource as TCardDataClass).sCardEmboseer;
  Self.CardBalance   := (ASource as TCardDataClass).CardBalance;
  Self.OwnerType     := (ASource as TCardDataClass).OwnerType;
  Self.nCardType     := (ASource as TCardDataClass).nCardType;
  Self.nCardKind     := (ASource as TCardDataClass).nCardKind;
  Self.nCardColor    := (ASource as TCardDataClass).nCardColor;
  Self.sForeignCardId:= (ASource as TCardDataClass).sForeignCardId;
  Self.bIsOurCard    := (ASource as TCardDataClass).bIsOurCard;
end;

procedure TCardDataClass.Clear;
var
  i: Integer;
begin
  for i:= 0 to 3 do
    FrgIDBUFF[i]:= $00;

  FMifareID     := $00;
  FCardNum      := 0;
  FCardEmboseer := '';
  FCardBalance  := 0.0;
  FOwnerType    := crdtUnknown;
  FCardType     := ctCard;
  FCardKind     := 0;
  FCardColor    := ccUnknown;
  FForeignCardId:= '';
  FIsOurCard    := False;
end;

function TCardDataClass.CompareBase(ASource: TCardDataClass): Boolean;
begin
  Result:= Assigned(ASource)
    and (ASource.nMifareID = Self.nMifareID)
    and (ASource.nCardNum  = Self.nCardNum)
    and (ASource.nCardType = Self.nCardType)
end;

function TCardDataClass.CompareFull(ASource: TCardDataClass): Boolean;
begin
  Result:= Self.CompareNoKind(ASource)
    and (ASource.nCardKind = Self.nCardKind)
end;

function TCardDataClass.CompareNoKind(ASource: TCardDataClass): Boolean;
begin
  Result:= Self.CompareBase(ASource)
    and (ASource.nCardColor= Self.nCardColor)
end;

constructor TCardDataClass.Create(ACardData: TCardData);
begin
  Create;
  LoadFromRec(ACardData);
end;

constructor TCardDataClass.Create;
begin
  inherited Create;
  Clear;
end;

function TCardDataClass.GetForeignCardIdF: string;
var
  s: string;
  i: Integer;
begin
  s:= FForeignCardId;
  i:= Length(s) + 1;
  while (i - 5) > 0 do
  begin
    i:= i - 5;
    Insert(' ', s, i);
  end;
  Result:= s;
end;

function TCardDataClass.GetRgIDBUFF(Index: Integer): Byte;
begin
  Result:= FrgIDBUFF[Index];
end;

function TCardDataClass.GetSCardColor: string;
begin
  Result:= g_rgsCardReadableColor[FCardColor]
end;

function TCardDataClass.GetSCardKind: string;
begin
  result:= '';
  case nCardType of
  ctTrinket:
  begin
    Result:= g_ReadTrinketExecution[TTrinketExecution(nCardKind)]
  end;
  ctBraclet:
  begin
    Result:= g_ReadBracletExecution[TBracletExecution(nCardKind)]
  end;
  end;
end;

function TCardDataClass.GetSCardNum: string;
begin
  Result:= Format('%0.6d', [nCardNum])
end;

function TCardDataClass.GetSCardType: string;
begin
  Result:= g_rgsCardReadableType[nCardType];
end;

function TCardDataClass.GetSMifareID: string;
begin
  result:= IntToHex( nMifareID, 8);
end;

procedure TCardDataClass.LoadFromRec(ACardData: TCardData);
var
  i: Integer;
begin
  for i:= 0 to 3 do
    rgIDBUFF[i]:= ACardData.rgsIDBUF[i];

  nMifareID     := ACardData.ID_GLOB;
  FCardNum      := ACardData.VN_NOM;
  FCardEmboseer := ACardData.sCardEmboseer;
  FCardBalance  := ACardData.fCardBalance;
  FOwnerType    := ACardData.nCardStatus;
  FCardType     := ACardData.nCardType;
  FCardKind     := ACardData.nCardKind;
  FCardColor    := ACardData.nCardColor;
  FForeignCardId:= ACardData.sForeignCardId;
  FIsOurCard    := ACardData.bIsOurCard;
end;

procedure TCardDataClass.SetCardBalance(const Value: Double);
begin
  FCardBalance := Value;
end;

procedure TCardDataClass.SetCardColor(const Value: TCardColor);
begin
  FCardColor := Value;
end;

procedure TCardDataClass.SetCardEmboseer(const Value: string);
begin
  FCardEmboseer := Value;
end;

procedure TCardDataClass.SetCardKind(const Value: Integer);
begin
  FCardKind := Value;
end;

procedure TCardDataClass.SetCardNum(const Value: Integer);
begin
  FCardNum := Value;
end;

procedure TCardDataClass.SetCardType(const Value: TCardType);
begin
  FCardType := Value;
end;

procedure TCardDataClass.SetForeignCardId(const Value: string);
begin
  FForeignCardId := Value;
end;

procedure TCardDataClass.SetIsOurCard(const Value: Boolean);
begin
  FIsOurCard := Value;
end;

procedure TCardDataClass.SetMifareID(const Value: DWORD);
begin
  FMifareID := Value;
  FrgIDBUFF[3]:= (FMifareID shr 24 ) and $ff;
  FrgIDBUFF[2]:= (FMifareID shr 16 ) and $ff;
  FrgIDBUFF[1]:= (FMifareID shr 8  ) and $ff;
  FrgIDBUFF[0]:= (FMifareID        ) and $ff;
end;

procedure TCardDataClass.SetOwnerType(const Value: TOwnerType);
begin
  FOwnerType := Value;
end;

procedure TCardDataClass.SetRgIDBUFF(Index: Integer; const Value: Byte);
begin
  FrgIDBUFF[Index]:= Value;
  FMifareID:= FrgIDBUFF[3] shl 24
            + FrgIDBUFF[2] shl 16
            + FrgIDBUFF[1] shl 8
            + FrgIDBUFF[0];
end;

end.
