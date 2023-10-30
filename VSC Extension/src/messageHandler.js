const vscode = require('vscode')
const messages = require('./config/messages')
const config = require('./config/settings')

function show(message, mode) {
    if (!config.hideNotifications) {
        message = messages[message]

        if (!message.toLowerCase().includes('argon')) {
            message = 'Argon: ' + message
        }
    
        switch (mode){
            case 1:
                vscode.window.showWarningMessage(message)
                break
            case 2:
                vscode.window.showErrorMessage(message)
                break
            default:
                vscode.window.showInformationMessage(message)
                break
        }
    }
}

module.exports = {
    show
}