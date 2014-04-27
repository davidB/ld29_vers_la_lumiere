# Idee

* runner
* FPS
* vitesse avant controlée par jeu
* control joueur : droite, gauche, jump, dash (optionnel)
* vue composee d'une grille de 3x3 le joueur
* titre : "...vers la lumière"



# J1

- setup
- vue FPS, avec zone lumiere reduite
* vue impression de monter
- deplacement sur la grille
- collision avec box (obstacle ou arrive)
- arrive : box de lumiere blanche (fin de course)
- succes du niveau
* echec du niveau
* level editor
  * 3 series : 1 par hauteur
  * pas fix
  * valeur: 0 rien, 1 gauche, 2, centre, 4 droite, + combinaison
- position du joueur
* niveau 1 :
  * 1 obstacle pour chaque zone de la grille
  * indicateur action
- obstacle sont des box
- obstacle immobile


# J2

* kind < 0 => afficher ou pas (fin du last level "impossible")
* changer la font
* brightness  + contrast dans level def
* 3 levels
* echec du niveau, effet tirer en arriere
* deploiement github
* test ordi isa, windows
* son : bruitage à la bouche (son de derriere)
  * grognement
  * "cours, cours vers la lumiere"
  * rire "grave", "sociere"
* polish gui
* polish visual (3d, light)
* opt: afficher des ohnomatopé sur la gui
* opt: generateur de niveau :
  * select son
  * select distance
  * select obstacle
* opt: vision nocturne (verte)
* opt: collimacon
