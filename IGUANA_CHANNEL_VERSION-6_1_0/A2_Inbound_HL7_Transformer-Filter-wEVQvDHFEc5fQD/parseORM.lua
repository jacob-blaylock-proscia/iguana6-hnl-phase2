local gc = require 'globalConfig'
local tzOffset = require 'date.getTimezoneOffset'
local bu = require 'barcodeUtils'
local tu = require 'tableUtils'
local mapBlockKey = require 'mapBlockKey'
hl7.unescape = require 'hl7.delimiter.unescape'
require 'date.parse'
local map = require 'mappingTables'

function parseORM(msg)  
   local j = {} -- create blank JSON placeholder

   -- set the message type
   local barcode = msg.OBR[3]:S()
   trace(barcode)
   if msg.ORC[1]:S() == 'CA' then
      if barcode == '' then
         j.messageType = 'deleteCase'
      else
         j.messageType = 'delete'

         -- set options
         j.options = gc.MESSAGE_OPTIONS

         -- Case Details
         local accessionId = msg.ORC[2][1]:S()

         -- Case Details
         local accessionDate = msg.ORC[9][1]:S()
         local offset = tzOffset(accessionDate:TIME(), gc.DEFAULT_OFFSET, gc.DST_TRANSITIONS)   

         j.case = {}
         j.case.accessionDate = accessionDate:ISO8601(offset)
         j.case.accessionId = accessionId
         j.case.assignedUserCode = map.assignedUserCode(msg.OBR[32][2][1]:S(),msg.OBR[32][3][1]:S())
         j.case.labSiteId = map.labSite(specimenClass)
         j.case.patientDob = msg.PID[7]:S():sub(1,8):DAY('yyyymmdd')
         j.case.patientLastName = msg.PID[5][1][1]:S()
         j.case.patientFirstName = msg.PID[5][1][2]:S()
         j.case.patientMrn = msg.PID[3][1][1]:S()
         j.case.patientSex = msg.PID[8]:S()
         j.case.patientGenderIdentity = j.case.patientSex
         j.case.specimenCategoryCode = msg.OBR[20][2][1]:S()
         j.case.specimenCategoryName = msg.OBR[20][2][1]:S()

         -- Parts
         local part = msg.OBR[19][1]:S()
         local block = msg.OBR[19][2]:S()
         local blockKey = mapBlockKey(part, block)
         local specimen = msg.OBR[15][1]:S():trimWS():gsub("'", ""):gsub('"', '')

         j.case.parts = {{}}
         j.case.parts[1].blocks = block ~= "" and {{key=blockKey, name=block}} or {} 
         j.case.parts[1].name = part
         --j.case.parts[1].procedureCode = ''
         --j.case.parts[1].procedureName = ''
         j.case.parts[1].specimenDescription = specimen
         j.case.parts[1].specimenCode = specimen
         j.case.parts[1].specimenName = specimen

         -- Slide   
         j.case.parts[1].slides = {{}}
         j.case.parts[1].slides[1].barcode = barcode
         j.case.parts[1].slides[1].blockKey = block ~= "" and blockKey or ""
         j.case.parts[1].slides[1].name = accessionId .. '-' .. part .. block .. '*' ..parsedBarcode.item

         j.case.parts[1].slides[1].stainCode = hl7.unescape(msg.OBR[15][3]:S())
         j.case.parts[1].slides[1].stainName = hl7.unescape(msg.OBR[15][3]:S())         

         -- UDFs
         return j
      end
   else
      iguana.logInfo('Message type not supported. Skipping message for case '..accessionId)      
   end

end

return parseORM
