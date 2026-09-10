.pragma library

// Distribution icon table mirrored from the OmaLogo plugin (DistroModel.js,
// MIT License, Copyright (c) suva) so the dashboard header can show the same
// icon OmaLogo is configured to display in the bar.
var DISTROS = [
  { key: "omarchy", name: "Omarchy", icon: "\ue900", font: "omarchy" },
  { key: "arch", name: "Arch", icon: "\uf303", font: "nerd" },
  { key: "debian", name: "Debian", icon: "\uf306", font: "nerd" },
  { key: "ubuntu", name: "Ubuntu", icon: "\uf31b", font: "nerd" },
  { key: "fedora", name: "Fedora", icon: "\uf30a", font: "nerd" },
  { key: "nixos", name: "NixOS", icon: "\uf313", font: "nerd" },
  { key: "gentoo", name: "Gentoo", icon: "\uf30d", font: "nerd" },
  { key: "void", name: "Void", icon: "\uf32e", font: "nerd" },
  { key: "alpine", name: "Alpine", icon: "\uf300", font: "nerd" },
  { key: "opensuse", name: "openSUSE", icon: "\uf314", font: "nerd" },
  { key: "manjaro", name: "Manjaro", icon: "\uf312", font: "nerd" },
  { key: "mint", name: "Mint", icon: "\uf30e", font: "nerd" },
  { key: "endeavour", name: "EndeavourOS", icon: "\uf322", font: "nerd" },
  { key: "popos", name: "Pop!_OS", icon: "\uf32a", font: "nerd" },
  { key: "kali", name: "Kali", icon: "\uf327", font: "nerd" },
  { key: "artix", name: "Artix", icon: "\uf31f", font: "nerd" },
  { key: "freebsd", name: "FreeBSD", icon: "\uf30c", font: "nerd" },
  { key: "redhat", name: "Red Hat", icon: "\uf316", font: "nerd" },
  { key: "rocky", name: "Rocky", icon: "\uf32b", font: "nerd" },
  { key: "almalinux", name: "AlmaLinux", icon: "\uf31d", font: "nerd" },
  { key: "centos", name: "CentOS", icon: "\uf304", font: "nerd" },
  { key: "linux", name: "Tux", icon: "\uf17c", font: "nerd" }
];

function findDistro(key) {
  if (!key) return null;
  var normalized = String(key).toLowerCase().trim();
  for (var i = 0; i < DISTROS.length; i++) {
    if (DISTROS[i].key === normalized) return DISTROS[i];
  }
  return null;
}

// Original media-card cat glyph used when OmaLogo is not installed / not in
// the bar layout.
var DEFAULT_HEADER = { key: "cat", name: "Cat", icon: "󰄛", font: "nerd" };

// Reads the distro OmaLogo is configured with from the bar layout config
// (shell.json "bar.layout"). Returns null when OmaLogo is not placed in the
// bar so callers can keep the default cat icon.
function omalogoDistroKey(barConfig) {
  var layout = barConfig && barConfig.layout ? barConfig.layout : null;
  if (!layout) return null;
  var sections = ["left", "center", "right"];
  for (var s = 0; s < sections.length; s++) {
    var entries = layout[sections[s]];
    if (!Array.isArray(entries)) continue;
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      if (entry && String(entry.id || "") === "omalogo")
        return String(entry.distro || "arch");
    }
  }
  return null;
}

function headerIcon(barConfig) {
  return findDistro(omalogoDistroKey(barConfig)) || DEFAULT_HEADER;
}
