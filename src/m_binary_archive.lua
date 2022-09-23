--  Binary Archive Module
--	Last Revision: 2022.09.23.0
--	Lua version: 5.1
--	License: MIT
--	Copyright <2022> <siu>


-- The following ensures certain texture filter effects provide same behavior on external textures.
if not pcall(function() display.setDefault("isExternalTextureRetina", false) end) then
	local msg = [[Warning: [BinaryArchiveModule] If you're using filter effects, you may experience different results with this module. To avoid issues, please update Solar2D to version 2022.3678 or higher.]]
	print(msg)
end


-- requirements
local bytemap = require( "plugin.Bytemap" )		-- for image file support
local lfs = require( "lfs" )					-- for generating fileList
local openssl = nil								-- for encryption; initialized with M.enableSSL()


-- localization
local assert = assert
local pairs = pairs
local print = print
local tonumber = tonumber
local type = type
local c_yield = coroutine.yield
local c_wrap = coroutine.wrap
local io_open = io.open
local io_close = io.close
local io_lines = io.lines
local s_format = string.format
local s_gsub = string.gsub
local s_len = string.len
local s_sub = string.sub
local t_sort = table.sort


-- module variables
local cipher = nil	-- initialized with M.enableSSL()
local md5 = nil		-- initialized with M.enableSSL()

local fileHeader = "BA22"	-- file signature, can be changed here or temporarily using M.setFileSignature().
local debugMode = true
local currentArchive
local delimiter = "\n"	-- should NOT be changed, data structure is based off lines.
local delimiterSize = s_len(delimiter)
local indexCounter = s_format("%08x", 0x0) 
local indexCounterSize = s_len(indexCounter) + delimiterSize
local d_imageSuffix = display.imageSuffix
local defaultOutputName = "data.bin"


-- module
local M = {}

	local function printDebug()
		if not debugMode then return end
		local info = debug.getinfo(3)
		local file, line, funcName = s_gsub(info.source, "=",""), info.currentline, debug.getinfo(2, "n").name
		print("[BinaryArchiveModule] Trace:\n\tFile: " .. file .. "\n\tLine: " .. line .. ", Function: " .. funcName)
	end

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
					c_yield(entry,attr)
					if attr.mode == "directory" then
						yieldtree(entry)
					end
				end
			end
		end
		return c_wrap(function() yieldtree(dir) end)
	end

	local function insertImageSuffix(string_, suffix_)
		-- inserts suffix in file name when using dynamic image selection
		local str = string_
		local pos = str:match(".*%.()") - 2
		return str:sub(1, pos) .. suffix_ .. str:sub(pos+1) -- return new string
	end

	local function compare(a_, b_)
		-- lowest to highest
		return a_[1] < b_[1]
	end

	local function getFileInfo(descriptor_, path_)
		-- Reads line by line from current index position.
		-- Correct index position (start of file name) should be set before calling this function
		local desc = descriptor_
		local filename = desc:read("*l")
		local bytes = tonumber(desc:read("*l"))

		if not filename or not bytes then
			sendToConsole("Warning: [BinaryArchiveModule] No more data found. Is 'totalFiles' correct for " .. tostring(path_) .. "?")
			return false
		end
		sendToConsole("[BinaryArchiveModule] Found data: " .. filename .. ", bytes: " .. bytes)
		return filename, bytes
	end

	local function loadTexture(name_, asMask_)
		local file = name_
		
		local binFile = io_open( currentArchive.path, "rb" )
			sendToConsole("[BinaryArchiveModule] Opening archive", binFile)
			binFile:seek("set", currentArchive[file].offset)

		local binData = binFile:read(currentArchive[file].bytes)
		local finalData = openssl and cipher:decrypt(binData, currentArchive.key) or binData -- decrypt only if openssl is enabled.
 
		currentArchive.binaryData[file] = asMask_ and bytemap.loadTexture{ from_memory = finalData, format = "mask" } or
											bytemap.loadTexture{ from_memory = finalData }

		sendToConsole("[BinaryArchiveModule] Actual file fetched:", file)
	end

	local function getFileExtension(string_)
		-- Returns all chars after last dot in string.
		local pos = string_:match(".*%.()")
		return s_sub(string_, pos)
	end

	local function getFileList(baseDir_, exclude_)
		-- Grab all filenames at specified baseDir, includes sub-directories.
		local path = baseDir_
		local list = {}
		local exclude = exclude_
		if not exclude then	-- will add all files without restriction
			for filename, attr in dirtree(path) do
			   if attr.mode == "file" then
					list[#list+1] = s_gsub(filename, path .. "/", "")
			   end
			end
		else -- use exclude table to filter files by file extension
			for filename, attr in dirtree(path) do
			   if attr.mode == "file" then
					local fileExtension = getFileExtension(filename)
					if not exclude[fileExtension] then -- add file to list if file extension is not in exclude table or value is false
						list[#list+1] = s_gsub(filename, path .. "/", "")
					end
			   end
			end
		end
		return list
	end
	
	local function updateTotalFiles(path_, num_)
		local file, err = io_open(path_, 'r+b')
			if not file then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			file:seek("set", s_len(fileHeader)+1)

			file:write(s_format("%08x", num_))
			io_close(file)
	end

	local function createBinaryData(options_)
		local o = options_
		local header = fileHeader .. delimiter
		local numFiles = indexCounter .. delimiter
		local baseDir = o.baseDir
		local outputName = o.output and ("/" .. o.output) or ("/" .. defaultOutputName)
		local outputFile = baseDir .. "\n"

		local file, err = io_open(outputFile, 'ab')
			if not file then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			file:write(header)		-- write file header
			file:write(numFiles)

		sendToConsole("[BinaryArchiveModule] Creating binary archive ...")
		-- load binary data
		local fileList = o.fileList
		local loadedFilecount = 0
		for i=1, #fileList do
			local path = baseDir .. "/" .. fileList[i]
				sendToConsole("[BinaryArchiveModule] appending: " .. path)
			local binFile, err = io_open( path, "rb" )
				if not binFile then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			local binData = binFile:read( "*a" )
			io_close( binFile )
			file:write(fileList[i] .. delimiter)		-- append file name
			file:write(s_len(binData) .. delimiter)     -- append data size in bytes
			file:write(binData)                         -- append data
			loadedFilecount = loadedFilecount + 1
		end
		io_close(file)
		
		updateTotalFiles(outputFile, loadedFilecount)
		sendToConsole("[BinaryArchiveModule] Archive '" .. defaultOutputName .. "' successfully created. Contains " .. loadedFilecount .. " files.")
	end
	
	local function createData(options_)
		local o = options_
		local header = fileHeader .. delimiter
		local numFiles = indexCounter .. delimiter
		local baseDir = o.baseDir
		local outputName = o.output and ("/" .. o.output) or ("/" .. defaultOutputName)
		local outputFile = baseDir .. outputName
		local encryptionKey = o.key

		local file, err = io_open(outputFile, 'ab')
			if not file then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			file:write(header)		-- write file header
			file:write(numFiles)

		sendToConsole("[BinaryArchiveModule] Creating binary archive ...")
		-- load binary data
		local fileList = o.fileList
		local loadedFilecount = 0
		for i=1, #fileList do
			local path = baseDir .. "/" .. fileList[i]
				sendToConsole("[BinaryArchiveModule] appending: " .. path)
			local binFile, err = io_open( path, "rb" )
				if not binFile then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			local binData = binFile:read( "*all" )
			io_close( binFile )
			local finalData = openssl and cipher:encrypt( binData, encryptionKey ) or binData -- encrypt only if openssl is enabled.

			file:write(fileList[i] .. delimiter)			-- append file name
			file:write(s_len(finalData) .. delimiter)		-- append data size in bytes
			file:write(finalData)                       	-- append data
			loadedFilecount = loadedFilecount + 1
		end
		io_close(file)

		updateTotalFiles(outputFile, #fileList)
		sendToConsole("[BinaryArchiveModule] Archive '" .. defaultOutputName .. "' successfully created. Contains " .. loadedFilecount .. " files.")
	end

	----------------------------------------------------
	----
	---- Module Functions
	----
	----------------------------------------------------

	-- new ; creates new binary archive
	function M.new(options_)
		local o = options_
			if not o or type(o) ~= "table" then sendToConsole("[BinaryArchiveModule] Missing parameters table.") ; printDebug() return false end
			if not o.baseDir then sendToConsole("[BinaryArchiveModule] Parameter 'baseDir' must be provided.") ; printDebug() return false end
			if not o.key and openssl then sendToConsole("[BinaryArchiveModule] Parameter 'key' must be provided.") ; printDebug() return false end
			-- change backslash to forward slash to maintain compatibility
			o.baseDir = o.baseDir:gsub("\\", "/")

		if not o.fileList then o.fileList = getFileList(o.baseDir, o.exclude) end
		
		local outputName = o.output and ("/" .. o.output) or ("/" .. defaultOutputName)
		local path = o.baseDir .. outputName
		
		-- if file does not already exists, proceed to create a new one
		local file = io_open(path, "r")
			if not file then createData(o) return end
			io_close(file)
			
		-- else, prompt whether to overwrite it, or cancel
		local function onComplete( event )
			if ( event.action == "clicked" ) then
				local i = event.index
				if ( i == 1 ) then
					-- overwrite file with no values ; could use lfs, but this might be simpler
					local file, err = io_open(path, "w+")
						if err then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
						file:write()
						io_close(file)
						createData(o)
				end
			end
		end
		-- Show alert with two buttons.
		local alert = native.showAlert( "BinaryArchiveModule","File '".. defaultOutputName .. "' already exists.", { "Overwrite", "Cancel" }, onComplete )
	end

	-- load ; loads an existing binary archive
	function M.load(options_, overWritePath)
		-- Creates and returns a binaryArchiveData table.
		local o = options_
			if not o then sendToConsole("[BinaryArchiveModule] Required parameters not found."); printDebug() return false end
		local signature = o.signature and o.signature or fileHeader
		local fileToload = o.file
			if not fileToload then sendToConsole("[BinaryArchiveModule] Parameter 'file' must be provided."); printDebug() return false end
		local key = o.key
			if not key and openssl then sendToConsole("[BinaryArchiveModule] Parameter 'key' must be provided."); printDebug() return false end
		local imageSuffix = ("table" == type(o.imageSuffix)) and o.imageSuffix or {}
			if not imageSuffix and d_imageSuffix then sendToConsole("[BinaryArchiveModule] Parameter 'imageSuffix' must be provided."); printDebug() return false end

		local signatureSize = s_len(signature) + delimiterSize
		local binaryArchiveData = {}	-- keep list of files cached.
			binaryArchiveData.binaryData = {} -- caches binary data
			binaryArchiveData.enableCache = "bool" == type(o.enableCache) and o.enableCache or false
			binaryArchiveData.imageSuffix = imageSuffix	-- must match table in config.lua
			binaryArchiveData.signature = signature
			binaryArchiveData.key = key

		-- open binary archive file from app's directory.
		local path = overWritePath and fileToload or system.pathForFile( fileToload, system.ResourceDirectory)
			if not path then sendToConsole("[BinaryArchiveModule] File not found: " .. tostring(fileToload)); printDebug() return false end
		local binFile, err = io_open( path, "rb" )	-- read in binary mode.
			if not binFile then sendToConsole("[BinaryArchiveModule] " .. err) ; printDebug() return false end

		binaryArchiveData.path = path -- cache file path for future use in case of multiple bin files.

		-- check signature
		if binFile:read("*l") ~= signature then
			if not binFile then sendToConsole("[BinaryArchiveModule] File signature mismatch on " .. fileToload) ; printDebug() return false end
		end

		-- get number of stored files as specified
		local totalFiles = tonumber(binFile:read("*l"), 16)	-- convert from hex to decimal
		binaryArchiveData.totalFiles = totalFiles
		sendToConsole("[BinaryArchiveModule] Archive has a total of " .. totalFiles .. " files.")

		-- fetch first file data
		local filename, bytes = getFileInfo(binFile, path)
		
		if filename then -- continue to load only if at least 1 file exists.
			binaryArchiveData[filename] = {bytes=bytes}
			
			-- set offset value for next file; this is the start next file data. All offsets are based off the beginning of binary archive file.
			binaryArchiveData[filename].offset = signatureSize + indexCounterSize
										+ s_len(filename) + delimiterSize
										+ s_len(bytes) + delimiterSize

			-- get other files, starting at current file index position
			local lastEntry = binaryArchiveData[filename]
			for i=2, totalFiles do
				binFile:seek("set", lastEntry.offset + lastEntry.bytes)

				local filename, bytes = getFileInfo(binFile)
				if not filename then break end

				binaryArchiveData[filename] = {bytes=bytes}
				binaryArchiveData[filename].offset = lastEntry.offset + lastEntry.bytes
											+ s_len(filename) + delimiterSize
											+ s_len(bytes) + delimiterSize

				lastEntry = binaryArchiveData[filename]
			end
		end
		io_close( binFile )

		currentArchive = binaryArchiveData -- automatically set as currentArchive.

		return binaryArchiveData
	end
	
	-- set Current Archive
	function M.setCurrentArchive(binaryArchiveData_)
		if not binaryArchiveData_ then sendToConsole("[BinaryArchiveModule] No valid data found.") ; printDebug() return false end
		currentArchive = binaryArchiveData_
	end

	-- clear All Cache
	function M.clearCache(binaryArchiveData_)
		-- Clear up all cached data from specified archive, or currentArchive, including textures
		local archive = binaryArchiveData_ or currentArchive

		for k, v in pairs(archive.binaryData) do
			if archive.binaryData[k].releaseSelf then
				archive.binaryData[k]:releaseSelf()
			end
			archive.binaryData[k] = nil	-- nil out references
			sendToConsole("[BinaryArchiveModule] Clearing cache:", k, v, archive.binaryData[k])
		end
	end

	-- clear specified cached data
	function M.clearBinaryData(file_, binaryArchiveData_)
		-- Clear up specified data from specified archive, or currentArchive; does not affect existing objects that were created with this data.
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
			sendToConsole("[BinaryArchiveModule] File Signature must be a valid string.") ; printDebug() return false end
		fileHeader = string_
	end

	-- get File Signature
	function M.getFileSignature()
		return fileHeader
	end

	-- fetch ; returns decrypted data
	function M.fetch(name_, binaryArchiveData_)
		local file = name_
		local archive = binaryArchiveData_ or currentArchive
		local binFile, err = io_open( archive.path, "rb" )
			if not binFile then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			sendToConsole("[BinaryArchiveModule] Opening archive", binFile)
			if not archive[file] then io_close(binFile); sendToConsole("[BinaryArchiveModule] File not found: " .. tostring(name_)) ; printDebug() return false end
			binFile:seek("set", archive[file].offset)
			sendToConsole("[BinaryArchiveModule] File fetched:", file)
		local binData = binFile:read(archive[file].bytes)
		return openssl and cipher:decrypt(binData, archive.key) or binData -- return decrypted data if openssl is enabled, else return data as is
	end

	-- fetch Raw ; same as fetch() but returns data as-is, no decryption performed
	function M.fetchRaw(name_, binaryArchiveData_)
		local file = name_
		local archive = binaryArchiveData_ or currentArchive
		local binFile, err = io_open( archive.path, "rb" )
			if not binFile then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			sendToConsole("[BinaryArchiveModule] Opening archive", binFile)
			if not archive[file] then io_close(binFile); sendToConsole("[BinaryArchiveModule] File not found: " .. tostring(name_)) ; printDebug() return false end
			binFile:seek("set", archive[file].offset)
			sendToConsole("[BinaryArchiveModule] File fetched:", file)
		return binFile:read(archive[file].bytes) -- return data as is
	end

	-- append Data ; appends a string of data.
	function M.appendData(name_, data_, binaryArchiveData_)
		local archive = binaryArchiveData_ or currentArchive
		if archive[name_] then sendToConsole("[BinaryArchiveModule] Append Data failed, name already exists: " .. name_ ) ; printDebug() return false end
		local finalData = openssl and cipher:encrypt( data_, archive.key ) or data_
		local file, err = io_open(archive.path, 'ab')
			if not file then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			sendToConsole("[BinaryArchiveModule] Opening archive", file)

			file:write(name_ .. delimiter)				-- append file name
			file:write(s_len(finalData) .. delimiter)	-- append data size in bytes
			file:write(finalData)						-- append data
			io_close(file)
			sendToConsole("[BinaryArchiveModule] Added data:", name_)
			updateTotalFiles(archive.path, archive.totalFiles+1)
		return true
	end
	
	-- append File ; appends a file from disk.
	function M.appendFile(name_, filepath_, binaryArchiveData_)
		-- filepath_ should be the string generated by using system.pathForFile(filename, system.DocumentsDirectory or system.ResourceDirectory)
		local archive = binaryArchiveData_ or currentArchive
		if archive[name_] then sendToConsole("[BinaryArchiveModule] Append Data failed, name already exists: " .. name_ ) ; printDebug() return false end
		
		-- get file data from disk
		local binFile, err = io_open( filepath_, "rb" )
			if not binFile then sendToConsole("[BinaryArchiveModule] Failed to open file " .. err) ; printDebug() return false end
			local binData = binFile:read( "*all" )
			io_close( binFile )

		local encyrptedData = openssl and cipher:encrypt( binData, archive.key ) or binData

		local file, err = io_open(archive.path, 'ab')
			if not file then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end
			sendToConsole("[BinaryArchiveModule] Opening archive", file)
			
			file:write(name_ .. delimiter)					-- append file name
			file:write(s_len(finalData) .. delimiter)	-- append data size in bytes
			file:write(finalData)						-- append data
			io_close(file)
			sendToConsole("[BinaryArchiveModule] Added file:", name_)
			updateTotalFiles(archive.path, archive.totalFiles+1)
		return true
	end

	-- refresh ; refreshes a loaded binaryArchiveData, should be used after appending new file or data.
	function M.refresh(binaryArchiveData_)
		local archive = binaryArchiveData_ or currentArchive

		local signatureSize = s_len(archive.signature) + delimiterSize

		-- open binary archive file from app's directory.
		local binFile = io_open( archive.path, "rb" )	-- read in binary mode.
			if not binFile then sendToConsole("[BinaryArchiveModule] Could not open " .. err) ; printDebug() return false end

		-- check signature
		if binFile:read("*l") ~= archive.signature then
			sendToConsole("[BinaryArchiveModule] File signature mismatch on " .. archive.path) ; printDebug() return false
		end

		-- get number of stored files as specified
		local totalFiles = tonumber(binFile:read("*l"), 16)
		archive.totalFiles = totalFiles
		sendToConsole("[BinaryArchiveModule] Refreshing a total of " .. totalFiles .. " files.")

		-- fetch first file data
		local filename, bytes = getFileInfo(binFile, path)
		
		if filename then -- continue to load only if at least 1 file exists.

			if not archive[filename] then -- only fresh if it's a new entry
				archive[filename] = {bytes=bytes}
				
				-- set offset value for next file; this is the start next file data. All offsets are based off the beginning of binary archive file.
				archive[filename].offset = signatureSize + indexCounterSize
											+ s_len(filename) + delimiterSize
											+ s_len(bytes) + delimiterSize
			end

			-- get other files, starting at current file index position
			local lastEntry = archive[filename]
			for i=2, totalFiles do
				binFile:seek("set", lastEntry.offset + lastEntry.bytes)

				local filename, bytes = getFileInfo(binFile)
				if not filename then break end
				if not archive[filename] then -- only fresh if it's a new entry
					archive[filename] = {bytes=bytes}
					archive[filename].offset = lastEntry.offset + lastEntry.bytes
												+ s_len(filename) + delimiterSize
												+ s_len(bytes) + delimiterSize
				end
				lastEntry = archive[filename]
			end
		end
		io_close( binFile )
	end

	-- encrypt ; encrypts data and returns results
	function M.encrypt(string_, key_)
		if not openssl then sendToConsole("[BinaryArchiveModule] You must enable openssl to use encrypt function") ; printDebug() return false end
		return cipher:encrypt( string_, key_)
	end
	
	-- decrypt ; decrypts data and returns results
	function M.decrypt(string_, key_)
		if not openssl then sendToConsole("[BinaryArchiveModule] You must enable openssl to use decrypt function") ; printDebug() return false end
		return cipher:decrypt( string_, key_)
	end

	-- getMD5 ; returns md5 hash of file
	function M.getMD5(file_)
		-- TODO: Complete implementation.
		-- Looking for something that works like this: https://github.com/zhaozg/lua-openssl#example-2-quick-evp_digest
		--  md = openssl.digest.get('md5')
		--  m = 'abcd'
		--	mdc = md:new()
		--	mdc:update(m)
		--	bb = mdc:final()

		if true then return false end
		local file = file_
		-- get file data from disk
		local path = system.pathForFile( file, system.ResourceDirectory)
			if not path then sendToConsole("Warning: [BinaryArchiveModule] Failed to open file " .. err) ; printDebug() return false end
		local binFile, err = io_open( path, "rb" )
			if not binFile then sendToConsole("Warning: [BinaryArchiveModule] Failed to open file " .. err) ; printDebug() return false end
			
			local md5chuncks = md5.new()	-- function does not exist, not sure it's been exposed or proper binding name.
			-- chunck up data line by line
			for line in io_lines(binFile) do 
				md5chuncks:update(line) -- this may not be actual function name.
			end
			io_close( binFile )
		return md5chuncks:final() -- this may not be actual function name.
	end

	-- enableSSL ; optional for encryption
	function M.enableSSL()
		openssl = require( "plugin.openssl" )
		cipher = openssl.get_cipher( "aes-256-cbc" )
		md5 = openssl.get_digest( "md5" )
	end

	-- release texture ; provides a way to individually remove a texture, as oppose to graphics.releaseTextures( { type="image" } ) which removes ALL textures
	function M.releaseTexture(filename_)
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end
		if currentArchive.binaryData[filename_] then
			currentArchive.binaryData[filename_]:releaseSelf()
			currentArchive.binaryData[filename_] = nil
		end
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
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end
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
		if not currentArchive[filename] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

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
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end
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

			-- do not cache data if enableCache is not set 'true'
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
		if not currentArchive[actualFile] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[actualFile] then loadTexture(actualFile) end

		-- create newImageRect
		local newImageRect = display.newImageRect(group, currentArchive.binaryData[actualFile].filename, currentArchive.binaryData[actualFile].baseDir, w, h)

		-- do not cache data if enableCache is not set 'true'
		if not currentArchive.enableCache then
			currentArchive.binaryData[actualFile]:releaseSelf()
			currentArchive.binaryData[actualFile] = nil
		end

		return newImageRect
	end

	function M.newImageSheet(filename_, options_)
		-- Returns a newImageSheet from graphics library.
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end
		local filename = filename_
		local suffixedFilename = d_imageSuffix and insertImageSuffix(filename, d_imageSuffix)

		-- first, attempt to fetch suffixed file from archive
		if suffixedFilename and currentArchive[suffixedFilename] then 
			-- load texture if not previously loaded, or removed.
			if not currentArchive.binaryData[suffixedFilename] then loadTexture(suffixedFilename) end
			
			-- create newImageSheet
			local newImageSheet = graphics.newImageSheet( currentArchive.binaryData[suffixedFilename].filename, currentArchive.binaryData[suffixedFilename].baseDir , options_ )

			-- do not cache data if enableCache is not set 'true'
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
		if not currentArchive[actualFile] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[actualFile] then loadTexture(actualFile) end
		
		-- create newImageSheet
		local newImageSheet = graphics.newImageSheet( currentArchive.binaryData[actualFile].filename, currentArchive.binaryData[actualFile].baseDir , options_ )

		-- do not cache data if enableCache is not set 'true'
		if not currentArchive.enableCache then
			currentArchive.binaryData[actualFile]:releaseSelf()
			currentArchive.binaryData[actualFile] = nil
		end

		return newImageSheet
	end
	
	function M.newTexture(filename_)
		-- Returns a newTexture from Bytemap plugin, essentially works the same as a texture from graphics library.
		-- Textures are cached in order to imitate graphics.newTexture, 
		-- however, graphics.releaseTextures( { type="image" } ) has no effect
		-- and should be removed with M.releaseTexture()
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end

		-- return Bytemap texture
		return currentArchive.binaryData[filename]
	end
	
	function M.newMask(filename_)
		-- Returns a newMask from graphics library.
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename, true) end

		-- create newMask
		local newMask = graphics.newMask( currentArchive.binaryData[filename].filename, currentArchive.binaryData[filename].baseDir )

		-- do not cache data if enableCache is not set 'true'
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return newMask
	end

	function M.newOutline(coarsenessInTexels_, filename_)
		-- Returns image outline from graphics library.
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end

		-- create outline
		local outline = graphics.newOutline( coarsenessInTexels_, currentArchive.binaryData[filename].filename, currentArchive.binaryData[filename].baseDir )

		-- do not cache data if enableCache is not set 'true'
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end

		return outline
	end

	function M.newEmitter(emitterParams_)
		-- Returns emitter obj from display library.
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end

		local filename = emitterParams_.textureFileName

		-- fetch non-suffixed file data
		if not currentArchive[filename] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end
		
		-- textureFileName needs to point back to file handle created with Bytemap
		emitterParams_.textureFileName = currentArchive.binaryData[filename].filename

		-- create emitter
		local emitter = display.newEmitter( emitterParams_, currentArchive.binaryData[filename].baseDir )

		-- do not cache data if enableCache is not set 'true'
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
	function M.imagePaint(obj_, filename_)
		-- Applies fill effect on obj, the approach below is necessary to apply the fill right away and avoid textures being released prematurely.
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end

		local filename = filename_

		-- fetch non-suffixed file data
		if not currentArchive[filename] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename] then loadTexture(filename) end

		obj_.fill = { type="image", filename=currentArchive.binaryData[filename].filename, baseDir=currentArchive.binaryData[filename].baseDir }

		-- do not cache data if enableCache is not set 'true'
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename]:releaseSelf()
			currentArchive.binaryData[filename] = nil
		end
	end

	function M.compositePaint(obj_, file1_, file2_)
		-- Applies composite fill effect on obj, the approach below is necessary to apply the fill right away and avoid textures being released prematurely.
		if not currentArchive then sendToConsole("Error: [BinaryArchiveModule] No archive loaded.") ; printDebug() return false end

		local filename1 = file1_
		local filename2 = file2_

		-- fetch non-suffixed file data
		if not currentArchive[filename1] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename1 .. "' not found.") ; printDebug() return false end
		if not currentArchive[filename2] then sendToConsole("Error: [BinaryArchiveModule] File '" .. filename2 .. "' not found.") ; printDebug() return false end

		-- load texture if not previously loaded, or removed.
		if not currentArchive.binaryData[filename1] then loadTexture(filename1) end
		if not currentArchive.binaryData[filename2] then loadTexture(filename2) end
		
		obj_.fill = { 
				type="composite", 
				paint1 = { type="image", filename = currentArchive.binaryData[filename1].filename, baseDir = currentArchive.binaryData[filename1].baseDir },
				paint2 = { type="image", filename = currentArchive.binaryData[filename2].filename, baseDir = currentArchive.binaryData[filename2].baseDir },
			}

		-- do not cache data if enableCache is not set 'true'
		if not currentArchive.enableCache then
			currentArchive.binaryData[filename1]:releaseSelf()
			currentArchive.binaryData[filename1] = nil

			currentArchive.binaryData[filename2]:releaseSelf()
			currentArchive.binaryData[filename2] = nil
		end
	end

return M