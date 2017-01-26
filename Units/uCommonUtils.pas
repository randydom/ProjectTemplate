unit uCommonUtils;

interface

uses FMX.ListView.Types, FMX.Graphics, FMX.Controls, FMX.SearchBox;

{$IFDEF ANDROID}
type
  {$SCOPEDENUMS ON}
  TDeviceType = (dpPhone, dpFablet, dpTablet);
  //Тип для определения типа устройста: телефон, фаблеи, планшет
  {$SCOPEDENUMS OFF}
{$ENDIF}

  function GetScale: Single;
  //Возвращает скэйл экрана

  function GetPrivedScale: Single;
  //Возвращает "приведеный" скэйл

  function LVTextHeight(const AText: TListItemText): Single;
  //Возвращает высоту текста

  function LVTextWidth(const AText: TListItemText): Single;
  //Возвращает ширину текста

  function TextHeight(const AText: string; aTextSettings: TTextSettings; const aWidth: Single): Single;
  // Подсчет высоты текста на основе его ширины и настроек шрифта

  function FileNameFromURL(const aURL: string): string;
  //Возвращает имя файла из URL

  function InternetEnabled: Boolean;
  //Проверка налиция интернета

  function FindSearchBox(const ARootControl: TControl): TSearchBox;
  //Нахождение и возвращение TSearchBox

  {$IFDEF ANDROID}
  function GetAndroidOSVersion: string;
  //Номер версии Android-приложения

  function GetDeviceType: TDeviceType;
  //Возвращает тип устройства: телефон, фаблет, планшет
  {$ENDIF}


implementation

uses FMX.Platform, System.SysUtils, FMX.TextLayout, System.Math, System.Types,
     FMX.Types, System.Net.HttpClient, System.Net.HttpClientComponent
     {$IFDEF ANDROID},  AndroidApi.JNI.OS, Androidapi.Helpers, FMX.BehaviorManager, FMX.Forms,
     System.Devices{$ENDIF};

function FindSearchBox(const ARootControl: TControl): TSearchBox;
//Нахождение и возвращение TSearchBox
var
  Child: TControl;
begin
  Result := nil;
  for Child in ARootControl.Controls do
    if Child is TSearchBox then
      Exit(TSearchBox(Child));
end;

function GetScale: Single;
//Возвращает скэйл экрана
var
  ScreenService: IFMXScreenService;
begin
  Result := 1.0;
  try
    if TPlatformServices.Current.SupportsPlatformService(IFMXScreenService, IInterface(ScreenService)) then
      Result := ScreenService.GetScreenScale;
  except
    Result := 1.0;
  end;
end;

function GetPrivedScale: Single;
//Возвращает "приведеный" скэйл
var
  r: Single;
begin
  r := GetScale;
  if r < 1 then
    r := 1;
  if (r >= 1.01) and (r <= 1.49) then
    r := 1;
  if (r >= 1.51) and (r <= 1.99) then
    r := 1.5;
  if (r >= 2.01) and (r <= 2.49) then
    r := 2;
  if (r >= 2.51) and (r <= 2.99) then
    r := 2.5;
  if (r >= 3.01) and (r <= 3.49) then
    r := 3;
  if (r >= 3.51) and (r <= 3.99) then
    r := 3.5;
  if r > 4.0 then
    r := 4;
  Result := r;
end;

function LVTextHeight(const AText: TListItemText): Single;
//Возвращает высоту текста ЛВ
var
  Layout: TTextLayout;
  aRect: TRectF;
  aWW: boolean;
begin
  Result := 0;
  if AText.Text.IsEmpty then
    Exit;

  aWW := Pos(#13#10, AText.Text) > 0;
  if (AText.WordWrap) or (aWW) then
    aRect := RectF(0, 0, AText.Width, MaxSingle)
  else
    aRect := RectF(0, 0, MaxSingle, MaxSingle);
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.TopLeft := aRect.TopLeft;
    Layout.MaxSize := PointF(aRect.Width, aRect.Height);
    Layout.WordWrap := AText.WordWrap;
    Layout.Trimming := AText.Trimming;
    Layout.HorizontalAlign := TTextAlign.Leading;
    Layout.VerticalAlign := TTextAlign.Leading;
    Layout.Font.Assign(AText.Font);
    Layout.Color := AText.TextColor;
    Layout.RightToLeft := False;
    Layout.Text := AText.Text;
    Layout.EndUpdate;
    aRect := Layout.TextRect;
  finally
    {$IF defined(MSWINDOWS)}
    FreeAndNil(Layout);
    {$ELSEIF defined(ANDROID)}
    Layout.DisposeOf;
    Layout := nil;
    {$ENDIF}
  end;
  Result := aRect.Bottom;
end;

function LVTextWidth(const AText: TListItemText): Single;
//Возвращает ширину текста ЛВ
var
  Layout: TTextLayout;
  aRect: TRectF;
  aWW: boolean;
begin
  Result := 0;
  if AText.Text.IsEmpty then
    Exit;

  aWW := Pos(#13#10, AText.Text) > 0;
  if (AText.WordWrap) or (aWW) then
    aRect := RectF(0, 0, AText.Width, MaxSingle)
  else
    aRect := RectF(0, 0, MaxSingle, MaxSingle);
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.TopLeft := aRect.TopLeft;
    Layout.MaxSize := PointF(aRect.Width, aRect.Height);
    Layout.WordWrap := AText.WordWrap;
    Layout.Trimming := AText.Trimming;
    Layout.HorizontalAlign := TTextAlign.Leading;
    Layout.VerticalAlign := TTextAlign.Leading;
    Layout.Font.Assign(AText.Font);
    Layout.Color := AText.TextColor;
    Layout.RightToLeft := False;
    Layout.Text := AText.Text;
    Layout.EndUpdate;
    aRect := Layout.TextRect;
  finally
    {$IF defined(MSWINDOWS)}
    FreeAndNil(Layout);
    {$ELSEIF defined(ANDROID)}
    Layout.DisposeOf;
    Layout := nil;
    {$ENDIF}
  end;
  Result := aRect.Right;
end;

function TextHeight(const AText: string; aTextSettings: TTextSettings; const aWidth: Single): Single;
// Подсчет высоты текста на основе его ширины и настроек шрифта
var
  Layout: TTextLayout;
  aRect: TRectF;
  aWW: boolean;
begin
  Result := 0;
  if AText.IsEmpty then
    Exit;

  aWW := Pos(#13#10, AText) > 0;
  if (aTextSettings.WordWrap) or (aWW) then
    aRect := RectF(0, 0, aWidth, MaxSingle)
  else
    aRect := RectF(0, 0, MaxSingle, MaxSingle);
  Layout := TTextLayoutManager.DefaultTextLayout.Create;
  try
    Layout.BeginUpdate;
    Layout.TopLeft := aRect.TopLeft;
    Layout.MaxSize := PointF(aRect.Width, aRect.Height);
    Layout.WordWrap := aTextSettings.WordWrap;
    Layout.HorizontalAlign := TTextAlign.Leading;
    Layout.VerticalAlign := TTextAlign.Leading;
    Layout.Font.Assign(aTextSettings.Font);
    Layout.Color := aTextSettings.FontColor;
    Layout.RightToLeft := false;
    Layout.Text := AText;
    Layout.EndUpdate;
    aRect := Layout.TextRect;
  finally
    {$IF defined(MSWINDOWS)}
    FreeAndNil(Layout);
    {$ELSEIF defined(ANDROID)}
    Layout.DisposeOf;
    Layout := nil;
    {$ENDIF}
  end;
  Result := aRect.Bottom;
end;

function FileNameFromURL(const aURL: string): string;
//Возвращает имя файла из URL
var
  i: Integer;
begin
  i := LastDelimiter('/', aURL);
  Result := Copy(aURL, i + 1, Length(aURL) - i);
end;

function InternetEnabled: Boolean;
//Проверка налиция интернета
var
  Resp: IHTTPResponse;
begin
  Result := False;
  with TNetHTTPClient.Create(nil) do
    begin
      try
        Resp := Head('http://google.com');
        Result := Resp.StatusCode < 400;
      except
        Result := False;
      end;
      Free;
    end;
end;

{$IFDEF ANDROID}
function GetAndroidOSVersion: string;
//Номер версии Android-приложения
begin
  Result := JStringToString(TJBuild_VERSION.JavaClass.release);
end;

function DefineDeviceClassByFormSize: TDeviceInfo.TDeviceClass;
const
  MaxPhoneWidth = 640;
begin
  if Screen.ActiveForm.Width <= MaxPhoneWidth then
    Result := TDeviceInfo.TDeviceClass.Phone
  else
    Result := TDeviceInfo.TDeviceClass.Tablet;
end;

function IsDeviceType: TDeviceInfo.TDeviceClass;
var
  DeviceService: IDeviceBehavior;
  Context: TFMXObject;
begin
  Context := Screen.ActiveForm;
  if TBehaviorServices.Current.SupportsBehaviorService(IDeviceBehavior, DeviceService, Context) then
    Result := DeviceService.GetDeviceClass(Context)
  else
    Result := DefineDeviceClassByFormSize;
end;

function GetDeviceType: TDeviceType;
//Возвращает тип устройства: телефон, фаблет, планшет
const
  MinLogicaSizeForLargePhone = 736;
var
  ThisDevice: TDeviceInfo;
begin
  Result := TDeviceType.dpPhone;

  if IsDeviceType = TDeviceInfo.TDeviceClass.Tablet then
    Result := TDeviceType.dpTablet;

  ThisDevice := TDeviceInfo.ThisDevice;
  if ThisDevice <> nil then
    if Max(ThisDevice.MinLogicalScreenSize.Width, ThisDevice.MinLogicalScreenSize.Height) >= MinLogicaSizeForLargePhone then
      Result := TDeviceType.dpFablet;
end;
{$ENDIF}

end.
