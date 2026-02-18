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

    property string cfg_panelInfoMode: "scroll"
    property int cfg_panelScrollSeconds: 4
    property bool cfg_panelShowTemperature: true
    property bool cfg_panelShowWeatherIcon: true
    property bool cfg_panelShowSunTimes: true
    property bool cfg_panelShowWind: true
    property bool cfg_panelShowFeelsLike: false
    property bool cfg_panelShowHumidity: false
    property bool cfg_panelShowPressure: false

    ScrollView {
        anchors.fill: parent

        ColumnLayout {
            width: parent.width
            spacing: 12

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.bold: true
                text: "Panel line (for thin panels)"
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 12

                Label { text: "Display mode:" }
                ComboBox {
                    Layout.fillWidth: true
                    model: [
                        { text: "Scrollable (cycle info)", value: "scroll" },
                        { text: "Single line", value: "single" }
                    ]
                    textRole: "text"
                    Component.onCompleted: {
                        for (var i = 0; i < model.length; ++i) {
                            if (model[i].value === root.cfg_panelInfoMode) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }
                    onActivated: root.cfg_panelInfoMode = model[currentIndex].value
                }

                Label { text: "Scroll interval (sec):" }
                SpinBox {
                    from: 1
                    to: 30
                    value: root.cfg_panelScrollSeconds
                    enabled: root.cfg_panelInfoMode === "scroll"
                    onValueModified: root.cfg_panelScrollSeconds = value
                }
            }

            Label {
                Layout.fillWidth: true
                text: "Show in panel line:"
                font.bold: true
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                CheckBox { text: "Temperature"; checked: root.cfg_panelShowTemperature; onToggled: root.cfg_panelShowTemperature = checked }
                CheckBox { text: "Weather icon"; checked: root.cfg_panelShowWeatherIcon; onToggled: root.cfg_panelShowWeatherIcon = checked }
                CheckBox { text: "Sunrise/Sunset"; checked: root.cfg_panelShowSunTimes; onToggled: root.cfg_panelShowSunTimes = checked }
                CheckBox { text: "Wind"; checked: root.cfg_panelShowWind; onToggled: root.cfg_panelShowWind = checked }
                CheckBox { text: "Feels like"; checked: root.cfg_panelShowFeelsLike; onToggled: root.cfg_panelShowFeelsLike = checked }
                CheckBox { text: "Humidity"; checked: root.cfg_panelShowHumidity; onToggled: root.cfg_panelShowHumidity = checked }
                CheckBox { text: "Pressure"; checked: root.cfg_panelShowPressure; onToggled: root.cfg_panelShowPressure = checked }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.15) }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                font.bold: true
                text: "Popup scrollbox"
            }

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
                Layout.preferredHeight: 120
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
}
