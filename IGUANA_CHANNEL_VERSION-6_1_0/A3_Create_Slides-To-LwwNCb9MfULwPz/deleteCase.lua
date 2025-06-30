-- Import necessary modules
local api = require 'concentriqAPI'

function deleteCase(msg)
   LOG_LEVEL = (msg.options.logLevel and msg.options.logLevel.deleteCase) or 'logError' 
   
   ----------------------------------------------------------------------------
   -- CASE DETAILS CHECK
   ----------------------------------------------------------------------------
   local caseDetailsQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = { 
               accessionId = msg.case.accessionId,
               labSiteId = msg.case.labSiteId
            }
         }
      }
   }
   caseDetails = api.getCaseDetails(caseDetailsQuery)   

   -- Delete the case
   if caseDetails then
      local deletedCase = api.deleteCaseDetails(caseDetails.id)
      iguana.logInfo('Case '..caseDetails.accessionId..' (id: '..caseDetails.id..')'..' deleted.')
   else
      iguana[LOG_LEVEL]('Skipping message. This case does not exist. Accession ID = ' ..msg.case.accessionId)
   end
end

return deleteCase