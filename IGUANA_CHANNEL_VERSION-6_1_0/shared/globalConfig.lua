local globalConfig = {}

-- Pattern explanation:
globalConfig.BARCODE_FORMAT = "^(%a+%d+-%d+)_(%d+)_(%d+)_(%d+)$"

-- The number of components must match the number of parenthesis pairs
globalConfig.BARCODE_COMPONENTS = {"accessionId","part","item","count"}

globalConfig.LAB_SITE = 1
globalConfig.EMAIL_DOMAIN = '@healthnetworklabs.com'

globalConfig.MESSAGE_OPTIONS = {
   addProcedures = true,
   addSpecimens = true,
   addSpecimenCategories = true, 
   addStains = true,
   assignedUserIdLookupField = 'name',
   deleteCaseIfNoSlidesLeft = true,
   archiveStatusLocked = true
}

-- TIMEZONE OFFSET
local defaultOffset = '-05:00'
local dstOffset = '-04:00'
globalConfig.DEFAULT_OFFSET = defaultOffset
globalConfig.DST_TRANSITIONS = {
   {year=2021, month=11, day=7, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2023, month=3, day=12, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2023, month=11, day=5, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2024, month=3, day=10, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2024, month=11, day=3, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2025, month=3, day=9, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2025, month=11, day=2, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2026, month=3, day=8, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2026, month=11, day=1, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2027, month=3, day=14, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2027, month=11, day=7, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2028, month=3, day=12, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2028, month=11, day=5, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2029, month=3, day=11, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2029, month=11, day=4, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2030, month=3, day=10, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2030, month=11, day=3, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2031, month=3, day=9, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2031, month=11, day=2, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2032, month=3, day=14, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2032, month=11, day=7, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2033, month=3, day=13, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2033, month=11, day=6, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2034, month=3, day=12, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2034, month=11, day=5, hour=2, min=0, sec=0, offset=defaultOffset},
   {year=2035, month=3, day=11, hour=2, min=0, sec=0, offset=dstOffset},
   {year=2035, month=11, day=4, hour=2, min=0, sec=0, offset=defaultOffset}
}

-- Convert transition dates to timestamps
for i, v in ipairs(globalConfig.DST_TRANSITIONS) do
   v.timestamp = os.time(v)
end

-- WEBHOOK IDS TO BE CHECKED
globalConfig.WEBHOOK_REQUEST_IDS = {1, 2, 4, 5}
globalConfig.WEBHOOK_REQUEST_START_DATE = '2024-09-17T00:00:00Z'

globalConfig.ALERTS = {
   PASSWORD = 'PROSCIA@dmin1234',
   USERNAME = 'admin',
   IGUANA_URL = 'http://10.128.25.4:6543/status',
   LIVE = true,
   EXCEPTIONS = {
      'X_Alerts',
      'A4_Case Results',
      'A5_Delete Slides'      
   },
   REQUESTER = 'proscia_alerts@healthnetworklabs.com',
   CLIENT_NAME = 'HNL',
   URL = 'https://hooks.zapier.com/hooks/catch/18692772/2mdtbtr/'
}

return globalConfig