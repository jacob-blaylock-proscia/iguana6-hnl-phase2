-- Import necessary modules
hl7.fix = require 'hl7.delimiter.fix'
local parseOML = require 'parseOML'
local parseORU = require 'parseORU'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function main(Data)      
   local Data = hl7.fix{data=Data, segment='OBR',field_index=15}

   -- Parse the incoming HL7 message
   local msg, msgType = hl7.parse{vmd='HNL_OML-ORU-ORM_02252025.vmd',data=Data}
   local jsonMsg = {}

   -- Filter messages and apply the necessary JSON mapping
   if msgType == 'CatchAll' then
      iguana.logInfo('Message type not supported')
      return
   elseif msgType == 'ADT' then
      iguana.logInfo('Skipping ADT message')
      return
   elseif msgType == 'OML' then
      jsonMsg = parseOML(msg)
      for i=1, #jsonMsg do
         queue.push{data=json.serialize{data=jsonMsg[i],alphasort=true}}         
      end
   elseif msgType == 'ORM' then
      -- Use OML parser for ORMs
      jsonMsg = parseOML(msg)
      for i=1, #jsonMsg do
         queue.push{data=json.serialize{data=jsonMsg[i],alphasort=true}}         
      end
   elseif msgType == 'ORU' then
      if msg.OBR[25]:S() ~= 'F' then
         iguana.logInfo('Case status not F, skipping. AccessionId: ' .. msg.OBR[2]:S())
         return
      else         
         jsonMsg = parseORU(msg)
         queue.push{data=json.serialize{data=jsonMsg,alphasort=true}}

      end
   end

end
