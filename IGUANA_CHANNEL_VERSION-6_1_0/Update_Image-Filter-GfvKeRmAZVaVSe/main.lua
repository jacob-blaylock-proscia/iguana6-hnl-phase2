-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.

local gc = require 'globalConfig'
local bu = require 'barcodeUtils'

function main(Data)
   local image = json.parse{data=Data}
   local barcode = image.event.current.barcodeData
   trace(barcode)

   -- Validate barcode
   if not gc.MESSAGE_OPTIONS.skipBarcodeValidation then
      local parsedBarcode = bu.parseBarcode(barcode, gc.BARCODE_FORMAT, gc.BARCODE_COMPONENTS)
      if parsedBarcode == nil then
         return
      end   
   end
   queue.push{data=Data}

end