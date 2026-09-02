import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  required property QtObject bar
  property var weather: null
  property date now: new Date()

  readonly property string icon: weather && weather.label !== "" ? weather.label : "󰖐"
  readonly property string temperature: weather && weather.reportTempNum !== ""
    ? weather.reportTempNum + weather.tempUnit : "--°"
  readonly property string location: weather && weather.reportLocation !== ""
    ? weather.reportLocation : "Weather"
  readonly property string condition: {
    var current = weather ? weather.current : null
    if (current && current.weatherDesc && current.weatherDesc.length > 0)
      return String(current.weatherDesc[0].value || "")
    return weather && weather.reportFeels !== "" ? "Feels like " + weather.reportFeels : "Updating forecast…"
  }
  readonly property var forecast: weather && weather.forecastDays
    ? weather.forecastDays.slice(0, 3) : []

  color: Style.normalFillFor(bar.foreground, Color.accent)
  borderSpec: Border.controlSpec("normal", bar.foreground, Color.accent)
  radius: Style.cornerRadius * 1.35

  Item {
    anchors.fill: parent
    anchors.margins: Style.space(12)

    Column {
      anchors.fill: parent
      spacing: Style.space(4)

      Row {
        id: summaryRow
        width: parent.width
        height: Style.space(54)
        spacing: Style.space(12)

        Row {
          id: currentBlock
          width: Style.space(180)
          height: parent.height
          spacing: Style.space(9)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: Color.accent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.space(42)
          }

          Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0

            Text {
              text: root.temperature
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.displayLarge
              font.bold: true
            }

            Text {
              width: Style.space(105)
              textFormat: Text.PlainText
              text: root.condition
              color: Qt.darker(root.bar.foreground, 1.35)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              elide: Text.ElideRight
            }
          }
        }

        Column {
          width: parent.width - currentBlock.width - refreshButton.width - summaryRow.spacing * 2
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(1)

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: root.location
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
          }

          Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: Qt.darker(root.bar.foreground, 1.45)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Button {
          id: refreshButton
          anchors.verticalCenter: parent.verticalCenter
          iconText: "󰑐"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingY
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: if (root.weather && root.weather.refresh) root.weather.refresh()
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: Qt.rgba(root.bar.foreground.r,
          root.bar.foreground.g, root.bar.foreground.b, 0.12)
      }

      Row {
        id: forecastRow
        width: parent.width
        height: parent.height - summaryRow.height - Style.space(9)
        spacing: 0

        Repeater {
          model: root.forecast

          Item {
            required property var modelData
            required property int index

            width: Math.floor(forecastRow.width / 3)
            height: forecastRow.height

            Rectangle {
              visible: parent.index > 0
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              width: 1
              height: Math.round(parent.height * 0.58)
              color: Qt.rgba(root.bar.foreground.r,
                root.bar.foreground.g, root.bar.foreground.b, 0.13)
            }

            Column {
              anchors.centerIn: parent
              width: parent.width - Style.space(12)
              spacing: Style.space(1)

              Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.weather ? root.weather.dayName(modelData.date).slice(0, 3).toUpperCase() : "---"
                color: Qt.darker(root.bar.foreground, 1.35)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }

              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(5)

                Text {
                  text: root.weather ? root.weather.dayIcon(modelData) : ""
                  color: Color.accent
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.body
                }

                Text {
                  text: root.weather
                    ? root.weather.bareTempForDay(modelData, "max") + "°"
                    : "--°"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                Text {
                  text: root.weather
                    ? root.weather.bareTempForDay(modelData, "min") + "°"
                    : "--°"
                  color: Qt.darker(root.bar.foreground, 1.45)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }
      }
    }
  }
}
