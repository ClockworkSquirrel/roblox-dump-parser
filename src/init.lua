local Config = require(script.Config)
local http = require(script.Request)
local Parser = {}

local clireq = http.default({
	url = Config.dumpUrl,
	json = true
})

local function IF(Condition, IfTrue, IfFalse, ...)
	if (type(Condition) == "function" and Condition(...) or Condition) then
		return IfTrue
	end

	return IfFalse
end

local function RecursiveMerge(origin, ...)
	local tables = {...}

	for _, currentTable in next, tables do
		if (type(currentTable) == "table") then
			for key, value in next, currentTable do
				if (type(origin[key]) == "table" and type(currentTable[key]) == "table") then
					origin[key] = RecursiveMerge(origin[key], currentTable[key])
				else
					origin[key] = value
				end
			end
		end
	end

	return origin
end

local function FilterTable(origin, filterFn)
	local filterResults = {}
	for index, value in ipairs(origin) do
		if (filterFn(value, index, origin)) then
			filterResults[#filterResults + 1] = value
		end
	end

	return filterResults
end

local function FindInTable(Needle, Haystack)
	for key, value in next, Haystack do
		if (value == Needle) then
			return true
		end
	end
end

function Parser:GetDump()
	if not (Parser._dump and Parser._dump.Classes) then
		local ok, dump = clireq:async():await()
		assert(ok, dump)

		Parser._dump = dump
	end

	assert(Parser._dump.Classes, "Classes not present in client dump")
	return Parser._dump
end

function Parser:FindClassInDump(ClassName, CaseSensitive)
	CaseSensitive = IF(type(CaseSensitive) == "boolean", CaseSensitive, true)
	ClassName = CaseSensitive and ClassName or string.lower(ClassName)

	local dump = Parser:GetDump()

	for _, classMember in next, dump.Classes do
		local memberName = classMember.Name

		if (memberName == ClassName) then
			return classMember
		end
	end
end

function Parser:GetClassInheritance(ClassName)
	local inheritance = {}

	inheritance[1] = Parser:FindClassInDump(ClassName)
	assert(inheritance[1], string.format("Class \"%s\" not found in client dump", ClassName))

	while (inheritance[#inheritance].Superclass ~= Config.rootClass) do
		local prevClass = inheritance[#inheritance]
		local nextClass = Parser:FindClassInDump(prevClass.Superclass)

		if (not nextClass) then break end
		inheritance[#inheritance + 1] = nextClass
	end

	local returnArray = {}
	for index = #inheritance, 1, -1 do
		returnArray[#returnArray + 1] = inheritance[index]
	end

	return #returnArray > 0 and returnArray
end

function Parser:BuildClass(ClassName)
	local formedClass

	local inheritance = Parser:GetClassInheritance(ClassName)
	assert(inheritance, string.format("Couldn't build inheritance array for \"%s\"", ClassName))

	local index = 0
	for _, ancestor in next, inheritance do
		index = index + 1

		if (index == 1) then formedClass = ancestor else
			formedClass = RecursiveMerge(formedClass, ancestor)
		end
	end

	assert(formedClass, string.format("Couldn't build class for \"%s\"", ClassName))
	return formedClass
end

function Parser:FilterMembers(ClassName, MemberType)
	local class = Parser:BuildClass(ClassName)
	if (not class.Members) then return {} end

	return FilterTable(class.Members, function(member)
		return member.MemberType == MemberType
	end)
end

function Parser:GetPropertiesRaw(ClassName)
	return Parser:FilterMembers(ClassName, "Property")
end

function Parser:GetPropertiesSafeRaw(ClassName)
	return FilterTable(Parser:GetPropertiesRaw(ClassName), function(property)
		local tags = property.Tags or {}
		local security = property.Security

		local insecure = (property.Security.Read == "None" and property.Security.Write == "None")
		local safeTags = not (
			FindInTable("ReadOnly", tags) or FindInTable("Deprecated", tags) or FindInTable("RobloxSecurity", tags)
			or FindInTable("NotAccessibleSecurity", tags) or FindInTable("RobloxScriptSecurity", tags)
		)

		return ((#tags == 0 or safeTags) and insecure)
	end)
end

function Parser:GetPropertyListAll(ClassName)
	local propertiesRaw, properties = Parser:GetPropertiesRaw(ClassName), {}

	for _, property in next, propertiesRaw do
		properties[#properties + 1] = property.Name
	end

	return properties
end

function Parser:GetPropertyList(ClassName)
	local propertiesRaw, properties = Parser:GetPropertiesSafeRaw(ClassName), {}

	for _, property in next, propertiesRaw do
		properties[#properties + 1] = property.Name
	end

	return properties
end

return Parser
