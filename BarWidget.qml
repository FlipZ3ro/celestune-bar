import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "celestune-bar"

  // The shell only grants the omarchy.media proxy to full-bar plugins, so
  // read MPRIS directly through a local controller instead.
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

  property bool opened: false
  property date now: new Date()
  property bool popoutSwitchClosing: false

  function open() { opened = true }
  function close() { opened = false }
  function togglePanel() { opened = !opened }
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
    if (weatherPanel && weatherPanel.refresh) weatherPanel.refresh()
  }

  function shortText(value, limit) {
    var text = String(value || "")
    return text.length > limit ? text.slice(0, limit - 1) + "…" : text
  }

  function barLabel() {
    var clock = Qt.formatDateTime(now, "ddd HH:mm")
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
  }

  onBarChanged: injectWeather()

  MediaSource {
    id: media
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
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
    active: root.opened
    horizontalMargin: 7
    tooltipText: "Dashboard\nClick: open · Middle: play/pause · Right: refresh weather · Scroll: prev/next track"

    onPressed: function(button) {
      if (button === Qt.MiddleButton) root.mediaAction("playPause")
      else if (button === Qt.RightButton) root.refreshWeather()
      else root.togglePanel()
    }

    onWheelMoved: function(delta) {
      root.mediaAction(delta > 0 ? "previous" : "next")
    }
  }

  // PopupCard's focus grab treats the whole bar window as an allowed surface,
  // so a click on another bar widget is not considered an outside click.
  // Observe the bar's registered click targets and dismiss this dashboard when
  // any target other than our own pill is pressed.
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
          if (root.opened && barClickObserver.modelData !== pill) root.close()
        }
      }
    }
  }

  Connections {
    target: root.bar
    ignoreUnknownSignals: true

    function onActivePopoutChanged() {
      if (root.opened && root.bar && root.bar.activePopout
          && root.bar.activePopout !== root) root.close()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.opened
    centerOnBar: true
    contentWidth: popup.fittedContentWidth(Style.space(760))
    contentHeight: popup.fittedContentHeight(dashboard.implicitHeight)

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
