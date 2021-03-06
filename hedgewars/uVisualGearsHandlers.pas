(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

(*
 * This file contains the step handlers for visual gears.
 *
 * Since the effects of visual gears do not affect the course of the game,
 * no "synchronization" between players is required.
 * => The usage of safe functions or data types (e.g. GetRandom() or hwFloat)
 * is usually not necessary and therefore undesirable.
 *)
 
{$INCLUDE "options.inc"} 
 
unit uVisualGearsHandlers;

interface
uses uTypes;

var doStepHandlers: array[TVisualGearType] of TVGearStepProcedure;

procedure doStepFlake(Gear: PVisualGear; Steps: Longword);
procedure doStepBeeTrace(Gear: PVisualGear; Steps: Longword);
procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
procedure doStepExpl(Gear: PVisualGear; Steps: Longword);
procedure doStepNote(Gear: PVisualGear; Steps: Longword);
procedure doStepLineTrail(Gear: PVisualGear; Steps: Longword);
procedure doStepEgg(Gear: PVisualGear; Steps: Longword);
procedure doStepFire(Gear: PVisualGear; Steps: Longword);
procedure doStepShell(Gear: PVisualGear; Steps: Longword);
procedure doStepSmallDamage(Gear: PVisualGear; Steps: Longword);
procedure doStepBubble(Gear: PVisualGear; Steps: Longword);
procedure doStepSteam(Gear: PVisualGear; Steps: Longword);
procedure doStepAmmo(Gear: PVisualGear; Steps: Longword);
procedure doStepSmoke(Gear: PVisualGear; Steps: Longword);
procedure doStepDust(Gear: PVisualGear; Steps: Longword);
procedure doStepSplash(Gear: PVisualGear; Steps: Longword);
procedure doStepDroplet(Gear: PVisualGear; Steps: Longword);
procedure doStepSmokeRing(Gear: PVisualGear; Steps: Longword);
procedure doStepFeather(Gear: PVisualGear; Steps: Longword);
procedure doStepTeamHealthSorterWork(Gear: PVisualGear; Steps: Longword);
procedure doStepTeamHealthSorter(Gear: PVisualGear; Steps: Longword);
procedure doStepSpeechBubbleWork(Gear: PVisualGear; Steps: Longword);
procedure doStepSpeechBubble(Gear: PVisualGear; Steps: Longword);
procedure doStepHealthTagWork(Gear: PVisualGear; Steps: Longword);
procedure doStepHealthTagWorkUnderWater(Gear: PVisualGear; Steps: Longword);
procedure doStepHealthTag(Gear: PVisualGear; Steps: Longword);
procedure doStepSmokeTrace(Gear: PVisualGear; Steps: Longword);
procedure doStepExplosionWork(Gear: PVisualGear; Steps: Longword);
procedure doStepExplosion(Gear: PVisualGear; Steps: Longword);
procedure doStepBigExplosionWork(Gear: PVisualGear; Steps: Longword);
procedure doStepBigExplosion(Gear: PVisualGear; Steps: Longword);
procedure doStepChunk(Gear: PVisualGear; Steps: Longword);
procedure doStepBulletHit(Gear: PVisualGear; Steps: Longword);
procedure doStepCircle(Gear: PVisualGear; Steps: Longword);
procedure doStepSmoothWindBar(Gear: PVisualGear; Steps: Longword);
procedure doStepStraightShot(Gear: PVisualGear; Steps: Longword);

function isSorterActive: boolean; inline;
procedure initModule;

implementation
uses uVariables, Math, uConsts, uVisualGearsList, uFloat, uSound, uRenderUtils, uWorld;

procedure doStepFlake(Gear: PVisualGear; Steps: Longword);
var sign: real;
    moved: boolean;
begin
if vobCount = 0 then exit;

sign:= 1;
with Gear^ do
    begin
    inc(FrameTicks, Steps);
    if not SuddenDeathDmg and (FrameTicks > vobFrameTicks) then
        begin
        dec(FrameTicks, vobFrameTicks);
        inc(Frame);
        if Frame = vobFramesCount then
            Frame:= 0
        end
    else if SuddenDeathDmg and (FrameTicks > vobSDFrameTicks) then
        begin
        dec(FrameTicks, vobSDFrameTicks);
        inc(Frame);
        if Frame = vobSDFramesCount then
            Frame:= 0
        end;
    X:= X + (cWindSpeedf * 400 + dX + tdX) * Steps * Gear^.Scale;
    if SuddenDeathDmg then
        Y:= Y + (dY + tdY + cGravityf * vobSDFallSpeed) * Steps * Gear^.Scale
    else
        Y:= Y + (dY + tdY + cGravityf * vobFallSpeed) * Steps * Gear^.Scale;
    Angle:= Angle + dAngle * Steps;
    if Angle > 360 then
        Angle:= Angle - 360
    else
        if Angle < - 360 then
            Angle:= Angle + 360;
    
  
    if (round(X) >= cLeftScreenBorder)
    and (round(X) <= cRightScreenBorder)
    and (round(Y) - 75 <= LAND_HEIGHT)
    and (Timer > 0) and (Timer-Steps > 0) then
        begin
        if tdX > 0 then
            sign := 1
        else
            sign:= -1;
        tdX:= tdX - 0.005*Steps*sign;
        if ((sign < 0) and (tdX > 0)) or ((sign > 0) and (tdX < 0)) then
            tdX:= 0;
        if tdX > 0 then
            sign := 1
        else
            sign:= -1;
        tdY:= tdY - 0.005*Steps*sign;
        if ((sign < 0) and (tdY > 0)) or ((sign > 0) and (tdY < 0)) then
            tdY:= 0;
        dec(Timer, Steps)
        end
    else
        begin
        moved:= false;
        if round(X) < cLeftScreenBorder then
            begin
            X:= X + cScreenSpace;
            moved:= true
            end
        else
            if round(X) > cRightScreenBorder then
                begin
                X:= X - cScreenSpace;
                moved:= true
                end;
            // if round(Y) < (LAND_HEIGHT - 1024 - 75) then Y:= Y + 25.0; // For if flag is set for flakes rising upwards?
        if (Gear^.Layer = 2) and (round(Y) - 225 > LAND_HEIGHT) then
            begin
            X:= cLeftScreenBorder + random(cScreenSpace);
            Y:= Y - (1024 + 250 + random(50)); // TODO - configure in theme (jellies for example could use limited range)
            moved:= true
            end
        else if (Gear^.Layer <> 2) and (round(Y) + 50 > LAND_HEIGHT) then
            begin
            X:= cLeftScreenBorder + random(cScreenSpace);
            Y:= Y - (1024 + random(25));
            moved:= true
            end;
        if moved then
            begin
            Angle:= random(360);
            dx:= 0.0000038654705 * random(10000);
            dy:= 0.000003506096 * random(7000);
            if random(2) = 0 then dx := -dx
            end;
        Timer:= 0;
        tdX:= 0;
        tdY:= 0
        end;
    end;

end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBeeTrace(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.FrameTicks > Steps then
    dec(Gear^.FrameTicks, Steps)
else
    DeleteVisualGear(Gear);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
var s: Longword;
    t: real;
begin
Gear^.X:= Gear^.X + (cWindSpeedf * 750 * Gear^.dX * Gear^.Scale) * Steps;

// up-and-down-bounce magic
s := (GameTicks + Gear^.Timer) mod 4096;
t := 8 * Gear^.Scale * hwFloat2Float(AngleSin(s mod 2048));
if (s < 2048) then t := -t;

Gear^.Y := LAND_HEIGHT - 1184 + LongInt(Gear^.Timer mod 8) + t;

if round(Gear^.X) < cLeftScreenBorder then
    Gear^.X:= Gear^.X + cScreenSpace
else
    if round(Gear^.X) > cRightScreenBorder then
        Gear^.X:= Gear^.X - cScreenSpace
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExpl(Gear: PVisualGear; Steps: Longword);
var s: LongInt;
begin
s:= min(Steps, cExplFrameTicks);

Gear^.X:= Gear^.X + Gear^.dX * s;
Gear^.Y:= Gear^.Y + Gear^.dY * s;
//Gear^.dY:= Gear^.dY + cGravityf;

if Gear^.FrameTicks <= Steps then
    if Gear^.Frame = 0 then
        DeleteVisualGear(Gear)
    else
        begin
        dec(Gear^.Frame);
        Gear^.FrameTicks:= cExplFrameTicks
        end
    else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepNote(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps / 2;

Gear^.Angle:= Gear^.Angle + (Gear^.Frame + 1) * Steps / 10;
while Gear^.Angle > cMaxAngle do
    Gear^.Angle:= Gear^.Angle - cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepLineTrail(Gear: PVisualGear; Steps: Longword);
begin
Steps := Steps;
if Gear^.Timer <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.Timer, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepEgg(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    begin
    DeleteVisualGear(Gear);
    exit
    end
else
    dec(Gear^.FrameTicks, Steps);

if Gear^.FrameTicks < $FF then
   Gear^.Tint:= (Gear^.Tint and $FFFFFF00) or Gear^.FrameTicks
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFire(Gear: PVisualGear; Steps: Longword);
var vgt: PVisualGear;
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;// + cGravityf * (Steps * Steps);
if (Gear^.State and gstTmpFlag) = 0 then
    begin
    Gear^.dY:= Gear^.dY + cGravityf * Steps;
    if ((GameTicks mod 200) < Steps + 1) then
        begin
        vgt:= AddVisualGear(round(Gear^.X), round(Gear^.Y), vgtFire);
        if vgt <> nil then
            begin
            vgt^.dx:= 0;
            vgt^.dy:= 0;
            vgt^.State:= gstTmpFlag;
            end;
        end
    end
else
    inc(Steps, Steps);

if Gear^.FrameTicks <= Steps then
       DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShell(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

procedure doStepSmallDamage(Gear: PVisualGear; Steps: Longword);
begin
Gear^.Y:= Gear^.Y - 0.02 * Steps;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBubble(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;
Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.Y:= Gear^.Y - cDrownSpeedf * Steps;
Gear^.dX := Gear^.dX / (1.001 * Steps);
Gear^.dY := Gear^.dY / (1.001 * Steps);

if (Gear^.FrameTicks <= Steps) or (round(Gear^.Y) < cWaterLine) then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSteam(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + (cWindSpeedf * 100 + Gear^.dX) * Steps;
Gear^.Y:= Gear^.Y - cDrownSpeedf * Steps;

if Gear^.FrameTicks <= Steps then
    if Gear^.Frame = 0 then
        DeleteVisualGear(Gear)
    else
        begin
        if Random(2) = 0 then
            dec(Gear^.Frame);
        Gear^.FrameTicks:= cExplFrameTicks
        end
else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepAmmo(Gear: PVisualGear; Steps: Longword);
begin
Gear^.Y:= Gear^.Y - cDrownSpeedf * Steps;

Gear^.scale:= Gear^.scale + 0.0025 * Steps;
Gear^.alpha:= Gear^.alpha - 0.0015 * Steps;

if Gear^.alpha < 0 then
    DeleteVisualGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmoke(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + (cWindSpeedf + Gear^.dX) * Steps;
Gear^.Y:= Gear^.Y - (cDrownSpeedf + Gear^.dY) * Steps;

Gear^.dX := Gear^.dX + (cWindSpeedf * 0.3 * Steps);
//Gear^.dY := Gear^.dY - (cDrownSpeedf * 0.995);

if Gear^.FrameTicks <= Steps then
    if Gear^.Frame = 0 then
        DeleteVisualGear(Gear)
    else
        begin
        if Random(2) = 0 then
            dec(Gear^.Frame);
        Gear^.FrameTicks:= cExplFrameTicks
        end
    else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDust(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + (cWindSpeedf + (cWindSpeedf * 0.03 * Steps) + Gear^.dX) * Steps;
Gear^.Y:= Gear^.Y - (Gear^.dY) * Steps;

Gear^.dX := Gear^.dX - (Gear^.dX * 0.005 * Steps);
Gear^.dY := Gear^.dY - (cDrownSpeedf * 0.001 * Steps);

if Gear^.FrameTicks <= Steps then
    if Gear^.Frame = 0 then
            DeleteVisualGear(Gear)
    else
        begin
        dec(Gear^.Frame);
        Gear^.FrameTicks:= cExplFrameTicks
        end
    else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSplash(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDroplet(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

if round(Gear^.Y) > cWaterLine then
    begin
    DeleteVisualGear(Gear);
    PlaySound(TSound(ord(sndDroplet1) + Random(3)));
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeRing(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps);
if Gear^.Timer >= Gear^.FrameTicks then
    DeleteVisualGear(Gear)
else
    begin
    Gear^.scale := 1.25 * (-power(2, -10 * Int(Gear^.Timer)/Gear^.FrameTicks) + 1) + 0.4;
    Gear^.alpha := 1 - power(Gear^.Timer / 350, 4);
    if Gear^.alpha < 0 then
        Gear^.alpha:= 0;
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFeather(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
const cSorterWorkTime = 640;
var thexchar: array[0..cMaxTeams] of
            record
            dy, ny, dw: LongInt;
            team: PTeam;
            SortFactor: QWord;
            hdw: array[0..cMaxHHIndex] of LongInt;
            end;
    currsorter: PVisualGear = nil;

function isSorterActive: boolean; inline;
begin
    isSorterActive:= currsorter <> nil
end;

procedure doStepTeamHealthSorterWork(Gear: PVisualGear; Steps: Longword);
var i, t, h: LongInt;
begin
for t:= 1 to min(Steps, Gear^.Timer) do
    begin
    dec(Gear^.Timer);
    if (Gear^.Timer and 15) = 0 then
        for i:= 0 to Pred(TeamsCount) do
            with thexchar[i] do
                begin
                {$WARNINGS OFF}
                team^.DrawHealthY:= ny + dy * LongInt(Gear^.Timer) div cSorterWorkTime;
                team^.TeamHealthBarHealth:= team^.TeamHealth + dw * LongInt(Gear^.Timer) div cSorterWorkTime;

                for h:= 0 to cMaxHHIndex do
                    if (team^.Hedgehogs[h].Gear <> nil) then
                        team^.Hedgehogs[h].HealthBarHealth:= team^.Hedgehogs[h].Gear^.Health + hdw[h] * LongInt(Gear^.Timer) div cSorterWorkTime
                    else
                        team^.Hedgehogs[h].HealthBarHealth:= hdw[h] * LongInt(Gear^.Timer) div cSorterWorkTime;
                {$WARNINGS ON}
                end;
    end;

if (Gear^.Timer = 0) or (currsorter <> Gear) then
    begin
    if currsorter = Gear then
        currsorter:= nil;
    DeleteVisualGear(Gear);
    exit
    end
end;

procedure doStepTeamHealthSorter(Gear: PVisualGear; Steps: Longword);
var i: Longword;
    b: boolean;
    t, h: LongInt;
begin
Steps:= Steps; // avoid compiler hint

for t:= 0 to Pred(TeamsCount) do
    with thexchar[t] do
        begin
        team:= TeamsArray[t];
        dy:= team^.DrawHealthY;
        dw:= team^.TeamHealthBarHealth - team^.TeamHealth;
        if team^.TeamHealth > 0 then
            begin
            SortFactor:= team^.Clan^.ClanHealth;
            SortFactor:= (SortFactor shl  3) + team^.Clan^.ClanIndex;
            SortFactor:= (SortFactor shl 30) + team^.TeamHealth;
            end
        else
            SortFactor:= 0;

        for h:= 0 to cMaxHHIndex do
            if (team^.Hedgehogs[h].Gear <> nil) then
                hdw[h]:= team^.Hedgehogs[h].HealthBarHealth - team^.Hedgehogs[h].Gear^.Health
            else
                hdw[h]:= team^.Hedgehogs[h].HealthBarHealth;
        end;

if TeamsCount > 1 then
    repeat
    b:= true;
    for t:= 0 to TeamsCount - 2 do
        if (thexchar[t].SortFactor > thexchar[Succ(t)].SortFactor) then
            begin
            thexchar[cMaxTeams]:= thexchar[t];
            thexchar[t]:= thexchar[Succ(t)];
            thexchar[Succ(t)]:= thexchar[cMaxTeams];
            b:= false
            end
    until b;

t:= - 4;
for i:= 0 to Pred(TeamsCount) do
        with thexchar[i] do
          if team^.TeamHealth > 0 then
            begin
            dec(t, team^.Clan^.HealthTex^.h + 2);
            ny:= t;
            dy:= dy - ny
            end;

Gear^.Timer:= cSorterWorkTime;
Gear^.doStep:= @doStepTeamHealthSorterWork;
currsorter:= Gear;
//doStepTeamHealthSorterWork(Gear, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSpeechBubbleWork(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.Timer > Steps then dec(Gear^.Timer, Steps) else Gear^.Timer:= 0;

if (Gear^.Hedgehog^.Gear <> nil) then
    begin
    Gear^.X:= hwFloat2Float(Gear^.Hedgehog^.Gear^.X) + (Gear^.Tex^.w div 2  - Gear^.FrameTicks);
    Gear^.Y:= hwFloat2Float(Gear^.Hedgehog^.Gear^.Y) - (16 + Gear^.Tex^.h);
    end;

if Gear^.Timer = 0 then
    begin
    if Gear^.Hedgehog^.SpeechGear = Gear then
        Gear^.Hedgehog^.SpeechGear:= nil;
    DeleteVisualGear(Gear)
    end;
end;

procedure doStepSpeechBubble(Gear: PVisualGear; Steps: Longword);
begin
Steps:= Steps; // avoid compiler hint

with Gear^.Hedgehog^ do
    if SpeechGear <> nil then
        SpeechGear^.Timer:= 0;

Gear^.Hedgehog^.SpeechGear:= Gear;

Gear^.Timer:= max(LongInt(Length(Gear^.Text)) * 150, 3000);

Gear^.Tex:= RenderSpeechBubbleTex(Gear^.Text, Gear^.FrameTicks, fnt16);

case Gear^.FrameTicks of
    1: Gear^.FrameTicks:= SpritesData[sprSpeechTail].Width-28;
    2: Gear^.FrameTicks:= SpritesData[sprThoughtTail].Width-20;
    3: Gear^.FrameTicks:= SpritesData[sprShoutTail].Width-10;
    end;

Gear^.doStep:= @doStepSpeechBubbleWork;

Gear^.Y:= Gear^.Y - Gear^.Tex^.h
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealthTagWork(Gear: PVisualGear; Steps: Longword);
begin
if Steps > Gear^.Timer then
    DeleteVisualGear(Gear)
else
    begin
    dec(Gear^.Timer, Steps);
    Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
    Gear^.X:= Gear^.X + Gear^.dX * Steps
    end;
end;

procedure doStepHealthTagWorkUnderWater(Gear: PVisualGear; Steps: Longword);
begin
if round(Gear^.Y) - 10 < cWaterLine then
    DeleteVisualGear(Gear)
else
    Gear^.Y:= Gear^.Y - 0.08 * Steps;

end;

procedure doStepHealthTag(Gear: PVisualGear; Steps: Longword);
var s: shortstring;
begin
s:= '';

str(Gear^.State, s);
if Gear^.Hedgehog <> nil then
    Gear^.Tex:= RenderStringTex(s, Gear^.Hedgehog^.Team^.Clan^.Color, fnt16)
else
    Gear^.Tex:= RenderStringTex(s, cWhiteColor, fnt16);

Gear^.doStep:= @doStepHealthTagWork;

if (round(Gear^.Y) > cWaterLine) and (Gear^.Frame = 0)  then
    Gear^.doStep:= @doStepHealthTagWorkUnderWater;

Gear^.Y:= Gear^.Y - Gear^.Tex^.h;

if Steps > 1 then
    Gear^.doStep(Gear, Steps-1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeTrace(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps );
if Gear^.Timer > 64 then
    begin
    if Gear^.State = 0 then
        begin
        DeleteVisualGear(Gear);
        exit;
        end;
    dec(Gear^.State, Gear^.Timer div 65);
    Gear^.Timer:= Gear^.Timer mod 65;
    end;
Gear^.dX:= Gear^.dX + cWindSpeedf * Steps;
Gear^.X:= Gear^.X + Gear^.dX;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExplosionWork(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps);
if Gear^.Timer > 75 then
    begin
    inc(Gear^.State, Gear^.Timer div 76);
    Gear^.Timer:= Gear^.Timer mod 76;
    if Gear^.State > 5 then
        DeleteVisualGear(Gear);
    end;
end;

procedure doStepExplosion(Gear: PVisualGear; Steps: Longword);
var i: LongWord;
    gX,gY: LongInt;
    vg: PVisualGear;
begin
gX:= round(Gear^.X);
gY:= round(Gear^.Y);
for i:= 0 to 31 do 
    begin
    vg:= AddVisualGear(gX, gY, vgtFire);
    if vg <> nil then 
        begin
        vg^.State:= gstTmpFlag;
        inc(vg^.FrameTicks, vg^.FrameTicks)
        end
    end;
for i:= 0 to  8 do AddVisualGear(gX, gY, vgtExplPart);
for i:= 0 to  8 do AddVisualGear(gX, gY, vgtExplPart2);
Gear^.doStep:= @doStepExplosionWork;
if Steps > 1 then
    Gear^.doStep(Gear, Steps-1);
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepBigExplosionWork(Gear: PVisualGear; Steps: Longword);
var maxMovement: LongInt;
begin

inc(Gear^.Timer, Steps);
if (Gear^.Timer and 5) = 0 then
    begin
    maxMovement := max(1, 13 - ((Gear^.Timer * 15) div 250));
    ShakeCamera(maxMovement);
    end;

if Gear^.Timer > 250 then
    DeleteVisualGear(Gear);
end;

procedure doStepBigExplosion(Gear: PVisualGear; Steps: Longword);
var i: LongWord;
    gX,gY: LongInt;
    vg: PVisualGear;
begin
//ScreenFade:= sfFromWhite;
//ScreenFadeValue:= round(60 * zoom * zoom);
//ScreenFadeSpeed:= 5;
gX:= round(Gear^.X);
gY:= round(Gear^.Y);
AddVisualGear(gX, gY, vgtSmokeRing);
for i:= 0 to 46 do 
    begin
    vg:= AddVisualGear(gX, gY, vgtFire);
    if vg <> nil then 
        begin
        vg^.State:= gstTmpFlag;
        inc(vg^.FrameTicks, vg^.FrameTicks)
        end
    end;
for i:= 0 to 15 do
    AddVisualGear(gX, gY, vgtExplPart);
for i:= 0 to 15 do
    AddVisualGear(gX, gY, vgtExplPart2);
Gear^.doStep:= @doStepBigExplosionWork;
if Steps > 1 then
    Gear^.doStep(Gear, Steps-1);
with mobileRecord do
    if (performRumble <> nil) and (not fastUntilLag) then
        performRumble(kSystemSoundID_Vibrate);
end;

procedure doStepChunk(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if (round(Gear^.Y) > cWaterLine) and ((cReducedQuality and rqPlainSplash) = 0) then
    begin
    AddVisualGear(round(Gear^.X), round(Gear^.Y), vgtDroplet);
    DeleteVisualGear(Gear);
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBulletHit(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCircle(Gear: PVisualGear; Steps: Longword);
var tmp: LongInt;
    i: LongWord;
begin
with Gear^ do
    if Frame <> 0 then
        for i:= 1 to Steps do
            begin
            inc(FrameTicks);
            if (FrameTicks mod Frame) = 0 then
                begin
                tmp:= Gear^.Tint and $FF;
                if tdY >= 0 then
                    inc(tmp)
                else
                    dec(tmp);
                if tmp < round(dX) then
                    tdY:= 1;
                if tmp > round(dY) then
                    tdY:= -1;
                if tmp > 255 then
                    tmp := 255;
                if tmp < 0 then
                    tmp := 0;
                Gear^.Tint:= (Gear^.Tint and $FFFFFF00) or Longword(tmp)
                end
            end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmoothWindBar(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps);
    
while Gear^.Timer >= 10 do
    begin
    dec(Gear^.Timer, 10);
    if WindBarWidth < Gear^.Tag then
        inc(WindBarWidth)
    else if WindBarWidth > Gear^.Tag then
        dec(WindBarWidth);
    end;
if cWindspeedf > Gear^.dAngle then
    begin
    cWindspeedf := cWindspeedf - Gear^.Angle*Steps;
    if cWindspeedf < Gear^.dAngle then cWindspeedf:= Gear^.dAngle;
    end
else if cWindspeedf < Gear^.dAngle then
    begin
    cWindspeedf := cWindspeedf + Gear^.Angle*Steps;
    if cWindspeedf > Gear^.dAngle then cWindspeedf:= Gear^.dAngle;
    end;
        
if (WindBarWidth = Gear^.Tag) and (cWindspeedf = Gear^.dAngle)  then 
    DeleteVisualGear(Gear)
end;
////////////////////////////////////////////////////////////////////////////////
procedure doStepStraightShot(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;
Gear^.Y:= Gear^.Y - Gear^.dY * Steps;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    begin
    dec(Gear^.FrameTicks, Steps);
    if (Gear^.FrameTicks < 501) and (Gear^.FrameTicks mod 5 = 0) then 
        Gear^.Tint:= (Gear^.Tint and $FFFFFF00) or (((Gear^.Tint and $000000FF) * Gear^.FrameTicks) div 500)
    end
end;


const handlers: array[TVisualGearType] of TVGearStepProcedure =
        (
            @doStepFlake,
            @doStepCloud,
            @doStepExpl,
            @doStepExpl,
            @doStepFire,
            @doStepSmallDamage,
            @doStepTeamHealthSorter,
            @doStepSpeechBubble,
            @doStepBubble,
            @doStepSteam,
            @doStepAmmo,
            @doStepSmoke,
            @doStepSmoke,
            @doStepShell,
            @doStepDust,
            @doStepSplash,
            @doStepDroplet,
            @doStepSmokeRing,
            @doStepBeeTrace,
            @doStepEgg,
            @doStepFeather,
            @doStepHealthTag,
            @doStepSmokeTrace,
            @doStepSmokeTrace,
            @doStepExplosion,
            @doStepBigExplosion,
            @doStepChunk,
            @doStepNote,
            @doStepLineTrail,
            @doStepBulletHit,
            @doStepCircle,
            @doStepSmoothWindBar,
            @doStepStraightShot
        );

procedure initModule;
begin
    doStepHandlers:= handlers
end;

end.
