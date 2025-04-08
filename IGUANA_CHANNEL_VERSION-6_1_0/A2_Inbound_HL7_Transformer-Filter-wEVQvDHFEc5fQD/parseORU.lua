local gc = require 'globalConfig'
local tzOffset = require 'date.getTimezoneOffset'
local bu = require 'barcodeUtils'
local mapBlockKey = require 'mapBlockKey'
require 'date.parse'

function parseORU(msg)

   local accessionId = msg.OBR[3][1]:S()
   
   local j = {} -- create blank JSON placeholder
   
   -- set the message type
   j.messageType = 'caseUpdate'
   
   -- set options
   j.options = gc.MESSAGE_OPTIONS
   
   -- Case Details
   j.case = {}
   j.case.accessionId = accessionId
   j.case.caseStage = 'diagnosisProvided'

   -- UDFs
   return j
end

return parseORU
