# IP Address Display for KDE Plasma 5.27

This repository ships a dedicated package for **KDE Plasma 5.27**: `package-plasma5/`. It carries the same features as the Plasma 6 version v0.9.6 (local/public IP, country flag, interface selection with automatic detection, custom prefix, font scale, middle-click copy), ported to the Plasma 5 QML APIs.

Plasma 5.27 is the only officially supported Plasma 5 target. Older releases (5.25/5.26) are not supported: the QML files import `org.kde.kirigami 2.20`, which some older installations do not ship.

## Requirements

- KDE Plasma **5.27**
- Qt **5.15**
- KDE Frameworks **5.102 or later** (provides the Kirigami 2.20 import used by the QML files)
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
mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.ipaddress
cp -r package-plasma5/. ~/.local/share/plasma/plasmoids/org.kde.plasma.ipaddress/
kquitapp5 plasmashell && kstart5 plasmashell
```

The trailing `/.` copies the package *contents* into the destination, so re-running the same command upgrades an existing installation in place instead of nesting a `package-plasma5/` folder inside it. Widget settings live in `~/.config/plasma-org.kde.plasma.desktop-appletsrc` and are preserved across upgrades with either method.

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

Ce dépôt fournit un paquet dédié à **KDE Plasma 5.27** : `package-plasma5/`. Il reprend les mêmes fonctionnalités que la version Plasma 6 v0.9.6 (IP locale/publique, drapeau du pays, sélection d'interface avec détection automatique, préfixe personnalisé, taille de police, copie par clic milieu), portées vers les APIs QML de Plasma 5.

Plasma 5.27 est la seule cible Plasma 5 officiellement prise en charge. Les versions plus anciennes (5.25/5.26) ne sont pas supportées : les fichiers QML importent `org.kde.kirigami 2.20`, qui n'est pas fourni par certaines installations plus anciennes.

## Prérequis

- KDE Plasma **5.27**
- Qt **5.15**
- KDE Frameworks **5.102 ou supérieur** (fournit l'import Kirigami 2.20 utilisé par les fichiers QML)
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
mkdir -p ~/.local/share/plasma/plasmoids/org.kde.plasma.ipaddress
cp -r package-plasma5/. ~/.local/share/plasma/plasmoids/org.kde.plasma.ipaddress/
kquitapp5 plasmashell && kstart5 plasmashell
```

Le `/.` final copie le *contenu* du paquet dans la destination : relancer la même commande met à jour une installation existante en place, au lieu d'imbriquer un dossier `package-plasma5/` à l'intérieur. Les réglages du widget sont stockés dans `~/.config/plasma-org.kde.plasma.desktop-appletsrc` et sont conservés lors des mises à jour, quelle que soit la méthode.

Puis clic droit sur votre panneau ou bureau → « Ajouter des composants graphiques… » → cherchez « IP Address Display ».

## Plasma 6.x

Utilisez le dossier `package/` — voir le [README](README.md) principal.
