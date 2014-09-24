private ["_folder","_ct"];

_allowManageAll = false; // For NOT P4L users: When true anyone can manage the elevator until someones adds himelf to the elevator list.

if (isServer || isDedicated) exitWith {
	diag_log "Error: Elevator script should NOT be started on the server";
};
if (count _this != 1) exitWith {
	diag_log "Error: elevator_init.sqf called with wrong parameter count (the only parameter should be the folder of the script relative to the mission folder)";
};

_folder = (_this select 0) + "\";

// global variables
if (isNil "ELE_PlatformClass") then { ELE_PlatformClass = "MetalFloor_DZ" };
if (isNil "ELE_StopClass") then { ELE_StopClass = "MetalFloor_Preview_DZ" };
if (isNil "ELE_MaxRange") then { ELE_MaxRange = 25 }; // m
if (isNil "ELE_Size") then { ELE_Size = 4 }; // m
if (isNil "ELE_Speed") then { ELE_Speed = 2 }; // m/s
if (isNil "ELE_StopWaitTime") then { ELE_StopWaitTime = 5 }; // s
if (isNil "ELE_UpdatesPerSecond") then { ELE_UpdatesPerSecond = 60 }; // animation updates per second
if (isNil "ELE_RequiredBuildTools") then { ELE_RequiredBuildTools = ["ItemToolbox", "ItemCrowbar"] }; // required tools for building an elevator and elevator stop
if (isNil "ELE_RequiredBuildItems") then { ELE_RequiredBuildItems = [["PartGeneric",4], "PartEngine", "ItemGenerator", "ItemJerrycan"] }; // required items to build an elevator
if (isNil "ELE_RequiredBuildStopItems") then { ELE_RequiredBuildStopItems = [["PartGeneric",4]] }; // required items to build an elevator stop
if (isNil "ELE_Debug") then { ELE_Debug = false }; // debug flag

ELE_elevator = nil;

// global functions
call compile preprocessFileLineNumbers (_folder + "vector.sqf");
call compile preprocessFileLineNumbers (_folder + "ac_functions.sqf");
call compile preprocessFileLineNumbers (_folder + "elevator_functions.sqf");

diag_log "Elevator script initialized";

// elevator actions
while {true} do {
	_ct = cursorTarget;
	if ((!isNull _ct) && {(player distance _ct) < ELE_Size}) then {
		// has target
		if (typeOf _ct == ELE_PlatformClass) then {		
			//Zupa: Check if you are the owner or on the list		
			_canOperate = false;
			_playerID = getPlayerUID player;
			_friends = TheElevator getVariable ["elevatorfriends",[]];
			{if ((_x  select 0) == _playerID) then{ _canOperate = true; }; } forEach _friends;
		
			if(isNil "ElevatorAdminList")then{ElevatorAdminList = ["-2"];};
			if ( _playerID in ElevatorAdminList) then{ _canOperate = true; };
			// The owner will get added to the list when he builds the elevator ( Ideal for non plot 4 life users); Admins needs to add the owner to elevator if not using P4L IF you disabled allow everyone to manage when no one is on the list.	
			//Check if server has P4L
			_owner = _ct getVariable["ownerPUID",0];
			if(isNil "_owner" || _owner == 0)then{ _owner = -1;};
			if (_owner == _playerID)then{ _canOperate = true; }; 			
			// allow operate when NOBODY is on the friend + owner list
			if( _allowManageAll && _owner = -1 && count(_friends) == 0)then{
				_canOperate = true;
			};
			
			if(_canOperate)then{
			// elevator actions
			if ([_ct] call ELE_fnc_isElevator) then {
				if (s_player_elevator_manage < 0 && {[_ct] call ELE_fnc_hasNextStop}) then {
					s_player_elevator_manage = player addAction ["<t color=""#ffffff"">Activate Elevator: Next Stop</t>", _folder+"initElevatorManagement.sqf", _ct, 5, false];
				};
				if (s_player_elevator_next < 0 && {[_ct] call ELE_fnc_hasNextStop}) then {
					s_player_elevator_next = player addAction ["<t color=""#ffffff"">Activate Elevator: Next Stop</t>", _folder+"elevator_actions.sqf", ["next",_ct], 5, false];
				};
				if (s_player_elevator_previous < 0 && {[_ct] call ELE_fnc_hasPreviousStop}) then {
					s_player_elevator_previous = player addAction ["<t color=""#ffffff"">Activate Elevator: Previous Stop</t>", _folder+"elevator_actions.sqf", ["previous",_ct], 5, false];
				};
				if (s_player_elevator_select < 0) then {
					s_player_elevator_select = player addAction ["<t color=""#ffffff"">Select Elevator</t>", _folder+"elevator_actions.sqf", ["select",_ct], 1, false];
				};
			} else {
				if (s_player_elevator_upgrade < 0) then {
					s_player_elevator_upgrade = player addAction ["<t color=""#ffffff"">Upgrade to Elevator</t>", _folder+"elevator_build.sqf", ["build",_ct], 0, false];
				};
				if (s_player_elevator_upgrade_stop < 0) then {
					s_player_elevator_upgrade_stop = player addAction ["<t color=""#ffffff"">Upgrade to Elevator Stop</t>", _folder+"elevator_build.sqf", ["build_stop",_ct], 0, false];
				};
			};
			
			};
			
		};
		// elevator stop actions
		if ( _canOperate && [_ct] call ELE_fnc_isElevatorStop) then {
			if (s_player_elevator_call < 0) then {
				s_player_elevator_call = player addAction ["<t color=""#ffffff"">Call Elevator</t>", _folder+"elevator_actions.sqf", ["call",_ct], 5, false];
			};
		};
		// debug actions
		if (s_player_elevator_id < 0 && ELE_Debug) then {
			s_player_elevator_id = player addAction ["<t color=""#ddffffff"">Show Elevator ID</t>", _folder+"elevator_actions.sqf", ["id",_ct], 0, false];
		};
	} else {
		player removeAction s_player_elevator_next;
		s_player_elevator_next = -1;
		player removeAction s_player_elevator_manage;
		s_player_elevator_manage = -1;
		player removeAction s_player_elevator_previous;
		s_player_elevator_previous = -1;
		player removeAction s_player_elevator_select;
		s_player_elevator_select = -1;
		player removeAction s_player_elevator_upgrade;
		s_player_elevator_upgrade = -1;
		player removeAction s_player_elevator_upgrade_stop;
		s_player_elevator_upgrade_stop = -1;
		player removeAction s_player_elevator_call;
		s_player_elevator_call = -1;
		player removeAction s_player_elevator_id;
		s_player_elevator_id = -1;
	};
	sleep 1;
};
