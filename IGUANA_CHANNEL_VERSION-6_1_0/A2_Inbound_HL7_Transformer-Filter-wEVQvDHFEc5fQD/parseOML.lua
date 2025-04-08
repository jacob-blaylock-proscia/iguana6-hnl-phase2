local gc = require 'globalConfig'
local tzOffset = require 'date.getTimezoneOffset'
local bu = require 'barcodeUtils'
local tu = require 'tableUtils'
local mapBlockKey = require 'mapBlockKey'
hl7.unescape = require 'hl7.delimiter.unescape'
require 'date.parse'
local map = require 'mappingTables'

function parseOML(msg)
   local accessionId = msg.ORC[2][1]:S()
   local specimenClass = accessionId:match("^(%a+)%d+%-.+")

   local jsonMsgs = {}

   -- Set the message type
   local messageType
   if msg.ORC[1]:S() == 'CA' then
      -- Check if there is an OBR with a slide barcode
      local barcodeCheck = msg.OBR[1][3][1]:S()
      if barcodeCheck == '' then
         local j = {}
         j.messageType = 'deleteCase'
         j.options = gc.MESSAGE_OPTIONS
         j.case = {}
         j.case.accessionId = accessionId
         j.case.labSiteId = map.labSite(specimenClass)
         -- Insert the JSON message into the jsonMsgs table
         table.insert(jsonMsgs, j)
         return jsonMsgs
      else      
         messageType = 'delete'
      end
   else
      messageType = 'upsert'
   end

   -- Case Details
   local accessionDate = msg.ORC[9][1]:S()
   local offset = tzOffset(accessionDate:TIME(), gc.DEFAULT_OFFSET, gc.DST_TRANSITIONS) 

   local caseDetails = {}
   caseDetails.accessionDate = accessionDate:ISO8601(offset)
   caseDetails.accessionId = accessionId
   caseDetails.assignedUserCode = map.assignedUserCode(msg.OBR[1][32][2][1]:S(),msg.OBR[1][32][3][1]:S())
   caseDetails.labSiteId = map.labSite(specimenClass)
   caseDetails.patientDob = msg.PID[7]:S():sub(1,8):DAY('yyyymmdd')
   caseDetails.patientLastName = msg.PID[5][1][1]:S()
   caseDetails.patientFirstName = msg.PID[5][1][2]:S()
   caseDetails.patientMrn = msg.PID[3][1][1]:S()
   caseDetails.patientSex = msg.PID[8]:S()
   caseDetails.patientGenderIdentity = caseDetails.patientSex
   caseDetails.specimenCategoryCode = msg.OBR[1][20][2][1]:S()
   caseDetails.specimenCategoryName = msg.OBR[1][20][2][1]:S()

   for i=1, #msg.OBR do

      -- Parts
      local part = msg.OBR[i][19][1]:S()
      local block = msg.OBR[i][19][2]:S()
      local blockKey = mapBlockKey(part, block)
      local specimen = msg.OBR[i][15][1]:S():trimWS():gsub("'", ""):gsub('"', '')      

      -- Initiate json message
      local j = {}
      j.options = gc.MESSAGE_OPTIONS
      j.messageType = messageType

      -- Copy case data
      j.case = tu.deepCopy(caseDetails)

      -- Part
      j.case.parts = {{}}
      j.case.parts[1].blocks = block ~= "" and {{key=blockKey, name=block}} or {} 
      j.case.parts[1].name = part
      --j.case.parts[1].procedureCode = ''
      --j.case.parts[1].procedureName = ''
      j.case.parts[1].specimenDescription = specimen
      j.case.parts[1].specimenCode = specimen
      j.case.parts[1].specimenName = specimen

      -- Slide   
      local barcode = msg.OBR[i][3][1]:S()
      local parsedBarcode = bu.parseBarcode(barcode, gc.BARCODE_FORMAT, gc.BARCODE_COMPONENTS)
      j.case.parts[1].slides = {{}}
      j.case.parts[1].slides[1].barcode = barcode
      j.case.parts[1].slides[1].blockKey = block ~= "" and blockKey or ""
      j.case.parts[1].slides[1].name = accessionId .. '-' .. part .. block .. '*' ..parsedBarcode.item

      j.case.parts[1].slides[1].stainCode = hl7.unescape(msg.OBR[i][15][3]:S())
      j.case.parts[1].slides[1].stainName = hl7.unescape(msg.OBR[i][15][3]:S())

      -- Insert the JSON message into the jsonMsgs table
      table.insert(jsonMsgs, j)
   end
   return jsonMsgs
end

return parseOML
