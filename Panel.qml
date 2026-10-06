import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "jacueblol.wallpaper-library"
  ipcTarget: "jacueblol.wallpaper-library"

  readonly property string helper: String(Qt.resolvedUrl("wallpaper-library")).replace(/^file:\/\//, "")
  readonly property string libraryDir: String(setting("libraryDir", "~/.config/omarchy/wallpapers/dharmx-walls-source"))
  readonly property string wallIcon: "󰸉"

  property var categories: []
  readonly property int total: categories.reduce(function(sum, c) { return sum + c.count }, 0)

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  function run(args) {
    root.close()
    Util.execArgv(["env", "WALLPAPER_LIBRARY_DIR=" + root.libraryDir, root.helper].concat(args))
  }

  onOpenedChanged: if (opened) refresh()
  onLibraryDirChanged: refresh()
  Component.onCompleted: refresh()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: listProc
    command: ["env", "WALLPAPER_LIBRARY_DIR=" + root.libraryDir, root.helper, "list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.categories = JSON.parse(text) } catch (e) { root.categories = [] }
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.wallIcon
    tooltipText: "Wallpaper Library"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: root.wallIcon
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.display
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              text: "Wallpaper Library"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: (root.categories.length + " categories · " + root.total + " walls").toUpperCase()
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }
        }

        Button {
          width: parent.width
          iconText: "󰒝"
          iconSize: Style.font.title
          text: "Random wallpaper"
          fontSize: Style.font.bodySmall
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
          bordered: true
          enabled: root.categories.length > 0
          onClicked: root.run(["random"])
        }

        PanelSeparator { foreground: root.bar.foreground }

        Text {
          visible: root.categories.length === 0
          width: parent.width
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
          text: "No categories found in " + root.libraryDir
          color: root.bar.foreground
          opacity: 0.6
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        // Categories, scrollable once the list outgrows the panel.
        Flickable {
          id: list
          visible: root.categories.length > 0
          width: parent.width
          height: Math.min(grid.implicitHeight, Style.space(460))
          contentHeight: grid.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Grid {
            id: grid
            width: list.width
            columns: 2
            columnSpacing: Style.space(6)
            rowSpacing: Style.space(4)

            Repeater {
              model: root.categories

              Button {
                required property var modelData
                width: (grid.width - grid.columnSpacing) / 2
                leftAlign: true
                text: modelData.label + "  " + modelData.count
                fontSize: Style.font.bodySmall
                foreground: root.bar.foreground
                fontFamily: root.bar.fontFamily
                onClicked: root.run(["pick", modelData.id])
              }
            }
          }
        }
      }
    }
  }
}
