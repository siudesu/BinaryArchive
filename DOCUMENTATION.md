# DOCS - Binary Archive Module 

</br>

# Function List
- [*.new](#new)
- [*.load](#load)
- [*.setCurrentArchive](#setCurrentArchive)
- [*.clearCache](#clearCache)
- [*.clearBinaryData](#clearBinaryData)
- [*.setFileSignature](#setFileSignature)
- [*.getFileSignature](#getFileSignature)
- [*.fetch](#fetch)
- [*.fetchRaw](#fetchRaw)
- [*.extract](#extract)
- [*.extractRaw](#extractRaw)
- [*.appendData](#appendData)
- [*.appendFile](#appendFile)
- [*.refresh](#refresh)
- [*.encrypt](#encrypt)
- [*.decrypt](#decrypt)
- [*.enableSSL](#enableSSL)
- [*.releaseTexture](#releaseTexture)
- [*.setDebugMode](#setDebugMode) *might be removed in the future or placed in a separate debug-only module.
- [*.newImage](#newImage)
- [*.newImageRect](#newImageRect)
- [*.newImageSheet](#newImageSheet)
- [*.newTexture](#newTexture)
- [*.setMask](#setMask)
- [*.newOutline](#newOutline)
- [*.newEmitter](#newEmitter)
- [*.imagePaint](#imagePaint)
- [*.compositePaint](#compositePaint)

</br>

> Note: In the provided syntax, "MODULE" denotes the reference name you give the Binary Archive Module when loading it.

</br>

# *.new
Creates a new archive.

### Syntax:
- MODULE.new( options )

### Parameters:

- options (required), a [Table](https://docs.coronalabs.com/api/type/Table.html) containing the following basic parameters:
	- signature (optional)
		- [String](https://docs.coronalabs.com/api/type/String.html). An ID for the archive file header. Default is `"BA22"`.

	- baseDir (required)
		- [String](https://docs.coronalabs.com/api/type/String.html). Full path to directory where assets are located on disk. All files are appended; includes files in sub-directories.
		> Note: Use the `exlude` option below to filter out any unwanted file types.

	- output (optional)
		- [String](https://docs.coronalabs.com/api/type/String.html). Name given to the archive file. Default is `"data.bin"`. 

	- fileList (optional)
		- [Table](https://docs.coronalabs.com/api/type/Table.html). If provided, only specified files in this list are appended to archive. Files must reside within `baseDir` and their names must include relative path.

	- key (*required*)
		- [String](https://docs.coronalabs.com/api/type/String.html). This is used to encrypt data in archive, only required if encryption is enabled.
	
	- exclude (optional)
		- [Table](https://docs.coronalabs.com/api/type/Table.html). Any file matching the listed file extension will be excluded and not appended.
		- The following will ignore *.txt, *.lua, and *.mp4 file types.
		</br>	```exclude = {txt=true, lua=true, mp4=true}```
		> Note: File extensions are case sensitive, you should use upper or lower case where necessary.
	

</br>

## Examples

###   Create a single archive with default values:
   
```lua
-- load module
local bin = require( "m_binary_archive" )

-- specify full path where assets are located (all files will be appended, includes sub-directories)
local options = { baseDir = "D:/Projects/Solar2D/AwesomeProject/assets/graphics" }

-- create a new archive, output will be saved at baseDir
bin.new( options )
```
### Create a new archive with encryption enabled:
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable SSL for encryption
bin.enableSSL()

-- specify full path where assets are located (all files will be appended, includes sub-directories)
local options = {
	baseDir = "D:/Projects/Solar2D/AwesomeProject/assets/graphics",
	key = tostring(37042), -- key for encrypting data
}

-- create a new archive, output will be saved at baseDir
bin.new( options )
```
### Create a single archive with specified fileList and signature:
```lua
-- load module
local bin = require( "m_binary_archive" )

local options = {
		signature = "abc123",
		baseDir = "C:/Projects/AwesomeApp/assets",
		key = tostring(37042),
		fileList = {
			"fish.png", -- asset is in "baseDir", only filename is provided
			"waterEffect/spritesheet_1.png" -- relative sub-directory and filename is provided
		}
	}

-- create a new archive, output will be saved at baseDir
bin.new( options )
```
### Create a single archive with file type exclusion:
```lua
-- load module
local bin = require( "m_binary_archive" )

local options = {
		baseDir = "C:/Projects/AwesomeApp/assets",
		exclude = {mp4=true, lua=true}	-- any file with extension name .mp4 or .lua, will not be appened to archive
	}

-- create a new archive, output will be saved at baseDir
bin.new( options )
```
### Create multiple archives:
```lua
-- load module
local bin = require( "m_binary_archive" )

local options1 = {
		signature = "abc123",
		baseDir = "C:/Assets/Airplanes",
		key = tostring(37042),
		output = "data1.bin"
	}
local options2 = {
		signature = "abc123",
		baseDir = "C:/Assets/Cars",
		key = tostring(78641),
		output = "data2.bin"
	}

-- create new archives, output will be saved at baseDir respectively
bin.new( options1 )
bin.new( options2 )
```

###   Create an empty archive to be used for saving data:
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- The options below are provided to create an empty archive, and can be used to append data at a later time.
local options = {
		baseDir = "C:/Assets",
		key = tostring(37042),
		fileList = {} -- IMPORTANT: pass empty table as fileList
		output = "settings.bin"
	}

-- create a new archive, output will be saved at baseDir
bin.new( options )
```

</br>

# *.load
Loads an archive. Returns a `binaryArchiveData` [Table](https://docs.coronalabs.com/api/type/Table.html) that can be used to toggle between multiple archives.

### Syntax:

- MODULE.load( options , overwritePath)

### Parameters:

- options (required), a [Table](https://docs.coronalabs.com/api/type/Table.html) containing the following basic parameters:

	- signature (optional)
	   - [String](https://docs.coronalabs.com/api/type/String.html). The ID used when creating the archive. If none provided it will use default value: `"BA22"`.

	- file (required)
	   - [String](https://docs.coronalabs.com/api/type/String.html). Location of file relative to where main.lua resides; this is the default location. If file is located elsewhere then specify path here and set `overwritePath` to `true`, see below.
	
	- key (required)
		- [String](https://docs.coronalabs.com/api/type/String.html). Used to decrypt data in archive. Must be same key provided when archive was created.
	
	- enableCache (optional)
	   - [Boolean](https://docs.coronalabs.com/api/type/Boolean.html). Enables the caching of binary data after being fetched, minimizing disk access. Default is `false`. 
		 > Note: If set `true` then [*.clearCache](#clearCache) or [*.clearBinaryData](#clearBinaryData) should be used respectively to free up memory.

	- imageSuffix (*optional*)
	   - [Table](https://docs.coronalabs.com/api/type/Table.html). If [dynamic image selection](https://docs.coronalabs.com/guide/basics/configSettings/index.html#dynamic-image-selection) is configured in `config.lua`, then it should also be provided here. If not provided then dynamic-image-selection will not work for certain objects in wrapped functions.

- overwritePath (optional)

	- [Boolean](https://docs.coronalabs.com/api/type/Boolean.html). Set to `true` if specifying a `file` path other than project's directory. Default is `false`.

> Note: When an archive is loaded it is automatically set active.

</br>

## Examples

### Load a single archive with default values:
   
```lua
-- load module
local bin = require( "m_binary_archive" )

local options = { file = "data.bin" }

-- load archive
bin.load( options )

-- create new object from assets in archive
local bg = bin.newImageRect( "graphics/background.png", 800, 600 )
```
### Load multiple encrypted archives and use content scaling suffix:
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option tables
local options1 = {
			file = "assets/data1.bin",
			key = tostring(37042),
			imageSuffix =
			{
				["@2x"] = 2,
				["@4x"] = 4
			}
		}
local options2 = {
			file = "assets/data2.bin",
			key = tostring(78641),
			imageSuffix =
			{
				["@2x"] = 2,
				["@4x"] = 4
			}
		}

-- archives are set active when loaded, however, only one archive can be active at any time
local airplanesBin = bin.load( options1 )
local carsBin = bin.load( options2 )	-- last archive loaded is set active

-- create display groups to insert our objects
local airplaneGroup = display.newGroup()
local carGroup = display.newGroup()

-- create some airplane objects
bin.setCurrentArchive( airplanesBin ) -- toggle archive

local jet1 = bin.newImageRect( airplaneGroup, "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150
	
local airbus1 = bin.newImageRect( airplaneGroup, "airbus/a300.png", 200, 200 )
	airbus1.x = 300
	airbus1.y = 150
	
-- create some car objects
bin.setCurrentArchive( carsBin ) -- toggle archive

local skyline1 = bin.newImageRect( carGroup, "imports/nissan/gtr32.png", 100, 50 )
	skyline1.x = 100
	skyline1.y = 25
	
local supra1 = bin.newImageRect( carGroup, "imports/toyota/supra.png", 100, 50 )
	supra1.x = 200
	supra1.y = 25
```
</br>

# *.setCurrentArchive
Sets an archive active.

### Syntax:
- MODULE.setCurrentArchive( binaryArchiveData )

### Parameters:

- binaryArchiveData (required)
	- `binaryArchiveData` [Table](https://docs.coronalabs.com/api/type/Table.html) that is returned when using [*.load](#load).

 > Note: This is used to toggle between multiple archives. No need to call this function if loading and using a single archive.

</br>

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- archives are set active when loaded, however, only one archive can be active at any time
local airplanesBin = bin.load( { file = "assets/data1.bin" } )
local carsBin = bin.load( { file = "assets/data2.bin" } )	-- last archive loaded is active

-- create an object from last loaded archive
local skyline1 = bin.newImageRect( "imports/nissan/gtr32.png", 100, 50 )
	skyline1.x = 100
	skyline1.y = 25

-- set active a different archive
bin.setCurrentArchive( airplanesBin ) -- toggle archive

-- create object with current active archive
local jet1 = bin.newImageRect( "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150

```

</br>

# *.clearCache
Clears **ALL** cached data and releases textures from specified archive.

### Syntax:
- MODULE.clearCache( binaryArchiveData )

### Parameters:

- binaryArchiveData (optional)
	- `binaryArchiveData` [Table](https://docs.coronalabs.com/api/type/Table.html) that is returned when using [*.load](#load).
	- If none provided, it will default to current active archive
> Note: If `enableCache` flag is not used (see [*.load](#load)) then this function will just clear cached textures, otherwise all cached data and textures will be cleared. Clearing cache does not affect existing objects, but textures will be removed when no longer in use.

</br>

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- setup option table with cache enabled
local options = {
			file = "assets/data1.bin",
			enableCache = true,
		}

-- load archive
bin.load( options )

-- create objects from archive
local jet1 = bin.newImageRect( "jets/jumbo/Dassault Falcon 7X.png", 200, 200 )
	jet1.x = 150
	jet1.y = 150
	
local airbus1 = bin.newImageRect( "airbus/a300.png", 200, 200 )
	airbus1.x = 300
	airbus1.y = 150

-- clear cache of all objects from current active archive
bin.clearCache()
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
-- load module
local bin = require( "m_binary_archive" )

-- setup option table with cache enabled
local options = {
			file = "data.bin",
			enableCache = true,
		}

bin.load( options )

-- create new object from assets in archive
local bg = bin.newImageRect( "graphics/background.png", 800, 600 )

-- clear cached data
bin.clearBinaryData("graphics/background.png")
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
-- load module
local bin = require( "m_binary_archive" )

-- set a new default file signature
bin.setFileSignature("MMXXII")

-- no signature specified, it will use the new default signature
local options = {
			file = "data.bin",
		}

-- load archive
bin.load( options )
```

</br>

# *.getFileSignature
Returns the current default file signature.

### Syntax:
- MODULE.getFileSignature()

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- get current default file signature
local currentFileSignature = bin.getFileSignature()

print("Current File Signature is: " .. tostring(currentFileSignature))
```

</br>

# *.fetch
Returns decrypted data from archive if encryption is enabled, else it returns data as is stored in archive.

### Syntax:
- MODULE.fetch( filename, binaryArchiveData )

### Parameters:

- filename (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `filename` used to append  file or data in archive, relative path included.

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

> Note: The archive's key will be used for decryption if encryption is enabled with [*.enableSSL](#enableSSL).

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option table with encryption key
local options = {
		file = "settings.bin",
		key = tostring(37042),
	}

-- load archive
bin.load( options )

-- fetch decrypted data
local score = bin.fetch( "player_score" )

-- create a text object with score data
local label = display.newText( score, 50, 25 )
```

</br>

# *.fetchRaw
Returns data from archive as-is, whether encrypted or not.

### Syntax:
- MODULE.fetchRaw( filename, binaryArchiveData)

### Parameters:

- filename (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `filename` used to create an object, relative path included.

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option table with encryption key
local options = {
		file = "settings.bin",
		key = tostring(37042),
	}

-- load archive
local settings_bin = bin.load( options )

-- fetch encrypted data
local encryptedScore = bin.fetchRaw("player_score", settings_bin)

-- manually decrypt data before use ; key used is the same that was provided to with load( options )
local score = bin.decrypt(encryptedScore, tostring(37042))

-- create a text object with score data
local label = display.newText(score, 50, 25)
```

</br>

# *.extract
Extracts data from archive and saves it specified path on disk. if encryption is enabled data will be decrypted.

### Syntax:
- MODULE.extract( filename, destination, binaryArchiveData)

### Parameters:

- filename (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `filename` of stored data, relative path included.

- destination (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Path on disk where file will be saved.

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option table with encryption key
local options = {
		file = "settings.bin",
		key = tostring(37042),
	}

-- load archive
bin.load( options )

-- get path to extract on disk
local path = system.pathForFile("", system.TemporaryDirectory)

-- extract files
bin.extract("graphics/SpriteTiles/sprites.png", path)
bin.extract("graphics/Fishies/fish.small.red.png", path)
bin.extract("graphics/HorseAnimation/moon.png", path)
```
</br>

# *.extractRaw
Extracts data as-is from archive and saves it specified path on disk, no decryption is performed.

### Syntax:
- MODULE.extractRaw( filename, destination, binaryArchiveData)

### Parameters:

- filename (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `filename` of stored data, relative path included.

- destination (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Path on disk where file will be saved.

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option table with encryption key
local options = {
		file = "settings.bin",
		key = tostring(37042),
	}

-- load archive
bin.load( options )

-- get path to extract on disk
local path = system.pathForFile("", system.TemporaryDirectory)

-- extract files, if files are encrypted in archive then they will also be encrypted on disk at specified path
bin.extractRaw("graphics/SpriteTiles/sprites.png", path)
bin.extractRaw("graphics/Fishies/fish.small.red.png", path)
bin.extractRaw("graphics/HorseAnimation/moon.png", path)
```
</br>

# *.appendData
Encrypts data, if encryption is enabled, and is appends it to specified archive.

### Syntax:
- MODULE.appendData( name, data, binaryArchiveData)

### Parameters:

- name (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `name` used as reference when fetching this data from archive.

- data (required)
	- [String](https://docs.coronalabs.com/api/type/String.html).

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

> Note: The archive's key will be used for encryption if enabled via [*.enableSSL](#enableSSL).

## Examples
### Append data to an existing archive
```lua
-- load modules
local bin = require( "m_binary_archive" )
local json = require( "json" )

-- enable encryption
bin.enableSSL()

-- setup option table with encryption key
local options = {
		file = "settings.bin",
		key = tostring(37042),
	}

-- load archive
local settings_bin = bin.load( options )

local data = {}
	data.score = 0
	data.coins = 20

-- append string
bin.appendData("player_score", tostring(data.coins))

-- append JSON data
local encodedTable = json.encode(data)
bin.appendData("data", encodedTable)
```
### Create a new archive for storing only strings of data
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option table, an empty archive will be created in system.TemporaryDirectory
local options = {
		baseDir = system.pathForFile( "", system.TemporaryDirectory ),
		key = tostring(37042),
		fileList = {}	-- IMPORTANT, pass empty fileList table
		output = "temp.bin"
	}

-- create archive
bin.new( options )

-- later in code ------

-- load archive
bin.load( {file=system.pathForFile( "temp.bin", system.TemporaryDirectory )}, key=tostring(37042)})

bin.appendData("time_1", tostring(os.clock()))

print("Time recorded:",bin.fetch("time_1"))
```

</br>

# *.appendFile
Encrypts a file from disk, if encryption is enabled, and appends it to specified archive.

### Syntax:
- MODULE.appendFile( name, filePath, binaryArchiveData )

### Parameters:

- name (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The `name` later used as reference to fetch from archive.

- filePath (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Use [system.pathForFile](https://docs.coronalabs.com/api/library/system/pathForFile.html). Can use raw path on supported platforms, ie `C:/temp/data.txt`.

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

> Note: The archive's key will be used to encrypt the data if enabled via [*.enableSSL](#enableSSL)

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- setup option table with key for encryption
local options = {
		file = "settings.bin",
		key = tostring(37042),
	}

-- load archive
local settings_bin = bin.load( options )

-- get file path
local path = system.pathForFile( "data.txt", system.TemporaryDirectory )

-- append file from disk
bin.appendFile("data.txt", path)
```

</br>

# *.refresh
Refreshes a loaded `binaryArchiveData`, should be used after appending new file or data if it needs to be fetched in same session.

### Syntax:
- MODULE.refresh( binaryArchiveData )

### Parameters:

- binaryArchiveData (*optional*, active archive will be used if none provided)
	- [Table](https://docs.coronalabs.com/api/type/Table.html). The `binaryArchiveData` is the table returned when using [*.load](#load).

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- load archive
local settings_bin = bin.load(  { file = "settings.bin" } )

-- get file path
local path = system.pathForFile( "data.txt", system.TemporaryDirectory )

-- append file from disk
bin.appendFile("data.txt", path)

-- refresh archive to fetch newly appended data
bin.refresh()

-- fetch new data
local data = bin.fetch("data.txt")
```

</br>

# *.encrypt
Encrypts any input data, returns encrypted string. 

### Syntax:
- MODULE.encrypt( data, key )

### Parameters:

- data (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Data to be encrypted.
	
- key (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Key used to encrypt.

> Note: Must use [*.enableSSL](#enableSSL) before using this function.

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- encrypt data
local secretData = "token:123456789"
local encryptedToken = bin.encrypt(secretData, "key123abc")
```

</br>

# *.decrypt
Decrypts encrypted input data, returns decrypted string. 

### Syntax:
- MODULE.refresh( data, key )

### Parameters:

- data (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Data to be decrypted.
	
- key (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). Key used to decrypt, should match the original key used when it was encrypted.

> Note: Must use [*.enableSSL](#enableSSL) before using this function.

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- encrypt data
local secretData = "token:123456789"
local encryptedToken = bin.encrypt(secretData, "key123abc")
print("Encrypted data:", encryptedToken)

secretData = nil

-- decrypt data
local tempData = bin.decrypt(encryptedToken, "key123abc")
print("Decrypted data:", tempData)
```
</br>

# *.releaseTexture
Queue up the release of a texture that was created with [*.newTexture](#newTexture)

### Syntax:
- MODULE.releaseTexture( textureName )

### Parameters:

- data (required)
	- [String](https://docs.coronalabs.com/api/type/String.html). The same name of file that was used to create the texture.

> Note: Releasing textures does not affect existing objects. If the texture is not in use it will be removed immediately, otherwise it'll be removed when it's no longer in use.
## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- load archive
bin.load(  { file = "data.bin" } )

-- create a rectangle
local rect = display.newRect(100,100,100,100)

-- load textures to use for composite filter
local tex1 = bin.newTexture("Fishies/fish.small.red.png")
local tex2 = bin.newTexture("HorseAnimation/moon.png")

local paint = {
	type = "composite",
	paint1 = { type="image", filename = tex1.filename, baseDir = tex1.baseDir},
	paint2 = { type="image", filename = tex2.filename, baseDir = tex2.baseDir}
}

-- apply fill and effect
rect.fill = paint
rect.fill.effect = "composite.average"

-- queue texture release ; does not exisint object, textures will be removed when no longer in use.
bin.releaseTexture("Fishies/fish.small.red.png")
bin.releaseTexture("HorseAnimation/moonpng")
```
</br>
# *.enableSSL
Enables openSSL plugin to use for encryption and decryption.

### Syntax:
- MODULE.enableSSL()

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable encryption
bin.enableSSL()

-- encrypt data
local secretData = "token:123456789"
local encryptedToken = bin.encrypt(secretData, "key123abc")
print("Encrypted data:", encryptedToken)

```

</br>

# *.setDebugMode
Enable or Disable debugMode mode to assist in troubleshoot process. 

### Syntax:
- MODULE.setDebugMode( enable )

### Parameters:

- enable (required)
	- [Boolean](https://docs.coronalabs.com/api/type/Boolean.html). 

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- enable debug
bin.setDebugMode(true)
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

# *.newMask
Returns a [Mask](https://docs.coronalabs.com/api/type/Mask/index.html) object.
### Syntax:
- MODULE.newMask( filename )

### Parameters:
- Only `filename` is required. Returns a Mask object that works the same as a graphics.newMask().
> Note: In order to keep mask object reusable, they are not disposed of automatically, and should be removed with [*.releaseTexture](#releaseTexture) when no longer needed. Alternatively, you can use [*.setMask](#setMask) if you want to set a mask and not worry about releasing it yourself later.

</br>

# *.newTexture
Returns a [TextureResource](https://docs.coronalabs.com/api/type/TextureResource/index.html) object.
### Syntax:
- MODULE.newTexture( filename )

### Parameters:
- Only `filename` is required. Returns a Bytemap texture that works similar to graphics.newTexture().
> Note: Similar to graphics.newTexture, these are not disposed automatically, and should be removed with [*.releaseTexture](#releaseTexture).

</br>

# *.setMask
Applies specified texture file as a mask to object. Once mask is apllied it works the same as [Mask](https://docs.coronalabs.com/api/type/Mask/index.html).

### Syntax:
- MODULE.setMask( object, filename )

### Parameters:
- The `object` to apply mask.
- The `filename` of an image file as stored in an archive.
> Note: Once mask is applied to object it works the same as [graphics.setMask](https://docs.coronalabs.com/api/library/graphics/newMask.html). 

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

# *.imagePaint
Applies [object.fill](https://docs.coronalabs.com/api/type/ShapeObject/fill.html#bitmap-image-fill) to an object with specified texture file.

### Syntax:
- MODULE.imagePaint( object, filename )

### Parameters:
- The `object` to apply fill effect.

- The `filename` of an image file as stored in an archive.

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- load archive
bin.load( {file = "assets/data.bin"} )

-- create a new rectangle and apply image fill
local rect = display.newRect( 150, 150, 50, 50 )
bin.imagePaint( rect,  "Fishies/fish.small.red.png" )
```
</br>

# *.compositePaint
Applies [CompositePaint](https://docs.coronalabs.com/api/type/CompositePaint/index.html) to an object with specified texture files.

### Syntax:
- MODULE.compositePaint( object, filename1,  filename2)

### Parameters:
- The `object` to apply fill effect.

- The `filename1` of the first image file as stored in an archive.

- The `filename2` of the second image file as stored in an archive.

## Example
```lua
-- load module
local bin = require( "m_binary_archive" )

-- load archive
bin.load( {file = "assets/data.bin"} )

-- create a new rectangle and apply composite fill
local rect = display.newRect( 150, 150, 50, 50 )
bin.compositePaint( rect, "Fishies/fish.small.red.png",  "HorseAnimation/moon.png")

-- apply effect
rect.fill.effect = "composite.average"
```
</br>

## License
Distributed under the MIT License. See [LICENSE](https://github.com/siudesu/BinaryArchive/blob/main/LICENSE) for more information.