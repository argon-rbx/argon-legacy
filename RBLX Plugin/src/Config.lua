local config = {}

config.argonVersion = '1.3.1'

config.host = 'localhost'
config.port = '8000'

config.autoRun = true
config.autoReconnect = true
config.onlyCode = true
config.openInEditor = false
config.twoWaySync = false
config.propertySyncing = false
config.syncDuplicates = false

config.filteringMode = false
config.filteredClasses = {}

config.syncedDirectories = {
    ['Workspace'] = false,
    ['Players'] = false,
    ['Lighting'] = false,
    ['MaterialService'] = false,
    ['ReplicatedFirst'] = true,
    ['ReplicatedStorage'] = true,
    ['ServerScriptService'] = true,
    ['ServerStorage'] = true,
    ['StarterGui'] = true,
    ['StarterPack'] = true,
    ['StarterPlayer'] = true,
    ['Teams'] = false,
    ['SoundService'] = false,
    ['Chat'] = false,
    ['LocalizationService'] = false,
    ['TestService'] = false
}

config.separator = '\\'

return config