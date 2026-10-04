# EasyClickCasting

Addon World of Warcraft de *click casting* simple et léger : on lance ses sorts directement depuis les **cadres de groupe et de raid de l'interface de base**, sans remplacer l'interface du jeu.

## Fonctionnalités

- **Souris** : clic gauche, clic droit, clic molette, molette haut, molette bas.
- **Clavier** : touches `1` à `6` et `A E R T F G H W X C V B`.
- **Modificateurs** : Aucun, Ctrl, Alt, Maj, Ctrl+Alt sur chaque action (115 combinaisons).
- **Molette et touches au survol** : elles ne lancent le sort que lorsque la souris survole un cadre de groupe ; partout ailleurs elles gardent leur rôle normal (zoom, déplacement…). Une touche sans sort n'est jamais modifiée.
- **Actions spéciales** : « Cibler le joueur » (partout) et « Menu du joueur » (clics uniquement).
- **Toutes les classes** : la liste des sorts vient du grimoire du personnage ; les réglages sont sauvegardés par personnage.
- **Portrait du joueur ignoré** : il garde son comportement habituel (ciblage, menu).
- **Mon cadre en solo** (activé par défaut) : quand tu n'es pas groupé, ton personnage s'affiche dans un cadre style raid avec tous tes raccourcis ; il disparaît dès que tu rejoins un groupe. Déplaçable avec le bouton « Déplacer » de la fenêtre de réglage.
- Sorts enregistrés par ID : le rang le plus élevé connu est lancé automatiquement, sans souci d'accents ou d'apostrophes dans les noms.

## Installation

1. Télécharger le dépôt (bouton **Code → Download ZIP**) ou le cloner.
2. Placer le dossier dans `World of Warcraft/_<version>_/Interface/AddOns/` et le nommer **`EasyClickCasting`**
   (le chemin final doit être `AddOns/EasyClickCasting/EasyClickCasting.toc`).
3. Lancer le jeu ou taper `/reload`.

> **Important** : dans les options de combat du jeu, régler la **touche d'auto-incantation** sur *Aucune*, sinon les combinaisons avec Alt lancent le sort sur soi.

## Utilisation

| Commande | Effet |
|---|---|
| `/ecc` ou `/easyclickcasting` | Ouvre la fenêtre de réglage |
| `/ecc liste` | Affiche les combinaisons actives dans le chat |

Dans la fenêtre :

- **Clic sur une case** : choisir un sort dans la liste (les actions spéciales sont en haut).
- **Glisser un sort** du grimoire sur une case : l'assigne directement.
- **Clic droit** sur une case : l'effacer (le cadre retrouve son comportement d'origine).
- **Config par défaut** : remet la configuration de départ de la classe.
- **Mon cadre en solo** : affiche ou masque le cadre solo ; **Déplacer** active la poignée pour le positionner (cliquer de nouveau pour verrouiller).

Les réglages ne peuvent pas être modifiés en combat (limitation du jeu).

## Configuration par défaut

Le prêtre démarre avec une configuration prête à l'emploi ; les autres classes démarrent vides (l'interface reste exactement comme celle du jeu tant que rien n'est réglé).

| Combinaison | Prêtre |
|---|---|
| Clic gauche | Soins inférieurs |
| Clic droit | Mot de pouvoir : Bouclier |
| Maj + clic gauche | Soins |
| Alt + clic gauche | Mot de pouvoir : Robustesse |
| Ctrl + clic gauche | Cibler le joueur |
| Ctrl + clic droit | Menu du joueur |
| Molette haut | Rénovation |

## Auteur

Kaladjin
