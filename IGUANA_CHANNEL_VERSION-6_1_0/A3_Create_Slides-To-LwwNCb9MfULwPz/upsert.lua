-- Import necessary modules
local api = require 'concentriqAPI'
local tu = require 'tableUtils'
local mapCaseDetails = require 'mapCaseDetails'
local mapCaseParts = require 'mapCaseParts'
local mapSlides = require 'mapSlides'
local mapImages = require 'mapImages'
local checkSlides = require 'checkSlides'
local checkOrphanedParts = require 'checkOrphanedParts'
local checkCaseStatus = require 'checkCaseStatus'
local hasParts = require 'hasParts'
local hasSlides = require 'hasSlides'

-- The main function is the first function called from Iguana.
-- The Data argument will contain the message to be processed.
function upsert(msg)
   -- Initialize flags to trigger API updates that are needed
   local createCaseDetails = false
   local updateCaseDetails = false
   local createCaseParts = false
   local updateCaseParts = false
   local createSlides = false
   local updateSlides = false
   local updateImages = false
   local caseDetailCaseTags = false
   local createFiles = false

   -- Initialize other variables
   local caseDetails
   local caseParts
   local blockExists = false
   local slides
   local images

   -- Use helper functions to determine existence of parts and slides
   local partExists = hasParts(msg)
   local caseSlideExists, partSlideExists = hasSlides(msg)

   ----------------------------------------------------------------------------
   -- CASE DETAILS CHECK
   ----------------------------------------------------------------------------
   local caseDetailsQuery = json.serialize{
      data = {
         eager = {
            ["$where"] = { 
               accessionId = msg.case.accessionId,
               labSiteId = msg.case.labSiteId
            },
            attachments = { ["empty"] = false } -- add dummy value to force attachments to be an object
         }
      }
   }
   caseDetailsQuery = caseDetailsQuery:gsub('"empty": false','') -- remove the dummy value
   caseDetails = api.getCaseDetails(caseDetailsQuery)

   if not caseDetails then
      createCaseDetails = true
      createCaseParts   = partExists
      createSlides      = (caseSlideExists or partSlideExists)
      createFiles       = msg.case.files and not tu.isNotTableOrEmpty(msg.case.files)
   else
      -- Case exists. Set flag to update case details
      updateCaseDetails = true
   end

   ----------------------------------------------------------------------------
   -- PART / BLOCK CHECK (only if caseDetails exist)
   ----------------------------------------------------------------------------
   if caseDetails then
      if partExists then
         -- Try to get the part from the existing case
         local partName = msg.case.parts[1].name
         local casePartsQuery = json.serialize{
            data = {
               eager = { ["$where"] = { 
                     caseDetailId = caseDetails.id, 
                     name = partName 
                  } 
               }
            }
         }
         caseParts = api.getCaseParts(casePartsQuery)

         if not caseParts then
            -- No part found
            createCaseParts = true
         else
            -- Part found
            updateCaseParts = true
         end
      end
   end

   ----------------------------------------------------------------------------
   -- SLIDE CHECK (only if caseDetails exist)
   ----------------------------------------------------------------------------
   if caseDetails then
      if caseSlideExists then
         local barcode = msg.case.slides[1].barcode
         slides, createSlides, updateSlides = checkSlides(barcode, caseDetails.id, createSlides, updateSlides)
      elseif partSlideExists then
         local barcode = msg.case.parts[1].slides[1].barcode
         slides, createSlides, updateSlides = checkSlides(barcode, caseDetails.id, createSlides, updateSlides)
      end
   end

   ----------------------------------------------------------------------------
   -- FILE ATTACHMENTS
   ----------------------------------------------------------------------------
   if not tu.isNotTableOrEmpty(msg.case.files) then
      -- If we have an existing case, filter out files that are already attached
      if caseDetails then
         local attachments = {}
         for _, attachment in ipairs(caseDetails.attachments or {}) do
            if attachment.filename then
               attachments[attachment.filename] = true
            end
         end

         local newFiles = {}
         for _, file in ipairs(msg.case.files) do
            if file.filename and not attachments[file.filename] then
               table.insert(newFiles, file)
            end
         end

         msg.case.files = newFiles
      end

      -- If any files remain, we know we need to attach them
      if #msg.case.files > 0 then
         createFiles = true
      end
   end

   ----------------------------------------------------------------------------
   -- IMAGE CHECK
   ----------------------------------------------------------------------------
   local barcodeData
   if caseSlideExists then
      images = msg.case.slides[1].images
      barcodeData = msg.case.slides[1].barcode
   elseif partSlideExists then
      images = msg.case.parts[1].slides[1].images
      barcodeData = msg.case.parts[1].slides[1].barcode          
   end

   -- If images were provided, update the images
   if images then
      updateImages = true
   else
      -- If not, then check to see if an image for the slide already exists in the system if a barcode is available      
      if barcodeData then
         local imagesQuery = json.serialize{ 
            data = {
               eager = { 
                  ["$where"] = { 
                     barcodeData = barcodeData
                  } 
               } 
            } 
         }
         images = api.getImagesAll(imagesQuery)

         -- TODO: limit images to only ones scanned on a scanner related to the lab site
         if images then
            updateImages = true
         end
      end
   end
   trace(updateImages)

   ----------------------------------------------------------------------------
   -- TAGS
   ----------------------------------------------------------------------------
   if not tu.isNotTableOrEmpty(msg.case.tags) then
      caseDetailCaseTags = true
   end

   ----------------------------------------------------------------------------
   -- DEBUG FLAGS
   ----------------------------------------------------------------------------
   trace(createCaseDetails)
   trace(updateCaseDetails)
   trace(createCaseParts)
   trace(updateCaseParts)
   trace(createSlides)
   trace(updateSlides)
   trace(updateImages)
   trace(createFiles)

   ----------------------------------------------------------------------------
   -- CREATE / UPDATE CASE
   ----------------------------------------------------------------------------
   if createCaseDetails then
      local caseDetailsBody = mapCaseDetails(msg, nil, { workflow = "upsert", action = "post" })
      caseDetails = api.postCaseDetails(caseDetailsBody)
   elseif updateCaseDetails and caseDetails then
      -- Only update the status if we aren't about to update slides or images
      local shouldUpdateStatus = not msg.options.skipStatusUpdates and not (createSlides or updateSlides or updateImages)
      local caseDetailsBody = mapCaseDetails(msg, caseDetails, { workflow = "upsert", action = "patch", updateStatus = shouldUpdateStatus })
      caseDetails = api.patchCaseDetails(caseDetails.id, caseDetailsBody)
   end

   ----------------------------------------------------------------------------
   -- CASE TAGS
   ----------------------------------------------------------------------------
   if caseDetailCaseTags and caseDetails then
      for i = 1, #msg.case.tags do
         local caseTagId = msg.case.tags[i]
         local caseDetailCaseTagsQuery = json.serialize{
            data = {
               eager = {
                  ["$where"] = {
                     ["$and"] = {
                        caseDetailId = caseDetails.id,
                        caseTagId     = caseTagId
                     }
                  }
               }
            }
         }
         local existingTags = api.getCaseDetailCaseTags(caseDetailCaseTagsQuery)
         if not existingTags then
            local caseDetailCaseTagsBody = {
               caseDetailId = caseDetails.id,
               caseTagId    = caseTagId
            }
            api.postCaseDetailCaseTags(caseDetailCaseTagsBody)
         end
      end
   end

   ----------------------------------------------------------------------------
   -- CREATE / UPDATE PARTS
   ----------------------------------------------------------------------------
   if createCaseParts and caseDetails then
      local casePartsBody = mapCaseParts(msg, caseDetails, nil, { action = "post" })
      caseParts = api.postCaseParts(casePartsBody)
   elseif updateCaseParts and caseParts and caseDetails then
      local casePartsBody = mapCaseParts(msg, caseDetails, caseParts, { action = "patch" })
      caseParts = api.patchCaseParts(caseParts.id, casePartsBody)
   end

   ----------------------------------------------------------------------------
   -- CREATE / UPDATE SLIDES
   ----------------------------------------------------------------------------
   if createSlides and caseDetails then
      local slidesBody = mapSlides.post(msg, caseDetails, caseParts)
      slides = api.postSlides(slidesBody)

      -- Now update the status based on the current state of the case if it has changed
      checkCaseStatus(msg, caseDetails)    
   elseif updateSlides and slides and caseDetails then
      local slidesBody = mapSlides.patch(msg, caseDetails, caseParts)
      slides = api.patchSlides(slides.id, slidesBody)

      -- Check for any orphaned blocks or parts and delete
      checkOrphanedParts(caseDetails, msg)

      -- Now update the status based on the current state of the case if it has changed
      checkCaseStatus(msg, caseDetails)    
   end

   ----------------------------------------------------------------------------
   -- UPDATE IMAGES
   ----------------------------------------------------------------------------
   if updateImages and slides and slides.id and images then
      for _, image in ipairs(images) do
         local imagesBody = mapImages(msg, slides)
         local imagesPatch = api.patchImages(image.id, imagesBody)
      end

      -- Now update the status based on the current state of the case if it has changed
      checkCaseStatus(msg, caseDetails)
   end

   ----------------------------------------------------------------------------
   -- CREATE FILE ATTACHMENTS
   ----------------------------------------------------------------------------
   if createFiles and caseDetails then
      if not tu.isNotTableOrEmpty(msg.case.files) then
         for _, file in ipairs(msg.case.files) do
            local fileUpload = api.uploadFile(caseDetails.id, file.directory, file.filename)
         end
      end
   end
end

return upsert