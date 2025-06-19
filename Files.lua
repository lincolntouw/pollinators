--[[--------------------------------------------------------------------------------------------------------------------------

	@title - FileSys			
	@description - Simple file system module for persistent data management.	
	@author - Lincoln Touw			

	Rewritten v3.15: 6/17/2025 18:22:26	by Lincoln Touw	  
					
--]]--------------------------------------------------------------------------------------------------------------------------
 
export type PlayerFile = {
	Player: Player, 			 	 	 	 	   	
	UserId: number,	 
	FileOpened: DateTime, 	
	FileClosed: DateTime,
	Data: {},	 
};
export type FileEvent = {
	file: {}, pass: (self: FileEvent) -> (), reject: (self: FileEvent) -> (), 	 			 	 
};
export type FileReadEvent = FileEvent & { path: string }
export type FileWriteEvent = FileEvent & { path: string, value: any } 		
export type FileIncrementEvent = FileWriteEvent;	 
export type FileBindEvent = FileEvent & { f: (() -> ())? };

------------------------------------------------------------------------------------------------------------------------------

local FileSys = {};	

local Util = game:GetService("ReplicatedStorage"):WaitForChild("Util");
local Modules = game:GetService("ReplicatedStorage"):WaitForChild("Modules");

local Errors = require(Modules:WaitForChild("Errors"));	
local Mem = require(Util:WaitForChild("MemoryLocator"));	 	
local Promise = require(Util:WaitForChild("Promise")); 			
local EnumList = require(Util:WaitForChild("EnumList"));		

------------------------------------------------------------------------------------------------------------------------------

local EventType = EnumList.new("EventType", {
	"FileEvent", "FileReadEvent", "FileWriteEvent", "FileIncrementEvent", "FileBindEvent",	
});	 	  
local EventResolvingStatus = EnumList.new("EventResolvingStatus", {
	"Ignored", "Passed", "Rejected",
});	 		
local FileEvent = {};
FileEvent.__index = FileEvent;	 		 
function FileEvent.new(onfile: PlayerFile, subtype: string?, ...: any): FileEvent? 	
	local Params: {}? = table.pack(...); Params.n = nil; 	 				 	
	local Event = { file = onfile, status = EventResolvingStatus.Ignored, type = subtype or 'FileEvent', };			
	--function Event.gstatus(): () return Status; end;
	--function Event.status(type: EnumListSubsetter?): () Status = type; end;	   
	if subtype == "FileReadEvent" then Event.path = Params[1]; end;
	if subtype == "FileWriteEvent" or subtype == "FileIncrementEvent" then Event.path = Params[1]; Event.value = Params[2]; end;  
	if subtype == "FileBindEvent" then Event.f = Params[1]; end; 	 	
	return setmetatable(Event, FileEvent);	 			 	
end;	  	 
function FileEvent:pass(): () self.status = EventResolvingStatus.Passed; end; 		
function FileEvent:reject(): () self.status = EventResolvingStatus.Rejected; end;	 	 	
	
------------------------------------------------------------------------------------------------------------------------------
		
local RunBinds = function(File: PlayerFile, Type: string?, ...): boolean	 		
	for k: number, f: () -> () in File['Bindings'][Type] do 				 
		local e = FileEvent.new(File, Type, ...); f(e); 				
		if e.status == EventResolvingStatus.Rejected then return false; end; 		
	end;	 	
	return true; 		
end;	 	

local Files: {PlayerFile} = {};	 	
local BindListeners_OnLoad = {}; 			
local File = {};	  
File.__index = File; 			
-- Opens a new OOP file manager for a player.
function File.new(Player: Player): PlayerFile? 
	local struct: PlayerFile = setmetatable({
		Player = Player,	 			
		UserId = Player.UserId,			
		FileOpened = tick(),
		Data = {},		
		Bindings = {
			FileEvent = {},
			FileReadEvent = {},
			FileWriteEvent = {},
			FileIncrementEvent = {}, 		
			FileBindEvent = {}  		
		},		  	 	
	}, File);			  	
	table.insert(Files, struct);	 	
	for k, v in BindListeners_OnLoad do v(Player.UserId, struct); end; 	
	return struct;	 	
end;	 		
-- Load data directly to the file. 		
function File:loadTo(Data: {}): () 	
	self.Data = Data;	 		
end;		 	
-- Get data from the file using a `Path` object. 	
function File:read(Path: string | {[number]: string}): {}  		
	if not RunBinds(self, "FileReadEvent", Path) then return; end; 	
	if not Path then return self.Data; end; 	
	if typeof(Path) == "table" then 	
		local Results: {[number]: any?} = {};		 		 
		for _, p: never in Path do table.insert(Results, self:read(p)); end;		 
		return Results;	 	
	end;	  		
	assert(typeof(Path) == "string", "Argument #1 'Path' must be a string or an array containing strings.");	 
	local Pieces: {string} = Path:split("/"); 	  	
	local CurrentLevel = self.Data;	 	
	for _, Piece in Pieces do 				
		if tonumber(Piece) ~= nil then Piece = tonumber(Piece); end; 	
		CurrentLevel = CurrentLevel[Piece];
	end;	 	
	return CurrentLevel;	 		
end;	  
-- Write data to the file using `Path` and `Values` objects. 			
function File:write(Path: string | {[number]: string}, Value: number | string | boolean |	{}): () 		
	if not RunBinds(self, "FileWriteEvent", Path, Value) then return; end; 		
	assert(Path, "Missing Argument #1 'Path'"); 		
	if typeof(Path) == "table" then 		
		local Results: {[number]: any?} = {};		 		 
		for k: number, p: never in Path do table.insert(Results, self:write(p, Value[k])); end;		 
		return Results;	 	
	end;	  		 	
	assert(typeof(Path) == "string", "Argument #1 'Path' must be a string or an array containing strings.");	 	
	local Pieces: {string} = Path:split("/"); 	  	
	local CurrentLevel = self.Data;	 	
	for k: number, Piece in Pieces do 		 				
		if tonumber(Piece) ~= nil then Piece = tonumber(Piece); end; 	
		if k == #Pieces then do CurrentLevel[Piece] = Value; break; end; end;
		CurrentLevel = CurrentLevel[Piece]; 	
	end;	 	 		
	return Value, Path;	 			 			  
end; 
-- Increment an entry inside the `PlayerFile`.
function File:increment(Path: string | {[number]: string}, Value: number | {[number]: number}): () 	
	if not RunBinds(self, "FileIncrementEvent", Path, Value) then return; end; 		
	assert(Path, "Missing Argument #1 'Path'"); 		
	if typeof(Path) == "table" then 		
		local Results: {[number]: any?} = {};		 		 
		for k: number, p: never in Path do table.insert(Results, self:increment(p, Value[k])); end;		 
		return Results;	 	
	end;	  		 	
	assert(typeof(Path) == "string", "Argument #1 'Path' must be a string or an array containing strings.");	 	
	local get = self:read(Path);
	assert(typeof(get) == "number", `Could not perform increment operation: Expected number at "{Path}", got {typeof(get)}`); 		
	self:write(Path, get + Value);	 		
end;				
-- Calls the function whenever a File write is attempted. Can reject, pass, or ignore. 	
function File:bindToAction(Type: string, f: (FileEvent?) -> ()): RBXScriptConnection 	
	if not RunBinds(self, "FileBindEvent", f) then return; end; 		
	table.insert(self.Bindings[Type], f); 			
	local binding: RBXScriptConnection = {};	
	function binding:Disconnect(): () 		
		local binderg = self.Bindings[Type]; 		
		local index: number? = table.find(binderg, f); 			
		table.remove(binderg, index);	 	
	end;	 					
	return binding;	   
end; 				
-- Removes the File, and returns a JSON copy of it. 		
function File:remove(): string? 		
	local content: string = game.HttpService:JSONEncode(self.Data);	 	
	table.remove(Files, table.find(Files, self)); 		
	self.Data = nil; self = nil;	 		
	return content;	 	
end; 	
 			
------------------------------------------------------------------------------------------------------------------------------
 
FileSys.new = File.new;	 	
FileSys.fromPlayer = function(Player: Player): PlayerFile
	for k: number, v: PlayerFile in Files do
		if v.Player == Player then return v; end;
	end; return;
end;	  		
FileSys.bindToLoad = function(f): RBXScriptConnection? 	
	table.insert(BindListeners_OnLoad, f); 	
	local s: RBXScriptConnection = {};
	function s:Disconnect(): () 	
		task.defer(function(): () 	
			table.remove(BindListeners_OnLoad, table.find(BindListeners_OnLoad, f));
		end);
	end;		
	return s; 					
end; 	
  	
return FileSys;	 	
