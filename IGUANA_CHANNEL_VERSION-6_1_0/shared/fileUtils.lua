local fileUtils = {}

function fileUtils.listFiles(directory)
   local files = {}
   local success, err = pcall(function()
      for Name, FileInfo in os.fs.glob(directory..'*') do
         local Filename = Name:sub(#directory + 1)
         table.insert(files, Filename)
      end
   end)

   if not success then
      trace("Error accessing directory: " .. err)
   end

   return files
end

function fileUtils.listFilesRecursive(root)
   local files = {}

   -- Ensure the root ends with a slash.
   if string.sub(root, -1) ~= "/" then
      root = root .. "/"
   end

   local function rec(currentDir)
      if string.sub(currentDir, -1) ~= "/" then
         currentDir = currentDir .. "/"
      end
      local success, err = pcall(function()
         for fullPath, info in os.fs.glob(currentDir .. '*') do
            if info.isdir then
               rec(fullPath)
            else
               -- Compute the relative path.
               local relative = fullPath:sub(#root + 1)
               -- Use non-greedy capture to split into directory and filename.
               local subdir, filename = relative:match("^(.-)([^/]+)$")
               if not filename then
                  subdir = ""
                  filename = relative
               end
               -- Rebuild the full directory path.
               local fileDirectory = root
               if subdir and subdir ~= "" then
                  fileDirectory = root .. subdir
               end
               table.insert(files, { directory = fileDirectory, filename = filename })
            end
         end
      end)
      if not success then
         trace("Error accessing directory '" .. currentDir .. "': " .. err)
      end
   end

   rec(root)
   return files
end

function fileUtils.fileExists(filepath)
   local fileFound = false
   local success, err = pcall(function()
      for Name, FileInfo in os.fs.glob(filepath) do
         if Name == filepath then
            fileFound = true
            break
         end
      end
   end)

   if not success then
      trace("Error accessing file: " .. err)
   end

   return fileFound
end

function fileUtils.searchFiles(directory, value)
   local matchingFiles = {}
   local success, err = pcall(function()
      for Name, FileInfo in os.fs.glob(directory..'*'..value..'*') do
         local Filename = Name:sub(#directory + 1)
         table.insert(matchingFiles, Filename)
      end
   end)

   if not success then
      trace("Error accessing directory: " .. err)
   end

   return matchingFiles
end

return fileUtils