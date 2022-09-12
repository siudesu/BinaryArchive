# DOCS - Binary Archive Module 

</br>

# Function List
- [*.new](#new)
- [*.load](#load)
- [*.setCurrentArchive](#setCurrentArchive)
- [*.clearCache](#clearCache*)
- [*.clearBinaryData](#clearBinaryData)
- [*.setFileSignature](#setFileSignature)
- [*.getFileSignature](#getFileSignature)
- [*.newImage](#newImage)
- [*.newImageRect](#newImageRect)
- [*.newImageSheet](#newImageSheet)
- [*.newTexture](#newTexture)
- [*.newMask](#newMask)
- [*.newOutline](#newOutline)
- [*.newEmitter](#newEmitter)
- [*.newImagePaint](#newImagePaint)

</br>

> Note: In the provided syntax, "MODULE" denotes the reference name you give the Binary Archive Module when loading it.

</br>

# *.new
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.new( options ) </div>

- Creates a new binary archive. This function takes a single argument, `options`, which is a [Table](https://docs.coronalabs.com/api/type/Table.html) that accepts basic parameters listed below.

### Parameters:

- signature (optional)
   - [String](https://docs.coronalabs.com/api/type/String.html). An ID for the archive file header. This value must be provided when loading an archive. Default is `"BA22"`.

- baseDir (required)
   - [String](https://docs.coronalabs.com/api/type/String.html). Full path to directory where assets are located on disk. All supported file types found at this location and sub-directories are appended to archive.

- output (optional)
   - [String](https://docs.coronalabs.com/api/type/String.html). Name given to the archive file. Default is `"data.bin"`. 

- fileList (optional)
   - [Table](https://docs.coronalabs.com/api/type/Table.html). If provided, only specified files in this list are appended to archive. Files must reside within `baseDir` and their names must include relative paths`.

</br>

## Examples

   Create a single binary archive with default values:
   
```lua
local binarch = require( "m_binary_archive" )

local options = { baseDir = "C:/Projects/AwesomeApp/assets" }

binarch.new( options )
```
   Create a single binary archive with specified fileList:
```lua
local binarch = require( "m_binary_archive" )

local options = {
		signature = "abc123",
		baseDir = "C:/Projects/AwesomeApp/assets",
		fileList = {
			-- asset is in "baseDir", only filename is provided
			"fish.png",
			-- asset is in "baseDir/waterEffect", relative sub-directory and filename is provided
			"waterEffect/spritesheet_1.png"
		}
	}
	
binarch.new( options )
```
   Create a multiple binary archive files:
```lua
local binarch = require( "m_binary_archive" )

local options1 = {
		signature = "abc123",
		baseDir = "C:/Assets/Airplanes",
		output = "data1.bin"
	}
local options2 = {
		signature = "abc123",
		baseDir = "C:/Assets/Cars",
		output = "data2.bin"
	}
	
binarch.new( options1 )
binarch.new( options2 )
```

</br>

# *.load
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.load( options ) </div>

- Loads a binary archive. This function takes a single argument, `options`, which is a table with basic parameters listed below.
- Returns a `binaryArchiveData` table that can be used to toggle between multiple archives.

### Parameters:

- signature (optional)
   - [String](https://docs.coronalabs.com/api/type/String.html). An ID for the archive file header. If none provided it will use default value. Default is `"BA22"`.

- file (required)
   - [String](https://docs.coronalabs.com/api/type/String.html). Relative path to binary archive in your Solar2D project.

- enableCache (optional)
   - [Boolean](https://docs.coronalabs.com/api/type/Boolean.html). Enable or disable the caching of binary data when fetched, minimizing disk access. Default is `false`. 
     > Note: If set `true` then `*.clearCache()` or ` *.clearBinaryData()` should be used respectively to free up memory.

- imageSuffix (required if set in config.lua)
   - [Table](https://docs.coronalabs.com/api/type/Table.html). If [dynamic image selection](https://docs.coronalabs.com/guide/basics/configSettings/index.html#dynamic-image-selection) is configured in `config.lua`, then it must also be provided here. 

> Note: When an archive is loaded it's active automatically.

</br>

## Examples

   Single binary archive with default values:
   
```lua
local binarch = require( "m_binary_archive" )

local options = {
			signature = "BA22",
			file = "data.bin",
		}

binarch.load( options )

-- create new object from assets in archive
local bg = binarch.newImageRect( "graphics/background.png", 800, 600 )
```
   Multiple binary archives with content scaling suffix:
```lua
local binarch = require( "m_binary_archive" )

local options1 = {
			signature = "abc123",
			file = "assets/data1.bin",
			imageSuffix =
			{
				["@2x"] = 2,
				["@4x"] = 4
			}
		}
local options2 = {
			signature = "abc123",
			file = "assets/data2.bin",
			imageSuffix =
			{
				["@2x"] = 2,
				["@4x"] = 4
			}
		}

local airplaneGroup = display.newGroup()
local carGroup = display.newGroup()

-- archives are set active when loaded, however, only one archive can be active at any time
local airplanesBin = binarch.load( options1 )
local carsBin = binarch.load( options2 )	-- last archive loaded is active

-- create some airplane objects
binarch.setCurrentArchive( airplanesBin ) -- set desired archive as active

local jet1 = binarch.newImageRect( airplaneGroup, "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150
	
local airbus1 = binarch.newImageRect( airplaneGroup, "airbus/a300.png", 200, 200 )
	airbus1.x = 300
	airbus1.y = 150
	
-- create some car objects
binarch.setCurrentArchive( carsBin ) -- set desired archive as active

local skyline1 = binarch.newImageRect( carGroup, "imports/nissan/gtr32.png", 100, 50 )
	skyline1.x = 100
	skyline1.y = 25
	
local supra1 = binarch.newImageRect( carGroup, "imports/toyota/supra.png", 100, 50 )
	supra1.x = 200
	supra1.y = 25
```

</br>

# *.setCurrentArchive
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.setCurrentArchive( binaryArchiveData ) </div>

- Sets a binary archive as active. This function takes a single argument, `binaryArchiveData`.

### Parameters:

- binaryArchiveData (required)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

 > Note: This is used to toggle between multiple archives. No need to call this function if loading and using a single binary archive.

</br>

## Example
```lua
local binarch = require( "m_binary_archive" )

local options1 = {
			signature = "abc123",
			file = "assets/data1.bin",
		}
local options2 = {
			signature = "abc123",
			file = "assets/data2.bin",
		}

-- archives are set active when loaded, however, only one archive can be active at any time
local airplanesBin = binarch.load( options1 )
local carsBin = binarch.load( options2 )	-- last archive loaded is active

-- create airplane object
binarch.setCurrentArchive( airplanesBin ) -- set desired archive as active

local jet1 = binarch.newImageRect( airplaneGroup, "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150


-- create some car objects
binarch.setCurrentArchive( carsBin ) -- set desired archive as active

local skyline1 = binarch.newImageRect( carGroup, "imports/nissan/gtr32.png", 100, 50 )
	skyline1.x = 100
	skyline1.y = 25

```

</br>

# *.clearCache
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.clearCache( binaryArchiveData ) </div>

- Clears ALL cached binary data from specified archive. This function takes a single argument, `binaryArchiveData`.

### Parameters:

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

> Note: Clearing cache does nothing unless "enableCache" is set to `true`. Clearing cache does not affect existing objects.

</br>

## Example
```lua
local binarch = require( "m_binary_archive" )

local options = {
			signature = "abc123",
			file = "assets/data1.bin",
			enableCache = true,
		}

-- create objects from archive
local jet1 = binarch.newImageRect( "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150
	
local airbus1 = binarch.newImageRect( "airbus/a300.png", 200, 200 )
	airbus1.x = 300
	airbus1.y = 150

-- clear cache of all objects from current active archive
binarch.clearCache()
```

</br>

# *.clearBinaryData
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.clearBinaryData( filename, binaryArchiveData ) </div>

- Clears cache of specified binary data from specified archive.

### Parameters:

- filename (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `filename` used to create an object, relative path included.

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

> Note: Clearing cache does not affect existing objects.

</br>

## Example
```lua
local binarch = require( "m_binary_archive" )

local options = {
			signature = "BA22",
			file = "data.bin",
			enableCache = true,
		}

binarch.load( options )

-- create new object from assets in archive
local bg = binarch.newImageRect( "graphics/background.png", 800, 600 )

-- clear cached data
binarch.clearBinaryData("graphics/background.png")
```

</br>

# *.setFileSignature
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.setFileSignature( signature ) </div>

- Sets a default file signature to use for creating or loading archives. This function takes a single argument, `signature`.

### Parameters:

- signature (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `signature` can be any form of a valid string.

## Example
```lua
local binarch = require( "m_binary_archive" )

-- set a new default file signature
binarch.setFileSignature("MMXXII")

-- no signature specified, it will use the new default signature
local options = {
			file = "data.bin",
		}

-- load archive
binarch.load( options )
```

</br>

# *.getFileSignature
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.getFileSignature() </div>

- Returns the default file signature. This function takes no arguments.

## Example
```lua
local binarch = require( "m_binary_archive" )

-- get current default file signature
local currentFileSignature = binarch.getFileSignature()

print("Current File Signature is: " .. tostring(currentFileSignature))
```

</br>

# *.newImage
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newImage( [parent,] filename [, x, y] ) </div>

### Parameters:
- Same as [display.newImage](https://docs.coronalabs.com/api/library/display/newImage.html) except no `baseDir`. 
> For using `*.newImage( [parent,] imageSheet, frameIndex [, x, y] )` use [display.newImage](https://docs.coronalabs.com/api/library/display/newImage.html) instead.



</br>

# *.newImageRect
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newImageRect( [parent,] filename, width, height ) </div>

### Parameters:
- Same as [display.newImageRect](https://docs.coronalabs.com/api/library/display/newImageRect.html) except no `baseDir`. 
> For using `*.newImageRect( [parent,] imageSheet, frameIndex, width, height )` use [display.newImageRect](https://docs.coronalabs.com/api/library/display/newImageRect.html) instead.

</br>

# *.newImageSheet
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newImageSheet( filename, options ) </div>

### Parameters:
- Same as [graphics.newImageSheet](https://docs.coronalabs.com/api/library/graphics/newImageSheet.html) except no `baseDir`. 

</br>

# *.newTexture
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newTexture( filename ) </div>

### Parameters:
- Only `filename` is required. Creates an `image` type of [TextureResourceBitmap](https://docs.coronalabs.com/api/type/TextureResourceBitmap/index.html).

</br>

# *.newMask
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newMask( filename ) </div>

### Parameters:
- Same as [graphics.newMask](https://docs.coronalabs.com/api/library/graphics/newMask.html) except no `baseDir`. 

</br>

# *.newOutline
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newOutline( coarsenessInTexels, imageFileName ) </div>

### Parameters:
- Same as [graphics.newOutline](https://docs.coronalabs.com/api/library/graphics/newOutline.html) except no `baseDir`. 

</br>

# *.newEmitter
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newEmitter( emitterParams ) </div>

### Parameters:
- Same as [graphics.newEmitter](https://docs.coronalabs.com/api/library/display/newEmitter.html) except no `baseDir`. 

</br>

# *.newImagePaint
<div style="background-color:#23CBFF10;font-size:16px;vertical-align:middle;padding:5px"> Syntax: MODULE.newImagePaint( filename ) </div>

### Parameters:
- Only `filename` is required. Returns a [Table](https://docs.coronalabs.com/api/type/Table.html) to be used as [Bitmap Image Fill](https://docs.coronalabs.com/api/type/ShapeObject/fill.html#bitmap-image-fill).

## Example
```lua
-- load module
local binarch = require( "m_binary_archive" )

-- load binary file
binarch.Load( {file = "assets/data.bin"} )

-- create new rectangle and do object fill
local rect = display.newRect( 150, 150, 50, 50 )
	rect.fill = binarch.newImagePaint( "Fishies/fish.small.red.png" )
```
</br>

## License
Distributed under the MIT License. See [LICENSE](https://github.com/siudesu/BinaryArchive/blob/main/LICENSE) for more information.