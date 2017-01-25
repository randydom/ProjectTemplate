unit uConsts;

interface

uses FontAwesome;

const
  {> Константы для бокового дровера}
  SideMenuHeaderResourceName = 'SIDEMENU_';
  SideMenuHeaderIndicator = 'header';
  SideMenuHeaderBackgroundImage = 'smBackgroundImage';
  SideMenuHeaderTitle = 'smHeaderTitle';
  SideMenuGlyph = 'smGlypth';
  SideMenuTitle = 'smTitile';
  //Массив с иконками пунктов меню, берутся из FontAwesome}
  SideMenuGlyphsArray: array [0 .. 3] of string =
  (fa_book, fa_bell, fa_calendar, fa_info_circle);
  //Массив с текстом пунктов меню}
  SideMenuTitlesArray: array [0 .. 3] of string =
  ('Пункт меню #1', 'Пункт меню #2',
   'Пункт меню #3', 'Пункт меню #4');
  {<}

  {> Цвета приложения}
  PrimaryColor = $FF3F51B5;
  LightPrimaryColor = $FFC5CAE9;
  DarkPrimaryColor = $FF303F9F;
  WhiteColor = $FFFFFFFF;
  AccentColor = $FFFF5722;
  PrimaryTextColor = $FF212121;
  SecondaryTextColor = $FF757575;
  DividerColor = $FFBDBDBD;
  {<}


implementation

end.
