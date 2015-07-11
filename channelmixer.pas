unit channelMixer;

{
 function to convert channel analog or digital read values to the desired range
 i.e. linear comes linear from minimun to maximun if minimum is more than max the channel is reversed
      v-tail comes from top-min to center to top-max




}




interface

uses
  Arduino_compat;

const
  dualRate010 = 10;
  dualRate020 = 20;
  dualRate030 = 30;
  dualRate040 = 40;
  dualRate050 = 50;
  dualRate060 = 60;
  dualRate070 = 70;
  dualRate080 = 80;
  dualRate090 = 90;
  dualRate100 = 100;



  curveEdgeExpo025 = 6.0;
  curveEdgeExpo050 = 4.0;
  curveEdgeExpo075 = 3.0;
  curveEdgeExpo100 = 2.0;
  curveStraight = 10.0;
  curveCenterExpo025 = 20.0;
  curveCenterExpo050 = 30.0;
  curveCenterExpo075 = 40.0;
  curveCenterExpo100 = 50.0;

type
  expoCurve = (curve00, curve01, curve02, curve03, curve04, curve00Dual,
    curve01Dual, curve02Dual, curve03Dual, curve04Dual);


function applyExpo(inValue: integer; chDual: boolean; curve: expoCurve): word;

function applyDualRate(inValue: longint; chDual: boolean; gain100: word): word;

function invertChannel(inValue: longint; inverted: boolean): word;


var
  expoParams: array[False..True, curve01..curve04] of
  word = ((320, 1012, 1800, 2557),//2560),
    (226, 640, 1070, 1470));


implementation


function applyExpo(inValue: longint; chDual: boolean; curve: expoCurve): word;
var
  tmpParam: longint;
  tmpValue: longint;
  compensateValue: longint;
  adjustSign: boolean;
  adjustValue: word;
begin
  adjustValue := 1000;
  if ((curve = curve00) or (curve = curve00Dual)) then
  begin
    Result := inValue;
  end
  else
  begin
    adjustSign := True;
    compensateValue := 0;
    if chDual = True then
    begin
      compensateValue := 511;
      inValue := inValue - 511;
      if inValue < 0 then
      begin
        adjustSign := False;
      end;
    end;
    tmpParam := 10 * adjustValue * inValue div expoParams[chDual, curve];
    if curve = curve01Dual then
    begin
      curve := curve01;
    end;
    if curve = curve02Dual then
    begin
      curve := curve02;
    end;
    if curve = curve03Dual then
    begin
      curve := curve03;
    end;
    if curve = curve04Dual then
    begin
      curve := curve04;
    end;

    case curve of
      curve01:
      begin
        tmpValue := tmpParam * tmpParam;
        tmpValue := TmpValue div adjustValue;
        tmpValue := tmpValue div adjustValue;
        if not adjustSign then
        begin
          tmpValue := -tmpValue;
        end;
      end;
      //    result:=round(adjustSign*tmpParam*tmpParam)+compensateValue;
      curve02:
      begin
        tmpValue := tmpParam * tmpParam;
        tmpValue := TmpValue div adjustValue;
        tmpValue := tmpValue div adjustValue;
        tmpValue := tmpValue * tmpParam;
        tmpValue := tmpValue div adjustValue;
        //  tmpValue:=adjustSign*tmpValue;
      end;
      //    result:=round(adjustSign*tmpParam*tmpParam*tmpParam)+compensateValue;
      curve03:
      begin
        tmpValue := tmpParam * tmpParam;
        tmpValue := TmpValue div adjustValue;
        tmpValue := tmpValue div adjustValue;
        tmpValue := tmpValue * tmpParam;
        tmpValue := tmpValue div adjustValue;
        tmpValue := tmpValue * tmpParam;
        tmpValue := tmpValue div adjustValue;
        if not adjustSign then
        begin
          tmpValue := -tmpValue;
        end;
      end;

      //result:=round(adjustSign*tmpParam*tmpParam*tmpParam*tmpParam)+compensateValue;
      curve04:
      begin
        tmpValue := tmpParam * tmpParam;
        tmpValue := TmpValue div adjustValue;
        tmpValue := tmpValue div adjustValue;
        tmpValue := tmpValue * tmpParam;
        tmpValue := tmpValue div adjustValue;
        tmpValue := tmpValue * tmpParam;
        tmpValue := tmpValue div adjustValue;
        tmpValue := tmpValue * tmpParam;
        tmpValue := tmpValue div adjustValue;
        //  tmpValue:=adjustSign*tmpValue;
      end;
      //result:=round(adjustSign*tmpParam*tmpParam*tmpParam*tmpParam*tmpParam)+compensateValue;
    end;
    Result := tmpValue + compensateValue;
    Result := constrain(Result, 0, 1023);
    // result:=adjustSign;
  end;
end;




function invertChannel(inValue: longint; inverted: boolean): word;
begin
  Result := inValue;
  if inverted = True then
  begin
    Result := 1023 - inValue;
  end;
end;

function applyDualRate(inValue: integer; chDual: boolean; gain100: word): word;
var
  tmp1: longint;
begin
  //inValue raw value 0-1023 of the channel
  //chDual true is standby is in the middle(512), false if standby is 0 (i.e. throttle)
  //gain100 multiplier in percentage
  //result value 0-1023/100*gain100 if chDual=false otherwise read the source below
  if chDual = True then
  begin
    tmp1 := 1023 * (100 - gain100) div 200; //i.e. 30% means 1023*(100-70)/200=153
    if inValue < 512 then
    begin
      Result := map(inValue, 0, 511, tmp1, 511);
    end
    else
    begin
      Result := map(inValue, 512, 1023, 512, 1023 - tmp1);
    end;
  end
  else
  begin
    Result := (inValue * gain100) div 100;  //value amplified in the range 0.0-1.0
  end;

end;




end.
