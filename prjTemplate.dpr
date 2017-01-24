program prjTemplate;





{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {fmMain},
  uConsts in 'Units\uConsts.pas',
  uCommonUtils in 'Units\uCommonUtils.pas',
  FontAwesome in 'Units\FontAwesome.pas',
  FMX.StatusBar in 'Units\FMX.StatusBar.pas',
  FMX.FontGlyphs.Android in 'Units\FMX.FontGlyphs.Android.pas',
  FMX.FontGlyphs in 'Units\FMX.FontGlyphs.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.Run;
end.
