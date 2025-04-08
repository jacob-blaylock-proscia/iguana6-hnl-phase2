local gc = require 'globalConfig'

local mappingTables = {}

function mappingTables.labSite(value)
   local labSite = {
      XA = 4,
      default = gc.LAB_SITE
   }
   return labSite[value] or labSite.default
end

function mappingTables.assignedUserCode(firstName, lastName)
   local assignedUserCode = {
      ['Shanth.Goonewardene'] = 'S.Goonewardene' .. gc.EMAIL_DOMAIN,
      ['Carolina.Sforza'] = 'c.sforza-huffman' .. gc.EMAIL_DOMAIN,
      ['Christopher.Sebastiano'] = 'c.sebastiano' .. gc.EMAIL_DOMAIN,
      ['Lisa.Dwyer-Joyce'] = 'lisa.dwyer-joyce' .. gc.EMAIL_DOMAIN,
      default = firstName .. '.' .. lastName .. gc.EMAIL_DOMAIN
   }
   return assignedUserCode[firstName .. '.' .. lastName] or assignedUserCode.default
   
end

return mappingTables