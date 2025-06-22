local Binds = {};	
local list = {};		

	local Bind = {};
	Bind.__index = Bind;
	Bind.new = function(c: string, f: () -> ()): RBXScriptConnection return setmetatable({ Function = f, }, Bind); end; 	
	function Bind:Disconnect(): ()		
		table.remove(list[self.c], table.find(list[self.c], self.f)); 	
		return true; 	
	end;			

function Binds:BindTo(Category: string, f: () -> ()): RBXScriptConnection	 				
	if not list[Category] then list[Category] = {}; end; 	
	table.insert(list[Category], f);	 	
	local _bind = Bind.new(Category, f); 		
	return _bind;	 
end;   

function Binds:FireCategory(Category: string, ...: any): () 	
	task.spawn(function(...): ()	 
		for _, f: ()->() in list[Category] or {} do f(...); end;	
	end, ...); 		
end;	

return Binds;	 	
