return { --if this file errors, you probably forgot a comma--

	['Automatic download timeout'] = 0,						--sets the timeout to automatically download files, in seconds. Options: number, 0 or above.
	['Get Unit Text Console Dump'] = false,					--Sets if text is dumped to console when you execute the get unit script in text only mode. Options: true, false.
	['Get Unit Default'] = 'text page',				--Sets the default mode(s) for the get unit script. Options: Mode(s) in plaintext
	['pngout'] = true,										--sets if you have or want to use pngout. Compresses png files without losing the image quality. Options: true / false.
	['render pngout'] = true,								--same as pngout, but specifically for renders. Options: true / false.
	['pngout_gifs'] = false,								-- pngout images used for gifs. Very slow, may reduce image size a few bytes, but never does. Options: true / false.
	['Image Cleanup'] = false,								--Cleans up data used to make images.
	['Unit directory'] = "out\\Units\\",					--Sets file paths for the unit folder. Options: filepath.
	['working directory'] = "working\\",					--Sets file paths for the working folder. Options: filepath.
	['dump directory'] = "out\\dump\\",						--Sets file paths for the dump folder. Options: filepath.
	['Named unit directory'] = "out\\cards\\",				--Sets file path for translated unit folders. Options: filepath, 'false' (same directory)
	['Named directories'] = true,							--If true, tries to translate the out/cards folder to an English name, from the translations/name file. Options: true, false.
	['Update filelist'] = true,								--If true, will automatically download the latest filelist when the url / xmls are updated via the http archive (list.har) method.
	['Change URLS'] = true,									--If true, adds url info to changes.txt
	
	--Options for progress printouts. Options: true, false.
	['Mode Completion Printouts'] = true,
	['iSet Completion Printouts'] = false,
	['iSet Startup Printouts'] = false,	
	['PNGout render Printouts'] = true,
	['PNGout sprite Printouts'] = true,
	['PNGout icon Printouts'] = true,
	['CURL Download Stream'] = true,	
	['CURL Printouts'] = false,
	['File Printouts'] = true,
	['GM Printouts'] = false,
	
	--Troubleshooting
	['GIF XY Cutoff'] = 5000,								--Prevents images with an X or Y transformation greater then this value from being made. Can be false. Stops massive slowdowns during gif phase.
	
	--Broken ATM IIRC
    ['Remove duplicate folders'] = true,      
	}