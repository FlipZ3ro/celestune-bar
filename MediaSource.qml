import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

// Normal bar widgets cannot access Omarchy's private media service on
// Omarchy 4, so Celestune reads the same MPRIS and PipeWire data directly.
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
      var node = nodes[i]
      if (node && node.isStream && isPlaybackStream(node) && node.audio)
        list.push(node)
    }
    return list
  }
  readonly property var activePlayer: selectActivePlayer()
  readonly property var activePlaybackStream: playbackStreamForPlayer(activePlayer)
  readonly property bool volumeSupported: !!(activePlaybackStream && activePlaybackStream.audio)
    || !!(activePlayer && activePlayer.volumeSupported)
  readonly property real volume: {
    if (activePlaybackStream && activePlaybackStream.audio)
      return Math.max(0, Math.min(1, Number(activePlaybackStream.audio.volume) || 0))
    if (activePlayer && activePlayer.volumeSupported)
      return Math.max(0, Math.min(1, Number(activePlayer.volume) || 0))
    return 0
  }

  PwObjectTracker {
    objects: root.playbackStreams
  }

  function isProxyPlayer(player) {
    var dbusName = String(player && player.dbusName || "").toLowerCase()
    var desktopEntry = String(player && player.desktopEntry || "").toLowerCase()
    return dbusName.indexOf("playerctld") !== -1 || desktopEntry === "playerctld"
  }

  function hasTrackMetadata(player) {
    return !!(player && (player.trackTitle || player.trackArtist
      || player.trackAlbum || player.trackArtUrl))
  }

  function canControl(player) {
    return !!(player && (player.canTogglePlaying || player.canPlay
      || player.canPause || player.canGoNext || player.canGoPrevious))
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
    return key.replace(/[^a-z0-9]+/g, "")
  }

  function rawStreamLabel(node) {
    if (!node) return ""
    var properties = node.ready && node.properties ? node.properties : {}
    return properties["application.name"] || node.description
      || properties["media.name"] || properties["node.name"] || node.name
  }

  function playerAppLabel(player) {
    if (!player) return ""
    var dbusName = String(player.dbusName || "")
      .replace(/^org\.mpris\.MediaPlayer2\./, "")
      .replace(/\.instance[0-9]+$/, "")
    return player.desktopEntry || player.identity || dbusName
  }

  function playerHasPlaybackStream(player) {
    return playbackStreamForPlayer(player) !== null
  }

  function playbackStreamForPlayer(player) {
    var key = streamLabelKey(playerAppLabel(player))
    if (!key) return null

    for (var i = 0; i < playbackStreams.length; i++) {
      var streamKey = streamLabelKey(rawStreamLabel(playbackStreams[i]))
      if (streamKey && (streamKey === key || streamKey.indexOf(key) !== -1
          || key.indexOf(streamKey) !== -1))
        return playbackStreams[i]
    }
    return null
  }

  function setVolume(value) {
    var next = Math.max(0, Math.min(1, Number(value) || 0))
    if (activePlaybackStream && activePlaybackStream.audio) {
      activePlaybackStream.audio.volume = next
      return true
    }
    if (activePlayer && activePlayer.volumeSupported) {
      activePlayer.volume = next
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
      var player = players[i]
      if (!player) continue

      var proxy = isProxyPlayer(player)
      var track = hasTrackMetadata(player)
      if (player.isPlaying) {
        if (!proxy && track && !playingWithTrack) playingWithTrack = player
        else if (!playing) playing = player
      }
      if (!proxy && !withStream && playerHasPlaybackStream(player)) withStream = player
      if (!proxy && track && !withTrack) withTrack = player
      if (!controllable && canControl(player)) controllable = player
    }

    return playingWithTrack || playing || withStream
      || playerForKey(preferredPlayerKey) || withTrack || controllable || null
  }

  function runAction(action, showFeedback, key) {
    var player = playerForKey(key) || activePlayer
    if (!player) return false

    var handled = false
    if (action === "next" && player.canGoNext) {
      player.next()
      handled = true
    } else if (action === "previous" && player.canGoPrevious) {
      player.previous()
      handled = true
    } else if (action === "play") {
      if (player.canPlay) {
        player.play()
        handled = true
      } else if (player.canTogglePlaying && !player.isPlaying) {
        player.togglePlaying()
        handled = true
      }
    } else if (action === "pause") {
      if (player.canPause) {
        player.pause()
        handled = true
      } else if (player.canTogglePlaying && player.isPlaying) {
        player.togglePlaying()
        handled = true
      }
    } else if (action === "playPause") {
      if (player.isPlaying && player.canPause) {
        player.pause()
        handled = true
      } else if (!player.isPlaying && player.canPlay) {
        player.play()
        handled = true
      } else if (player.canTogglePlaying) {
        player.togglePlaying()
        handled = true
      }
    }

    if (handled) preferredPlayerKey = playerKey(player)
    return handled
  }
}
