import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "celestune-bar"

  // Omarchy 4 does not expose its private media service to bar-widget
  // plugins. Use the local MPRIS controller instead.
  readonly property var mediaService: media
  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property var weatherPanel: weatherLoader.item
  readonly property bool hasMedia: activePlayer !== null
    && ((activePlayer.trackTitle || "") !== "" || (activePlayer.trackArtist || "") !== "")
  readonly property string mediaTitle: hasMedia ? (activePlayer.trackTitle || "Unknown track") : ""
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property string weatherIcon: weatherPanel && weatherPanel.label !== ""
    ? weatherPanel.label : "󰖐"
  readonly property string weatherTemp: weatherPanel && weatherPanel.reportTempNum !== ""
    ? weatherPanel.reportTempNum + weatherPanel.tempUnit : ""
  readonly property var clockFormats: [
    "ddd HH:mm",
    "HH:mm",
    "h:mm AP",
    "ddd d MMM HH:mm",
    "ddd d MMM h:mm AP",
    "dddd HH:mm",
    "dddd h:mm AP",
    "yyyy-MM-dd HH:mm"
  ]
  readonly property string activeClockFormat: setting("format", "ddd HH:mm")

  property bool opened: false
  property date now: new Date()
  property bool popoutSwitchClosing: false

  function open() {
    syncWeatherLocation()
    opened = true
  }
  function close() {
    opened = false
    if (weatherPanel && weatherPanel.opened) weatherPanel.close()
  }
  function togglePanel() {
    if (opened || (weatherPanel && weatherPanel.opened)) close()
    else open()
  }
  function closeForPopoutSwitch() {
    popoutSwitchClosing = true
    close()
    Qt.callLater(function() { root.popoutSwitchClosing = false })
  }

  function mediaAction(action) {
    if (!mediaService) return
    var key = activePlayer ? mediaService.playerKey(activePlayer) : ""
    mediaService.runAction(action, false, key)
  }

  function refreshWeather() {
    syncWeatherLocation()
    if (weatherPanel && weatherPanel.refresh) Qt.callLater(weatherPanel.refresh)
  }

  function syncWeatherLocation() {
    if (weatherPanel && weatherPanel.locationFile)
      weatherPanel.locationFile.reload()
  }

  function cycleClockFormat() {
    var current = String(activeClockFormat)
    var index = clockFormats.indexOf(current)
    var next = clockFormats[(index + 1) % clockFormats.length]

    var entry = { id: root.moduleName }
    for (var key in root.settings) {
      if (key !== "id") entry[key] = root.settings[key]
    }
    entry.format = next

    root.settings = entry
    root.now = new Date()
    if (root.bar && root.bar.shell
        && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  function shortText(value, limit) {
    var text = String(value || "")
    return text.length > limit ? text.slice(0, limit - 1) + "…" : text
  }

  function barLabel() {
    var clock = Qt.formatDateTime(now, activeClockFormat)
    var weather = weatherIcon + (weatherTemp !== "" ? " " + weatherTemp : "")
    var media = hasMedia ? playIcon + " " + shortText(mediaTitle, 18) : ""
    if (vertical) return weatherIcon
    return clock + "  ·  " + weather + (media !== "" ? "  ·  " + media : "")
  }

  function injectWeather() {
    var target = weatherLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = ({})
    if ("anchorItem" in target) target.anchorItem = pill
    if ("hostWidget" in target) target.hostWidget = root
    if (target.locationFile) target.locationFile.reload()
  }

  onBarChanged: injectWeather()

  MediaSource {
    id: media
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.now = date
  }

  Loader {
    id: weatherLoader
    active: true
    asynchronous: false
    visible: false
    source: Util.fileUrl(Quickshell.env("OMARCHY_PATH") + "/shell/plugins/panels/weather/Panel.qml")
    onLoaded: {
      root.injectWeather()
      Qt.callLater(root.injectWeather)
    }
  }

  visible: true
  implicitWidth: pill.implicitWidth
  implicitHeight: pill.implicitHeight

  WidgetButton {
    id: pill
    anchors.fill: parent
    bar: root.bar
    text: root.barLabel()
    active: root.opened || (root.weatherPanel && root.weatherPanel.opened)
    horizontalMargin: 7
    tooltipText: "Dashboard\nKlik: buka · Tengah: play/pause · Kanan: format jam · Gulir: ganti lagu"

    onPressed: function(button) {
      if (button === Qt.MiddleButton) root.mediaAction("playPause")
      else if (button === Qt.RightButton) root.cycleClockFormat()
      else root.togglePanel()
    }

    onWheelMoved: function(delta) {
      root.mediaAction(delta > 0 ? "previous" : "next")
    }
  }

  // Observe bar targets as an extra dismissal path alongside KeyboardPanel's
  // full-screen outside-click surface.
  Repeater {
    model: root.bar ? root.bar.clickTargets : []

    delegate: Item {
      id: barClickObserver
      required property var modelData

      width: 0
      height: 0
      visible: false

      Connections {
        target: barClickObserver.modelData
        ignoreUnknownSignals: true

        function onPressed(button) {
          var weatherOpen = root.weatherPanel && root.weatherPanel.opened
          if ((root.opened || weatherOpen) && barClickObserver.modelData !== pill)
            root.close()
        }
      }
    }
  }

  Connections {
    target: root.bar
    ignoreUnknownSignals: true

    function onActivePopoutChanged() {
      var weatherOpen = root.weatherPanel && root.weatherPanel.opened
      if ((root.opened || weatherOpen) && root.bar && root.bar.activePopout
          && root.bar.activePopout !== root) root.close()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: popup.fittedContentWidth(Style.space(760))
    contentHeight: popup.fittedContentHeight(dashboard.implicitHeight)

    PanelKeyCatcher {
      anchors.fill: parent
      id: keyCatcher
      blocked: dashboard.editingLocation
      onCloseRequested: root.close()

      Dashboard {
        id: dashboard
        anchors.fill: parent
        bar: root.bar
        weather: root.weatherPanel
        mediaService: root.mediaService
        now: root.now
      }
    }
  }
}
