local api = require 'concentriqAPI'

function checkCaseStatus(msg, caseDetails)
   if msg.options.skipStatusUpdates then
      return 'Skip status updates'
   end
   
   local status = api.caseStatus(caseDetails.id, msg.options.archiveStatusLocked, caseDetails.caseStage)
   if status ~= caseDetails.caseStage then
      local caseDetailsBody = {caseStage = status}
      local caseDetails = api.patchCaseDetails(caseDetails.id, caseDetailsBody)
      return caseDetails
   end 
   return 'Status not changed: '..status
end

return checkCaseStatus