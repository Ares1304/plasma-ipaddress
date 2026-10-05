# IP Address Display for KDE Plasma 5.27

This repository ships a dedicated package for **KDE Plasma 5.27** (also works on Plasma 5.25/5.26): `package-plasma5/`. It carries the same features as the Plasma 6 version v0.9.6 (local/public IP, country flag, interface selection with automatic detection, custom prefix, font scale, middle-click copy), ported to the Plasma 5 QML APIs.

## Requirements

- KDE Plasma **5.25 or later** (tested against 5.27)
- `curl` for the public IP lookup
- `ip` (iproute2) for local network information

```bash
sudo apt install curl iproute2  # Debian/Ubuntu
sudo pacman -S curl iproute2    # Arch
sudo dnf install curl iproute2  # Fedora
```

## Installation

### With kpackagetool5 (recommended)

```bash
kpackagetool5 --type Plasma/Applet --install package-plasma5
# To upgrade an existing installation:
kpackagetool5 --type Plasma/Applet --upgrade package-plasma5
```

### Manual copy

```bash
mkdir -p ~/.local/share/plasma/plasmoids/
cp -r package-plasma5 ~/.local/share/plasma/plasmoids/org.kde.plasma.ipaddress
kquitapp5 plasmashell && kstart5 plasmashell
```

Then right-click your panel or desktop → "Add Widgets…" → search for "IP Address Display".

## Plasma 6.x

Use the `package/` directory instead — see the main [README](README.md).

## Differences from the Plasma 6 package

Only the QML/metadata layer differs; flags, translations and country data are identical:

- `metadata.json`: Plasma 5 applet keys (`X-Plasma-API: declarativeappletscript`, `X-Plasma-MainScript`)
- `main.qml`: root `Item` with `Plasmoid.*` attached representations instead of `PlasmoidItem`; `PlasmaCore.DataSource` instead of `P5Support.DataSource`; the `PowerDevil` source name used by Plasma 5
- `IpDisplay.qml`: versioned Plasma 5 imports, `plasmoid.` context property instead of the `Plasmoid` attached object
- `configGeneral.qml`: plain `Kirigami.FormLayout` page (Plasma 5 provides its own scroll view) instead of `KCM.SimpleKCM`
- `ColorPicker.qml`: versioned Qt 5 imports

---

# Affichage des Adresses IP pour KDE Plasma 5.27

Ce dépôt fournit un paquet dédié à **KDE Plasma 5.27** (fonctionne aussi sur Plasma 5.25/5.26) : `package-plasma5/`. Il reprend les mêmes fonctionnalités que la version Plasma 6 v0.9.6 (IP locale/publique, drapeau du pays, sélection d'interface avec détection automatique, préfixe personnalisé, taille de police, copie par clic milieu), portées vers les APIs QML de Plasma 5.

## Prérequis

- KDE Plasma **5.25 ou supérieur** (testé pour 5.27)
- `curl` pour la requête d'IP publique
- `ip` (iproute2) pour les informations réseau locales

```bash
sudo apt install curl iproute2  # Debian/Ubuntu
sudo pacman -S curl iproute2    # Arch
sudo dnf install curl iproute2  # Fedora
```

## Installation

### Avec kpackagetool5 (recommandé)

```bash
kpackagetool5 --type Plasma/Applet --install package-plasma5
# Pour mettre à jour une installation existante :
kpackagetool5 --type Plasma/Applet --upgrade package-plasma5
```

### Copie manuelle

```bash
mkdir -p ~/.local/share/plasma/plasmoids/
cp -r package-plasma5 ~/.local/share/plasma/plasmoids/org.kde.plasma.ipaddress
kquitapp5 plasmashell && kstart5 plasmashell
```

Puis clic droit sur votre panneau ou bureau → « Ajouter des composants graphiques… » → cherchez « IP Address Display ».

## Plasma 6.x

Utilisez le dossier `package/` — voir le [README](README.md) principal.
