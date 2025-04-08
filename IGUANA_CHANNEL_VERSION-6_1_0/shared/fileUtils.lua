local fileUtils = {}

function fileUtils.listFiles(directory)
   local files = {}
   -- Check if directory exists and is accessible
   local success, err = pcall(function()
      for Name, FileInfo in os.fs.glob(directory..'*') do
         local Filename = Name:sub(#directory + 1)
         table.insert(files, Filename)
      end
   end)

   if not success then
      trace("Error accessing directory: "..err)
      return files -- Return empty table if an error occurs
   end

   return files
end

function fileUtils.fileExists(filepath)
   local fileFound = false
   -- Check if the file exists and is accessible
   local success, err = pcall(function()
      for Name, FileInfo in os.fs.glob(filepath) do
         if Name == filepath then
            fileFound = true
            break
         end
      end
   end)

   if not success then
      trace("Error accessing file: "..err)
   end

   return fileFound
end

function fileUtils.searchFiles(directory, value)
   local matchingFiles = {}
   -- Check if directory exists and is accessible
   local success, err = pcall(function()
      for Name, FileInfo in os.fs.glob(directory..'*'..value..'*') do
         local Filename = Name:sub(#directory + 1)
         table.insert(matchingFiles, Filename)
      end
   end)

   if not success then
      trace("Error accessing directory: "..err)
      return matchingFiles -- Return empty table if an error occurs
   end

   return matchingFiles
end

return fileUtils
