import QtQuick

Item {
    id: root
    
    // Public API - Properties that all widgets should support
    property string title: ""
    property bool enabled: true
    property bool visible: true
    property bool loading: false
    property string errorMessage: ""
    
    // Visual properties
    property alias backgroundColor: background.color
    property alias borderColor: background.border.color
    property alias borderWidth: background.border.width
    property alias radius: background.radius
    
    // Signals for external communication
    signal clicked()
    signal doubleClicked()
    signal rightClicked()
    signal entered()
    signal exited()
    signal loadingChanged(bool isLoading)
    signal errorOccurred(string message)
    
    // Internal implementation
    Rectangle {
        id: background
        anchors.fill: parent
        color: "#313244"  // Theme.colors.surface
        border.color: "#585b70"  // Theme.colors.border  
        border.width: 1
        radius: 8  // Theme.geometry.radius
        opacity: root.enabled ? 1.0 : 0.6
        
        // Loading indicator
        Rectangle {
            anchors.fill: parent
            color: Theme.colors.overlay
            radius: parent.radius
            visible: root.loading
            opacity: 0.8
            
            Text {
                anchors.centerIn: parent
                text: "Loading..."
                color: Theme.colors.text
                font: Theme.fonts.caption
            }
        }
        
        // Error state
        Rectangle {
            anchors.fill: parent
            color: Theme.colors.error
            radius: parent.radius
            visible: root.errorMessage !== ""
            opacity: 0.9
            
            Text {
                anchors.centerIn: parent
                text: root.errorMessage
                color: Theme.colors.onError
                font: Theme.fonts.caption
                wrapMode: Text.WordWrap
                width: parent.width - Theme.spacing.medium * 2
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    
    // Mouse interaction
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled && !root.loading
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.clicked()
            } else if (mouse.button === Qt.RightButton) {
                root.rightClicked()
            }
        }
        
        onDoubleClicked: root.doubleClicked()
        onEntered: root.entered()
        onExited: root.exited()
    }
    
    // Helper functions
    function setLoading(isLoading) {
        loading = isLoading
        loadingChanged(isLoading)
    }
    
    function setError(message) {
        errorMessage = message
        if (message !== "") {
            errorOccurred(message)
        }
    }
    
    function clearError() {
        errorMessage = ""
    }
}