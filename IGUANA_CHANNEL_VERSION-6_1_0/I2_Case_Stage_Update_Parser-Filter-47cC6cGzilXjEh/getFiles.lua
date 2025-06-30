local fu = require 'fileUtils'
local tu = require 'tableUtils'

local function parseYearFromAccession(accessionId)
   -- Extract the numeric year part between the letters and the first dash
   local year = accessionId:match("^%a+(%d+)%-.+")
   if year then
      return 2000 + tonumber(year)
   else
      error("Invalid accessionId format: " .. accessionId)
   end
end

function getFiles(accessionId)
   local year = parseYearFromAccession(accessionId)
   local grossDirectory = '/media/copath_images/' .. year .. '/GROSS IMAGES/' .. accessionId .. '/'
   trace(grossDirectory)

   -- For test case manipulation.
   if accessionId == 'S24-802' then
      grossDirectory = '/media/copath_images/2024/GROSS IMAGES/Proscia test S24-802 (test case)/'
   end

   -- Use the recursive function to list all files (subdirectories are handled properly)
   local files = fu.listFilesRecursive(grossDirectory)

   -- Process files from the Scanned Protocols directory.
   local reqDirectory = '/media/copath_images/Scanned Protocols/'
   local underscoreResults = fu.searchFiles(reqDirectory, accessionId..'_')
   local periodResults    = fu.searchFiles(reqDirectory, accessionId..'.')
   local mergedResults = tu.mergeTables(underscoreResults, periodResults)

   for _, file in ipairs(mergedResults) do
      local fileObject = {
         directory = reqDirectory,
         filename = file
      }
      table.insert(files, fileObject)
   end

   return files
end

return getFiles