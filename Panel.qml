import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "io.github.jacueblol.wallpaper-library"
  ipcTarget: "io.github.jacueblol.wallpaper-library"

  readonly property string helper: String(Qt.resolvedUrl("wallpaper-library")).replace(/^file:\/\//, "")
  // Empty means the helper's default (~/.config/omarchy/wallpapers/dharmx-walls).
  readonly property string libraryDir: String(setting("libraryDir", ""))
  readonly property var helperArgv: libraryDir ? ["env", "WALLPAPER_LIBRARY_DIR=" + libraryDir, helper] : [helper]
  readonly property string wallIcon: "󰸉"
  readonly property int columns: 3

  property var categories: []
  property var current: ({ path: "", category: "", name: "" })
  property bool loaded: false
  property bool libraryExists: true
  property string libraryPath: ""
  property string filterText: ""
  property int cursor: 0

  readonly property int total: categories.reduce(function(sum, c) { return sum + c.count }, 0)
  readonly property var shown: {
    var needle = filterText.trim().toLowerCase()
    if (!needle) return categories
    return categories.filter(function(c) { return c.label.toLowerCase().indexOf(needle) !== -1 })
  }
  readonly property var cursorCategory: shown.length > 0 ? shown[Math.min(cursor, shown.length - 1)] : null
  readonly property string currentLabel: {
    for (var i = 0; i < categories.length; i++)
      if (categories[i].id === current.category) return categories[i].label
    return ""
  }

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  function run(args) {
    root.close()
    Util.execArgv(root.helperArgv.concat(args))
  }

  // gum needs a terminal, so the downloader runs in Omarchy's floating one.
  function download() {
    root.close()
    Util.execArgv(["omarchy-launch-floating-terminal-with-presentation",
      root.helperArgv.map(Util.shellQuote).join(" ") + " download"])
  }

  function browse(category) { if (category) run(["pick", category.id]) }
  function randomFrom(category) { if (category) run(["random", category.id]) }
  function shuffle() { run(["random"]) }

  function moveCursor(dx, dy) {
    if (shown.length === 0) return
    var next = Math.max(0, Math.min(shown.length - 1, cursor + dx + dy * columns))
    if (dy < 0 && cursor < columns) { focusSearch(); return }
    cursor = next
    grid.ensureVisible(cursor)
  }

  // Start the cursor on the category holding the current wallpaper.
  function cursorToCurrent() {
    for (var i = 0; i < shown.length; i++) {
      if (shown[i].id === current.category) { cursor = i; grid.ensureVisible(i); return }
    }
    cursor = 0
  }

  function focusSearch() { search.forceActiveFocus() }
  function focusGrid() { keyCatcher.forceActiveFocus() }

  onOpenedChanged: {
    if (opened) {
      filterText = ""
      refresh()
    }
  }
  onFilterTextChanged: {
    if (search.text !== filterText) search.text = filterText
    cursor = 0
    list.contentY = 0
  }
  onLibraryDirChanged: refresh()
  Component.onCompleted: refresh()

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: listProc
    command: root.helperArgv.concat(["list"])
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text)
          root.categories = data.categories || []
          root.current = data.current || { path: "", category: "", name: "" }
          root.libraryExists = data.exists !== false
          root.libraryPath = data.library || ""
        } catch (e) {
          root.categories = []
        }
        root.loaded = true
        root.cursorToCurrent()
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.wallIcon
    tooltipText: root.currentLabel ? "Wallpaper Library · " + root.currentLabel : "Wallpaper Library"
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(600))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: search.activeFocus
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) { root.moveCursor(dx, dy) }
      onActivateRequested: root.browse(root.cursorCategory)
      onTextKey: function(t) {
        if (t === "/") root.focusSearch()
        else if (t === "r") root.randomFrom(root.cursorCategory)
        else if (t === "s") root.shuffle()
      }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // ---------- Hero: current wallpaper ----------
        Item {
          width: parent.width
          implicitHeight: preview.height

          Rectangle {
            id: preview
            width: Style.space(160)
            height: Math.round(width * 9 / 16)
            radius: Style.cornerRadius
            color: Util.alpha(root.bar.foreground, 0.08)
            clip: true

            Image {
              anchors.fill: parent
              source: root.current.path ? Util.fileUrl(root.current.path) : ""
              sourceSize.width: 480
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
            }
          }

          Column {
            anchors.left: preview.right
            anchors.leftMargin: Style.space(14)
            anchors.right: shuffleButton.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

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
              visible: root.current.name !== ""
              text: "NOW · " + (root.currentLabel ? root.currentLabel.toUpperCase() + " · " : "") + root.current.name.replace(/[_-]+/g, " ")
              color: Color.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              textFormat: Text.PlainText
              text: root.categories.length + " categories · " + root.total + " walls"
              color: root.bar.foreground
              opacity: 0.6
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Button {
            id: shuffleButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            iconText: "󰒝"
            iconSize: Style.font.title
            text: "Shuffle"
            tooltipText: "Random wallpaper from the whole library (s)"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            visible: root.categories.length > 0
            onClicked: root.shuffle()
          }
        }

        // ---------- Search ----------
        TextField {
          id: search
          visible: root.categories.length > 0
          width: parent.width
          placeholderText: "Search categories  ( / )"
          foreground: root.bar.foreground
          accent: Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          onTextEdited: root.filterText = text
          Keys.onEscapePressed: function(event) {
            if (root.filterText) root.filterText = ""
            root.focusGrid()
            event.accepted = true
          }
          Keys.onDownPressed: function(event) { root.focusGrid(); event.accepted = true }
          Keys.onReturnPressed: function(event) { root.browse(root.cursorCategory); event.accepted = true }
          Keys.onEnterPressed: function(event) { root.browse(root.cursorCategory); event.accepted = true }
        }

        // ---------- Empty / first-run states ----------
        Column {
          visible: root.shown.length === 0
          width: parent.width
          spacing: Style.space(10)
          topPadding: Style.space(16)
          bottomPadding: Style.space(16)

          readonly property bool needsLibrary: root.loaded && root.categories.length === 0

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: !root.loaded ? "Generating previews…"
              : !root.libraryExists ? "No wallpaper library yet"
              : root.categories.length === 0 ? "No categories with images in this folder"
              : "No categories match “" + root.filterText + "”"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: parent.needsLibrary ? Style.font.title : Style.font.bodySmall
            font.bold: parent.needsLibrary
            opacity: parent.needsLibrary ? 1 : 0.6
          }

          Text {
            visible: parent.needsLibrary
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: "Download categories from dharmx/walls into "
              + root.libraryPath.replace(Quickshell.env("HOME"), "~")
              + ", or set this widget's Library folder to any folder of category subfolders."
            color: root.bar.foreground
            opacity: 0.6
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          Button {
            visible: parent.needsLibrary
            anchors.horizontalCenter: parent.horizontalCenter
            iconText: "󰇚"
            iconSize: Style.font.title
            text: "Download wallpapers"
            fontSize: Style.font.bodySmall
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            verticalPadding: Style.spacing.controlPaddingY + Style.space(2)
            bordered: true
            onClicked: root.download()
          }
        }

        Flickable {
          id: list
          visible: root.shown.length > 0
          width: parent.width
          // Show three and a half rows so it's obvious the grid scrolls.
          height: Math.min(grid.implicitHeight, grid.tileHeight * 3.5 + grid.rowSpacing * 3)
          contentHeight: grid.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          Behavior on contentY { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

          Grid {
            id: grid
            width: list.width
            columns: root.columns
            columnSpacing: Style.space(8)
            rowSpacing: Style.space(8)

            readonly property real tileWidth: (width - columnSpacing * (columns - 1)) / columns
            readonly property real tileHeight: Math.round(tileWidth * 9 / 16)

            function ensureVisible(index) {
              var y = Math.floor(index / columns) * (tileHeight + rowSpacing)
              if (y < list.contentY) list.contentY = y
              else if (y + tileHeight > list.contentY + list.height) list.contentY = y + tileHeight - list.height
            }

            Repeater {
              model: root.shown

              Item {
                id: tile
                required property var modelData
                required property int index
                readonly property bool highlighted: root.cursor === index && !search.activeFocus
                readonly property bool isCurrent: modelData.id === root.current.category

                width: grid.tileWidth
                height: grid.tileHeight

                Rectangle {
                  anchors.fill: parent
                  radius: Style.cornerRadius
                  color: Util.alpha(root.bar.foreground, 0.08)
                  clip: true

                  Image {
                    anchors.fill: parent
                    source: Util.fileUrl(tile.modelData.cover)
                    sourceSize.width: 480
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: tile.highlighted || mouse.containsMouse ? 1 : 0.78
                    scale: tile.highlighted ? 1.04 : 1
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                  }

                  // Legibility gradient behind the label.
                  Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * 0.55
                    gradient: Gradient {
                      GradientStop { position: 0.0; color: "transparent" }
                      GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.78) }
                    }
                  }

                  Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: Style.space(8)
                    spacing: Style.space(6)

                    Text {
                      id: tileLabel
                      textFormat: Text.PlainText
                      text: tile.modelData.label
                      color: "white"
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.body
                      font.bold: true
                      elide: Text.ElideRight
                      width: Math.min(implicitWidth, parent.width - countLabel.implicitWidth - parent.spacing)
                    }

                    Text {
                      id: countLabel
                      anchors.baseline: tileLabel.baseline
                      textFormat: Text.PlainText
                      text: tile.modelData.count
                      color: "white"
                      opacity: 0.7
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }

                  // Marks the category the current wallpaper is from.
                  Rectangle {
                    visible: tile.isCurrent
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Style.space(8)
                    width: Style.space(8)
                    height: width
                    radius: width / 2
                    color: Color.accent
                  }
                }

                Rectangle {
                  anchors.fill: parent
                  radius: Style.cornerRadius
                  color: "transparent"
                  border.width: tile.highlighted || tile.isCurrent ? 2 : (mouse.containsMouse ? 1 : 0)
                  border.color: tile.highlighted ? root.bar.foreground
                    : tile.isCurrent ? Color.accent
                    : Util.alpha(root.bar.foreground, 0.5)
                }

                MouseArea {
                  id: mouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  acceptedButtons: Qt.LeftButton | Qt.RightButton
                  onEntered: root.cursor = tile.index
                  onClicked: function(event) {
                    if (event.button === Qt.RightButton) root.randomFrom(tile.modelData)
                    else root.browse(tile.modelData)
                  }
                }
              }
            }
          }
        }

        // ---------- Key hints ----------
        Text {
          visible: root.categories.length > 0
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          textFormat: Text.PlainText
          text: "↵ browse  ·  r random from category  ·  right-click random  ·  s shuffle  ·  / search"
          color: root.bar.foreground
          opacity: 0.45
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
