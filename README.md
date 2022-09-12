# Binary Archive Module
### A [Solar2D](https://solar2d.com) Lua module for reading and writing binary archive files for storing assets.


</br>

## Features
 - Support for multiple archive files in the same project.
 - Allows caching (optional) of the binary data minimizing disk access.
 - Provides a set of wrapper functions for creating Solar2D objects using assets stored in archive.
 - In compliance with Solar2D's [dynamic image selection](https://docs.coronalabs.com/guide/basics/configSettings/index.html#dynamic-image-selection) when creating newImageRect and newImageSheet objects.

</br>


## Limitations
 - Currently, the only files supported are images, in particular `png`, `jpg`, and `jpeg`. See [FAQ](#FAQ) for more info.

</br>

## Requirements
- [Bytemap plugin](https://github.com/solar2d/com.xibalbastudios-plugin.Bytemap) by [Steven Johnson](https://github.com/ggcrunchy), must be added in `build.settings`:
```lua
	plugins =
	{
		["plugin.Bytemap"] = { publisherId = "com.xibalbastudios"},	
	}
```

</br>

## TODO
- [ ] [Dynamically-Selected Mask](https://docs.coronalabs.com/api/library/graphics/newMask.html#dynamically-selected-mask) can be implemented in module so that no additional code is required as shown in Solar2D docs.

</br>


## Sample Code
### Creating a new archive:
```lua
-- load module
local binarch = require( "m_binary_archive" )

-- specify full path; all supported file types will be appended, includes sub-directories
local options = {
	path = "D:/Projects/Solar2D/AwesomeProject/assets/graphics",
}
-- create a new archive at path location
binarch.new(options)
```
### Loading and using an archive:
```lua
-- load module
local binarch = require( "m_binary_archive" )

-- specify file to load, file path is relative to project
local options = {
	file = "assets/data.bin",
}

-- load binary file
binarch.Load(options)

-- create newImageRect using wrapper function; parameters are the same as using display.newImageRect()
local balloon = binarch.newImageRect( "SnapshotEraser/balloon.jpg", 200, 240 )


-- create new rectangle and apply object fill
local rect = display.newRect( 150, 150, 50, 50 )
	rect.fill = binarch.newImagePaint( "Fishies/fish.small.red.png" )


-- load a mask object and apply it to newImageRect
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
	MODULE.newTexture( params ) -- for "image" type only, not "canvas" type
```
### Custom:
```lua
	-- used with object.fill
	MODULE.newImagePaint( filename )
```

</br>

## For more details on usage please see [DOCS](https://github.com/siudesu/BinaryArchive/blob/main/DOCUMENTATION.md)

</br>

## FAQ
1. `How are binary archives created?`
   
   Archives are created by using Lua's LFS library to read and append files into a single binary file. 
   </br>Additional information is added to help fetch files quickly.

2. `Are the files secured in the archive?`
   
   At the moment, data in a binary archive is in no way secured.
   </br>Anyone in the practice of reverse engineering can easily extract the data, basically copy and paste.

3. `What's the purpose of using a binary archive file?`
   
   1. Hide project assets from plain sight, images in particular.
   2. Implement a method that uses data from an archive without the need to first extract data to disk, such as a zip file. This, of course, is part of the limitations, see below `FAQ #5`.

4. `Any chance of adding some form of protection in the future?`

	Because files in archives are processed individually, *theoretically* any method, whether encryption or compression, can be applied as long as there exists a library for it in Lua/Solar2D. Might look into it in the future if there's a desire for it.

5. `What about supporting other file types?`
   
   Current restrictions of file types are implemented to avoid confusion; using a binary archive file itself has no limitation.
   </br>
   To elaborate, Solar2D only supports loading assets from disk, our intended method however is to feed data from RAM.
   It does provide a way to create "external textures"; the [Bytemap plugin](https://github.com/solar2d/com.xibalbastudios-plugin.Bytemap) takes advantage of this and takes it a step further with the ability to feed texture data from RAM.
   </br>
   </br>
   But, to answer the question, I think fonts and audio data are the only type of assets worth considering (leaving out HTML and related files), and a technical implementation is first required which is out of my scope-- I'm just doing the easy "packaging" part.
   </br>
   </br>
   Speaking of audio files, the same [creator](https://github.com/ggcrunchy) of the [Bytemap plugin](https://github.com/solar2d/com.xibalbastudios-plugin.Bytemap) has a [WIP project](https://discord.com/channels/721785436195782677/721785737258860544/1013963898589823056) which may open the door to do the same with audio files, those may be added in the future.
   </br>
   </br>
   A last note on restrictions, I am actually debating whether to keep or remove them. The current setup forces extension name on files, and not everyone might want to use a file extension. Additionally, other file types such as txt, and JSON can probably be included as well, but currently are not.

</br>

---

## License
Distributed under the MIT License. See [LICENSE](https://github.com/siudesu/BinaryArchive/blob/main/LICENSE) for more information.