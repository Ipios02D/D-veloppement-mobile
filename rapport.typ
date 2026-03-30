#import "./shafoin-typst-template/vibrant-color.typ" : *

#show: doc => vibrant-color(
  theme: "pastel-theme",  // choix du theme parmi pastel-theme, blue-theme, green-theme, red-theme
  title: "Rapport Développement Mobile",  // titre du document
  authors: (  // liste des auteurs
    "Louis CHALVIGNAC",
    "Clément CANO",
    "Antoine BEAUPREZ",
    "Emilien COUSIN",
  ),
  lang: "fr",
  heading-numbering: true,
  sub-authors: "3A ICY",  // texte optionnel au dessus des auteurs ex : groupe 2, 4A ICY 
  description: "Présentation de l'application CityMov", // description du document
  date: datetime(day: 10, month: 3, year: 2025), // date du document, sous format datetime
  subject: "Développement Mobile", // matière du document ou texte en bas
  bib-yaml: bibliography("./shafoin-typst-template/example/refs.yaml"),  // référence vers une bibliographie
  logo: image("./shafoin-typst-template/example/insa-hdf.png", width: 33%),
  doc
)

= Cahier des charges

== Contexte et besoins
Dans l'optique d'améliorer la qualité de vie urbaines pour tous, nous avons décidé de créer une application nommé *_CityMove_*. Son objectif est simple : informer les habitants des différents évenements présent dans leur ville ou aux alentours. 

Un seconde partie de l'application permettra à la mairie et aux associations inscrites sur l'application de sonder la habitants afin d'obtenir des retours importants sur des évenements ou des sujets clé pour la municipalité.

Notre application doit donc être ergonomique et intuitive car elle pourra être utilisé par 

== Périmètre Technique 
Afin de répondre au mieux à nos besoins, nous allons utiliser diverses solutions techniques.

=== Outils collaboratif
- GitHub pour le partage du code et des documents : #link("https://github.com/Ipios02D/D-veloppement-mobile")
- Notion pour la répartition des tâches 

=== Technologies utilisé

Le langage de proggramation flutter nous est imposé pour le développement de notre application.

L'application que nous souhaitons concevoir devra utiliser de nombreuses données, tel que les emails et mot de passe des utilisateurs, ou encore les différents évenements affiché sur la carte. Nous allons donc devoir utiliser une Système de Gestion de Base de Données. Nous avons choisi *Firebase* pour notre projet car ce SGBD à été conçu pour une integration avec Flutter simple, et possède de nombreuses fonctionalités comme la gestion des authentifications integré, ou le hachage des mots de passe de manière automatique.



= Conception
Avant de nous lancer dans la proggramation de notre application, nous devons réaliser une maquette générale ainsi qu'un diagramme de notre base de données.

== Maquette de l'application

Afin d'avoir une idée claire sur le développement de notre application, nous avons creer une maquette (rudimentaire).
Cette maquette nous permettra de savoir quoi proggramer et où, et aussi de nous répartir le travail de manière plus efficace.
#image("shafoin-typst-template/assets/images/maquette.png")

== Architecture de l'application 
Maintenant que notre maquette est fin prête, nous pouvons nous lancer dans l'architecture technique de notre application.
Le nombreux d'écrans différents étant conséquents, chaque page de l'application aura sont propre fichier dart. 

Au delà d'avoir des proggrames plus propres et lisibles, nous pouvons nour répartir le travail de manière plus simple.

Nous utiliserons alors une fonction spécialement conçu pour changer de page selon leurs index.

== Schéma entité-relation
Lors de la création d'une base de données, il est impératif de créer un schéma complet de la base de données, afin d'éviter des redondances, mais aussi pour pouvoir effectuer nos requêtes plus aisement sur nos différentes pages.


Voici notre schéma entité-relation :

#image("shafoin-typst-template/assets/images/BDD.drawio-1.png")

#info("Veuillez noter que la table utilisateur à été modifié suite à l'implementation des fonctionnalitées d'authentification de Firebase")

= Organisation du projet

== Outils collaboratif
Comme décrit plus tôt dans notre cahier des charges, nous avons utilisé plusieurs outils afin de collaborer plus efficacement.
En effet, nous travaillons en groupe avec un nombre important de personnes (ici 4). Il est donc important de s'organiser afin d'avoir un cylce de développement le plus fluide possible.

=== Notion 
Pour la répartition des différentes tâches, nous avons utilisé l'outils Notion, qui nous permet de suivre les tâches en cours ou finis, et de mettre en place une deadline pour chaque tâche.

=== Git et GitHub
Pour sauvegarder et partager notre code, nous avons utilisé l'outis GitHub. Cet outil nous permet aussi de fusionner nos différents proggrammes et de récuperer ceux des autres à distance.
Voici le GitHub que nous avons utilisé pour ce projet : #link("https://github.com/Ipios02D/D-veloppement-mobile")

== Répartition des tâches
Comme expliqué plus haut, notre application est composé de plusieurs pages qui seront affiché à tour de rôle.
Nous pouvons donc nous répartir les différentes pages à développer. Ainsi nous pouvons tous travailler de manière indépendante et fusionner nos projets plus tard.
Cela nous permet de nous organiser correctement et de pouvoir travailler en parallele, plutôt que d'attendre que certaines partie de notre projet soit finies pour continuer.

= Mise en place des pages





#pagebreak()
=== Titre 3

==== Titre 4

Les titres sont numérotés automatiquement si l'on utilise le `heading-numbering: true`.
    
*Texte stylisé* :
On peut #strike[barrer du texte], mettre du texte en *gras*, en _italique_, ou *_les deux_*. Le texte en inférieur#sub[aussi], et en supérieur aussi pour les 1#super[er] par exemple. Enfin on peut #underline[souligner], mettre une ligne #overline[au dessus], et #highlight[surligner] (selon la couleur du thème).

*Citation* :

#quote(attribution: [Didier])[
  _Voilà une jolie citation pour illustrer le principe. L'italique est inséré manuellement au cas où l'on ne souhaite pas l'utiliser (pour autre chose qu'une citation par exemple)_
]

*Footnote* : Création d'une petite note de bas de page
#footnote[Une petite note de bas de page]

#figure(
  kind: table,
  rect[Hello],
  caption: [Voici un tableau et son caption.],
)

#figure(
  caption: [Un nouveau tableau. Il contient des hline et vline pour accentuer le tableau, utilisable manuellement et accordés au thème actuel.],

  table(
    columns: 4,
    table.header([*Header*], [*Value*], [*Unit*], [*Type*]),
    table.hline(start: 0, stroke : 2pt),
    table.vline(x: 1, stroke : 2pt),
    [John], [], [A], [],
    [Mary], [], [A], [A],
    [Robert], [B], [A], [B],
    table.hline(start: 0, stroke : 2pt),
    table.footer([*Footer*], [*Value*], [*Unit*], [*Type*]),
  )
)

#figure(
  caption: [Un autre tableau. Les figures sont centrées par défaut. Seuls des lignes horizontales grisées sont affichées par choix de design.],

  table(
    columns: 4,
    [t], [1], [2], [3],
    [y], [0.3s], [0.4s], [0.8s],
  ),
)

#pagebreak()

#columns(2,[
  #figure(
    caption: [Une image d'un gros lapin. La caption des images est différente, avec une barre colorée selon le thème en arrière-plan.], 
    image("./shafoin-typst-template/example/lapin.jpg", width: 100%)
  )<lapin>
  #colbreak()
  #text[*Colonnes* : Nous avons placé un texte en colonnes. Les images, figures, comment, info, warning fonctionnent très bien avec, mais pas les codeblock. Il faut préciser soit même le \#columns pour l'utiliser.]
  ]
)

*Reference* : uniquement pour les figures, tableaux, équations. Headings aussi mais pas là car ils sont pas numérotés. Il faut préciser la référence en mettant un \<nomDeMaReference\> à côté de l'endroit à référencer. Référence vers le lapin : @lapin

*Dictionnaire* : Une liste de description de termes. Utiles en annexe par exemple.
/ Ligature: A merged glyph.
/ Kerning: #lorem(50) 

*Liste non numérotée* : utiliser le "-" avec des tabulations
- test
  - test 2
- test 3

*Liste numérotée*: utiliser le "+" et les tabulations pour automatiquement faire la numérotation. On peut mélanger la liste numérotée et non numérotée.

+ test
  + test
+ test 2
  + test 2.1
+ test 3

*Délimiteur* : 

#line(length: 100%)
#line(length: 100%, stroke: (dash: "dashed"))

*Référence bibliographique* : Il suffit de fournir un fichier bibliographique YAML (voir exemple). Il permet de stocker nos références bibliographiques et de les citer dans le texte. Il faut préciser le nom du fichier dans l'attribut "bib-yaml" de la fonction insa-report. Une section "BIBLIOGRAPHIE" apparait alors automatiquement à la fin de notre rapport. On cite un document de la bibliographie de la même manière que les références. Exemple : @harry

*Liens/URL* : Cliquables et colorés selon le thème. On peut les mettre en brut #link("https://example.com") ou avec 
#link("https://example.com")[
  un texte.
]

*Code inline* : Possibilité de taper du code inline comme `test` et même de lui mettre la syntaxe de son langage avec ```rust fn main()```.

*Block de code* : Possibilité de mettre un block de code avec la syntaxe de son langage. On peut préciser un nom de fichier et si l'on souhaite afficher les numéros de ligne ou non.

#codeblock(filename: "Main.java", line-number: true,
```java
public class Main {
  public static void main(String[] args) {
    System.out.println("Hello, World!");
  }
}
```) 

*Blocks customs * : Plusieurs blocs custom avec des couleurs & icônes *fixes* sont définis ci dessous :

#warning("Le warning, utile pour mettre en avant des informations importantes ou un avertissement")

#info("L'info, pour donner des informations supplémentaires ou des précisions.")

#comment("Le commentaire, pour mettre des annotations, remarques ou des exemples.")
