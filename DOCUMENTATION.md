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
Creates a new binary archive.

### Syntax:
- MODULE.new( options )

### Parameters:

- options (required)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). Containing the following basic parameters:
		- signature (optional)
			- [String](https://docs.coronalabs.com/api/type/String.html). An ID for the archive file header. This value can be used when loading an archive. Default is `"BA22"`.

		- baseDir (required)
			- [String](https://docs.coronalabs.com/api/type/String.html). Full path to directory where assets are located on disk. All supported file types found at this location and sub-directories are appended to archive.

		- output (optional)
			- [String](https://docs.coronalabs.com/api/type/String.html). Name given to the archive file. Default is `"data.bin"`. 

		- fileList (optional)
			- [Table](https://docs.coronalabs.com/api/type/Table.html). If provided, only specified files in this list are appended to archive. Files must reside within `baseDir` and their names must include relative paths.

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
Loads a binary archive. Returns a `binaryArchiveData` [Table](https://docs.coronalabs.com/api/type/Table.html) that can be used to toggle between multiple archives.

### Syntax:

- MODULE.load( options )

### Parameters:

- options (required)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). Containing the following basic parameters:

		- signature (optional)
		   - [String](https://docs.coronalabs.com/api/type/String.html). An ID for the archive file header. If none provided it will use default value. Default is `"BA22"`.

		- file (required)
		   - [String](https://docs.coronalabs.com/api/type/String.html). Relative path to binary archive in your Solar2D project.

		- enableCache (optional)
		   - [Boolean](https://docs.coronalabs.com/api/type/Boolean.html). Enable or disable the caching of binary data when fetched, minimizing disk access. Default is `false`. 
			 > Note: If set `true` then `*.clearCache()` or ` *.clearBinaryData()` should be used respectively to free up memory.

		- imageSuffix (*required*)
		   - [Table](https://docs.coronalabs.com/api/type/Table.html). If [dynamic image selection](https://docs.coronalabs.com/guide/basics/configSettings/index.html#dynamic-image-selection) is configured in `config.lua`, then it must also be provided here. 

> Note: When an archive is loaded it is automatically set active.

</br>

## Examples

   Single binary archive with default values:
   
```lua
local binarch = require( "m_binary_archive" )

local options = {
			signature = "BA22",
			file = "data.bin",
		}

-- load archive
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

-- create display groups to insert our objects
local airplaneGroup = display.newGroup()
local carGroup = display.newGroup()

-- archives are set active when loaded, however, only one archive can be active at any time
local airplanesBin = binarch.load( options1 )
local carsBin = binarch.load( options2 )	-- last archive loaded is set active

-- create some airplane objects
binarch.setCurrentArchive( airplanesBin ) -- toggle archive

local jet1 = binarch.newImageRect( airplaneGroup, "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150
	
local airbus1 = binarch.newImageRect( airplaneGroup, "airbus/a300.png", 200, 200 )
	airbus1.x = 300
	airbus1.y = 150
	
-- create some car objects
binarch.setCurrentArchive( carsBin ) -- toggle archive

local skyline1 = binarch.newImageRect( carGroup, "imports/nissan/gtr32.png", 100, 50 )
	skyline1.x = 100
	skyline1.y = 25
	
local supra1 = binarch.newImageRect( carGroup, "imports/toyota/supra.png", 100, 50 )
	supra1.x = 200
	supra1.y = 25
```

</br>

# *.setCurrentArchive
Sets a binary archive active.

### Syntax:
- MODULE.setCurrentArchive( binaryArchiveData )

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
binarch.setCurrentArchive( airplanesBin ) -- toggle archive

local jet1 = binarch.newImageRect( airplaneGroup, "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150


-- create some car objects
binarch.setCurrentArchive( carsBin ) -- toggle archive

local skyline1 = binarch.newImageRect( carGroup, "imports/nissan/gtr32.png", 100, 50 )
	skyline1.x = 100
	skyline1.y = 25

```

</br>

# *.clearCache
Clears **ALL** cached data from specified archive.

### Syntax:
- MODULE.clearCache( binaryArchiveData )

### Parameters:

- binaryArchiveData (optional)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).
	
	- If note provided, it will default to current active archive
> Note: Clearing cache does nothing unless "enableCache" flag is set to `true`. Clearing cache does not affect existing objects.

</br>

## Example
```lua
local binarch = require( "m_binary_archive" )

local options = {
			signature = "abc123",
			file = "assets/data1.bin",
			enableCache = true,
		}

-- load archive
binarch.load( options )

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
Clears cache from specified data and archive.

### Syntax:
- MODULE.clearBinaryData( filename, binaryArchiveData )

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
Sets a default file signature to use for creating or loading archives.

### Syntax:
- MODULE.setFileSignature( signature )

### Parameters:

- signature (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `signature` can be any valid [String](https://docs.coronalabs.com/api/type/String.html).

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
Returns the current default file signature.

### Syntax:
- MODULE.getFileSignature()

## Example
```lua
local binarch = require( "m_binary_archive" )

-- get current default file signature
local currentFileSignature = binarch.getFileSignature()

print("Current File Signature is: " .. tostring(currentFileSignature))
```

</br>

# *.newImage
Returns a [DisplayObject](https://docs.coronalabs.com/api/type/DisplayObject/index.html).

### Syntax:
- MODULE.newImage( [parent,] filename [, x, y] )

### Parameters:
- Same as [display.newImage](https://docs.coronalabs.com/api/library/display/newImage.html) except no `baseDir`. 
> For `*.newImage( [parent,] imageSheet, frameIndex [, x, y] )` use [display.newImage](https://docs.coronalabs.com/api/library/display/newImage.html) instead.



</br>

# *.newImageRect
Returns a [DisplayObject](https://docs.coronalabs.com/api/type/DisplayObject/index.html).

### Syntax:
- MODULE.newImageRect( [parent,] filename, width, height )

### Parameters:
- Same as [display.newImageRect](https://docs.coronalabs.com/api/library/display/newImageRect.html) except no `baseDir`. 
> For `*.newImageRect( [parent,] imageSheet, frameIndex, width, height )` use [display.newImageRect](https://docs.coronalabs.com/api/library/display/newImageRect.html) instead.

</br>

# *.newImageSheet
Returns an [ImageSheet](https://docs.coronalabs.com/api/type/ImageSheet/index.html) object.

### Syntax:
- MODULE.newImageSheet( filename, options )

### Parameters:
- Same as [graphics.newImageSheet](https://docs.coronalabs.com/api/library/graphics/newImageSheet.html) except no `baseDir`. 

</br>

# *.newTexture
Returns a [TextureResource](https://docs.coronalabs.com/api/type/TextureResource/index.html) object.

### Syntax:
- MODULE.newTexture( filename )

### Parameters:
- Only `filename` is required. Creates an `image` type of [TextureResourceBitmap](https://docs.coronalabs.com/api/type/TextureResourceBitmap/index.html).

</br>

# *.newMask
Returns a [Mask](https://docs.coronalabs.com/api/type/Mask/index.html) object.

### Syntax:
- MODULE.newMask( filename )

### Parameters:
- Same as [graphics.newMask](https://docs.coronalabs.com/api/library/graphics/newMask.html) except no `baseDir`. 

</br>

# *.newOutline
Returns a [Table](https://docs.coronalabs.com/api/type/Table.html) of x and y coordinates in content space that can be used as the outline for the [physics.addBody](https://docs.coronalabs.com/api/library/physics/addBody.html).

### Syntax:
- MODULE.newOutline( coarsenessInTexels, imageFileName )

### Parameters:
- Same as [graphics.newOutline](https://docs.coronalabs.com/api/library/graphics/newOutline.html) except no `baseDir`. 

> For `*.newOutline( coarsenessInTexels, imageSheet, frameIndex )` use [graphics.newOutline](https://docs.coronalabs.com/api/library/graphics/newOutline.html) instead.

</br>

# *.newEmitter
Returns a [EmitterObject](https://docs.coronalabs.com/api/type/EmitterObject/index.html).

### Syntax:
- MODULE.newEmitter( emitterParams )

### Parameters:
- Same as [graphics.newEmitter](https://docs.coronalabs.com/api/library/display/newEmitter.html) except no `baseDir`. 

</br>

# *.newImagePaint
Returns a [BitmapPaint](https://docs.coronalabs.com/api/type/BitmapPaint/index.html) that can be used with [object.fill](https://docs.coronalabs.com/api/type/ShapeObject/fill.html#bitmap-image-fill).

### Syntax:
- MODULE.newImagePaint( filename )

### Parameters:
- The `filename` of an image file as stored in an archive.

## Example
```lua
-- load module
local binarch = require( "m_binary_archive" )

-- load archive
binarch.load( {file = "assets/data.bin"} )

-- create a new rectangle and apply object fill
local rect = display.newRect( 150, 150, 50, 50 )
	rect.fill = binarch.newImagePaint( "Fishies/fish.small.red.png" )
```
</br>

## License
Distributed under the MIT License. See [LICENSE](https://github.com/siudesu/BinaryArchive/blob/main/LICENSE) for more information.