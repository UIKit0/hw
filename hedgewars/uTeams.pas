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

{$INCLUDE "options.inc"}

unit uTeams;
interface
uses uConsts, uInputHandler, uRandom, uFloat, uStats, 
     uCollisions, uSound, uStore, uTypes, uScript
     {$IFDEF USE_TOUCH_INTERFACE}, uWorld{$ENDIF};


procedure initModule;
procedure freeModule;

function  AddTeam(TeamColor: Longword): PTeam;
procedure SwitchHedgehog;
procedure AfterSwitchHedgehog;
procedure InitTeams;
function  TeamSize(p: PTeam): Longword;
procedure RecountTeamHealth(team: PTeam);
procedure RestoreHog(HH: PHedgehog);

procedure RestoreTeamsFromSave;
function  CheckForWin: boolean;
procedure TeamGoneEffect(var Team: TTeam);
procedure SwitchCurrentHedgehog(newHog: PHedgehog);

var MaxTeamHealth: LongInt;

implementation
uses uLocale, uAmmos, uChat, uVariables, uUtils, uIO, uCaptions, uCommands, uDebug,
    uGearsUtils, uGearsList, uVisualGearsList, uTextures
    {$IFDEF USE_TOUCH_INTERFACE}, uTouch{$ENDIF};

var GameOver: boolean;
    NextClan: boolean;

function CheckForWin: boolean;
var AliveClan: PClan;
    s: shortstring;
    t, AliveCount, i, j: LongInt;
begin
CheckForWin:= false;
AliveCount:= 0;
for t:= 0 to Pred(ClansCount) do
    if ClansArray[t]^.ClanHealth > 0 then
        begin
        inc(AliveCount);
        AliveClan:= ClansArray[t]
        end;

if (AliveCount > 1) or ((AliveCount = 1) and ((GameFlags and gfOneClanMode) <> 0)) then
    exit;
CheckForWin:= true;

TurnTimeLeft:= 0;
ReadyTimeLeft:= 0;

// if the game ends during a multishot, do last TurnReaction
if (not bBetweenTurns) and isInMultiShoot then
    TurnReaction();

if not GameOver then
    begin
    if AliveCount = 0 then
        begin // draw
        AddCaption(trmsg[sidDraw], cWhiteColor, capgrpGameState);
        SendStat(siGameResult, trmsg[sidDraw]);
        AddGear(0, 0, gtATFinishGame, 0, _0, _0, 3000)
        end
    else // win
        with AliveClan^ do
            begin
            if TeamsNumber = 1 then
                s:= Format(shortstring(trmsg[sidWinner]), Teams[0]^.TeamName)  // team wins
            else
                s:= Format(shortstring(trmsg[sidWinner]), Teams[0]^.TeamName); // clan wins

            for j:= 0 to Pred(TeamsNumber) do
                with Teams[j]^ do
                    for i:= 0 to cMaxHHIndex do
                        with Hedgehogs[i] do
                            if (Gear <> nil) then
                                Gear^.State:= gstWinner;
            if Flawless then
                AddVoice(sndFlawless, Teams[0]^.voicepack)
            else
                AddVoice(sndVictory, Teams[0]^.voicepack);

            AddCaption(s, cWhiteColor, capgrpGameState);
            SendStat(siGameResult, s);
            AddGear(0, 0, gtATFinishGame, 0, _0, _0, 3000)
            end;
    SendStats;
    end;
GameOver:= true
end;

procedure SwitchHedgehog;
var c, i, t: LongWord;
    PrevHH, PrevTeam : LongWord;
begin
TargetPoint.X:= NoPointX;
TryDo(CurrentTeam <> nil, 'nil Team', true);
with CurrentHedgehog^ do
    if (PreviousTeam <> nil) and PlacingHogs and Unplaced then
        begin
        Unplaced:= false;
        if Gear <> nil then
           begin
           DeleteCI(Gear);
           FindPlace(Gear, false, 0, LAND_WIDTH);
           if Gear <> nil then
               AddCI(Gear)
           end
        end;

PreviousTeam:= CurrentTeam;

with CurrentHedgehog^ do
    begin
    if Gear <> nil then
        begin
        MultiShootAttacks:= 0;
        Gear^.Message:= 0;
        Gear^.Z:= cHHZ;
        RemoveGearFromList(Gear);
        InsertGearToList(Gear)
        end
    end;
// Try to make the ammo menu viewed when not your turn be a bit more useful for per-hog-ammo mode
with CurrentTeam^ do
    if ((GameFlags and gfPerHogAmmo) <> 0) and (not ExtDriven) and (CurrentHedgehog^.BotLevel = 0) then
        begin
        c:= CurrHedgehog;
        repeat
            begin
            inc(c);
            if c > cMaxHHIndex then
                c:= 0
            end
        until (c = CurrHedgehog) or (Hedgehogs[c].Gear <> nil);
        LocalAmmo:= Hedgehogs[c].AmmoStore
        end;

c:= CurrentTeam^.Clan^.ClanIndex;
repeat
    with ClansArray[c]^ do
        if (CurrTeam = TagTeamIndex) and ((GameFlags and gfTagTeam) <> 0) then
            begin
            TagTeamIndex:= Pred(TagTeamIndex) mod TeamsNumber;
            CurrTeam:= Pred(CurrTeam) mod TeamsNumber;
            inc(c);
            NextClan:= true;
            end;

    if (GameFlags and gfTagTeam) = 0 then
        inc(c);

    if c = ClansCount then
        begin
        if not PlacingHogs then
            inc(TotalRounds);
        c:= 0
        end;

    with ClansArray[c]^ do
        begin
        PrevTeam:= CurrTeam;
        repeat
            CurrTeam:= Succ(CurrTeam) mod TeamsNumber;
            CurrentTeam:= Teams[CurrTeam];
            with CurrentTeam^ do
                begin
                PrevHH:= CurrHedgehog mod HedgehogsNumber; // prevent infinite loop when CurrHedgehog = 7, but HedgehogsNumber < 8 (team is destroyed before its first turn)
                repeat
                    CurrHedgehog:= Succ(CurrHedgehog) mod HedgehogsNumber;
                until ((Hedgehogs[CurrHedgehog].Gear <> nil) and (Hedgehogs[CurrHedgehog].Effects[heFrozen] < 256)) or (CurrHedgehog = PrevHH)
                end
        until ((CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) and (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Effects[heFrozen] < 256)) or (PrevTeam = CurrTeam) or ((CurrTeam = TagTeamIndex) and ((GameFlags and gfTagTeam) <> 0))
        end;
        if (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear = nil) or (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Effects[heFrozen] > 255) then
            begin
            with CurrentTeam^.Clan^ do
                for t:= 0 to Pred(TeamsNumber) do
                    with Teams[t]^ do
                        for i:= 0 to Pred(HedgehogsNumber) do
                            with Hedgehogs[i] do
                                begin
                                if Effects[heFrozen] > 255 then Effects[heFrozen]:= max(255,Effects[heFrozen]-50000);
                                if (Gear <> nil) and (Effects[heFrozen] < 256) and (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Effects[heFrozen] > 255) then
                                    CurrHedgehog:= i
                                end;
            if (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear = nil) or (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Effects[heFrozen] > 255) then
                inc(CurrentTeam^.Clan^.TurnNumber);
            end
until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) and (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Effects[heFrozen] < 256);

SwitchCurrentHedgehog(@(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog]));
{$IFDEF USE_TOUCH_INTERFACE}
if (Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_NoCrosshair) = 0 then
    begin
    if not(arrowUp.show) then
        begin
        animateWidget(@arrowUp, true, true);
        animateWidget(@arrowDown, true, true);
        end;
    end
else
    if arrowUp.show then
        begin
        animateWidget(@arrowUp, true, false);
        animateWidget(@arrowDown, true, false);
        end;
{$ENDIF}
AmmoMenuInvalidated:= true;
end;

procedure AfterSwitchHedgehog;
var i, t: LongInt;
    CurWeapon: PAmmo;
    w: real;
    vg: PVisualGear;

begin
if PlacingHogs then
    begin
    PlacingHogs:= false;
    for t:= 0 to Pred(TeamsCount) do
        for i:= 0 to cMaxHHIndex do
            if (TeamsArray[t]^.Hedgehogs[i].Gear <> nil) and (TeamsArray[t]^.Hedgehogs[i].Unplaced) then
                PlacingHogs:= true;

    if not PlacingHogs then // Reset  various things I mucked with
        begin
        for i:= 0 to ClansCount do
            if ClansArray[i] <> nil then
                ClansArray[i]^.TurnNumber:= 0;
        ResetWeapons
        end
    end;

inc(CurrentTeam^.Clan^.TurnNumber);
with CurrentTeam^.Clan^ do
    for t:= 0 to Pred(TeamsNumber) do
        with Teams[t]^ do
            for i:= 0 to Pred(HedgehogsNumber) do
                with Hedgehogs[i] do
                    if Effects[heFrozen] > 255 then
                        Effects[heFrozen]:= max(255,Effects[heFrozen]-50000);

CurWeapon:= GetCurAmmoEntry(CurrentHedgehog^);
if CurWeapon^.Count = 0 then
    CurrentHedgehog^.CurAmmoType:= amNothing;

with CurrentHedgehog^ do
    begin
    with Gear^ do
        begin
        Z:= cCurrHHZ;
        State:= gstHHDriven;
        Active:= true;
        Power:= 0;
        LastDamage:= nil
        end;
    RemoveGearFromList(Gear);
    InsertGearToList(Gear);
    FollowGear:= Gear
    end;

if (GameFlags and gfDisableWind) = 0 then
    begin
    cWindSpeed:= rndSign(GetRandomf * 2 * cMaxWindSpeed);
    w:= hwFloat2Float(cWindSpeed);
    vg:= AddVisualGear(0, 0, vgtSmoothWindBar);
    if vg <> nil then vg^.dAngle:= w;
    AddFileLog('Wind = '+FloatToStr(cWindSpeed));
    end;

ApplyAmmoChanges(CurrentHedgehog^);

if (not CurrentTeam^.ExtDriven) and (CurrentHedgehog^.BotLevel = 0) then
    SetBinds(CurrentTeam^.Binds);

bShowFinger:= true;

if PlacingHogs then
    begin
    if CurrentHedgehog^.Unplaced then
        TurnTimeLeft:= 15000
    else TurnTimeLeft:= 0
    end
else if ((GameFlags and gfTagTeam) <> 0) and (not NextClan) then
    begin
    if TagTurnTimeLeft <> 0 then
        TurnTimeLeft:= TagTurnTimeLeft;
    TagTurnTimeLeft:= 0;
    end
else
    begin
    TurnTimeLeft:= cHedgehogTurnTime;
    TagTurnTimeLeft:= 0;
    NextClan:= false;
    end;

if (TurnTimeLeft > 0) and (CurrentHedgehog^.BotLevel = 0) then
    begin
    if CurrentTeam^.ExtDriven then
        begin
        if GetRandom(2) = 0 then
             AddVoice(sndIllGetYou, CurrentTeam^.voicepack)
        else AddVoice(sndJustYouWait, CurrentTeam^.voicepack)
        end
    else
        begin
        GetRandom(2); // needed to avoid extdriven desync
        AddVoice(sndYesSir, CurrentTeam^.voicepack);
        end;
    if cHedgehogTurnTime < 1000000 then
        ReadyTimeLeft:= cReadyDelay;
    AddCaption(Format(shortstring(trmsg[sidReady]), CurrentTeam^.TeamName), cWhiteColor, capgrpGameState)
    end
else
    begin
    if TurnTimeLeft > 0 then
        begin
        if GetRandom(2) = 0 then
             AddVoice(sndIllGetYou, CurrentTeam^.voicepack)
        else AddVoice(sndJustYouWait, CurrentTeam^.voicepack)
        end;
    ReadyTimeLeft:= 0
    end;
end;

function AddTeam(TeamColor: Longword): PTeam;
var team: PTeam;
    c, t: LongInt;
begin
TryDo(TeamsCount < cMaxTeams, 'Too many teams', true);
New(team);
TryDo(team <> nil, 'AddTeam: team = nil', true);
FillChar(team^, sizeof(TTeam), 0);
team^.AttackBar:= 2;
team^.CurrHedgehog:= 0;
team^.Flag:= 'hedgewars';

TeamsArray[TeamsCount]:= team;
inc(TeamsCount);

for t:= 0 to cKbdMaxIndex do
    team^.Binds[t]:= DefaultBinds[t];

c:= Pred(ClansCount);
while (c >= 0) and (ClansArray[c]^.Color <> TeamColor) do dec(c);
if c < 0 then
    begin
    new(team^.Clan);
    FillChar(team^.Clan^, sizeof(TClan), 0);
    ClansArray[ClansCount]:= team^.Clan;
    inc(ClansCount);
    with team^.Clan^ do
        begin
        ClanIndex:= Pred(ClansCount);
        Color:= TeamColor;
        TagTeamIndex:= 0;
        Flawless:= true
        end
    end
else
    begin
    team^.Clan:= ClansArray[c];
    end;

with team^.Clan^ do
    begin
    Teams[TeamsNumber]:= team;
    inc(TeamsNumber)
    end;

CurrentTeam:= team;
AddTeam:= team;
end;

procedure RecountAllTeamsHealth;
var t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
    RecountTeamHealth(TeamsArray[t])
end;

procedure InitTeams;
var i, t: LongInt;
    th, h: LongInt;
begin

for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
        begin
        if (not ExtDriven) and (Hedgehogs[0].BotLevel = 0) then
            begin
            LocalClan:= Clan^.ClanIndex;
            LocalTeam:= t;
            LocalAmmo:= Hedgehogs[0].AmmoStore
            end;
        th:= 0;
        for i:= 0 to cMaxHHIndex do
            if Hedgehogs[i].Gear <> nil then
                inc(th, Hedgehogs[i].Gear^.Health);
        if th > MaxTeamHealth then
            MaxTeamHealth:= th;
        // Some initial King buffs
        if (GameFlags and gfKing) <> 0 then
            begin
            Hedgehogs[0].King:= true;
            Hedgehogs[0].Hat:= 'crown';
            Hedgehogs[0].Effects[hePoisoned] := 0;
            h:= Hedgehogs[0].Gear^.Health;
            Hedgehogs[0].Gear^.Health:= hwRound(int2hwFloat(th)*_0_375);
            if Hedgehogs[0].Gear^.Health > h then
                begin
                dec(th, h);
                inc(th, Hedgehogs[0].Gear^.Health);
                if th > MaxTeamHealth then
                    MaxTeamHealth:= th
                end
            else
                Hedgehogs[0].Gear^.Health:= h;
            Hedgehogs[0].InitialHealth:= Hedgehogs[0].Gear^.Health
            end;
        end;

RecountAllTeamsHealth
end;

function  TeamSize(p: PTeam): Longword;
var i, value: Longword;
begin
value:= 0;
for i:= 0 to cMaxHHIndex do
    if p^.Hedgehogs[i].Gear <> nil then
        inc(value);
TeamSize:= value;
end;

procedure RecountClanHealth(clan: PClan);
var i: LongInt;
begin
with clan^ do
    begin
    ClanHealth:= 0;
    for i:= 0 to Pred(TeamsNumber) do
        inc(ClanHealth, Teams[i]^.TeamHealth)
    end
end;

procedure RecountTeamHealth(team: PTeam);
var i: LongInt;
begin
with team^ do
    begin
    TeamHealth:= 0;
    for i:= 0 to cMaxHHIndex do
        if Hedgehogs[i].Gear <> nil then
            inc(TeamHealth, Hedgehogs[i].Gear^.Health)
        else if Hedgehogs[i].GearHidden <> nil then
            inc(TeamHealth, Hedgehogs[i].GearHidden^.Health);

    if TeamHealth > MaxTeamHealth then
        begin
        MaxTeamHealth:= TeamHealth;
        RecountAllTeamsHealth;
        end
    end;

RecountClanHealth(team^.Clan);

AddVisualGear(0, 0, vgtTeamHealthSorter)
end;

procedure RestoreHog(HH: PHedgehog);
begin
    HH^.Gear:=HH^.GearHidden;
    HH^.GearHidden:= nil;
    InsertGearToList(HH^.Gear);
    HH^.Gear^.State:= (HH^.Gear^.State and (not (gstHHDriven or gstInvisible or gstAttacking))) or gstAttacked;
    AddCI(HH^.Gear);
    HH^.Gear^.Active:= true;
    ScriptCall('onHogRestore', HH^.Gear^.Uid)
end;

procedure RestoreTeamsFromSave;
var t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
   TeamsArray[t]^.ExtDriven:= false
end;

procedure TeamGoneEffect(var Team: TTeam);
var i: LongInt;
begin
with Team do
    for i:= 0 to cMaxHHIndex do
        with Hedgehogs[i] do
            begin
            if Hedgehogs[i].GearHidden <> nil then
                RestoreHog(@Hedgehogs[i]);

            if Gear <> nil then
                begin
                Gear^.Hedgehog^.Effects[heInvulnerable]:= 0;
                Gear^.Damage:= Gear^.Health;
                Gear^.State:= (Gear^.State or gstHHGone) and (not gstHHDriven)
                end
            end
end;

procedure chAddHH(var id: shortstring);
var s: shortstring;
    Gear: PGear;
begin
s:= '';
if (not isDeveloperMode) or (CurrentTeam = nil) then
    exit;
with CurrentTeam^ do
    begin
    SplitBySpace(id, s);
    SwitchCurrentHedgehog(@Hedgehogs[HedgehogsNumber]);
    CurrentHedgehog^.BotLevel:= StrToInt(id);
    CurrentHedgehog^.Team:= CurrentTeam;
    Gear:= AddGear(0, 0, gtHedgehog, 0, _0, _0, 0);
    SplitBySpace(s, id);
    Gear^.Health:= StrToInt(s);
    TryDo(Gear^.Health > 0, 'Invalid hedgehog health', true);
    if (GameFlags and gfSharedAmmo) <> 0 then
        CurrentHedgehog^.AmmoStore:= Clan^.ClanIndex
    else if (GameFlags and gfPerHogAmmo) <> 0 then
        begin
        AddAmmoStore;
        CurrentHedgehog^.AmmoStore:= StoreCnt - 1
        end
    else CurrentHedgehog^.AmmoStore:= TeamsCount - 1;
    CurrentHedgehog^.Gear:= Gear;
    CurrentHedgehog^.Name:= id;
    CurrentHedgehog^.InitialHealth:= Gear^.Health;
    CurrHedgehog:= HedgehogsNumber;
    inc(HedgehogsNumber)
    end
end;

procedure loadTeamBinds(s: shortstring);
var i: LongInt;
begin
    for i:= 1 to length(s) do
        if s[i] in ['\', '/', ':'] then s[i]:= '_';

    s:= cPathz[ptTeams] + '/' + s + '.hwt';

    loadBinds('bind', s);
end;

procedure chAddTeam(var s: shortstring);
var Color: Longword;
    ts, cs: shortstring;
begin
cs:= '';
ts:= '';
if isDeveloperMode then
    begin
    SplitBySpace(s, cs);
    SplitBySpace(cs, ts);
    Color:= StrToInt(cs);
    TryDo(Color <> 0, 'Error: black team color', true);

    // color is always little endian so the mask must be constant also in big endian archs
    Color:= Color or $FF000000;
    AddTeam(Color);
    CurrentTeam^.TeamName:= ts;
    CurrentTeam^.PlayerHash:= s;
    loadTeamBinds(ts);
    
    if GameType in [gmtDemo, gmtSave, gmtRecord] then
        CurrentTeam^.ExtDriven:= true;

    CurrentTeam^.voicepack:= AskForVoicepack('Default')
    end
end;

procedure chSetHHCoords(var x: shortstring);
var y: shortstring;
    t: Longint;
begin
    y:= '';
    if (not isDeveloperMode) or (CurrentHedgehog = nil) or (CurrentHedgehog^.Gear = nil) then
        exit;
    SplitBySpace(x, y);
    t:= StrToInt(x);
    CurrentHedgehog^.Gear^.X:= int2hwFloat(t);
    t:= StrToInt(y);
    CurrentHedgehog^.Gear^.Y:= int2hwFloat(t)
end;

procedure chBind(var id: shortstring);
begin
    if CurrentTeam = nil then
        exit;

    addBind(CurrentTeam^.Binds, id)
end;

procedure chTeamGone(var s:shortstring);
var t: LongInt;
begin
t:= 0;
while (t < cMaxTeams) and (TeamsArray[t] <> nil) and (TeamsArray[t]^.TeamName <> s) do
    inc(t);
if (t = cMaxTeams) or (TeamsArray[t] = nil) then
    exit;

with TeamsArray[t]^ do
    if not hasGone then
        begin
        AddChatString('** '+ TeamName + ' is gone');
        hasGone:= true;

        RecountTeamHealth(TeamsArray[t])
        end;
end;


procedure chFinish(var s:shortstring);
var t: LongInt;
begin
// avoid compiler hint
s:= s;

t:= 0;
while (t < cMaxTeams) and (TeamsArray[t] <> nil) do
    begin
    TeamsArray[t]^.hasGone:= true;
    inc(t);
    end;

AddChatString('** Good-bye!');
RecountAllTeamsHealth();
end;

procedure SwitchCurrentHedgehog(newHog: PHedgehog);
var oldCI, newCI: boolean;
    oldHH: PHedgehog;
begin
   if (CurrentHedgehog <> nil) and (CurrentHedgehog^.CurAmmoType = amKnife) then
       LoadHedgehogHat(CurrentHedgehog^, CurrentHedgehog^.Hat);
    oldCI:= (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) and (CurrentHedgehog^.Gear^.CollisionIndex >= 0);
    newCI:= (newHog^.Gear <> nil) and (newHog^.Gear^.CollisionIndex >= 0);
    if oldCI then DeleteCI(CurrentHedgehog^.Gear);
    if newCI then DeleteCI(newHog^.Gear);
    oldHH:= CurrentHedgehog;
    CurrentHedgehog:= newHog;
   if (CurrentHedgehog <> nil) and (CurrentHedgehog^.CurAmmoType = amKnife) then
       LoadHedgehogHat(CurrentHedgehog^, 'Reserved/chef');
    if oldCI then AddCI(oldHH^.Gear);
    if newCI then AddCI(newHog^.Gear)
end;


procedure initModule;
begin
RegisterVariable('addhh', @chAddHH, false);
RegisterVariable('addteam', @chAddTeam, false);
RegisterVariable('hhcoords', @chSetHHCoords, false);
RegisterVariable('bind', @chBind, true );
RegisterVariable('teamgone', @chTeamGone, true );
RegisterVariable('finish', @chFinish, true ); // all teams gone

CurrentTeam:= nil;
PreviousTeam:= nil;
CurrentHedgehog:= nil;
TeamsCount:= 0;
ClansCount:= 0;
LocalClan:= -1;
LocalTeam:= -1;
LocalAmmo:= -1;
GameOver:= false;
NextClan:= true;
MaxTeamHealth:= 0;
end;

procedure freeModule;
var i, h: LongWord;
begin
if TeamsCount > 0 then
    begin
    for i:= 0 to Pred(TeamsCount) do
        begin
        for h:= 0 to cMaxHHIndex do
            with TeamsArray[i]^.Hedgehogs[h] do
                begin
                if GearHidden <> nil then
                    Dispose(GearHidden);

                FreeTexture(NameTagTex);
                FreeTexture(HealthTagTex);
                FreeTexture(HatTex);
                end;

        with TeamsArray[i]^ do
            begin
            FreeTexture(NameTagTex);
            FreeTexture(GraveTex);
            FreeTexture(AIKillsTex);
            FreeTexture(FlagTex);
            end;

        Dispose(TeamsArray[i]);
    end;
    for i:= 0 to Pred(ClansCount) do
        begin
        FreeTexture(ClansArray[i]^.HealthTex);
        Dispose(ClansArray[i]);
        end
    end;
TeamsCount:= 0;
ClansCount:= 0;
end;

end.
