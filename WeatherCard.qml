import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  required property QtObject bar
  property var weather: null
  property date now: new Date()

  property bool editingLocation: false
  property bool savingLocation: false
  property string locationError: ""
  property bool deviceLocationResolved: false

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

  function startEditingLocation() {
    editingLocation = true
    locationError = ""
    locationField.text = weather && weather.configuredLocation
      ? weather.configuredLocation : ""
    Qt.callLater(function() {
      locationField.selectAll()
      locationField.forceActiveFocus()
    })
  }

  function cancelEditingLocation() {
    autoLocationTimeout.stop()
    if (geocodeProc.running) geocodeProc.running = false
    if (deviceLocationProc.running) deviceLocationProc.running = false
    locationField.focus = false
    editingLocation = false
    savingLocation = false
    locationError = ""
  }

  function saveLocation() {
    var query = locationField.text.trim()
    if (query === "") {
      useAutomaticLocation()
      return
    }

    savingLocation = true
    locationError = ""
    geocodeProc.command = ["curl", "-fsS", "--max-time", "5",
      "https://geocoding-api.open-meteo.com/v1/search?name="
        + encodeURIComponent(query) + "&count=1&language=id&format=json"]
    geocodeProc.running = true
  }

  function applyLocation(name, latitude, longitude) {
    if (!weather) return
    weather.savingLocation = true
    weather.savingLocationQueryStarted = false
    weather.configuredLocationState = {
      name: name,
      latitude: latitude,
      longitude: longitude
    }
    weather.persistLocation(name, latitude, longitude)
    editingLocation = false
    savingLocation = false
  }

  function useAutomaticLocation() {
    if (!weather || deviceLocationProc.running) return
    deviceLocationResolved = false
    savingLocation = true
    locationError = ""
    autoLocationTimeout.restart()
    deviceLocationProc.running = true
  }

  function applyDeviceLocation(rawOutput) {
    autoLocationTimeout.stop()
    var raw = String(rawOutput || "")
    var pattern = /Latitude:\s*([-+]?[0-9]+(?:\.[0-9]+)?)[\s\S]*?Longitude:\s*([-+]?[0-9]+(?:\.[0-9]+)?)[\s\S]*?Accuracy:\s*([0-9]+(?:\.[0-9]+)?)/g
    var best = null
    var match

    while ((match = pattern.exec(raw)) !== null) {
      var candidate = {
        latitude: Number(match[1]),
        longitude: Number(match[2]),
        accuracy: Number(match[3])
      }
      if (!best || candidate.accuracy < best.accuracy) best = candidate
    }

    deviceLocationResolved = true
    if (!best) {
      savingLocation = false
      locationError = "Lokasi perangkat tidak tersedia"
      return
    }

    // GeoClue reports IP fallbacks at roughly 25 km. Do not replace a good
    // manual city with that misleading result; only accept a real Wi-Fi/GPS fix.
    if (best.accuracy > 5000) {
      savingLocation = false
      locationError = "Lokasi perangkat belum akurat"
      return
    }

    applyLocation("Lokasi saat ini", best.latitude, best.longitude)
  }

  Process {
    id: geocodeProc

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        try {
          var parsed = JSON.parse(raw)
          var result = parsed && parsed.results && parsed.results.length > 0
            ? parsed.results[0] : null
          if (!result) {
            root.savingLocation = false
            root.locationError = "Lokasi tidak ditemukan"
            return
          }
          root.applyLocation(String(result.name || locationField.text.trim()),
            Number(result.latitude), Number(result.longitude))
        } catch (error) {
          root.savingLocation = false
          root.locationError = "Gagal mencari lokasi"
        }
      }
    }

    onExited: function(exitCode) {
      if (exitCode !== 0 && root.savingLocation) {
        root.savingLocation = false
        root.locationError = "Gagal mencari lokasi"
      }
    }
  }

  Process {
    id: deviceLocationProc
    // Both timeout(1) and the QML watchdog below bound the request. The second
    // guard also covers a stuck D-Bus client that never emits process exit.
    command: ["timeout", "3s", "/usr/lib/geoclue-2.0/demos/where-am-i",
      "-t", "2", "-a", "8"]

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyDeviceLocation(text)
    }

    onExited: function(exitCode) {
      autoLocationTimeout.stop()
      if (!root.deviceLocationResolved && root.savingLocation) {
        root.savingLocation = false
        root.locationError = exitCode === 127
          ? "GeoClue belum terpasang"
          : "Lokasi perangkat tidak tersedia"
      }
    }
  }

  Timer {
    id: autoLocationTimeout
    interval: 3500

    onTriggered: {
      if (deviceLocationProc.running) deviceLocationProc.running = false
      if (!root.deviceLocationResolved) {
        root.deviceLocationResolved = true
        root.savingLocation = false
        root.locationError = "Lokasi perangkat tidak tersedia"
      }
    }
  }

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
          width: parent.width - currentBlock.width - weatherActions.width - summaryRow.spacing * 2
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(1)

          Text {
            visible: !root.editingLocation
            width: parent.width
            textFormat: Text.PlainText
            text: root.location
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight

            TapHandler {
              onTapped: root.startEditingLocation()
            }

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
          }

          TextField {
            id: locationField
            visible: root.editingLocation
            width: parent.width
            enabled: !root.savingLocation
            placeholderText: "Cari kota"
            foreground: root.bar.foreground
            font.family: root.bar.fontFamily

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape) {
                root.cancelEditingLocation()
                event.accepted = true
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.saveLocation()
                event.accepted = true
              }
            }
          }

          Text {
            text: root.editingLocation
              ? (root.locationError !== "" ? root.locationError : "Enter: simpan · Auto: lokasi perangkat")
              : Qt.formatDate(root.now, "dddd, d MMMM")
            color: Qt.darker(root.bar.foreground, 1.45)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }
        }

        Row {
          id: weatherActions
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Button {
            visible: !root.editingLocation
            iconText: ""
            tooltipText: "Ganti lokasi / gunakan otomatis"
            foreground: root.bar.foreground
            horizontalPadding: Style.spacing.controlPaddingY
            verticalPadding: Style.spacing.controlPaddingY
            onClicked: root.startEditingLocation()
          }

          Button {
            visible: !root.editingLocation
            iconText: "󰑐"
            tooltipText: "Perbarui cuaca"
            foreground: root.bar.foreground
            horizontalPadding: Style.spacing.controlPaddingY
            verticalPadding: Style.spacing.controlPaddingY
            onClicked: if (root.weather && root.weather.refresh) root.weather.refresh()
          }

          Button {
            visible: root.editingLocation
            iconText: root.savingLocation ? "󰦖" : "✓"
            iconSpinning: root.savingLocation
            tooltipText: "Simpan lokasi"
            foreground: root.bar.foreground
            horizontalPadding: Style.spacing.controlPaddingY
            verticalPadding: Style.spacing.controlPaddingY
            onClicked: if (!root.savingLocation) root.saveLocation()
          }

          Button {
            visible: root.editingLocation
            text: "AUTO"
            tooltipText: "Lokasi perangkat melalui GeoClue"
            foreground: root.bar.foreground
            fontSize: Style.font.caption
            horizontalPadding: Style.spacing.controlPaddingY
            verticalPadding: Style.spacing.controlPaddingY
            onClicked: if (!root.savingLocation) root.useAutomaticLocation()
          }

          Button {
            visible: root.editingLocation
            iconText: "✕"
            tooltipText: "Batal"
            foreground: root.bar.foreground
            horizontalPadding: Style.spacing.controlPaddingY
            verticalPadding: Style.spacing.controlPaddingY
            onClicked: if (!root.savingLocation) root.cancelEditingLocation()
          }
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
