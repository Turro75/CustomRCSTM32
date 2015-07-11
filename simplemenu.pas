unit SimpleMenu;

{$mode objfpc}

interface
const
  SMlist = 1;
  SMintValue = 2;
  SMstring = 3;
  SMboolean = 4;

type
SimpleMenuItem = record
  Index : word;
  Name : string;
  kindof : byte;
  end;

procedure initSimpleMenu;

var
  item1,item2,item3,item4,item5 : SimpleMenuItem;
  listitem : array [1..20] of SimpleMenuItem;


implementation

procedure initSimpleMenu;
begin
          item1.Index:=0;
          item1.Name:='Protocol';
          item1.kindof:=SMlist;

          item2.kindof:=SMintValue;
          item2.Name:='Period [ms]';
          item2.Index:=1;

          item2.kindof:=SMboolean;
          item2.Name:='Save';
          item2.Index:=3;

          item3.Index:=2;
          item3.Name:='ModelName';
          item3.kindof:=SMstring;
end;


end.

