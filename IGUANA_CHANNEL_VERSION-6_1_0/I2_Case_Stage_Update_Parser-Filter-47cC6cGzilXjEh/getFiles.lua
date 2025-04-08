local fu = require 'fileUtils'
local tu = require 'tableUtils'

local function parseYearFromAccession(accessionId)
   -- Extract the numeric year part between the letters and the first dash
   local year = accessionId:match("^%a+(%d+)%-.+")
   if year then
      -- Convert the two-digit year into a four-digit year
      return 2000 + tonumber(year)
   else
      -- Handle cases where the format is unexpected
      error("Invalid accessionId format: " .. accessionId)
   end
end

function getFiles(accessionId)

   -- Get the Gross Images
   -- - First build the directory
   local year = parseYearFromAccession(accessionId)
   local grossDirectory = '/media/copath_images/'..year..'/GROSS IMAGES/'..accessionId ..'/'
   trace(grossDirectory)

   -- MANIPULATION FOR INITIAL TEST CASE
   if accessionId == 'S24-802' then
      grossDirectory = '/media/copath_images/2024/GROSS IMAGES/Proscia test S24-802 (test case)/'
   end

   -- - Then list the files in the directory
   local fileList = fu.listFiles(grossDirectory)

   -- Build the files table with the directory and filename values
   local files = {}
   for _, file in ipairs(fileList) do
      local fileObject = {
         directory = grossDirectory,
         filename = file
      }
      table.insert(files, fileObject)
   end

   -- - Check if the requisition exists, and if so, add it to the files table
   local reqDirectory = '/media/copath_images/Scanned Protocols/'
   --local reqExists = fu.fileExists(IGUANA_OS, reqDirectory .. reqFilename)
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
