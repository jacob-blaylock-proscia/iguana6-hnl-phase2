-- Import necessary modules
local gc = require 'globalConfig'
local tu = require 'tableUtils'
local getFiles = require 'getFiles'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)      
   local msg = json.parse{data=Data}
   local files = getFiles(msg.event.current.accessionId)

   if tu.isNotTableOrEmpty(files) then
      iguana.logInfo('Skipping message. There are no files for ' .. msg.event.current.accessionId)
      return
   end

   local j = {} -- create blank JSON placeholder

   -- Set the message type
   j.messageType = 'upsert'


   -- set options
   j.options = gc.MESSAGE_OPTIONS  
   j.options.skipStatusUpdates = true

   j.case = {}
   j.case.accessionId = msg.event.current.accessionId
   j.case.files = files


   queue.push{data=json.serialize{data=j,alphasort=true}}

end
