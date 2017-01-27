unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, FMX.Types, FMX.Controls, FMX.Forms,
  FMX.Graphics, FMX.Dialogs, FMX.Effects, FMX.StdCtrls, FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
  FMX.MultiView, FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView, uCommonUtils, FMX.ListView.Adapters.Base;

type
  TSpeedButton = class(FMX.StdCtrls.TSpeedButton)
  protected
    procedure AdjustFixedSize(const Ref: TControl); override;
  end;

  TfmMain = class(TForm)
    mvSideMenu: TMultiView;
    loClient: TLayout;
    recToolbar: TRectangle;
    sbDetailsBack: TSpeedButton;
    seToolbarShadow: TShadowEffect;
    lvSideMenu: TListView;
    lbHeader: TLabel;
    recStatusbar: TRectangle;
    lnSideMenuVertLine: TLine;
    procedure lvSideMenuApplyStyleLookup(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure lvSideMenuUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
    procedure FormResize(Sender: TObject);
    procedure sbDetailsBackClick(Sender: TObject);
    procedure lvSideMenuItemClick(const Sender: TObject; const AItem: TListViewItem);
    procedure mvSideMenuStartShowing(Sender: TObject);
    procedure mvSideMenuHidden(Sender: TObject);
    procedure sbDetailsBackTap(Sender: TObject; const Point: TPointF);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure mvSideMenuApplyStyleLookup(Sender: TObject);
    procedure lvSideMenuScrollViewChange(Sender: TObject);
  private
    { Private declarations }
    {$IFDEF ANDROID}
    FDeviceType: TDeviceType;
    {$ENDIF}
    FSideMenuSelected: Integer; //Храним выбранный пункт бокового меню
    FSideMenuActivated: Integer; //Загруженный экран приложения
    procedure CreateSideMenu;
    procedure DoDetailsBack;
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.fmx}

uses
  uConsts, FontAwesome, System.Rtti {$IFDEF ANDROID}, FMX.StatusBar{$ENDIF};

procedure TfmMain.FormCreate(Sender: TObject);
begin
  {> Настраиваем боковое меню дровера}
  lvSideMenu.TransparentSeparators := True;
  if lvSideMenu.getAniCalc <> nil then
    lvSideMenu.getAniCalc.BoundsAnimation := False;
  lvSideMenu.ShowScrollBar := False;
  {$IFDEF ANDROID}
  sbDetailsBack.OnClick := nil;
  {$ENDIF}
  FSideMenuSelected := 1;
  FSideMenuActivated := 1;
  {<}
end;

procedure TfmMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
//Показываем или прячем боковое меню при нажатии на кнопку Menu телефона
begin
  {$IFDEF ANDROID}
  if (Key = vkMenu) and (mvSideMenu.Mode = TMultiViewMode.Drawer) then
    if mvSideMenu.IsShowed then
      mvSideMenu.HideMaster
    else
      mvSideMenu.ShowMaster;
  {$ENDIF}
end;

procedure TfmMain.FormResize(Sender: TObject);
begin
  {> Изменяем ширину дровера в соответствии с требованиями и типом устройства}
  {$IF defined(ANDROID)}
  if FDeviceType = TDeviceType.dtPhone then
    begin
      if (Width >= 306) and (Width <= 480) then
        mvSideMenu.Width := Width - 56;
    end
  else
  if (FDeviceType = TDeviceType.dtFablet) or (FDeviceType = TDeviceType.dtTablet) then
    begin
      mvSideMenu.Mode := TMultiViewMode.Panel;
      lnSideMenuVertLine.Visible := True;
      if Assigned(lvSideMenu.Items[0]) then
        lnSideMenuVertLine.Margins.Top := lvSideMenu.Items[0].Height;
      mvSideMenu.Width := 320;
      sbDetailsBack.Visible := (sbDetailsBack.Tag <> 0);
    end;

  {$ELSEIF defined(MSWINDOWS)}
  if (Width >= 306) and (Width <= 480) then
    begin
      mvSideMenu.Mode := TMultiViewMode.Drawer;
      lnSideMenuVertLine.Visible := False;
      sbDetailsBack.Visible := True;
      mvSideMenu.Width := Width - 56;
    end
  else
  if Width > 560 then
    begin
      mvSideMenu.Mode := TMultiViewMode.Panel;
      if Assigned(lvSideMenu.Items[0]) then
        lnSideMenuVertLine.Margins.Top := lvSideMenu.Items[0].Height;
      lnSideMenuVertLine.Visible := True;
      sbDetailsBack.Visible := (sbDetailsBack.Tag <> 0);
      mvSideMenu.Width := 424;
    end;
  {$ENDIF}
  {<}

  {> Выводим Stausbar, если версия Android >= 5}
  {$IFDEF ANDROID}
  if TOSVersion.Major >= 5 then
    begin
      recStatusBar.Height := TmyWindow.StatusBarHeight;
      recStatusBar.Visible := True;
      recToolbar.BringToFront;
      recStatusBar.BringToFront;
    end;
  {$ENDIF}
  {<}
end;

procedure TfmMain.CreateSideMenu;
//Создаем боковое меню в дровере
var
  aItem: TListViewItem;
  aItemImg: TListViewItem;
  i: Integer;
  ImgRes: TResourceStream;
  ImageLoaded: Boolean;
begin
  {> Загружаем изображение для меню}
  aItemImg := lvSideMenu.Items.Add;
  aItemImg.Data[SideMenuHeaderIndicator] := True;
  try
    ImageLoaded := True;
    try
      ImgRes := TResourceStream.Create(HInstance, SideMenuHeaderResourceName + Trunc(GetPrivedScale * 10).ToString, RT_RCDATA);
    except
      ImageLoaded := False;
    end;
    if ImageLoaded then
      try
        aItemImg.Bitmap.LoadFromStream(ImgRes);
      except
        aItemImg.Bitmap := nil;
      end;
  finally
    {$IF defined(MSWINDOWS)}
    FreeAndNil(ImgRes);
    {$ELSEIF defined(ANDROID)}
    ImgRes.DisposeOf;
    ImgRes := nil;
    {$ENDIF}
  end;
  aItemImg.Data[SideMenuHeaderTitle] := Caption;
  lvSideMenu.Adapter.ResetView(aItemImg);
  {<}

  {> Заполняем текстом и иконками}
  for i := Low(SideMenuGlyphsArray) to High(SideMenuGlyphsArray) do
    begin
      aItem := lvSideMenu.Items.Add;
      aItem.Data[SideMenuHeaderIndicator] := False;
      aItem.Data[SideMenuGlyph] := SideMenuGlyphsArray[i];
      aItem.Data[SideMenuTitle] := SideMenuTitlesArray[i];
      lvSideMenu.Adapter.ResetView(aItem);
    end;
  {<}
  lvSideMenu.ItemIndex := FSideMenuActivated;
end;

procedure TfmMain.FormShow(Sender: TObject);
begin
  {$IFDEF ANDROID}
  {> Узнаем тип устройства}
  FDeviceType := GetDeviceType;
  {<}
  {$ENDIF}

  {> При показе формы заполняем бокове меню дровера и прменяем цвета}
  CreateSideMenu;
  recStatusbar.Fill.Color := PrimaryColor;
  recToolbar.Fill.Color := PrimaryColor;
  lnSideMenuVertLine.Stroke.Color := DividerColor;
  {<}

  {> Применяем шрифт FontAwesome для кнопки sbDetailsBack}
  FontAwesomeAssign(sbDetailsBack);
  sbDetailsBack.Text := fa_bars;
  {<}

  {> Устанавливаем размер тени, равный скейлу устройства}
  seToolbarShadow.Distance := GetScale;
  {<}
end;

procedure TfmMain.lvSideMenuApplyStyleLookup(Sender: TObject);
// Применяем стиль для бокового меню
begin
  lvSideMenu.SetColorItemFill(WhiteColor);
  lvSideMenu.SetColorItemSelected(LightPrimaryColor);
  if Assigned(lvSideMenu.Items[0]) then
    lvSideMenu.SetCustomColorForItem(0, PrimaryColor);
end;

procedure TfmMain.lvSideMenuItemClick(const Sender: TObject; const AItem: TListViewItem);
//Обработчик нажатия на пункт бокового меню
begin
  if AItem.Index = 0 then
    begin
      lvSideMenu.ItemIndex := FSideMenuSelected;
      if mvSideMenu.Mode = TMultiViewMode.Drawer then
        mvSideMenu.HideMaster;
      Exit;
    end
  else
    lvSideMenu.AllowSelection := True;

  FSideMenuSelected := AItem.Index;
  if mvSideMenu.Mode = TMultiViewMode.Panel then
    begin
      {> Выполняем действие для выбранного итема}
      if FSideMenuSelected = FSideMenuActivated then
        Exit;
      ShowMessage(lvSideMenu.Items[FSideMenuSelected].Data[SideMenuTitle].AsString);
      FSideMenuActivated := FSideMenuSelected;
      {<}
    end
  else
  if mvSideMenu.Mode = TMultiViewMode.Drawer then
    mvSideMenu.HideMaster;
end;

procedure TfmMain.lvSideMenuScrollViewChange(Sender: TObject);
//Изменение высоты линии-границы бокового меню в режиме Panel
begin
  if (lnSideMenuVertLine.Visible) and Assigned(lvSideMenu.Items[0]) then
    lnSideMenuVertLine.Margins.Top := lvSideMenu.getHeightByIndex(0) - lvSideMenu.ScrollViewPos;
end;

procedure TfmMain.lvSideMenuUpdatingObjects(const Sender: TObject; const AItem: TListViewItem; var AHandled: Boolean);
// Расставляем все элементы в боковом меню
var
  aImg: TListItemImage;
  aGlyph: TListItemText;
  aTitle: TListItemText;
begin
  if AItem.Data[SideMenuHeaderIndicator].AsBoolean then
    begin
      aImg := AItem.Objects.FindObjectT<TListItemImage>(SideMenuHeaderBackgroundImage);
      if aImg = nil then
        aImg := TListItemImage.Create(AItem);
      aImg.Name := SideMenuHeaderBackgroundImage;
      aImg.PlaceOffset.X := 0;
      aImg.PlaceOffset.Y := 0;
      aImg.Width := lvSideMenu.Width;
      aImg.Height := 176;
      aImg.ScalingMode := TImageScalingMode.Original;
      aImg.Bitmap := AItem.Bitmap;
      AItem.Height := 176;
      if lnSideMenuVertLine.Visible then
        lnSideMenuVertLine.Margins.Top := AItem.Height;

      aTitle := AItem.Objects.FindObjectT<TListItemText>(SideMenuHeaderTitle);
      if aTitle = nil then
        aTitle := TListItemText.Create(AItem);
      aTitle.Name := SideMenuHeaderTitle;
      aTitle.TextAlign := TTextAlign.Leading;
      aTitle.TextVertAlign := TTextAlign.Trailing;
      aTitle.SelectedTextColor := WhiteColor;
      aTitle.TextColor := WhiteColor;
      aTitle.Font.Style := [TFontStyle.fsBold];
      aTitle.Font.Size := 14;
      aTitle.WordWrap := True;
      aTitle.PlaceOffset.X := 24;
      aTitle.PlaceOffset.Y := AItem.Height - 48;
      aTitle.Width := lvSideMenu.Width - 48;
      aTitle.Height := 24;
      if mvSideMenu.Mode = TMultiViewMode.Drawer then
        aTitle.Text := AItem.Data[SideMenuHeaderTitle].AsString
      else
        aTitle.Text := '';
    end
  else
    begin
      aGlyph := AItem.Objects.FindObjectT<TListItemText>(SideMenuGlyph);
      if aGlyph = nil then
        aGlyph := TListItemText.Create(AItem);
      aGlyph.Name := SideMenuGlyph;
      aGlyph.TextAlign := TTextAlign.Leading;
      aGlyph.TextVertAlign := TTextAlign.Center;
      aGlyph.SelectedTextColor := PrimaryColor;
      aGlyph.TextColor := PrimaryColor;
      aGlyph.Font.Family := FontAwesomeName;
      aGlyph.Font.Style := [TFontStyle.fsBold];
      aGlyph.Font.Size := 24;
      aGlyph.WordWrap := True;
      aGlyph.PlaceOffset.X := 24;
      aGlyph.PlaceOffset.Y := 0;
      aGlyph.Width := 48;
      aGlyph.Text := AItem.Data[SideMenuGlyph].AsString;
      aGlyph.Height := 60;

      aTitle := AItem.Objects.FindObjectT<TListItemText>(SideMenuTitle);
      if aTitle = nil then
        aTitle := TListItemText.Create(AItem);
      aTitle.Name := SideMenuTitle;
      aTitle.TextAlign := TTextAlign.Leading;
      aTitle.TextVertAlign := TTextAlign.Center;
      aTitle.SelectedTextColor := PrimaryTextColor;
      aTitle.TextColor := PrimaryTextColor;
      aTitle.Font.Style := [];
      aTitle.Font.Size := 14;
      aTitle.WordWrap := True;
      aTitle.PlaceOffset.X := 72;
      aTitle.PlaceOffset.Y := 0;
      aTitle.Width := lvSideMenu.Width - 80;
      aTitle.Text := AItem.Data[SideMenuTitle].AsString;
      aTitle.Height := 60;
      AItem.Height := 60;
    end;

  AHandled := True;
end;

procedure TfmMain.mvSideMenuApplyStyleLookup(Sender: TObject);
//Убираем стандарную линию-границу бокового меню
begin
  mvSideMenu.StylesData['dropline.Brush.Color'] := TValue.From<TAlphaColor>(TAlphaColorRec.Null);
end;

procedure TfmMain.mvSideMenuHidden(Sender: TObject);
//Выполяем действия при скрытии дровера
//если был выбран пункт меню, то выполняем соответствующее действие
begin
  {> Выполняем необходимые действия}
  if FSideMenuSelected = FSideMenuActivated then
    Exit;
  ShowMessage(lvSideMenu.Items[FSideMenuSelected].Data[SideMenuTitle].AsString);
  FSideMenuActivated := FSideMenuSelected;
  {<}
end;

procedure TfmMain.mvSideMenuStartShowing(Sender: TObject);
//Выполняем действия перед показом дровера:
//скроллим к первому элементу
begin
  FSideMenuSelected := FSideMenuActivated;
  lvSideMenu.ItemIndex := FSideMenuActivated;
  lvSideMenu.ScrollViewPos := 0;
end;

procedure TfmMain.DoDetailsBack;
//Выполняем открытие/скрытие дровера или выполняем действия для кнопки "Назад"
//Индикатором того, что нужно будет выполнять является свойство Tag у кнопки sbDetailsBack
begin
  if sbDetailsBack.Tag = 0 then
    begin
      if mvSideMenu.IsShowed then
        mvSideMenu.HideMaster
      else
        mvSideMenu.ShowMaster;
    end
  else
    begin
      {> Выполняем действия для кнопки "Назад"}
      {<}
      sbDetailsBack.Tag := 0;
      sbDetailsBack.Text := fa_bars;
      if mvSideMenu.Mode = TMultiViewMode.Panel then
        sbDetailsBack.Visible := (sbDetailsBack.Tag <> 0);
    end;
end;

procedure TfmMain.sbDetailsBackClick(Sender: TObject);
//Обрабатываем нажатие на кнопку sbDetailsBack
begin
  DoDetailsBack;
end;

procedure TfmMain.sbDetailsBackTap(Sender: TObject; const Point: TPointF);
//Обрабатываем нажатие на кнопку sbDetailsBack
begin
  DoDetailsBack;
end;

{ TSpeedButton }
procedure TSpeedButton.AdjustFixedSize(const Ref: TControl);
begin
  SetAdjustType(TAdjustType.None);
end;

initialization
  {$IFDEF ANDROID}
  TmyWindow.Init;
  {$ENDIF}
  //ReportMemoryLeaksOnShutdown := True;

end.


