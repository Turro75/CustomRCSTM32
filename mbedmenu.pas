unit mbedMenu;



interface
  uses
    nokia1100_lcd;

type

  PMenu = ^TMenu;
  PSelection = ^TSelection;
  fun = procedure ;









   { TSelection }

  TSelection = class
  private

  public
            selText : string;
            pos : word;
            childmenu : PMenu;
            _fun : fun;
            constructor Create(__fun: fun; _pos: word;  _childMenu: PMenu;
		      _selText: string);
            destructor Destroy; override;
  end;

   { TMenu }

  TMenu = class
  private

  public
            menuID : string;
            Selections : array [0..20] of PSelection;
            size:word;
            procedure add(var toAdd: TSelection);
            function getText(index : word):string;
            constructor Create(_menuID : string);
            destructor Destroy; override;
  end;


  { Navigator }

  TNavigator = class
  private


  public
            activeMenu : PMenu;
            lcd : ^TNokia1100LCD;
            lastButton : word;
            button : word;
            bottom : word;
            mycursorPos : word;
            mycursorLine : word;
            procedure poll;
            procedure moveUp;
            procedure moveDown;
            procedure printMenu(_pos, _line: word);
            procedure printCursor;
            constructor Create(var _menu: TMenu; var _lcd: TNokia1100LCD);
            destructor Destroy; override;


  end;



  VAR
     menustr : array[0..9] of string = (
   'Menuitem00      ',
   'Menuitem01      ',
   'Menuitem02      ',
   'Menuitem03      ',
   'Menuitem04      ',
   'Menuitem05      ',
   'Menuitem06      ',
   'Menuitem07      ',
   'Menuitem08      ',
   'Menuitem09      ');

implementation



{ Navigator }



procedure TNavigator.poll;
begin

end;

procedure TNavigator.moveUp;
begin
   if mycursorLine=2 then
      mycursorLine:=1;

   if mycursorPos > 0 then
        begin
          dec(mycursorPos);
	end;
   printMenu(mycursorPos,mycursorLine);
   printCursor;
end;

procedure TNavigator.moveDown;
begin
   if mycursorLine=1 then
      mycursorLine := 2;

   if (mycursorPos < (bottom-1)) then
        begin
          inc(mycursorPos);
	end;
  printMenu(mycursorPos,mycursorLine);
   printCursor;
end;

procedure TNavigator.printMenu(_pos,_line:word);
var
  tmpstr1,tmpstr2:string;
begin
   //   tmpstr:=hexstr(self.mycursorPos,2);
       if _line = 1 then
            begin
              tmpstr1:=menustr[_pos];
                 tmpstr2:=menustr[_pos+1];
	    end
             else
            begin
                tmpstr1:=menustr[_pos-1];
                 tmpstr2:=menustr[_pos];
            end;
           lcd^.lcdGotoyx(1,1);
           lcd^.print(tmpstr1);
           lcd^.lcdGotoyx(2,1);
           lcd^.print(tmpstr2);
end;

procedure TNavigator.printCursor;
begin
  lcd^.lcdGotoyx(1,0);
  if mycursorLine = 1 then
    begin
     lcd^.print('>');
     lcd^.lcdGotoyx(2,0);
     lcd^.print(' ');
    end
  else
    begin
     lcd^.print(' ');
     lcd^.lcdGotoyx(2,0);
     lcd^.print('>');
    end;
end;

constructor TNavigator.Create(var _menu: TMenu;var _lcd: TNokia1100LCD);
var
  i:word;
begin
   activeMenu:=@_menu;
   lcd:=@_lcd;
   i:=0;
   bottom:=activeMenu^.size;
   mycursorPos:=0;
   mycursorLine:=1;
   button:=0;
   lastButton:=0;
   printMenu(mycursorPos,mycursorLine);
   printCursor;
end;

destructor TNavigator.Destroy;
begin
	  inherited Destroy;
end;

{ Selection }


constructor TSelection.Create(__fun: fun; _pos: word; _childMenu: PMenu;
	  _selText: string);
begin
   _fun:=__fun;
   pos := _pos;
   childMenu:=@_childMenu;
   selText:=_selText;
end;

destructor TSelection.Destroy;
begin
	  inherited Destroy;
end;

{ Menu }

procedure TMenu.add(var toAdd: TSelection);
var
  i : word;
begin
  i:=0;
  while Selections[i]<>Nil do
  begin
      inc(i);
  end;
  Selections[i]:=@toAdd;
  inc(size);
end;

function TMenu.getText(index: word): string;
begin
    result:=menuID;
end;

constructor TMenu.Create(_menuID: string);
var
  i:word;
begin
   menuID:=_menuID;
  // Selections:=TMyList.Create;
   for i:=0 to high(Selections) do
       Selections[i]:=Nil;
     size:=0;
end;

destructor TMenu.Destroy;
begin
	  inherited Destroy;
end;

end.

