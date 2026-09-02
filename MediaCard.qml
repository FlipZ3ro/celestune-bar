import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  required property QtObject bar
  property var mediaService: null

  readonly property var activePlayer: mediaService ? mediaService.activePlayer : null
  readonly property bool hasMedia: activePlayer !== null
    && ((activePlayer.trackTitle || "") !== "" || (activePlayer.trackArtist || "") !== "")
  readonly property string title: hasMedia ? (activePlayer.trackTitle || "Unknown track") : "Nothing playing"
  readonly property string artist: hasMedia
    ? (activePlayer.trackArtist || activePlayer.identity || "Unknown artist") : "Start Spotify or another player"
  readonly property string album: hasMedia ? (activePlayer.trackAlbum || "") : ""
  readonly property string artUrl: hasMedia ? (activePlayer.trackArtUrl || "") : ""
  readonly property string playIcon: activePlayer && activePlayer.isPlaying ? "󰏤" : "󰐊"
  readonly property real trackLength: activePlayer && activePlayer.lengthSupported
    ? Math.max(0, Number(activePlayer.length) || 0) : 0
  readonly property real playerVolume: activePlayer && activePlayer.volumeSupported
    ? Math.max(0, Math.min(1, Number(activePlayer.volume) || 0)) : 0
  readonly property real playerProgress: trackLength > 0
    ? Math.max(0, Math.min(1, displayPosition / trackLength)) : 0

  property real displayPosition: 0
  property int visualizerPhase: 0

  function playerKey() {
    return mediaService && activePlayer ? mediaService.playerKey(activePlayer) : ""
  }

  function action(name) {
    if (mediaService) mediaService.runAction(name, false, playerKey())
  }

  function syncPosition() {
    displayPosition = activePlayer && activePlayer.positionSupported
      ? Math.max(0, Number(activePlayer.position) || 0) : 0
  }

  function formatTime(seconds) {
    var value = Math.max(0, Math.floor(Number(seconds) || 0))
    var minutes = Math.floor(value / 60)
    var remainder = value % 60
    return minutes + ":" + (remainder < 10 ? "0" : "") + remainder
  }

  onActivePlayerChanged: syncPosition()
  onPlayerProgressChanged: progressArc.requestPaint()

  Timer {
    interval: 500
    repeat: true
    running: root.hasMedia
    onTriggered: root.syncPosition()
  }

  Timer {
    interval: 120
    repeat: true
    running: root.activePlayer && root.activePlayer.isPlaying
    onTriggered: root.visualizerPhase = (root.visualizerPhase + 1) % 360
  }

  color: Style.normalFillFor(bar.foreground, Color.accent)
  borderSpec: Border.controlSpec("normal", bar.foreground, Color.accent)
  radius: Style.cornerRadius * 1.7

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(5)

    Row {
      width: parent.width
      height: Style.space(24)

      Text {
        width: parent.width - cat.width
        text: root.hasMedia ? "NOW PLAYING" : "MEDIA"
        color: Color.accent
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.2
      }

      Text {
        id: cat
        text: "󰄛"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.iconLarge
        scale: root.activePlayer && root.activePlayer.isPlaying ? 1.05 : 1

        SequentialAnimation on rotation {
          running: root.activePlayer && root.activePlayer.isPlaying
          loops: Animation.Infinite
          NumberAnimation { from: -5; to: 5; duration: 600; easing.type: Easing.InOutSine }
          NumberAnimation { from: 5; to: -5; duration: 600; easing.type: Easing.InOutSine }
        }
      }
    }

    Item {
      id: coverStage
      width: parent.width
      height: Style.space(150)

      Canvas {
        id: progressArc
        anchors.centerIn: parent
        width: Style.space(144)
        height: width

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var center = width / 2
          var radius = center - Style.space(5)
          ctx.lineWidth = Math.max(2, Style.space(3))
          ctx.lineCap = "round"
          ctx.strokeStyle = Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.16)
          ctx.beginPath()
          ctx.arc(center, center, radius, 0, Math.PI * 2)
          ctx.stroke()
          ctx.strokeStyle = Color.accent
          ctx.beginPath()
          ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * root.playerProgress)
          ctx.stroke()
        }
      }

      Repeater {
        model: 28

        Rectangle {
          required property int index
          readonly property real angle: (index / 28) * Math.PI * 2
          readonly property real pulse: root.activePlayer && root.activePlayer.isPlaying
            ? (Math.sin(root.visualizerPhase * 0.18 + index * 1.41) + 1) / 2 : 0.12
          width: Math.max(1, Style.space(2))
          height: Style.space(3) + pulse * Style.space(6)
          radius: width / 2
          color: Color.accent
          opacity: 0.25 + pulse * 0.5
          x: coverStage.width / 2 + Math.cos(angle) * Style.space(66) - width / 2
          y: coverStage.height / 2 + Math.sin(angle) * Style.space(66) - height / 2
          rotation: index * (360 / 28) + 90
          transformOrigin: Item.Center
        }
      }

      Rectangle {
        id: coverFrame
        anchors.centerIn: parent
        width: Style.space(112)
        height: width
        radius: width / 2
        color: Style.selectedFillFor(root.bar.foreground, Color.accent)
        border.width: Math.max(1, Style.space(2))
        border.color: Color.accent
      }

      Rectangle {
        id: coverMask
        anchors.centerIn: parent
        width: coverFrame.width - Style.space(6)
        height: width
        radius: width / 2
        color: "white"
        visible: false
        layer.enabled: true
      }

      Item {
        anchors.centerIn: parent
        width: coverMask.width
        height: coverMask.height
        visible: root.artUrl !== ""
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: coverMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.02
        }

        Image {
          anchors.fill: parent
          source: root.artUrl
          asynchronous: true
          fillMode: Image.PreserveAspectCrop
          smooth: true
          mipmap: true
        }
      }

      Text {
        anchors.centerIn: parent
        visible: root.artUrl === ""
        text: "󰝚"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.displayLarge
      }
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignHCenter
      text: root.title
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.subtitle
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignHCenter
      text: root.album !== "" ? root.album : root.artist
      color: Color.accent
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.album !== ""
      textFormat: Text.PlainText
      horizontalAlignment: Text.AlignHCenter
      text: root.artist
      color: Qt.darker(root.bar.foreground, 1.4)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(6)

      Button {
        iconText: "󰒮"
        foreground: root.bar.foreground
        enabled: root.activePlayer && root.activePlayer.canGoPrevious
        opacity: enabled ? 1 : 0.35
        onClicked: root.action("previous")
      }

      Button {
        iconText: root.playIcon
        foreground: root.bar.foreground
        background: Style.selectedFillFor(root.bar.foreground, Color.accent)
        iconSize: Style.font.iconLarge
        horizontalPadding: Style.spacing.panelGap
        enabled: root.activePlayer !== null
        opacity: enabled ? 1 : 0.35
        onClicked: root.action("playPause")
      }

      Button {
        iconText: "󰒭"
        foreground: root.bar.foreground
        enabled: root.activePlayer && root.activePlayer.canGoNext
        opacity: enabled ? 1 : 0.35
        onClicked: root.action("next")
      }
    }

    Column {
      width: parent.width
      spacing: 0
      visible: root.hasMedia && root.trackLength > 0

      PanelSlider {
        bar: root.bar
        width: parent.width
        minimum: 0
        maximum: Math.max(1, root.trackLength)
        step: 5
        value: Math.min(root.displayPosition, maximum)
        knobSize: Style.space(10)
        onMoved: function(value) { root.displayPosition = value }
        onReleased: function(value) {
          if (root.activePlayer && root.activePlayer.positionSupported && root.activePlayer.canSeek)
            root.activePlayer.position = value
        }
      }

      Row {
        width: parent.width

        Text {
          id: elapsed
          text: root.formatTime(root.displayPosition)
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }

        Item { width: parent.width - elapsed.width - duration.width; height: 1 }

        Text {
          id: duration
          text: root.formatTime(root.trackLength)
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    Row {
      width: parent.width
      spacing: Style.space(6)
      visible: root.activePlayer && root.activePlayer.volumeSupported

      Text {
        text: root.playerVolume <= 0.01 ? "󰝟" : "󰕾"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.bodySmall
        anchors.verticalCenter: parent.verticalCenter
      }

      PanelSlider {
        bar: root.bar
        width: parent.width - Style.space(55)
        minimum: 0
        maximum: 1
        step: 0.05
        value: root.playerVolume
        knobSize: Style.space(10)
        onMoved: function(value) {
          if (root.activePlayer && root.activePlayer.volumeSupported)
            root.activePlayer.volume = value
        }
      }

      Text {
        width: Style.space(32)
        text: Math.round(root.playerVolume * 100) + "%"
        color: Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }
}
