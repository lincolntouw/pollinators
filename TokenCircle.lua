--[[------------------------------------------------------------------------------------------------------------------------
 
	--- TokenCircle Module ---	
	
	Created by Lincoln Touw
	V1.1 6/16/2025
	V1.0 9/16/2024 		 	 			
	 
	--- LJPackageManager Information: ---	 
	<ModuleName>TokenCircle</ModuleName>
	<ModuleAuthor>Lincoln Touw</ModuleAuthor>	 
	<ModuleVersion>1.1</ModuleVersion>	
	<PackageDependencies></PackageDependencies>	 			
	
--]]------------------------------------------------------------------------------------------------------------------------
	 
local TokenCircle = {};
				      	
function TokenCircle.generate(center: Vector3, amount: number, customRadius: number?)		  	
	local list: {number}, radius: number = {}, customRadius or amount * 1.6;  
	for i = 1, amount do
		local angle = i / amount * math.pi * 2;
		local x = center.X + math.cos(angle) * (radius); 	
		local z = center.Z + math.sin(angle) * (radius);
		local space = Vector3.new(x, center.Y, z); 	
		table.insert(list, space);
	end;
	return list;   	
end;	
 		
return TokenCircle;
