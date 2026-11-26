import QtQuick
import "../services"

PanelButton {
    id: root

    property string glyph
    property color glyphColor: Theme.overlay1
    property color activeColor: Theme.mauve
    property int glyphSize: Theme.fontSize

    width: 20
    height: 20

    BarText {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: root.glyphSize
        color: root.hovered || root.showFocus ? root.activeColor : root.glyphColor
    }
}
