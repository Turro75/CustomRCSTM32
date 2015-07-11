{/*
||
|| @file   MenuBackend.h
|| @version 1.4
|| @author   Alexander Brevig
|| @contact alexanderbrevig@gmail.com
|| @contribution Adrian Brzezinski adrb@wp.pl, http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?action=viewprofile;username=vzhang
||
|| @description
|| | Provide an easy way of making menus
|| #
||
|| @license
|| | This library is free software; you can redistribute it and/or
|| | modify it under the terms of the GNU Lesser General Public
|| | License as published by the Free Software Foundation; version
|| | 2.1 of the License.
|| |
|| | This library is distributed in the hope that it will be useful,
|| | but WITHOUT ANY WARRANTY; without even the implied warranty of
|| | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
|| | Lesser General Public License for more details.
|| |
|| | You should have received a copy of the GNU Lesser General Public
|| | License along with this library; if not, write to the Free Software
|| | Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
|| #
||
*/}



unit MenuBackend;



interface

type

  { TMenuItem }
  PMenuItem = ^TMenuItem;

  TMenuItem = class
  private
    Name: string;
    shortkey: char;
    before: PMenuItem;
    right: PMenuItem;
    after: PMenuItem;
    left: PMenuItem;
    back: PMenuItem;
  public
    function getName: string;
    function getShortKey: char;
    function hasShortKey: boolean;
    function getBack: PMenuItem;
    function getRight: PMenuItem;
    function getBefore: PMenuItem;
    function getLeft: PMenuItem;
    function getAfter: PMenuItem;
    procedure setBack(b: PMenuItem);

    function moveBack: PMenuItem;
    function moveDown: PMenuItem;
    function moveLeft: PMenuItem;
    function moveRight: PMenuItem;
    function moveUp: PMenuItem;

    function add(mi: PMenuItem): PMenuItem;
    function addBefore(mi: PMenuItem): PMenuItem;
    function addRight(mi: PMenuItem): PMenuItem;
    function addAfter(mi: PMenuItem): PMenuItem;
    function addLeft(var mi: TMenuItem): PMenuItem;
    constructor Create(_name: string; _shortkey: char = #0);
    destructor Destroy; override;
  end;

  MenuChangeEvent = record
    _from: PMenuItem;
    _to: PMenuItem;
  end;

  MenuUseEvent = record
    item: PMenuItem;
  end;


  cb_change = procedure(_menu_change_event: MenuChangeEvent);
  cb_use = procedure(_menu_use_event: MEnuUseEvent);

  { TMenuBackend }

  TMenuBackend = class
  private
    root: TMenuItem;
    current: PMenuItem;
    cb_menuChange: cb_change;
    cb_menuUse: cb_use;
    procedure setCurrent(Next: PMenuItem);
    procedure foundShortKeyItem(mi: PMenuItem);
    function canSearch(shortkey: char; m: PMenuItem): boolean;
    procedure rSAfter(shortkey: char; m: PMenuItem);
    procedure rSRight(shortkey: char; m: PMenuItem);
    procedure rSLeft(shortkey: char; m: PMenuItem);
    procedure rSBefore(shortkey: char; m: PMenuItem);
    procedure recursiveSearch(shortkey: char; m: PMenuItem);
  public
    function getRoot: PMenuItem;
    function getCurrent: PMenuItem;
    procedure moveBack;
    procedure moveUp;
    procedure moveDown;
    procedure moveLeft;
    procedure moveRight;
    procedure use(shortkey: char);
    procedure use;
    procedure toRoot;

    constructor Create(menuUse: cb_use; menuChange: cb_change);
    destructor Destroy; override;
  end;

implementation

{ TMenuBackend }

procedure TMenuBackend.setCurrent(Next: PMenuItem);
var
  mce: MenuChangeEvent;
begin
  if @Next <> nil then
  begin
    if cb_menuChange <> nil then
    begin
      mce._from := @current;
      mce._to := @Next;
      cb_menuChange(mce);
    end;
    current := @Next;
  end;
end;

procedure TMenuBackend.foundShortKeyItem(mi: PMenuItem);
begin
  mi^.setBack(current);
  current := @mi;
end;

function TMenuBackend.canSearch(shortkey: char;  m: PMenuItem): boolean;
begin
  if m = Nil then
  begin
    Result := false;
  end
  else
  begin
     if m^.getShortKey=shortkey then
       begin
          foundShortkeyItem(m);
          result:=true;
       end
       else
       begin
          result:=false;
       end;
  end;
end;

procedure TMenuBackend.rSAfter(shortkey: char; m: PMenuItem);
begin
     if not canSearch(shortkey,m) then
       begin
         rSAfter(shortkey,m^.getAfter);
         rSRight(shortkey,m^.getRight);
         rSLeft(shortkey,m^.getLeft);
       end;
end;

procedure TMenuBackend.rSRight(shortkey: char; m: PMenuItem);
begin
    if not canSearch(shortkey,m) then
       begin
         rSAfter(shortkey,m^.getAfter);
         rSRight(shortkey,m^.getRight);
         rSBefore(shortkey,m^.getBefore);
       end;
end;

procedure TMenuBackend.rSLeft(shortkey: char; m: PMenuItem);
begin
     if not canSearch(shortkey,m) then
       begin
         rSAfter(shortkey,m^.getAfter);
         rSLeft(shortkey,m^.getLeft);
         rSBefore(shortkey,m^.getBefore);
       end;
end;

procedure TMenuBackend.rSBefore(shortkey: char; m: PMenuItem);
begin
      if not canSearch(shortkey,m) then
       begin
         rSRight(shortkey,m^.getRight);
         rSLeft(shortkey,m^.getLeft);
         rSBefore(shortkey,m^.getBefore);
       end;
end;

procedure TMenuBackend.recursiveSearch(shortkey: char; m: PMenuItem);
begin
      if not canSearch(shortkey,m) then
       begin
         rSAfter(shortkey,m^.getAfter);
         rSRight(shortkey,m^.getRight);
         rSLeft(shortkey,m^.getLeft);
         rSBefore(shortkey,m^.getBefore);
       end;
end;

function TMenuBackend.getRoot: PMenuItem;
begin
    result:=@root;
end;

function TMenuBackend.getCurrent: PMenuItem;
begin
   result:=@current;
end;

procedure TMenuBackend.moveBack;
begin
     setCurrent(current^.getBack);
end;

procedure TMenuBackend.moveUp;
begin
    setCurrent(current^.moveUp);
end;

procedure TMenuBackend.moveDown;
begin
    setCurrent(current^.moveDown);
end;

procedure TMenuBackend.moveLeft;
begin
    setCurrent(current^.moveLeft);
end;

procedure TMenuBackend.moveRight;
begin
   setCurrent(current^.moveRight);
end;

procedure TMenuBackend.use(shortkey: char);
begin
    recursiveSearch(shortkey,@root);
    use;
end;

procedure TMenuBackend.use;
var
  mue : MenuUseEvent;
begin
     if cb_menuUse <> Nil then
      begin
         mue.item:=@current;
         cb_menuUse(mue);
      end;
end;

procedure TMenuBackend.toRoot;
begin
    setCurrent(getRoot);
end;

constructor TMenuBackend.Create( menuUse: cb_use;  menuChange: cb_change);
begin
    root:=TMenuItem.Create('MenuRoot');
   // root.Name:='MenuRoot';
    current:=@root;
    cb_menuChange:=menuChange;
    cb_menuUse:=menuUse;
end;

destructor TMenuBackend.Destroy;
begin
  inherited Destroy;
end;

{ TMenuItem }

function TMenuItem.getName: string;
begin
  Result := Name;
end;

function TMenuItem.getShortKey: char;
begin
  Result := shortKey;
end;

function TMenuItem.hasShortKey: boolean;
begin
  Result := False;
  if shortKey <> #0 then
  begin
    Result := True;
  end;
end;

function TMenuItem.getBack: PMenuItem;
begin
  Result := @back;
end;

function TMenuItem.getRight: PMenuItem;
begin
  Result := @right;
end;

function TMenuItem.getBefore: PMenuItem;
begin
  Result := @before;
end;

function TMenuItem.getLeft: PMenuItem;
begin
  Result := @left;
end;

function TMenuItem.getAfter: PMenuItem;
begin
  Result := @after;
end;

procedure TMenuItem.setBack(b: PMenuItem);
begin
  back := @b;
end;

function TMenuItem.moveBack: PMenuItem;
begin
  Result := @back;
end;

function TMenuItem.moveDown: PMenuItem;
begin
  if after <> nil then
  begin
    after^.back := @Self;
  end;
  Result := @after;
end;

function TMenuItem.moveLeft: PMenuItem;
begin
  if left <> nil then
  begin
    left^.back := @Self;
  end;
  Result := @left;
end;

function TMenuItem.moveRight: PMenuItem;
begin
  if right <> nil then
  begin
    right^.back := @Self;
  end;
  Result := @right;
end;

function TMenuItem.moveUp: PMenuItem;
begin
  if before <> nil then
  begin
    before^.back := @Self;
  end;
  Result := @before;
end;

function TMenuItem.add(mi: PMenuItem): PMenuItem;
begin
  Result := addAfter(mi);
end;

function TMenuItem.addBefore(mi: PMenuItem): PMenuItem;
begin
  mi^.after := @self;
  before := @mi;
  if mi^.back = nil then
  begin
    mi^.back := back;
  end;
  Result := @mi;
end;

function TMenuItem.addRight(mi: PMenuItem): PMenuItem;
begin
  mi^.left := @self;
  right := mi;
  if mi^.back = nil then
  begin
    mi^.back := back;
  end;
  Result := mi;
end;

function TMenuItem.addAfter(mi: PMenuItem): PMenuItem;
begin
  mi^.before := @self;
  after := @mi;
  if mi^.back = nil then
  begin
    mi^.back := back;
  end;
  Result := mi;
end;

function TMenuItem.addLeft(var mi: TMenuItem): PMenuItem;
begin
  mi.right := @self;
  left := @mi;
  if mi.back = nil then
  begin
    mi.back := back;
  end;
  Result := @mi;
end;

constructor TMenuItem.Create(_name: string; _shortkey: char = #0);
begin
  Name := _name;
  shortkey := _shortkey;
  after := nil;
  before := nil;
  right := nil;
  left := nil;
  back := nil;
end;

destructor TMenuItem.Destroy;
begin
  inherited Destroy;
end;

end.
