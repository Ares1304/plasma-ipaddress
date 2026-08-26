## Version v0.9.5

### 🇬🇧 English

#### New Features

-   **Middle-click copy**: Middle-click the widget to copy the currently displayed local or public IP address.
-   **Adjustable font size**: Added a 60% to 200% font-size setting while keeping the panel flag compact and centered.

#### Improvements

-   **Centered panel layout**: The IP type stays above the address, with the country flag centered beside the complete two-line block in horizontal and vertical panels.
-   **Adaptive configuration page**: Added a visible scrollbar for short dialogs, clearer automatic interface detection, and filtering for Docker bridges, veth peers, and other container-only interfaces.
-   **Smarter network refresh**: Local mode performs no public lookup; public mode now uses one combined request, a five-minute refresh, and bounded retry backoff.
-   **Plasma 6 package metadata**: Updated the package structure and license metadata so KDE can reliably install and upgrade the widget.

#### Bug Fixes

-   Fixed the repeated `contentLayout is not defined` runtime error and related Qt 6 layout warnings.
-   Restored reliable country-flag display and kept valid IP addresses visible when country data is temporarily unavailable.
-   Fixed interface preferences being reported or overwritten incorrectly when the configuration page opens.

I will continue to work on improving the widget's features and reliability!
For any issues or suggestions, please visit our GitHub repository.

---

### 🇫🇷 Français

#### Nouvelles Fonctionnalités

-   **Copie au clic milieu** : Un clic milieu sur le widget copie l'adresse IP locale ou publique actuellement affichée.
-   **Taille de police réglable** : Ajout d'un réglage de 60 % à 200 % tout en conservant un drapeau compact et centré dans le panneau.

#### Améliorations

-   **Centrage dans le panneau** : Le type d'IP reste au-dessus de l'adresse, avec le drapeau du pays centré à côté du bloc complet sur deux lignes dans les panneaux horizontaux et verticaux.
-   **Page de configuration adaptative** : Ajout d'un ascenseur visible dans les fenêtres courtes, clarification de la détection automatique et filtrage des ponts Docker, des pairs veth et des autres interfaces réservées aux conteneurs.
-   **Rafraîchissement réseau intelligent** : Le mode local ne fait aucune requête publique ; le mode public utilise une seule requête combinée, un rafraîchissement de cinq minutes et des nouvelles tentatives espacées.
-   **Métadonnées du paquet Plasma 6** : Mise à jour de la structure du paquet et de la licence afin que KDE puisse installer et mettre à niveau le widget de façon fiable.

#### Corrections de Bugs

-   Correction de l'erreur répétée `contentLayout is not defined` et des avertissements de disposition associés sous Qt 6.
-   Rétablissement de l'affichage fiable du drapeau et conservation d'une IP valide lorsque les données du pays sont temporairement indisponibles.
-   Correction des préférences d'interface affichées ou écrasées incorrectement à l'ouverture de la configuration.

Je continuerai à travailler pour améliorer les fonctionnalités et la fiabilité du widget !
Pour tout problème ou suggestion, veuillez visiter notre dépôt GitHub.
