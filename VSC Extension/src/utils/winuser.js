// @ts-nocheck
const config = require('../config/settings')
const messageHandler = require('../messageHandler')

function getVersion() {
    switch (config.nodeModules) {
        case '106':
            return require('./winuser-106')
        case '110':
            return require('./winuser-110')
        case '116':
            return require('./winuser-116')
        case '118':
            return require('./winuser-118')
        default:
            return {
                "showVSC": () => {
                    messageHandler.show('unsupportedVersion', 2)
                },
                "showStudio": () => {
                    messageHandler.show('unsupportedVersion', 2)
                },
                "isStudioRunning" : () => {
                    return false
                },
                "resetWindow": () => {}
            }
        }
}

if (config.os == 'win32') {
    module.exports = getVersion()
}
else {
    module.exports = null
}