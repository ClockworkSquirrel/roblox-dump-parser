--[[
<metadata>
	Author: ClockworkSquirrel
	Name: DumpParser
	Description: Fetch and parses the latest client API dump.
	Updated: 2020-03-03
	Release: 0.1.2-pre
</metadata>
--]]

local Config = require(script.Config)
local http = require(script.Request)

local Parser = {
	_classes = {}
}

local clireq = http.default({
	url = Config.dumpUrl,
	json = true
})

local function CopyTable(origin)
	if (type(origin) == "table") then
		local copy = {}

		for key, value in next, origin do
			copy[CopyTable(key)] = CopyTable(value)
		end

		return copy
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

function Parser:FindClassInDump(ClassName)
	ClassName = string.lower(ClassName)
	local dump = Parser:GetDump()

	for index, classMember in ipairs(dump.Classes) do
		local memberName = string.lower(classMember.Name)

		if (memberName == ClassName) then
			return CopyTable(classMember)
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
	local lowerClassName = string.lower(ClassName)

	if (Parser._classes[lowerClassName]) then
		return Parser._classes[lowerClassName]
	end

	local formedClass

	local inheritance = Parser:GetClassInheritance(ClassName)
	assert(inheritance, string.format("Couldn't build inheritance array for \"%s\"", ClassName))

	local index, memberHistory, registeredMembers = 0, {}, {}
	for _, ancestor in next, inheritance do
		index = index + 1

		if (index == 1) then
			formedClass = ancestor

			if (formedClass.Members) then
				for _, member in ipairs(formedClass.Members) do
					registeredMembers[#registeredMembers + 1] = member.Name
				end
			end
		else
			for key, value in next, ancestor do
				if (key == "Members") then
					memberHistory[#memberHistory + 1] = value
				else
					formedClass[key] = value
				end
			end
		end
	end

	if (not formedClass.Members) then
		formedClass.Members = {}
	end

	for _, memberTable in ipairs(memberHistory) do
		for _, member in ipairs(memberTable) do
			if (not FindInTable(member.Name, registeredMembers)) then
				formedClass.Members[#formedClass.Members + 1] = member
				registeredMembers[#registeredMembers + 1] = member.Name
			end
		end
	end

	assert(formedClass, string.format("Couldn't build class for \"%s\"", ClassName))
	Parser._classes[lowerClassName] = formedClass

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
			or FindInTable("NotAccessibleSecurity", tags) or FindInTable("RobloxScriptSecurity", tags) or
			FindInTable("NotScriptable", tags)
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
