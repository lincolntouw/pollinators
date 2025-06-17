--!strict			

--[[------------------------------------------------------------------------------------------------------------------------
 
	--- Alerts Module ---	
	
	Created by Lincoln Touw
	V2.3 6/16/2025  
	V1.0 9/15/2024 		 	 			
	
	---------------------
	
	## LJPM created by Lincoln Touw 6/03/2025	
	## https://lincolntouw.github.io/ljpm-rbx			
	
	--- LJPackageManager Information: --- 
	<ModuleName>Alerts</ModuleName>
	<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
	<ModuleVersion>2.3</ModuleVersion>			
	<PackageDependencies>
		<Package>
			<Name>ChatMessenger</Name>
			<Version>1.0</Version>		
		</Package>
		<Package>
			<Name>RbxMulti</Name> 		
			<Version>1.48</Version>		
		</Package>
		<Package>
			<Name>NumXL</Name> 		
			<Version>2.5</Version>		
		</Package> 
		<Package>
			<Name>BetterErrors</Name> 		
			<Version>1.1</Version> 			
		</Package> 
	</PackageDependencies>	 			
	
--]]------------------------------------------------------------------------------------------------------------------------
	 
local Chat = require('./ChatMessenger');   	
local Multi = require('./Multi'); 
local NumXL = require('./Numbers');
local Errors = require('./Errors');	 	

----------------------------------------------------------------------------------------------------------------------------
  	
local Alerts = {
	defaultDuration = 15,
	buttons = {
		default = script:WaitForChild("Alert"),
		interactable = script:WaitForChild("AlertB"),
		quest = script:WaitForChild("QAlert"),
	},
};		
		
-- @class Alert	
-- @type Alert
local Alert = {};
Alert.__index = Alert;

export type Alert = {
	Label: GuiObject
};    
  	
-- @desc - Creates a new Alert object.  	
-- @param Player* - The player to send the alert to.
-- @param Text(*if!Parameters) - The content of the alert.
-- @param Color - The background color (can be a ColorSequence). 	
-- @param DontSendToChat - Determines if the alert's content is also sent to the game chat. 		
-- @param Clickable - Determines if the alert is a button.
-- @param Callback - Calls this function when the alert is clicked (if it's a button).		 
-- @param Parameters - This table is used when spawning item-related alerts.		 
function Alert.new(	 		
	Player: Player,
	Text: string,
	Color: Color3?, 	
	DontSendToChat: boolean?,
	Clickable: boolean,
	Callback: () -> (),
	Parameters: {
		type: string,
		origin: string,
		amount: number	
	}): GuiButton			
	-- required		 
 	Errors.assert(typeof(Player) == "Instance" and Player:IsA("Player"), Errors.TypeError, 'Argument #1 "Player" must be a valid Player instance.');
	Errors.assert((
 		if typeof(Parameters) == "table" then (typeof(Parameters.type) == "string" and typeof(Parameters.amount) == "number") else Parameters == nil		
		), Errors.TypeError, 'Argument #7 "Paramters" must be a valid set.');	
	Errors.assert(if Parameters ~= nil then true else typeof(Text) == "string", Errors.TypeError, 'Argument #2 "Text" must be a valid string.');		 
	
	-- create		 
	local class = { Label = nil, }
	local duration: number = Alerts.defaultDuration
	local container: Frame = Player.PlayerGui:WaitForChild("Main"):WaitForChild("Alerts");
	
	local box: GuiObject = Alerts.buttons[if Clickable == true then 'interactable' else 'default']:Clone(); 	
	class.Label = box;	 	
	Multi:SetAttributes(box, {
		origin = Parameters.origin,
		type = Parameters.type,
		amount = Parameters.amount,
	});			
	if Parameters ~= nil then
		local pre: GuiButton? | nil; 	
		table.foreach(container:GetChildren(), function(k: number, v: Instance): ()	
			if v.Name:match("alert") 
				and Multi:AttributeEquality(v, box, { "origin", "type", })				
			then
				pre = v; 	
			end;		
		end);
		if pre then
			local combined: number = (Parameters.amount or 0) + tonumber(pre:GetAttribute("amount"));
			box:SetAttribute("amount", combined);			
			Text = `{if combined < 0 then '-' else '+'}{NumXL:Abbreviate(true, math.abs(combined))} {Parameters.type}{if Parameters.origin then ` (from {Parameters.origin})` else ''}`; 		
			pre:Destroy();
		end;	 				  
	end;			
	box.Name = `alert#{#container:GetChildren()+1}`; 		
	box.Parent = container;	
	box.Text = Text;
	box.Size = UDim2.new();	
	game.TweenService:Create(
		box,
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(1, 0, 0, 25), }
	):Play(); 				
	
	if typeof(Color) == "Color3" then
		box.BackgroundColor3 = Color;	 						
	elseif typeof(Color) == "ColorSequence" then
		coroutine.wrap(function()   
			local keys = Color.Keypoints;	 		
			while box.Parent ~= nil do 
			   for i: number, e: ColorSequenceKeypoint in keys do  									
					local t = game.TweenService:Create(
						box,
						TweenInfo.new(e.Time * duration / 2),
						{ BackgroundColor3 = e.Value, }
					);	
					t:Play(); t.Completed:Wait();	   
				end;	 		
			end; 		
		end)();
	end;
	
	if Clickable == true and typeof(Callback) == "function" then
		box.MouseButton1Click:Connect(function(): () task.spawn(Callback, Player, Text, Parameters, box); end);  	 	 	 	      	 	 	
		if typeof(Color) == "Color3" then
			box.MouseEnter:Connect(function(): ()	 
				game.TweenService:Create(box, TweenInfo.new(.3), { BackgroundColor3 = Color:Lerp(Color3.new(1, 1, 1), 0.5), }):Play();
			end);
			box.MouseLeave:Connect(function(): ()		 
				game.TweenService:Create(box, TweenInfo.new(.3), { BackgroundColor3 = Color, }):Play();	
			end);
		end;
	end;	 
	if not DontSendToChat then
		Chat:Message(Text, nil, Player or game.Players.LocalPlayer);			
	end;					

	task.delay(duration / 5, function(): ()
		game.TweenService:Create(
			box,
			TweenInfo.new(duration - duration / 5, Enum.EasingStyle.Linear), 
			{ BackgroundTransparency = 1, TextTransparency = 1, }
		):Play(); 				
	end);   			 
	task.delay(duration, Alert.Destroy, class); 
	 
	return setmetatable(class, Alert); 			
end;			

-- @desc - Removes an Alert object from the screen. 		
-- @param @self - The Alert to remove.
function Alert.Destroy(self: Alert): () 	
	game.TweenService:Create(
		self.Label,
		TweenInfo.new(.1, Enum.EasingStyle.Linear), 
		{ Size = UDim2.new(), } 	
	):Play(); 	 	  
	task.delay(.1, function(): nil self.Label :Destroy(); self = nil; return; end);
end;

-- @desc - Sends the Alert to every player in the server.	 		
-- @param @self - The Alert to replicate.	
function Alert.ReplicateToAllClients(self: Alert): () 	
	return Errors.NotImplementedError.new();			
end; 

----------------------------------------------------------------------------------------------------------------------------
  
return Alert; 	
