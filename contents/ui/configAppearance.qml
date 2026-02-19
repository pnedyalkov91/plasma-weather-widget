import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_tooltipStyle: "verbose"
    property string cfg_forecastLayout: "rows"
    property int cfg_forecastDays: 5
    property bool cfg_roundValues: true
    property bool cfg_singlePanelRow: true
    property bool cfg_autoRefresh: true
    property int cfg_refreshIntervalMinutes: 15
    property int cfg_panelOpacityPercent: 70
    property bool cfg_transparentBackground: false

    function setCombo(combo, value) {
        for (var i = 0; i < combo.model.length; ++i) {
            if (combo.model[i].value === value) {
                combo.currentIndex = i;
                return;
            }
        }
    }

    Component.onCompleted: {
        setCombo(tooltipCombo, cfg_tooltipStyle);
        setCombo(layoutCombo, cfg_forecastLayout);
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 8
        columnSpacing: 12

        Label { text: "Tooltip style:" }
        ComboBox {
            id: tooltipCombo
            model: [
                { text: "Verbose", value: "verbose" },
                { text: "Simple", value: "simple" }
            ]
            textRole: "text"
            onActivated: root.cfg_tooltipStyle = model[currentIndex].value
        }

        Label { text: "Forecast layout:" }
        ComboBox {
            id: layoutCombo
            model: [
                { text: "Days in rows", value: "rows" },
                { text: "Days in columns", value: "columns" }
            ]
            textRole: "text"
            onActivated: root.cfg_forecastLayout = model[currentIndex].value
        }

        Label { text: "Number of forecast days:" }
        SpinBox {
            from: 3
            to: 10
            value: root.cfg_forecastDays
            onValueModified: root.cfg_forecastDays = value
        }

        Label { text: "Panel opacity:" }
        RowLayout {
            Slider {
                Layout.preferredWidth: 180
                from: 0
                to: 100
                value: root.cfg_panelOpacityPercent
                stepSize: 1
                onMoved: root.cfg_panelOpacityPercent = Math.round(value)
                enabled: !root.cfg_transparentBackground
            }
            Label { text: root.cfg_transparentBackground ? "Auto" : (root.cfg_panelOpacityPercent + "%") }
        }

        CheckBox {
            Layout.columnSpan: 2
            text: "Transparent widget background"
            checked: root.cfg_transparentBackground
            onToggled: root.cfg_transparentBackground = checked
        }

        CheckBox {
            Layout.columnSpan: 2
            text: "Use only a single panel row"
            checked: root.cfg_singlePanelRow
            onToggled: root.cfg_singlePanelRow = checked
        }

        CheckBox {
            Layout.columnSpan: 2
            text: "Round values"
            checked: root.cfg_roundValues
            onToggled: root.cfg_roundValues = checked
        }

        CheckBox {
            Layout.columnSpan: 2
            text: "Refresh weather automatically"
            checked: root.cfg_autoRefresh
            onToggled: root.cfg_autoRefresh = checked
        }

        Label { text: "Refresh interval (minutes):" }
        SpinBox {
            from: 5
            to: 180
            value: root.cfg_refreshIntervalMinutes
            onValueModified: root.cfg_refreshIntervalMinutes = value
        }
    }
}
