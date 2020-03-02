# roblox-dump-parser
Library for parsing the Roblox client dump API. Requires the [@ClockworkSquirrel/Request](https://github.com/ClockworkSquirrel/request) library.

# Releases
The `DumpParser` library is available in the [releases tab](../../releases/latest). You can also grab a copy from the [Roblox library page](https://www.roblox.com/library/4731644789).

# Summary of Methods
- `Parser:GetDump()`
- `Parser:FindClassInDump(ClassName, CaseSensitive)`
- `Parser:GetClassInheritance(ClassName)`
- `Parser:BuildClass(ClassName)`
- `Parser:FilterMembers(ClassName, MemberType)`
- `Parser:GetPropertiesRaw(ClassName)`
- `Parser:GetPropertiesSafeRaw(ClassName)`
- `Parser:GetPropertyListAll(ClassName)`
- `Parser:GetPropertyList(ClassName)`

# Methods
## `Parser:GetDump()`
Fetches the latest API dump from the repo specified in `Config.lua`. By default, this uses [@CloneTrooper1019](https://github.com/CloneTrooper1019)'s [Roblox-Client-Tracker/API-Dump.json](https://github.com/CloneTrooper1019/Roblox-Client-Tracker/blob/roblox/API-Dump.json).

### Syntax
`<Dictionary> Parser:GetDump()`

## `Parser:FindClassInDump()`
Fetches the API dump (using `::GetDump()`) and searches the `Classes` array for the matching `ClassName`. By default, `ClassNames` are case-sensitive. Set `CaseSensitive` to `false` to match any case.

### Syntax
`<Dictionary> Parser:FindClassInDump(<string> ClassName, <boolean> CaseSensitive)`

## `Parser:GetClassInheritance()`
Returns an array of classes which are ancestors of the given `ClassName`, starting with the root class (generally `Instance`), and working down to the given `ClassName`.

### Syntax
`<Array (of Dictionaries)> Parser:GetClassInheritance(<string> ClassName)`

## `Parser:BuildClass()`
Retrieves the inheritance of the given `ClassName` and flattens it down to a single dictionary, containing all metadata about the given class.

### Syntax
`<Dictionary> Parser:BuildClass(<string> ClassName)`

## `Parser:FilterMembers()`
Iterates through the `Members` array of a given class, and singles out members matching the given `MemberType`. Useful for fetching properties of a class, etc.

### Syntax
`<Array (of Dictionaries)> Parser:FilterMembers(<string> ClassName, <string> MemberType)`

## `Parser:GetPropertiesRaw()`
Returns the properties of the given `ClassName` in its raw format; as specified in the API dump.

### Syntax
`<Array (of Dictionaries)> Parser:GetPropertiesRaw(<string> ClassName)`

## `Parser:GetPropertiesSafeRaw()`
Returns only the properties which can be both read from and written to in-game in their raw format; as specified in the API dump. This will exclude any properties whose `Security` values are not set to `None`, in addition to any properties with the following tags: `ReadOnly`, `Deprecated`, `RobloxSecurity`, `NotAccessibleSecurity`, `RobloxScriptSecurity`.

### Syntax
`<Array (of Dictionaries)> Parser:GetPropertiesSafeRaw(<string> ClassName)`

## `Parser:GetPropertyListAll()`
Returns an array containing only the names of the properties for the given `ClassName`.

### Syntax
`<Array (of strings)> Parser:GetPropertyListAll(<string> ClassName)`

## `Parser:GetPropertyList()`
Returns an array containing only the names of the properties for the given `ClassName`. Unsafe properties will be excluded. See [`Parser:GetPropertiesSafeRaw()`]() for the criteria.

### Syntax
`<Array (of strings)> Parser:GetPropertyList(<string> ClassName)`

### Example
```lua
local parser = require(path.to.parser)

local target = workspace.Baseplate
local properties = parser:GetPropertyList(target.ClassName)

for _, property in next, properties do
    print(property, "=", target[property])
end
```

> **Expected Output**\
> `Anchored = true`\
> `BackParamA = -0.5`\
> `BackParamB = 0.5`\
> `BackSurface = Enum.SurfaceType.Smooth`\
> `BackSurfaceInput = Enum.InputType.NoInput`\
> `BottomParamA = -0.5`\
> `BottomParamB = 0.5`\
> `BottomSurface = Enum.SurfaceType.Inlet`\
> `BottomSurfaceInput = Enum.InputType.NoInput`\
> `BrickColor = Dark stone grey`\
> `CFrame = 0, -10, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1`\
> `CanCollide = true`\
> `CastShadow = true`\
> `CollisionGroupId = 0`\
> `Color = 0.388235, 0.372549, 0.384314`\
> `CustomPhysicalProperties = nil`\
> `FrontParamA = -0.5`\
> `FrontParamB = 0.5`\
> `FrontSurface = Enum.SurfaceType.Smooth`\
> `FrontSurfaceInput = Enum.InputType.NoInput`\
> `LeftParamA = -0.5`\
> `LeftParamB = 0.5`\
> `LeftSurface = Enum.SurfaceType.Smooth`\
> `LeftSurfaceInput = Enum.InputType.NoInput`\
> `LocalTransparencyModifier = 0`\
> `Locked = true`\
> `Massless = false`\
> `Material = Enum.Material.Plastic`\
> `Orientation = 0, 0, 0`\
> `Position = 0, -10, 0`\
> `Reflectance = 0`\
> `RightParamA = -0.5`\
> `RightParamB = 0.5`\
> `RightSurface = Enum.SurfaceType.Smooth`\
> `RightSurfaceInput = Enum.InputType.NoInput`\
> `RootPriority = 0`\
> `RotVelocity = 0, 0, 0`\
> `Rotation = 0, 0, 0`\
> `Size = 512, 20, 512`\
> `TopParamA = -0.5`\
> `TopParamB = 0.5`\
> `TopSurface = Enum.SurfaceType.Studs`\
> `TopSurfaceInput = Enum.InputType.NoInput`\
> `Transparency = 0`\
> `Velocity = 0, 0, 0`\
> `Shape = Enum.PartType.Block`\
