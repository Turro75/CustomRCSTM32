unit MyList;

{$mode objfpc}

interface


type


 PPointerList = ^TPointerList;
 TPointerList = array[0..200] of Pointer;


{ TMyList }
 TMyList = class
 private
        FList: PPointerList;
       // FCount : word;
       // FCapacity : word;
        function expand: TMyList;

        function Get(Index: Integer): Pointer;
        function GetCapacity: Integer;
        function GetCount: Integer;
        procedure Put(Index: Integer; AValue: Pointer);
        procedure SetCapacity(AValue: Integer);
        procedure SetCount(AValue: Integer);
 public
           procedure clear;
           function push_back(item: Pointer): integer;
           function size:word;


           property Capacity: Integer read GetCapacity write SetCapacity;
           property Count: Integer read GetCount write SetCount;
           property Items[Index: Integer]: Pointer read Get write Put; default;


           constructor Create;
           destructor Destroy; override;
 end;


implementation



{ TMyList }

function TMyList.expand : TMyList;
var
  IncSize : Longint;
begin
  if Count < Capacity then exit(self);
  IncSize := 4;
  if Capacity > 3 then IncSize := IncSize + 4;
  if Capacity > 8 then IncSize := IncSize+8;
  if Capacity > 127 then Inc(IncSize, Capacity shr 2);
  SetCapacity(Capacity + IncSize);
  Result := Self;
end;



procedure TMyList.SetCapacity(AValue: Integer);
begin
   if AValue = Capacity then
    exit;
  ReallocMem(FList, SizeOf(Pointer)*AValue);
  Capacity := AValue;
end;

procedure TMyList.SetCount(AValue: Integer);
begin

end;



procedure TMyList.clear;
begin
   While (Count>0) do
    begin
    FList^[Count]:=Nil;
    Count:=Count-1;
    end;
end;


function TMyList.Get(Index: Integer): Pointer;
begin
  Result:=FList^[Index];
end;

function TMyList.GetCapacity: Integer;
begin
   result:=Capacity;
end;

function TMyList.GetCount: Integer;
begin
  result:=Count;
end;

procedure TMyList.Put(Index: Integer; AValue: Pointer);
begin
   Flist^[Index] := AValue;
end;

function TMyList.push_back(item: Pointer): integer;
begin
if Count = Capacity then
   Self.Expand;
 FList^[Count] := Item;
 Result := Count;
 Count := Count + 1;

end;

function TMyList.size: word;
begin
  result:=Count;
end;

constructor TMyList.Create;
begin
  Count:=0;
  Capacity:=0;
  FList:=Nil;
end;

destructor TMyList.Destroy;
begin
           clear;
	  inherited Destroy;
end;


end.

