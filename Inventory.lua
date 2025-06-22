--[[------------------------------------------------------------------------------------------------------------------------
 
	--- Inventory Module ---	
	
	Created by Lincoln Touw
	V4.6 6/21/2025 20:28:11  
	V2.1 12/05/2024 3:16:25 		
	V1.0 9/18/2025 14:57:39	 	 			
	
	---------------------
	
	## LJPM created by Lincoln Touw 6/03/2025	
	## https://lincolntouw.github.io/ljpm-rbx			 	
	
	--- LJPackageManager Information: --- 
	<ModuleName>Inventory-[Pollenators]</ModuleName>
	<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
	<ModuleVersion>4.6</ModuleVersion>	 			
	<PackageDependencies> 		
	</PackageDependencies>	 			
	
--]]------------------------------------------------------------------------------------------------------------------------

export type integer = number;
export type Item = {
	Type: string, Meta: (string | nil)?, Amount: number
};													
export type ItemData = {
	Name: string,
	Type: string,
	Description: string,
	Rarity: ("Common" | "Rare" | "Unique" | "Epic" | "Exotic" | "Mythic" | "Ethereal") | string?, 		 	
	Image: string,
	StackLimit: (integer | nil)?,	 	
	Useable: (boolean | nil?), 
	Callback: (Player: Player, SlotId: number, BeeAtSlot: {}?, DEPRECATED: nil, ItemObject: Item?) -> boolean?,
	GetAllValidMetas: () -> {ItemData}, 	 		
	GetUpdInfoFromMeta: (Meta: string) -> ItemData,	 	
}; 
export type ItemCollection = { Item }?;
export type Inventory = { [number]: Item, };

----------------------------------------------------------------------------------------------------------------------------

local Storage = game:GetService("ReplicatedStorage"); 		
local Assets = Storage:WaitForChild("assets"); 	 	
local db = Assets:WaitForChild("ItemDB"); 		
local Modules = Storage.Modules; 			

local Errors = require(Modules.Errors);	 	
local Files = require(Modules.Files); 	  
local Binds = require(Modules.Binds); 	  

local function ParameterAssertion(Parameter: any, ExpectedType: string, ErrorMsg: string, Required: boolean?): () 	
	if (not Required) and (Parameter == nil) then return true; end; 				
	Errors.assert(typeof(Parameter) == ExpectedType, Errors.TypeError, ErrorMsg); end;	 	 			
local function FormatArgumentMessage(Name: string, Position: number, ExpectedType: string): string?
	return `Argument {Position ~= nil and `#{Position} ` or ""}"{Name}" must be of type {ExpectedType}`; end; 	
 				 
----------------------------------------------------------------------------------------------------------------------------

local Inventory = {}; 					

@deprecated function Inventory:GetItemModule(Item: string): ModuleScript? 	 		
	ParameterAssertion(Item, "string", FormatArgumentMessage("Item", 1, "string"), true); 			
	for _, M: Instance in db:GetDescendants() do 	
		if M.Name == Item then return M; end; 			
	end;   
	return Errors.DependencyError.new(
		`Item with name "{Item}" was not found in the database, or has not been loaded in yet.`,
		404,
		{ Trace = true, },				 	
		Item
	); 		
end;	 	
@deprecated function Inventory:Get(Type: string, Meta: string?): ItemData?	 
	ParameterAssertion(Type, "string", FormatArgumentMessage("Type", 1, "string"), true);	 
	ParameterAssertion(Meta, "string", FormatArgumentMessage("Meta", 2, "string"));	 
	local ItemModule: ItemData? = require(Inventory:GetItemModule(Type)); 		
	if Meta and Meta ~= "" then
		local ItemMeta: ItemData? = ItemModule.GetUpdInfoFromMeta(Meta);	 	
		if not ItemMeta.Callback then ItemMeta.Callback = ItemModule.Callback; end;	
		return ItemMeta;	
	end; return ItemModule; 		
end; 			
function Inventory:Scan(Player: Player | nil, Type: string, Meta: string?, Strict: boolean?): ItemData? 	
	ParameterAssertion(Type, "string", FormatArgumentMessage("Type", 1, "string"), true);	 
	ParameterAssertion(Meta, "string", FormatArgumentMessage("Meta", 2, "string"));	 
	Meta = Meta or "";	 		
	local File: Files.PlayerFile = Files.fromPlayer(Player);  
	local PlayerInventory: Inventory = File.Data.Inventory or {}; 		
	for _, Item: Item in PlayerInventory do
		if Item.Type == Type and Item.Meta == Meta then return Item; end;	
	end;	 
	return if Strict then Errors.DependencyError.new(
		`Player "{Player}" does not have [{Type}/{Meta}] in their Inventory.`,	 				
		404, 
		{ Except = true, },					 	
		{ Type = Type, Meta = Meta, } 
	) else { Type = Type, Meta = Meta, Amount = 0, }; 		
end;

local Item = {};		 	
Item.__index = Item;
function Item.new(Type: string, Meta: string?, Amount: number?): Item? 		
	local Class = { Type = Type, Meta = Meta or "", Amount = Amount or 0, };			
	return setmetatable(Class, Item);	 
end; 		
function Item:copy(): Item return { Type = self.Type, Meta = self.Meta, Amount = self.Amount }; end; 		
function Item:IncreaseQuantity(Amount: number): () self.Amount += Amount; end; 	
function Item:DecreaseQuantity(Amount: number): () self.Amount -= Amount; end;	 		
function Item:SetQuantity(Amount: number): () self.Amount = Amount; end;		  		
function Item:GiveTo(Player: Player | number): ()	 	 
	local File: Files.PlayerFile = Files.fromPlayer(Player);  
	local PlayerInventory: Inventory = File.Data.Inventory or {};				
	local RemoveQueue: {[number]: number,} = {}; 		
	for _, item: Item in PlayerInventory do 
		if item.Meta == self.Meta and item.Type == self.Type then item.Amount += self.Amount; end; 	
		if item.Amount <= 0 then table.insert(RemoveQueue, _); end;			
	end;
	if #RemoveQueue > 0 then
		for _, Index: number in RemoveQueue do
			table.remove(PlayerInventory, Index);
		end; end; 	
	Binds:FireCategory("InventoryChanged", Player, self:copy());			
	-- TODO Insert quests here 		 		
	-- TODO Insert messaging here 	
end;	 		   
function Item:HasEnough(Player: Player | number): boolean	
	local File: Files.PlayerFile = Files.fromPlayer(Player);  
	local PlayerInventory: Inventory = File.Data.Inventory or {};		 		
	for _, item: Item in PlayerInventory do 
		if item.Meta == self.Meta and item.Type == self.Type then 
			return item.Amount >= self.Amount;	
		end;
	end; return false;	
end;			
function Item:Delete(): () self = nil; end;	 	

Inventory.Item = { new = Item.new, };
return Inventory;	 			
