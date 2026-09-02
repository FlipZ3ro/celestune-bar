import QtQuick
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  required property QtObject bar
  property date shownDate: new Date()

  function changeMonth(delta) {
    shownDate = new Date(shownDate.getFullYear(), shownDate.getMonth() + delta, 1)
  }

  function resetToday() {
    shownDate = new Date()
  }

  color: Style.normalFillFor(bar.foreground, Color.accent)
  borderSpec: Border.controlSpec("normal", bar.foreground, Color.accent)
  radius: Style.cornerRadius * 1.35

  Column {
    anchors.fill: parent
    anchors.margins: Style.space(14)
    spacing: Style.space(3)

    Row {
      width: parent.width
      height: Style.space(30)

      Button {
        iconText: "󰅁"
        foreground: root.bar.foreground
        horizontalPadding: Style.spacing.controlPaddingY
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.changeMonth(-1)
      }

      Item {
        width: parent.width - Style.space(64)
        height: parent.height

        Text {
          anchors.centerIn: parent
          text: Qt.formatDate(root.shownDate, "MMMM yyyy")
          color: Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.resetToday()
          }
        }
      }

      Button {
        iconText: "󰅂"
        foreground: root.bar.foreground
        horizontalPadding: Style.spacing.controlPaddingY
        verticalPadding: Style.spacing.controlPaddingY
        onClicked: root.changeMonth(1)
      }
    }

    QQC.DayOfWeekRow {
      id: daysRow
      width: parent.width
      height: Style.space(24)
      locale: monthGrid.locale

      delegate: Text {
        required property var model
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: model.shortName.slice(0, 2).toUpperCase()
        color: model.day === 0 || model.day === 6
          ? Color.accent : Qt.darker(root.bar.foreground, 1.35)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
      }
    }

    QQC.MonthGrid {
      id: monthGrid
      width: parent.width
      height: parent.height - Style.space(60)
      month: root.shownDate.getMonth()
      year: root.shownDate.getFullYear()
      locale: Qt.locale()
      spacing: Style.space(2)

      delegate: Item {
        id: dayCell
        required property var model

        implicitWidth: Style.space(48)
        implicitHeight: Style.space(27)
        opacity: model.month === monthGrid.month || model.today ? 1 : 0.32

        Rectangle {
          anchors.centerIn: parent
          width: Style.space(26)
          height: width
          radius: width / 2
          visible: dayCell.model.today
          color: Color.accent
        }

        Text {
          anchors.centerIn: parent
          text: dayCell.model.day
          color: dayCell.model.today ? Color.background
            : (dayCell.model.date.getDay() === 0 || dayCell.model.date.getDay() === 6
                ? Color.accent : root.bar.foreground)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: dayCell.model.today
        }
      }
    }
  }
}
