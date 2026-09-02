import QtQuick
import qs.Commons

Item {
  id: root

  required property QtObject bar
  property var weather: null
  property var mediaService: null
  property date now: new Date()

  implicitWidth: Style.space(760)
  implicitHeight: Style.space(420)

  Row {
    anchors.fill: parent
    spacing: Style.space(12)

    Column {
      width: parent.width - mediaCard.width - parent.spacing
      height: parent.height
      spacing: Style.space(12)

      WeatherCard {
        width: parent.width
        height: Style.space(132)
        bar: root.bar
        weather: root.weather
        now: root.now
      }

      CalendarCard {
        width: parent.width
        height: parent.height - Style.space(144)
        bar: root.bar
      }
    }

    MediaCard {
      id: mediaCard
      width: Style.space(270)
      height: parent.height
      bar: root.bar
      mediaService: root.mediaService
    }
  }
}
