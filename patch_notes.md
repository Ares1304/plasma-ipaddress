## Version v0.9.6

### 🇬🇧 English

#### New Features

-   **Panel-aware font sizing**: The 60% to 200% setting now adapts to the panel thickness while keeping the IP type above the address and the flag centered.

#### Improvements

-   **Progressive panel scaling**: Increasing or decreasing the configured percentage now changes the rendered text in the same direction, without breaking the compact two-line layout.
-   **Reliable Plasma 6 configuration lifecycle**: Declared the default configuration properties supplied by Plasma so Reset and Cancel keep consistent values without loader warnings.

#### Bug Fixes

-   Fixed a panel auto-fit feedback loop that could make a higher font-size percentage render smaller.
-   Fixed the discrepancy between the saved font-size percentage and the size rendered after reopening the configuration or reloading Plasma.
-   Removed the `cfg_*Default` property warnings emitted when Plasma opens the configuration page.

I will continue to work on improving the widget's features and reliability!
For any issues or suggestions, please visit our GitHub repository.

---

### 🇫🇷 Français

#### Nouvelles Fonctionnalités

-   **Taille de police adaptée au panneau** : Le réglage de 60 % à 200 % s'adapte désormais à l'épaisseur du panneau tout en maintenant le type d'IP au-dessus de l'adresse et le drapeau centré.

#### Améliorations

-   **Mise à l'échelle progressive dans le panneau** : Augmenter ou diminuer le pourcentage configuré modifie désormais le texte affiché dans le même sens, sans casser la disposition compacte sur deux lignes.
-   **Cycle de configuration Plasma 6 fiable** : Déclaration des propriétés de configuration par défaut fournies par Plasma afin que Réinitialiser et Annuler conservent des valeurs cohérentes sans avertissement du chargeur.

#### Corrections de Bugs

-   Correction d'une boucle de redimensionnement automatique qui pouvait rendre un pourcentage de taille de police supérieur visuellement plus petit dans le panneau.
-   Correction de l'écart entre le pourcentage de taille enregistré et la taille affichée après la réouverture de la configuration ou le rechargement de Plasma.
-   Suppression des avertissements concernant les propriétés `cfg_*Default` lors de l'ouverture de la page de configuration par Plasma.

Je continuerai à travailler pour améliorer les fonctionnalités et la fiabilité du widget !
Pour tout problème ou suggestion, veuillez visiter notre dépôt GitHub.
