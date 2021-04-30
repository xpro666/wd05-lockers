program CdxWD05Test;





uses
  Vcl.Forms,
  MainUnit in 'MainUnit.pas' {frmCdxWD05},
  core in 'src\core.pas',
  WD05Unit in 'src\WD05Unit.pas',
  CardReaderUnit in 'CardReaderUnit.pas' {frmReadCard};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmCdxWD05, frmCdxWD05);
  Application.Run;
end.
