import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
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

  readonly property var defaultNerdFontGlyphs: ({
    "com.mitchellh.ghostty": "",
    "ghostty": "",
    "kitty": "",
    "foot": "",
    "alacritty": "",
    "agent": "󱚤",
    "google-chrome": "",
    "chrome": "",
    "firefox": "",
    "zen": "",
    "zen-browser": "",
    "antigravity-ide": "󰲇",
    "antigravity": "󰲇",
    "vscode": "",
    "code": "",
    "nvim": "",
    "obsidian": "󰈙",
    "discord": "",
    "vesktop": "",
    "signal": "󰭹",
    "signal-desktop": "󰭹",
    "telegram": "",
    "thunderbird": "",
    "spotify": "",
    "steam": "",
    "vlc": "󰕼",
    "mpv": "",
    "system-file-manager": "",
    "nautilus": "",
    "thunar": "",
    "yazi": "",
    "youtube": "󰗃",
    "google-photos": "󰋩",
    "github": "󰊤",
    "whatsapp": "󰖣",
    "chatgpt": "󰚩",
    "grok": "󰚩",
    "google messages": "󰭹",
    "linkedin": "󰌻"
  })

  function getGlyphOrFallback(data) {
    if (!data) return ""
    var s = String(data)
    if (s.indexOf("app:") === 0) {
      var appName = s.substring(4).toLowerCase()
      if (root.defaultNerdFontGlyphs[appName]) return root.defaultNerdFontGlyphs[appName]
      return ""
    }
    if (s.indexOf("svg:") === 0 || s.indexOf("/") === 0) return ""
    return s
  }

  function getIconSpec(val) {
    if (!val) return { icon: "", brightness: 0.0, contrast: 0.6 }
    if (typeof val === "object" && val.icon) {
      return {
        icon: val.icon,
        brightness: (typeof val.brightness === "number") ? val.brightness : 0.0,
        contrast: (typeof val.contrast === "number") ? val.contrast : 0.6
      }
    }
    return { icon: String(val), brightness: 0.0, contrast: 0.6 }
  }

  function resolveIconSource(icon) {
    if (!icon) return ""
    var s = String(icon)
    if (s.indexOf("app:") === 0) {
      var appName = s.substring(4)

      // Direct Papirus SVG mapping exclusively for dedicated vector apps
      if (appName === "ghostty" || appName === "com.mitchellh.ghostty") {
        return "/usr/share/icons/Papirus/32x32/apps/com.mitchellh.ghostty.svg"
      }
      if (appName === "kitty") {
        return "/usr/share/icons/Papirus/32x32/apps/kitty.svg"
      }
      if (appName === "antigravity" || appName === "antigravity-ide") {
        return "/usr/share/icons/Papirus/32x32/apps/antigravity.svg"
      }

      return ""
    }
    if (s.indexOf("svg:") === 0) {
      return s.substring(4)
    }
    if (s.indexOf("/") === 0 || s.indexOf("file://") === 0) {
      return s
    }
    return ""
  }

  readonly property var titleRules: [
    { patterns: ["youtube"],                                 icon: "󰗃" },
    { patterns: ["google photos"],                          icon: "󰋩" },
    { patterns: [
        "github", "github.io", "github.com",
        "/ repositories", "/ stars", "/ followers", "/ following", "/ projects", "/ packages",
        "pull request", "pull requests", "issues ·", "issue #", "commits ·", "commit ·",
        "releases ·", "release ·", "actions ·"
      ],                                                     icon: "󰊤" },
    { patterns: ["linkedin"],                               icon: "󰌻" },
    { patterns: ["chatgpt", "grok"],                        icon: "󰚩" },
    { patterns: ["whatsapp"],                               icon: "󰖣" },
    { patterns: ["google messages"],                        icon: "󰭹" },
    { patterns: ["is sharing your screen"],                 icon: "󰹑" }
  ]

  readonly property var classRules: [
    // Terminals (Theme-Aware SVGs for Ghostty and Kitty)
    { patterns: ["ghostty"],                                icon: "app:com.mitchellh.ghostty" },
    { patterns: ["kitty"],                                  icon: "app:kitty", brightness: 0.80, contrast: 1.0 },
    { patterns: ["foot", "alacritty"],                      icon: "" },
    { patterns: ["agent"],                                  icon: "󱚤" },

    // Browsers (Nerd Font Glyphs)
    { patterns: ["google-chrome", "chrome", "chromium", "brave"], icon: "" },
    { patterns: ["firefox", "librewolf", "zen"],            icon: "" },

    // Editors & IDEs (Antigravity with custom brightness & contrast)
    { patterns: ["antigravity"],                            icon: "app:antigravity", brightness: 0.80, contrast: 1.0 },
    { patterns: ["code", "vscode"],                         icon: "" },
    { patterns: ["nvim", "neovim"],                         icon: "" },
    { patterns: ["typora", "obsidian", "writer"],           icon: "󰈙" },

    // Communication
    { patterns: ["vesktop", "discord"],                     icon: "" },
    { patterns: ["signal"],                                 icon: "󰭹" },
    { patterns: ["telegram"],                               icon: "" },
    { patterns: ["thunderbird"],                            icon: "" },

    // Media
    { patterns: ["spotify"],                                icon: "" },
    { patterns: ["steam"],                                  icon: "" },
    { patterns: ["vlc"],                                    icon: "󰕼" },
    { patterns: ["mpv"],                                    icon: "" },

    // Files
    { patterns: ["nautilus", "dolphin", "thunar", "yazi"],  icon: "" },

    // Omarchy Tools & System
    { patterns: ["impala"],                                 icon: "󰤨" },
    { patterns: ["bluetui"],                                icon: "󰂰" },
    { patterns: ["wiremix"],                                icon: "󰕾" },
    { patterns: ["btop"],                                   icon: "󰍛" },
    { patterns: ["lazydocker"],                             icon: "󰡨" },
    { patterns: ["lazygit"],                                icon: "󰊢" }
  ]

  readonly property var titleFallbackRules: [
    { patterns: ["chrome", "google"],                       icon: "" },
    { patterns: ["ghostty"],                                icon: "app:com.mitchellh.ghostty" },
    { patterns: ["kitty"],                                  icon: "app:kitty", brightness: 0.80, contrast: 1.0 },
    { patterns: ["bash", "zsh"],                            icon: "" },
    { patterns: ["antigravity"],                            icon: "app:antigravity", brightness: 0.80, contrast: 1.0 },
    { patterns: ["code"],                                   icon: "" },
    { patterns: ["spotify"],                                icon: "" },
    { patterns: ["discord"],                                icon: "" }
  ]

  function matchRule(rules, target) {
    if (!target) return null
    for (var i = 0; i < rules.length; i++) {
      var rule = rules[i]
      for (var j = 0; j < rule.patterns.length; j++) {
        if (target.indexOf(rule.patterns[j]) !== -1) {
          return {
            icon: rule.icon,
            brightness: (typeof rule.brightness === "number") ? rule.brightness : 0.0,
            contrast: (typeof rule.contrast === "number") ? rule.contrast : 1.0
          }
        }
      }
    }
    return null
  }

  function iconForToplevel(toplevel) {
    if (!toplevel) return { icon: "", brightness: 0.0, contrast: 1.0 }

    var cls = ""
    var title = ""

    // 1. Try wayland (Wayland toplevel instance for this exact window)
    var wlHandle = toplevel.wayland || toplevel.waylandHandle
    if (wlHandle) {
      if (wlHandle.appId) cls = String(wlHandle.appId)
      if (wlHandle.title) title = String(wlHandle.title)
    }

    // 2. Try direct properties on toplevel
    if (!cls) {
      if (toplevel.appId) cls = String(toplevel.appId)
      else if (toplevel.waylandClass) cls = String(toplevel.waylandClass)
      else if (toplevel.initialClass) cls = String(toplevel.initialClass)
      else if (toplevel.cls) cls = String(toplevel.cls)
      else if (toplevel.klass) cls = String(toplevel.klass)
      else if (toplevel["class"]) cls = String(toplevel["class"])
    }

    if (!title && toplevel.title) {
      title = String(toplevel.title)
    }

    // 3. Try lastIpcObject (Hyprland IPC JSON properties)
    if (toplevel.lastIpcObject) {
      if (!cls) {
        if (toplevel.lastIpcObject["class"]) cls = String(toplevel.lastIpcObject["class"])
        else if (toplevel.lastIpcObject.initialClass) cls = String(toplevel.lastIpcObject.initialClass)
      }
      if (!title) {
        if (toplevel.lastIpcObject.title) title = String(toplevel.lastIpcObject.title)
        else if (toplevel.lastIpcObject.initialTitle) title = String(toplevel.lastIpcObject.initialTitle)
      }
    }

    if (!title && toplevel.initialTitle) {
      title = String(toplevel.initialTitle)
    }

    // 4. Only if this EXACT toplevel instance is the active Wayland window, use active title
    if (wlHandle && ToplevelManager.activeToplevel && wlHandle === ToplevelManager.activeToplevel) {
      if (ToplevelManager.activeToplevel.title) {
        title = String(ToplevelManager.activeToplevel.title)
      }
    }

    var clsLower = cls.toLowerCase()
    var titleLower = title.toLowerCase()

    var isBrowser = (clsLower.indexOf("chrome") !== -1 ||
                     clsLower.indexOf("chromium") !== -1 ||
                     clsLower.indexOf("brave") !== -1 ||
                     clsLower.indexOf("firefox") !== -1 ||
                     clsLower.indexOf("zen") !== -1 ||
                     clsLower.indexOf("librewolf") !== -1 ||
                     clsLower.indexOf("browser") !== -1)

    // Tier 1: Semantic Title Patterns (Webapps & Special States - evaluated for browsers)
    var ruleMatch = null
    if (isBrowser) {
      ruleMatch = matchRule(root.titleRules, titleLower)
      if (ruleMatch) return ruleMatch
    }

    // Tier 2: Application Class Mapping (appId / class)
    ruleMatch = matchRule(root.classRules, clsLower)
    if (ruleMatch) return ruleMatch

    // Tier 3: Title Heuristics Fallback
    ruleMatch = matchRule(root.titleFallbackRules, titleLower)
    if (ruleMatch) return ruleMatch

    // Tier 4: Generic window icon fallback
    return { icon: "", brightness: 0.0, contrast: 1.0 }
  }

  function getWorkspaceIcons(workspace, id, focused) {
    if (!workspace || !workspace.toplevels || !workspace.toplevels.values || workspace.toplevels.values.length === 0) {
      return [{ icon: focused ? "\uDB85\uDCFB" : String(id), brightness: 0.0, contrast: 1.0 }]
    }

    var toplevels = workspace.toplevels.values
    var icons = []
    for (var i = 0; i < toplevels.length; i++) {
      var iconSpec = root.iconForToplevel(toplevels[i])
      if (iconSpec) icons.push(iconSpec)
    }
    return icons.length > 0 ? icons : [{ icon: focused ? "\uDB85\uDCFB" : String(id), brightness: 0.0, contrast: 1.0 }]
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

        // Reactive signature that triggers instant icon re-computation on tab/title changes for THIS workspace only
        readonly property string toplevelSignature: {
          var sig = ""
          if (workspace && workspace.toplevels && workspace.toplevels.values) {
            var vals = workspace.toplevels.values
            for (var i = 0; i < vals.length; i++) {
              var t = vals[i]
              if (t.wayland && t.wayland.title) sig += t.wayland.title + ";"
              if (t.waylandHandle && t.waylandHandle.title) sig += t.waylandHandle.title + ";"
              if (t.title) sig += t.title + ";"
              if (t.lastIpcObject && t.lastIpcObject.title) sig += t.lastIpcObject.title + ";"
            }
          }
          if (focused && ToplevelManager.activeToplevel) {
            sig += (ToplevelManager.activeToplevel.title || "") + ";"
          }
          return sig
        }

        readonly property var iconList: {
          var _dep = toplevelSignature
          return root.getWorkspaceIcons(workspace, modelData, focused)
        }
        readonly property color itemColor: {
          if (focused) return Color.accent
          if (mouseArea.containsMouse) return Color.foreground
          if (occupied) return Qt.lighter(Color.muted, 1.65)
          return Util.alpha(Color.muted, 0.45)
        }

        implicitWidth: pillRect.implicitWidth
        implicitHeight: root.barSize

        Rectangle {
          id: pillRect
          anchors.verticalCenter: parent.verticalCenter
          height: root.barSize - 8
          radius: height / 2

          implicitWidth: Math.max(height, iconsRow.implicitWidth + 14)

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

          Row {
            id: iconsRow
            anchors.centerIn: parent
            spacing: Style.space(2)

            Repeater {
              model: pillItem.iconList

              Item {
                required property var modelData
                readonly property var spec: root.getIconSpec(modelData)
                readonly property string resolvedSvg: root.resolveIconSource(spec.icon)
                readonly property bool hasSvg: resolvedSvg.length > 0
                readonly property real iconSize: Math.max(13, Style.font.body)

                width: hasSvg ? iconSize : glyphText.implicitWidth
                height: hasSvg ? iconSize : glyphText.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                // 1. Default Nerd Font / Numeric Glyph
                Text {
                  id: glyphText
                  visible: !hasSvg
                  anchors.centerIn: parent
                  text: hasSvg ? "" : root.getGlyphOrFallback(spec.icon)
                  color: pillItem.itemColor
                  font.family: "JetBrainsMono Nerd Font Propo"
                  font.pixelSize: Style.font.body
                  renderType: Text.NativeRendering
                  horizontalAlignment: Text.AlignHCenter
                  verticalAlignment: Text.AlignVCenter

                  Behavior on color { ColorAnimation { duration: 140 } }
                }

                // 2. Theme-Aware Vector Icon (Papirus SVG / PNG via MultiEffect)
                Image {
                  id: svgImage
                  visible: false
                  anchors.fill: parent
                  fillMode: Image.PreserveAspectFit
                  sourceSize.width: Math.round(width * Screen.devicePixelRatio)
                  sourceSize.height: Math.round(height * Screen.devicePixelRatio)
                  source: hasSvg ? resolvedSvg : ""
                  layer.enabled: hasSvg
                  smooth: true
                }

                MultiEffect {
                  visible: hasSvg
                  anchors.fill: svgImage
                  source: svgImage
                  brightness: spec.brightness
                  contrast: spec.contrast
                  colorization: 1.0
                  colorizationColor: pillItem.itemColor

                  Behavior on colorizationColor { ColorAnimation { duration: 140 } }
                }
              }
            }
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
