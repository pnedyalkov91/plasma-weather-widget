import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property bool cfg_showScrollbox: true
    property int cfg_scrollboxLines: 2
    property string cfg_scrollboxItems: "Humidity;Wind;Pressure;Dew Point;Visibility"
    property bool cfg_animateTransitions: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            CheckBox {
                text: "Show scrollbox"
                checked: root.cfg_showScrollbox
                onToggled: root.cfg_showScrollbox = checked
            }

            Label { text: "Lines:" }
            SpinBox {
                from: 1
                to: 6
                value: root.cfg_scrollboxLines
                onValueModified: root.cfg_scrollboxLines = value
            }
        }

        Label { text: "Labels to display (semicolon-separated):" }
        TextArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.cfg_scrollboxItems
            wrapMode: TextEdit.Wrap
            onTextChanged: root.cfg_scrollboxItems = text
        }

        CheckBox {
            text: "Animate transitions between labels"
            checked: root.cfg_animateTransitions
            onToggled: root.cfg_animateTransitions = checked
        }
    }
}
