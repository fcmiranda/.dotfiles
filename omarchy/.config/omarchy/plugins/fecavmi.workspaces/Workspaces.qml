import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "fecavmi.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id || values[i].name === String(id) || (id === 0 && (values[i].name === "0" || values[i].name === "name:0"))) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [0, 1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var w = values[i]
      var id = w.id
      if ((w.name === "0" || w.name === "name:0" || id === 0) && ids.indexOf(0) === -1) {
        ids.push(0)
      } else if (id > 0 && id <= 10 && ids.indexOf(id) === -1) {
        ids.push(id)
      }
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    var target = (id === 0) ? "name:0" : String(id)
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + target + "\" })"))
  }

  function iconForToplevel(toplevel) {
    if (!toplevel) return ""

    var cls = ""
    var title = ""

    // 1. Try lastIpcObject (Hyprland IPC JSON properties)
    if (toplevel.lastIpcObject) {
      if (toplevel.lastIpcObject["class"]) cls = String(toplevel.lastIpcObject["class"])
      else if (toplevel.lastIpcObject.initialClass) cls = String(toplevel.lastIpcObject.initialClass)
      if (toplevel.lastIpcObject.title) title = String(toplevel.lastIpcObject.title)
      else if (toplevel.lastIpcObject.initialTitle) title = String(toplevel.lastIpcObject.initialTitle)
    }

    // 2. Try waylandHandle (Wayland toplevel)
    if (!cls && toplevel.waylandHandle) {
      if (toplevel.waylandHandle.appId) cls = String(toplevel.waylandHandle.appId)
      if (!title && toplevel.waylandHandle.title) title = String(toplevel.waylandHandle.title)
    }

    // 3. Direct properties on toplevel
    if (!cls) {
      if (toplevel.appId) cls = String(toplevel.appId)
      else if (toplevel.waylandClass) cls = String(toplevel.waylandClass)
      else if (toplevel.initialClass) cls = String(toplevel.initialClass)
      else if (toplevel.cls) cls = String(toplevel.cls)
      else if (toplevel.klass) cls = String(toplevel.klass)
      else if (toplevel["class"]) cls = String(toplevel["class"])
    }

    if (!title) {
      if (toplevel.title) title = String(toplevel.title)
      else if (toplevel.initialTitle) title = String(toplevel.initialTitle)
    }

    cls = cls.toLowerCase()

    // 1. Title matches (webapps & special titles)
    if (title.indexOf("YouTube") !== -1) return "󰗃"
    if (title.indexOf("Google Photos") !== -1) return "󰋩"
    if (title.indexOf("GitHub") !== -1) return "󰊤"
    if (title.indexOf("ChatGPT") !== -1) return "󰚩"
    if (title.indexOf("Grok") !== -1) return "󰚩"
    if (title.indexOf("WhatsApp") !== -1) return "󰖣"
    if (title.indexOf("Google Messages") !== -1) return "󰭹"
    if (title.indexOf("is sharing your screen") !== -1) return "󰹑"

    // 2. Class matches (from legacy waybar config ca80b30d422cd30a19acf0843f144d4d10b07625)
    // Terminals
    if (cls.indexOf("ghostty") !== -1) return ""
    if (cls.indexOf("kitty") !== -1) return ""
    if (cls.indexOf("foot") !== -1) return ""
    if (cls.indexOf("alacritty") !== -1) return ""
    if (cls.indexOf("agent") !== -1) return "󱚤"

    // Browsers
    if (cls.indexOf("google-chrome") !== -1 || cls.indexOf("chrome") !== -1) return ""
    if (cls.indexOf("chromium") !== -1) return ""
    if (cls.indexOf("brave") !== -1) return ""
    if (cls.indexOf("firefox") !== -1) return ""
    if (cls.indexOf("librewolf") !== -1) return ""
    if (cls.indexOf("zen") !== -1) return ""

    // Editors & IDEs
    if (cls.indexOf("antigravity") !== -1) return "󰲇"
    if (cls.indexOf("code") !== -1 || cls.indexOf("vscode") !== -1) return ""
    if (cls.indexOf("nvim") !== -1 || cls.indexOf("neovim") !== -1) return ""
    if (cls.indexOf("typora") !== -1) return "󰈙"
    if (cls.indexOf("obsidian") !== -1) return "󰈙"
    if (cls.indexOf("writer") !== -1) return "󰈙"

    // Communication
    if (cls.indexOf("vesktop") !== -1 || cls.indexOf("discord") !== -1) return ""
    if (cls.indexOf("signal") !== -1) return "󰭹"
    if (cls.indexOf("telegram") !== -1) return ""
    if (cls.indexOf("thunderbird") !== -1) return ""

    // Media
    if (cls.indexOf("spotify") !== -1) return ""
    if (cls.indexOf("steam") !== -1) return ""
    if (cls.indexOf("vlc") !== -1) return "󰕼"
    if (cls.indexOf("mpv") !== -1) return ""

    // Files
    if (cls.indexOf("nautilus") !== -1 || cls.indexOf("dolphin") !== -1 || cls.indexOf("thunar") !== -1 || cls.indexOf("yazi") !== -1) return ""

    // Omarchy Tools & System
    if (cls.indexOf("impala") !== -1) return "󰤨"
    if (cls.indexOf("bluetui") !== -1) return "󰂰"
    if (cls.indexOf("wiremix") !== -1) return "󰕾"
    if (cls.indexOf("btop") !== -1) return "󰍛"
    if (cls.indexOf("lazydocker") !== -1) return "󰡨"
    if (cls.indexOf("lazygit") !== -1) return "󰊢"

    // Fallback: title heuristics
    var titleLower = title.toLowerCase()
    if (titleLower.indexOf("chrome") !== -1 || titleLower.indexOf("google") !== -1) return ""
    if (titleLower.indexOf("ghostty") !== -1 || titleLower.indexOf("bash") !== -1 || titleLower.indexOf("zsh") !== -1) return ""
    if (titleLower.indexOf("antigravity") !== -1) return "󰲇"
    if (titleLower.indexOf("code") !== -1) return ""
    if (titleLower.indexOf("spotify") !== -1) return ""
    if (titleLower.indexOf("discord") !== -1) return ""

    // Generic window icon fallback
    return ""
  }

  function getWorkspaceLabel(workspace, id, focused) {
    if (!workspace || !workspace.toplevels || !workspace.toplevels.values || workspace.toplevels.values.length === 0) {
      return focused ? "\uDB85\uDCFB" : String(id)
    }

    var toplevels = workspace.toplevels.values
    var icons = []
    for (var i = 0; i < toplevels.length; i++) {
      var icon = root.iconForToplevel(toplevels[i])
      if (icon) icons.push(icon)
    }
    return icons.length > 0 ? icons.join(" ") : (focused ? "\uDB85\uDCFB" : String(id))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(3)
    rowSpacing: root.vertical ? Style.space(3) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: pillItem
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels && workspace.toplevels.values && workspace.toplevels.values.length > 0
        readonly property bool focused: {
          if (Hyprland.focusedWorkspace === null) return false
          if (Hyprland.focusedWorkspace.id === modelData) return true
          if (modelData === 0 && (Hyprland.focusedWorkspace.name === "0" || Hyprland.focusedWorkspace.name === "name:0")) return true
          return Hyprland.focusedWorkspace.name === String(modelData)
        }

        readonly property string labelText: root.getWorkspaceLabel(workspace, modelData, focused)

        implicitWidth: pillRect.implicitWidth
        implicitHeight: root.barSize

        Rectangle {
          id: pillRect
          anchors.verticalCenter: parent.verticalCenter
          height: root.barSize - 8
          radius: height / 2

          implicitWidth: Math.max(height, label.implicitWidth + 14)

          color: {
            if (focused) return Util.alpha(Color.accent, 0.22)
            if (mouseArea.containsMouse) return Util.alpha(Color.foreground, 0.12)
            if (occupied) return Util.alpha(Color.foreground, 0.06)
            return "transparent"
          }

          border.color: {
            if (focused) return Color.accent
            if (mouseArea.containsMouse) return Util.alpha(Color.foreground, 0.3)
            if (occupied) return Util.alpha(Color.foreground, 0.15)
            return "transparent"
          }
          border.width: focused ? 1.5 : (occupied ? 1 : 0)

          Behavior on color { ColorAnimation { duration: 140 } }
          Behavior on border.color { ColorAnimation { duration: 140 } }

          Text {
            id: label
            anchors.centerIn: parent
            text: pillItem.labelText
            color: focused ? Color.accent : (occupied ? (root.bar ? root.bar.barForeground : Color.foreground) : Util.alpha(Color.foreground, 0.45))
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: Style.font.body
            renderType: Text.NativeRendering
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter

            Behavior on color { ColorAnimation { duration: 140 } }
          }
        }

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: function() { root.focusWorkspace(pillItem.modelData) }
        }
      }
    }
  }
}
