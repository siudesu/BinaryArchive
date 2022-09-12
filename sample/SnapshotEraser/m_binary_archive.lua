--  Binary Archive Module
--	Last Revision: 2022.09.12.0
--	Lua version: 5.1
--	License: MIT
--	Copyright <2022> <siu>


-- The following ensures certain texture filter effects provide same behavior on external textures.
if not pcall(function() display.setDefault("isExternalTextureRetina", false) end) then
	local msg = [[Warning: [BinaryArchiveModule] If you're using filter effects, you may get different results with this module. To avoid issues, please update Solar2D to version 2022.3678 or higher.]]
	print(msg)
end


-- requirements
local bytemap = require( "plugin.Bytemap" )
local lfs = require( "lfs" )


-- localization
local assert = assert
local error = error
local print = print
local tonumber = tonumber
local type = type
local io_open = io.open
local io_close = io.close
local s_format = string.format
local s_gsub = string.gsub
local s_len = string.len
local s_sub = string.sub
local t_sort = table.sort


-- module variables
local fileHeader = "BA22"	-- file signature, can be changed, but must match the one used when loading the archive
local debugMode = true
local fileType = { png = true, jpg = true, jpeg = true }
local currentArchive
local sizeOfBinDelimiter = 1	-- do not change!
local sizeOfTotalRecords = 8 + sizeOfBinDelimiter	-- do not change!
local d_imageSuffix = display.imageSuffix
local defaultOutputName = "data.bin"

-- module
local M = {}

	local function sendToConsole(...)
		if not debugMode then return end
		print(...)
	end

	local function dirtree(dir)
		-- http://lua-users.org/wiki/DirTreeIterator
		assert(dir and dir ~= "", "directory parameter is missing or empty")
		if s_sub(dir, -1) == "/" then
			dir=s_sub(dir, 1, -2)
		end

		local function yieldtree(dir)
			for entry in lfs.dir(dir) do
				if entry ~= "." and entry ~= ".." then
					entry=dir.."/"..entry
					local attr=lfs.attributes(entry)
					coroutine.yield(entry,attr)
					if attr.mode == "directory" then
						yieldtree(entry)
					end
				end
			end
		end
		return coroutine.wrap(function() yieldtree(dir) end)
	end

	-- Inserts suffix in file name when using dynamic image selection
	local function insertImageSuffix(string_, suffix_)
		local str = string_
		local pos = str:match(".*%.()") - 2
		local newString = str:sub(1, pos) .. suffix_ .. str:sub(pos+1)
		return newString
	end

	local function compare(a_, b_)
		return a_[1] <  b_[1]
	end

	local function getFileInfo(descriptor_)
		-- Reads line by line from current index position.
		-- Correct index position (start of file name) should be set before calling this function
		local desc = descriptor_
		local filename = desc:read("*l")
		local bytes = tonumber(desc:read("*l"))

		if not filename or not bytes then
			sendToConsole("Warning: No more data found. Is 'totalFiles' correct?")
			return false
		end
		sendToConsole("Found image: " .. filename .. ", bytes: " .. bytes)
		return filename, bytes
	end

	local function loadTexture(name_, asMask_)
		local file, offset, bytes = name_
		
		local binFile = io_open( currentArchive.path, "rb" )
			sendToConsole("Opening archive", binFile)
			binFile:seek("set", currentArchive[file].offset)

		local binData = binFile:read(currentArchive[file].bytes)
		
		currentArchive.binaryData[file] = asMask_ and bytemap.loadTexture{ from_memory = binData, format = "mask" } or
											bytemap.loadTexture{ from_memory = binData }

		sendToConsole("Actual file fetched:", file)
	end

	local function getFileExtension(string_)
		-- Returns all characters after last dot in string.
		local pos = string_:match(".*%.()")
		return s_sub(string_, pos)
	end

	local function getFileList(path_)
		-- Fetch all image file names at specified path including sub-directories.
		local path = path_
		local list = {}
		for filename, attr in dirtree(path) do
		   if attr.mode == "file" then
				if fileType[getFileExtension(filename)] then
					list[#list+1] = s_gsub(filename, path .. "/", "")
				end
		   end
		end
		return list
	end
	
	local function updateTotalFiles(path_, num_)
		local file = io.open(path_, 'r+b')
			file:seek("set", s_len(fileHeader)+1)
			file:write(s_format("%08x", num_))
			file:close()
	end

	local function createBinaryData(options_)
		local o = options_
		local header = fileHeader .. "\n"
		local numFiles = "00000000\n"
		local baseDir = o.baseDir
		local outputName = o.output and ("/" .. o.output) or ("/" .. defaultOutputName)
		local outputFile = baseDir .. outputName

		local file, err = io_open(outputFile, 'ab')
			if not file then error("Error encountered. Verify baseDir: " .. baseDir .. " is valid.") end
			file:write(header)		-- write file header
			file:write(numFiles)

		sendToConsole("Creating binary archive ...")
		-- load binary data
		local fileList = o.fileList
		local loadedFilecount = 0
		for i=1, #fileList do

			local path = baseDir .. "/" .. fileList[i]
				sendToConsole("appending: " .. path)
			local binFile = io_open( path, "rb" )
			if not binFile then error("Could not open " .. path) end
			local binData = binFile:read( "*a" )
			io_close( binFile )
			file:write(fileList[i] .."\n")
			file:write(s_len(binData) .. "\n")	-- effectively write size of file in bytes
			file:write(binData)
			loadedFilecount = loadedFilecount + 1
		end
		file:close()

		updateTotalFiles(outputFile, #fileList)
		sendToConsole("Binary archive '" .. defaultOutputName .. "' successfully created. Contains " .. loadedFilecount .. " files.")
	end

	----------------------------------------------------
	----
	---- Module Functions
	----
	----------------------------------------------------

	-- new ; creates new binary archive
	function M.new(options_)
		local o = options_
			if not o or type(o) ~= "table" then error("Missing parameters table.", -1) end
			if not o.baseDir then error("Value for 'baseDir' not found.", -1) end
			-- change backslashes to forward slashes to maintain compatibility
			o.baseDir = o.baseDir:gsub("\\", "/")

		if not o.fileList then o.fileList = getFileList(o.baseDir) end
		
		local outputName = o.output and ("/" .. o.output) or ("/" .. defaultOutputName)
		local path = o.baseDir .. outputName
		
		-- if file does not already exists, proceed to create a new one
		local file = io_open(path, "r")
			if not file then createBinaryData(o) return end
			io_close(file)
			
		-- else, prompt whether to overwrite it, or cancel
		local function onComplete( event )
			if ( event.action == "clicked" ) then
				local i = event.index
				if ( i == 1 ) then
					-- overwrite file with no values ; could use lfs, but this might be simpler
					local file, err = io_open(path, "w+")
						if err then error("Could not overwrite file: " .. err .. "\nIs file in use?") end
						file:write()
						io_close(file)
						createBinaryData(o)
				end
			end
		end
		-- Show alert with two buttons.
		local alert = native.showAlert( "BinaryArchiveModule","File '".. defaultOutputName .. "' already exists.", { "Overwrite", "Cancel" }, onComplete )
	end

	-- load ; loads an existing binary archive
	function M.load(options_)
		-- Creates and returns a binaryArchiveData table with all required information for fetching files.
		local o = options_
			if not o then error("Error loading file, no parameters found.", -1) end
		local signature = o.signature and o.signature or fileHeader

		local fileToload = o.file
			if not fileToload then error("Error, missing 'file' name.", -1) end
		local imageSuffix = ("table" == type(o.imageSuffix)) and o.imageSuffix or nil
			if not imageSuffix and d_imageSuffix then error("Error, missing 'imageSuffix' table.", -1) end

		local signatureSize = s_len(signature) + sizeOfBinDelimiter
		local binaryArchiveData = {}	-- keep list of files cached.
			binaryArchiveData.enableCache = "bool" == type(o.enableCache) and o.enableCache or false
			binaryArchiveData.imageSuffix = imageSuffix	-- must match table in config.lua
			binaryArchiveData.binaryData = {}

		-- open binary archive file from app's directory.
		local path = system.pathForFile( fileToload, system.ResourceDirectory) 
		local binFile = io_open( path, "rb" )	-- read in binary mode.

		if not binFile then error("File not found:", path) end

		binaryArchiveData.path = path -- cache file path for future use in case multiple bin files are used.

		-- check signature
		if binFile:read("*l") ~= signature then
			error("File signature mismatch on " .. fileToload)
		end

		-- get number of stored files as specified
		local totalFiles = tonumber(binFile:read("*l"), 16)
		sendToConsole("Binary archive has a total of " .. totalFiles .. " files.")

		-- fetch first file data
		local filename, bytes = getFileInfo(binFile)
		binaryArchiveData[filename] = {bytes=bytes}
		
		-- set offset value for next file; this is the start next file data. All offsets are based off the beginning of binary archive file.
		binaryArchiveData[filename].offset = signatureSize + sizeOfTotalRecords
									+ s_len(filename) + sizeOfBinDelimiter
									+ s_len(bytes) + sizeOfBinDelimiter

		-- get other files, starting at current file index position
		local lastEntry = binaryArchiveData[filename]
		for i=2, totalFiles do
			binaryArchiveData[i] = {}

			binFile:seek("set", lastEntry.offset + lastEntry.bytes)

			local filename, bytes = getFileInfo(binFile)
			if not filename then break end

			binaryArchiveData[filename] = {bytes=bytes}
			binaryArchiveData[filename].offset = lastEntry.offset + lastEntry.bytes
										+ s_len(filename) + sizeOfBinDelimiter
										+ s_len(bytes) + sizeOfBinDelimiter

			lastEntry = binaryArchiveData[filename]
		end
		io_close( binFile )

		currentArchive = binaryArchiveData -- automatically set as currentArchive.

		return binaryArchiveData
	end
	
	-- set Current Archive
	function M.setCurrentArchive(binaryArchiveData_)
		if not binaryArchiveData_ then error("No valid data found", -2) end
		currentArchive = binaryArchiveData_
	end

	-- clear All Cache
	function M.clearCache(binaryArchiveData_)
		-- Clear up all cached binary data from specified archive, or currentArchive.
		local archive = binaryArchiveData_ or currentArchive
		graphics.releaseTextures( { type="image" } ) -- release all textures
		for k, v in pairs(archive.binaryData) do
			archive.binaryData[k] = nil	-- nil out references
			sendToConsole("Clearing cache:", k, v, archive.binaryData[k])
		end
	end

	-- clear specified cached data
	function M.clearBinaryData(file_, binaryArchiveData_)
		-- Clear up the specified binary data from specified archive, or currentArchive; does not affect existing objects that were created with this data.
		-- file_ value is the same value that's used when creating a display object through this module.
		-- Returns true if success, else returns false.
		local archive = binaryArchiveData_ or currentArchive
		if archive.binaryData[file_] then
			if archive.binaryData[file_].releaseSelf then archive.binaryData[file_]:releaseSelf() end -- if data is a texture then release it.
			archive.binaryData[file_] = nil
			return true
		end
		return false
	end

	-- set File Signature
	function M.setFileSignature(string_)
		if not string_ or 
			type(string_) ~= "string" or
			string_ == "" then 
			error("File Signature must be a valid string.") end
		fileHeader = string_
	end

	-- get File Signature
	function M.getFileSignature()
		return fileHeader
	end

	-- Enable or Disable debugMode mode to assist in troubleshoot process.
	function M.setDebugMode(bool_)
		debugMode = type(bool_) == "boolean" and bool_ or false
	end

	----------------------------------------------------
	----
	---- Wrapped Functions
	----
	----------------------------------------------------
	function M.newImage(...)
		if not currentArchive then error("Archive not loaded.", -2) end
		local group, filename, x, y
		-- newImage's API can take up to 4 arguments (group, file, x, y)
		if type(arg[1]) == "table" then -- assume a group was passed
			group = arg[1]
			filename = arg[2]
			x = arg[3] or 0
			y = arg[4] or 0
		else
			group = display.currentStage
			filename = arg[1]
			x = arg[2] or 0
			y = arg[3] or 0
		end

		-- fetch non-suffixed file data
		if not currentArchive[filename] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end

		-- create newImage
		local newImage = display.newImage(group, currentArchive.binaryData[filename].filename, currentArchive.binaryData[filename].baseDir, x, y)

		-- do not cache data if enableCache is not set to 'true'
		if not currentArchive.enableCache then 
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return newImage
	end

	function M.newImageRect(...)
		if not currentArchive then error("Archive not yet loaded.", -2) end
		local group, filename, w, h
		-- newImageRect's API can take up to 6 arguments (group, file, x, y)
		if type(arg[1]) == "table" then -- assume a group was passed
			group = arg[1]
			filename = arg[2]
			w = arg[3] or 0
			h = arg[4] or 0
		else
			group = display.currentStage
			filename = arg[1]
			w = arg[2] or 0
			h = arg[3] or 0
		end

		-- setup name suffix if set in display lib
		local suffixedFilename = d_imageSuffix and insertImageSuffix(filename, d_imageSuffix)
		
		-- first, attempt to fetch suffixed file from archive
		if suffixedFilename and currentArchive[suffixedFilename] then -- attempt current suffix 
			-- load texture if not previously loaded, or removed.
			if not currentArchive.binaryData[suffixedFilename] then loadTexture(suffixedFilename) end

			-- create newImageRect
			local newImageRect = display.newImageRect(group, currentArchive.binaryData[suffixedFilename].filename, currentArchive.binaryData[suffixedFilename].baseDir, w, h)

			-- do not cache data if enableCache is not set to true
			if not currentArchive.enableCache then
				currentArchive.binaryData[suffixedFilename]:releaseSelf()
				currentArchive.binaryData[suffixedFilename] = nil
			end

			return newImageRect
		end

		-- else, attempt to fetch next suffixed file in list, if none then use non-suffixed file
		-- start by creating an array of suffix names and sorted it by value, not by suffix as it can be anything.
		local imageSuffixArray = {}
		local lookupStartsAt = 0
		for suffix, value in pairs(currentArchive.imageSuffix) do
			imageSuffixArray[#imageSuffixArray+1] = { value, suffix }
			if suffix == d_imageSuffix then
				lookupStartsAt = #imageSuffixArray -- keep track of current suffix index
			end
		end
		t_sort(imageSuffixArray, compare)
		
		-- setup file name to be used, defaults to non-suffixed name
		local actualFile = filename
		for i=lookupStartsAt, 1, -1 do
			local file = insertImageSuffix(filename, imageSuffixArray[i][2])
			if currentArchive[file] then -- if there's an entry in archive file
				actualFile = file
				break
			end
		end

		-- fetch non-suffixed file data
		if not currentArchive[actualFile] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[actualFile] then loadTexture(actualFile) end

		-- create newImageRect
		local newImageRect = display.newImageRect(group, currentArchive.binaryData[actualFile].filename, currentArchive.binaryData[actualFile].baseDir, w, h)

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[actualFile]:releaseSelf()
			currentArchive.binaryData[actualFile] = nil
		end

		return newImageRect
	end

	function M.newImageSheet(filename_, options_)
		-- Returns a newImageSheet from graphics library.
		if not currentArchive then sendToConsole("No current archive set.") ; return end
		local filename = filename_
		local suffixedFilename = d_imageSuffix and insertImageSuffix(filename, d_imageSuffix)

		-- first, attempt to fetch suffixed file from archive
		if suffixedFilename and currentArchive[suffixedFilename] then 
			-- load texture if not previously loaded, or removed.
			if not currentArchive.binaryData[suffixedFilename] then loadTexture(suffixedFilename) end
			
			-- create newImageSheet
			local newImageSheet = graphics.newImageSheet( currentArchive.binaryData[suffixedFilename].filename, currentArchive.binaryData[suffixedFilename].baseDir , options_ )

			-- do not cache data if enableCache is not set to true
			if not currentArchive.enableCache then
				currentArchive.binaryData[suffixedFilename]:releaseSelf()
				currentArchive.binaryData[suffixedFilename] = nil
			end
			
			return newImageSheet
		end

		-- else, attempt to fetch next suffixed file in list, if none then use non-suffixed file
		-- start by creating an array of suffix names and sorted it by value, not by suffix as it can be anything.
		local imageSuffixArray = {}
		local lookupStartsAt = 0
		for suffix, value in pairs(currentArchive.imageSuffix) do
			imageSuffixArray[#imageSuffixArray+1] = { value, suffix }
			if suffix == d_imageSuffix then
				lookupStartsAt = #imageSuffixArray -- to keep track of current suffix index
			end
		end
		t_sort(imageSuffixArray, compare)
		
		-- setup file name to be used, defaults to non-suffixed name
		local actualFile = filename
		for i=lookupStartsAt, 1, -1 do
			local file = insertImageSuffix(filename, imageSuffixArray[i][2])
			if currentArchive[file] then -- if there's an entry in archive file
				actualFile = file
				break
			end
		end
		
		-- fetch non-suffixed file data
		if not currentArchive[actualFile] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[actualFile] then loadTexture(actualFile) end
		
		-- create newImageSheet
		local newImageSheet = graphics.newImageSheet( currentArchive.binaryData[actualFile].filename, currentArchive.binaryData[actualFile].baseDir , options_ )

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[actualFile]:releaseSelf()
			currentArchive.binaryData[actualFile] = nil
		end

		return newImageSheet
	end
	
	function M.newTexture(filename_)
		-- Returns a newTexture from graphics library.
		if not currentArchive then sendToConsole("No current archive set.") ; return end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end
		
		-- create newTexture
		local newTexture = graphics.newTexture( { type="image", filename=currentArchive.binaryData[filename].filename, baseDir=currentArchive.binaryData[filename].baseDir } )

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return newTexture
	end
	
	function M.newMask(filename_)
		-- Returns a newMask from graphics library.
		if not currentArchive then sendToConsole("No current archive set.") ; return end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename, true) end

		-- create newMask
		local newMask = graphics.newMask( currentArchive.binaryData[filename].filename, currentArchive.binaryData[filename].baseDir )

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return newMask
	end

	function M.newOutline(coarsenessInTexels_, filename_)
		-- Returns image outline from graphics library.
		if not currentArchive then sendToConsole("No current archive set.") ; return end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end

		-- create outline
		local outline = graphics.newOutline( coarsenessInTexels_, currentArchive.binaryData[filename].filename, currentArchive.binaryData[filename].baseDir )

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return outline
	end

	function M.newEmitter(emitterParams_)
		-- Returns emitter obj from display library.
		if not currentArchive then sendToConsole("No current archive set.") ; return end

		local filename = emitterParams_.textureDataFileName

		-- fetch non-suffixed file data
		if not currentArchive[filename] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end
		
		-- textureFileName needs to point back to file handle created with Bytemap
		emitterParams_.textureDataFileName = currentArchive.binaryData[filename].filename

		-- create emitter
		local emitter = display.newEmitter( emitterParams_, currentArchive.binaryData[filename].baseDir )

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return emitter
	end

	----------------------------------------------------
	----
	---- Custom Functions
	----
	----------------------------------------------------
	function M.newImagePaint(filename_)
		-- Returns a fill data table.
		if not currentArchive then sendToConsole("No current archive set.") ; return end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then error("File '" .. filename .. "' not found.", -2) end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end

		local paint = { type="image", filename=currentArchive.binaryData[filename].filename, baseDir=currentArchive.binaryData[filename].baseDir }

		-- do not cache data if enableCache is not set to true
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return paint
	end

return M