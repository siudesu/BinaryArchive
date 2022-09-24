# Binary Archive Module
### A [Solar2D](https://solar2d.com) Lua module for reading and writing binary archive files for storing resources.


</br>

## Features
 - Support for multiple archive files in same project.
 - Allows caching (optional) of fetched data, minimizing disk access.
 - Provides a set of wrapper functions to facilitate the creation of certain Solar2D objects using assets stored in archive, see [DOCS](https://github.com/siudesu/BinaryArchive/blob/main/DOCUMENTATION.md).
 - In compliance with Solar2D's [dynamic image selection](https://docs.coronalabs.com/guide/basics/configSettings/index.html#dynamic-image-selection) when creating [newImageRect](https://docs.coronalabs.com/api/library/display/newImageRect.html) and [newImageSheet](https://docs.coronalabs.com/api/library/graphics/newImageSheet.html) objects.
 - Uses AES-256 for data encryption; *now optional by default.*
 - Not limited to files, any data in form of [String](https://docs.coronalabs.com/api/type/String.html) can be easily appended, and retrieved, such as data encoded in [JSON](https://docs.coronalabs.com/api/library/json/index.html).


</br>

## Limitations
 - While the purpose of using this type of archive is, in part, loading assets without disk extraction, in this fashion it is currently limited to `png`, `jpg`, and `jpeg` files.
 </br>Any file can be appended, but would need to be extracted before it can be used. Please see [FAQ](#FAQ) for more details.

</br>

## Requirements
- [Bytemap plugin](https://github.com/solar2d/com.xibalbastudios-plugin.Bytemap) by [Steven Johnson](https://github.com/ggcrunchy), must be added in `build.settings`.
- (Optional) [OpenSSL plugin](https://docs.coronalabs.com/plugin/openssl/index.html), must be added in `build.settings` ONLY if encryption is desired.

### build.settings (Plugins section)
```lua
	plugins =
	{
		["plugin.Bytemap"] = { publisherId = "com.xibalbastudios" },
		["plugin.openssl"] = { publisherId = "com.coronalabs" }, -- optional
	}
```

</br>

## Sample Code
### Creating a new archive with default values:
```lua
-- load module
local binarch = require( "m_binary_archive" )

-- specify full path where assets are located (all files will be appended, includes sub-directories)
local options = { baseDir = "D:/Projects/Solar2D/AwesomeProject/assets/graphics" }

-- create a new archive, output will be saved at baseDir
binarch.new(options)
```
### Loading and using an archive:
```lua
-- load module
local binarch = require( "m_binary_archive" )

-- specify file to load, file path is relative to project where main.lua resides
local options = { file = "assets/data.bin" }

-- load binary file
binarch.load(options)

-- create newImageRect using wrapper function; parameters are the same as display.newImageRect()
local balloon = binarch.newImageRect( "SnapshotEraser/balloon.jpg", 200, 240 )

-- create new rectangle and apply object fill using custom function
local rect = display.newRect( 150, 150, 50, 50 )
	binarch.imagePaint( rect, "Fishies/fish.small.red.png" )

-- create a mask object and apply it to newImageRect
local mask = binarch.newMask( "SnapshotEraser/mask.png" )
local bg = binarch.newImageRect( "FilterGraph/image.jpg", 480, 320 )
	bg:setMask( mask )
	bg.x = 240
	bg.y = 160
```

</br>

## Wrapper Functions
These are designed to work in place of Solar2D API functions by the same name:
</br>
> Note: Parameters and requirements are the same in all cases except for `baseDir`, this variable is neither used nor parsed as assets are stored in archive.

</br>

### From `display.*` API:
```lua
	MODULE.newEmitter( emitterParams )
	MODULE.newImage( [parent,] filename, [x, y] )
	MODULE.newImageRect( [parent,] filename, width, height )
```

### From `graphics.*` API:
```lua
	MODULE.newImageSheet( filename, options )
	MODULE.newMask( filename )
	MODULE.newOutline( coarsenessInTexels, imageFileName )
	MODULE.newTexture( params ) -- this returns a Bytemap texture which is used in the same manner as graphics.newTexure()
```
### Custom:
```lua
	-- to apply object.fill effects
	MODULE.imagePaint( object, filename )
	MODULE.compositePaint( object, filename1,  filename2 )
```

</br>

## For more details on usage and samples please see [DOCS](https://github.com/siudesu/BinaryArchive/blob/main/DOCUMENTATION.md)

</br>

## TODO
- [ ] [Dynamically-Selected Mask](https://docs.coronalabs.com/api/library/graphics/newMask.html#dynamically-selected-mask) can be tentatively implemented in module so that no additional code is required as shown in Solar2D docs.

</br>

## FAQ
1. `What's the purpose of using an archive file?`

   1. Hide project assets from plain sight.
   2. Implement a method of using bundled assets without extracting them to disk, such as a zip file. This has other implications, see below `FAQ #7`.

2. `How are archives created?`

   Archives are created using Lua libraries (LFS and I/O) to read and append files into a single binary file. 
   </br>Additional information is added to help fetch files quickly.

3. `How many files can be stored in an archive?`

   An arbitrary number of 4,294,967,295 .... that's probably more than enough. :smile:

4. `Is there any overhead in disk space?`

	Not much testing done there, but in one instance, appending 137 MB worth of data resulted in a 137 MB archive.
	
5. `Are the files secured in the archive?`

   All appended files and data can be optionally encrypted using AES-256, please see [DOCS](https://github.com/siudesu/BinaryArchive/blob/main/DOCUMENTATION.md).

6. `What files can I store in an archive?`

   You can append any type of file from disk, and any data in form of a [String](https://docs.coronalabs.com/api/type/String.html), but usage may vary, see below `FAQ #7`.

7. `What are the implications of using an archive for assets?`
   
   The implication is that Solar2D API loads asset from disk, in particular [these four directories](https://docs.coronalabs.com/guide/data/readWriteFiles/index.html#system-directories).
   </br>The loading of textures is currently supported by [Bytemap plugin](https://github.com/solar2d/com.xibalbastudios-plugin.Bytemap) providing the ability to create external textures from Memory, these are not extracted anywhere on disk.
   </br>For any other file types, you may need to extract them to [any of the write-access directories](https://docs.coronalabs.com/guide/data/readWriteFiles/index.html#system-directories) before using them.

8. `Is there future plans for using other files in an archive without extracting them to disk?`

   I think fonts and audio files are desirable to load from an archive, this would allow for most common applications to have assets fully bundled.
   </br>However, a technical implementation in the engine, or by way of a plugin, is first required, and both are out of my scope-- I'm just doing the easy "packaging" part. :slightly_smiling_face:
   </br>It's worth noting that audio files will soon be usable from an archive; the same [creator](https://github.com/ggcrunchy) of the [Bytemap plugin](https://github.com/solar2d/com.xibalbastudios-plugin.Bytemap) has a [WIP project](https://discord.com/channels/721785436195782677/721785737258860544/1013963898589823056) which also allows loading audio files from Memory.

</br>

---

## License
Distributed under the MIT License. See [LICENSE](https://github.com/siudesu/BinaryArchive/blob/main/LICENSE) for more information.