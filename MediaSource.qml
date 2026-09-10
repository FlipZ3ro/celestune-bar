import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Self-contained MPRIS controller. The Omarchy shell only exposes its
// omarchy.media proxy to full-bar plugins and Indicators clones, so this
// bar-widget plugin reads Quickshell's Mpris service directly instead.
// It exposes the same members the dashboard consumes: activePlayer,
// playerKey(player) and runAction(action, showFeedback, key).
Item {
  id: root

  width: 0
  height: 0
  visible: false

  property string preferredPlayerKey: ""

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
  readonly property var playbackStreams: {
    var list = []
    for (var i = 0; i < nodes.length; i++) {
      var n = nodes[i]
      if (n && n.isStream && isPlaybackStream(n) && n.audio) list.push(n)
    }
    return list
  }
  readonly property var activePlayer: selectActivePlayer()

  PwObjectTracker { objects: root.playbackStreams }

  function isProxyPlayer(player) {
    var dbusName = String(player && player.dbusName || "").toLowerCase()
    var desktopEntry = String(player && player.desktopEntry || "").toLowerCase()
    return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld"
  }

  function hasTrackMetadata(player) {
    return !!(player && (player.trackTitle || player.trackArtist || player.trackAlbum || player.trackArtUrl))
  }

  function canControl(player) {
    return !!(player && (player.canTogglePlaying || player.canPlay || player.canPause
      || player.canGoNext || player.canGoPrevious))
  }

  function playerKey(player) {
    if (!player) return ""
    return String(player.dbusName || player.desktopEntry || player.identity || "")
  }

  function playerForKey(key) {
    if (!key) return null
    for (var i = 0; i < players.length; i++) {
      if (playerKey(players[i]) === key) return players[i]
    }
    return null
  }

  // Players that currently hold an audio stream are the ones the user was
  // actually listening to; prefer them when nothing is playing.
  function isPlaybackStream(node) {
    if (!node || !node.isStream) return false
    if (node.isSink === true) return true
    var mediaClass = String(node.type || "")
    return mediaClass.indexOf("Stream/Output/Audio") !== -1
      || mediaClass.indexOf("AudioOutStream") !== -1
      || mediaClass.indexOf("Output") !== -1
  }

  function streamLabelKey(label) {
    var key = String(label || "").toLowerCase()
    key = key.replace(/^pipewire alsa \[/, "")
    key = key.replace(/\]$/, "")
    key = key.replace(/^alsa playback \[/, "")
    key = key.replace(/[^a-z0-9]+/g, "")
    return key
  }

  function rawStreamLabel(node) {
    if (!node) return ""
    var p = node.ready && node.properties ? node.properties : {}
    return p["application.name"] || node.description || p["media.name"] || p["node.name"] || node.name
  }

  function playerAppLabel(player) {
    if (!player) return ""
    var dbus = String(player.dbusName || "")
    dbus = dbus.replace(/^org\.mpris\.MediaPlayer2\./, "")
    dbus = dbus.replace(/\.instance[0-9]+$/, "")
    return player.desktopEntry || player.identity || dbus
  }

  function playerHasPlaybackStream(player) {
    var key = streamLabelKey(playerAppLabel(player))
    if (!key) return false
    var streams = playbackStreams
    for (var i = 0; i < streams.length; i++) {
      var streamKey = streamLabelKey(rawStreamLabel(streams[i]))
      if (!streamKey) continue
      if (streamKey === key || streamKey.indexOf(key) !== -1 || key.indexOf(streamKey) !== -1)
        return true
    }
    return false
  }

  function selectActivePlayer() {
    var playingWithTrack = null
    var playing = null
    var withStream = null
    var withTrack = null
    var controllable = null

    for (var i = 0; i < players.length; i++) {
      var p = players[i]
      if (!p) continue
      var proxy = isProxyPlayer(p)
      var track = hasTrackMetadata(p)

      if (p.isPlaying) {
        if (!proxy && track && !playingWithTrack) playingWithTrack = p
        else if (!playing) playing = p
      }
      if (!proxy && !withStream && playerHasPlaybackStream(p)) withStream = p
      if (!proxy && track && !withTrack) withTrack = p
      if (canControl(p) && !controllable) controllable = p
    }

    var preferred = playerForKey(preferredPlayerKey)
    return playingWithTrack || playing || withStream || preferred || withTrack || controllable || null
  }

  function runAction(action, showFeedback, key) {
    var player = playerForKey(key) || activePlayer
    if (!player) return false

    var handled = false
    if (action === "next") {
      if (player.canGoNext) { player.next(); handled = true }
    } else if (action === "previous") {
      if (player.canGoPrevious) { player.previous(); handled = true }
    } else if (action === "play") {
      if (player.canPlay) { player.play(); handled = true }
      else if (player.canTogglePlaying && !player.isPlaying) { player.togglePlaying(); handled = true }
    } else if (action === "pause") {
      if (player.canPause) { player.pause(); handled = true }
      else if (player.canTogglePlaying && player.isPlaying) { player.togglePlaying(); handled = true }
    } else if (action === "playPause") {
      if (player.isPlaying && player.canPause) { player.pause(); handled = true }
      else if (!player.isPlaying && player.canPlay) { player.play(); handled = true }
      else if (player.canTogglePlaying) { player.togglePlaying(); handled = true }
    }

    if (handled) preferredPlayerKey = playerKey(player)
    return handled
  }
}
