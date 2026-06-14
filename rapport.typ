#import "./shafoin-typst-template/vibrant-color.typ" : *

#show: doc => vibrant-color(
  theme: "pastel-theme",  // choix du thème parmi pastel-theme, blue-theme, green-theme, red-theme
  title: "Rapport Développement Mobile",  // titre du document
  authors: (  // liste des auteurs
    "Louis CHALVIGNAC",
    "Clément CANO",
    "Antoine BEAUPREZ",
    "Emilien COUSIN",
  ),
  lang: "fr",
  heading-numbering: true,
  sub-authors: "3A ICY",  // texte optionnel au-dessus des auteurs ex : groupe 2, 4A ICY 
  description: "Présentation de l'application CityMov", // description du document
  date: datetime(day: 10, month: 3, year: 2025), // date du document, au format datetime
  subject: "Développement Mobile", // matière du document ou texte en bas 
  logo: image("./shafoin-typst-template/example/insa-hdf.png", width: 33%),
  doc
)

= Cahier des charges

== Contexte et besoins
Dans l'optique d'améliorer la qualité de vie urbaine pour tous, nous avons décidé de créer une application nommée *_CityMove_*.
Son objectif est simple : informer les habitants des différents événements présents dans leur ville ou aux alentours.
Une seconde partie de l'application permettra à la mairie et aux associations inscrites sur l'application de sonder les habitants afin d'obtenir des retours importants sur des événements ou des sujets clés pour la municipalité.
Notre application doit donc être ergonomique et intuitive car elle pourra être utilisée par des personnes qui ne sont pas familières avec les nouvelles technologies.

== Périmètre Technique 
Afin de répondre au mieux à nos besoins, nous allons utiliser diverses solutions techniques.

=== Outils collaboratifs
- GitHub pour le partage du code et des documents : #link("https://github.com/Ipios02D/D-veloppement-mobile")
- Notion pour la répartition des tâches : #link("https://app.notion.com/p/322cd6fc0740801d8d53d0fca77ca2ac?v=322cd6fc0740801c8926000cc454b211&source=copy_link ")

=== Technologies utilisées

Le langage de programmation Flutter nous est imposé pour le développement de notre application.
L'application que nous souhaitons concevoir devra utiliser de nombreuses données, telles que les e-mails et mots de passe des utilisateurs, ou encore les différents événements affichés sur la carte.
Nous allons donc devoir utiliser un Système de Gestion de Base de Données.
Nous avons choisi *Firebase* pour notre projet car ce SGBD a été conçu pour une intégration simple avec Flutter, et possède de nombreuses fonctionnalités comme la gestion des authentifications intégrée, ou le hachage des mots de passe de manière automatique.

= Conception
Avant de nous lancer dans la programmation de notre application, nous devons réaliser une maquette générale ainsi qu'un diagramme de notre base de données.

== Maquette de l'application

Afin d'avoir une idée claire sur le développement de notre application, nous avons créé une maquette (rudimentaire).
Cette maquette nous permettra de savoir quoi programmer et où, et aussi de nous répartir le travail de manière plus efficace.
#image("shafoin-typst-template/assets/images/maquette.png",width: 90%)

== Architecture de l'application 
Maintenant que notre maquette est fin prête, nous pouvons nous lancer dans l'architecture technique de notre application.
Le nombre d'écrans différents étant conséquent, chaque page de l'application aura son propre fichier dart.
Nous avons donc les pages suivantes : 
- Page d'authentification ou de création de compte
- Barre de navigation présente sur toutes les autres pages 
- Page d'accueil 
- Page de vote pour les différents sondages
- Page de news pour les informations diffusées
- La carte avec les différents points des événements 
- Page administrateur (console) pour la modération de l'application

Au-delà d'avoir des programmes plus propres et lisibles, nous pouvons nous répartir le travail de manière plus simple.

== Schéma entité-relation
Lors de la création d'une base de données, il est impératif de créer un schéma complet de la base de données, afin d'éviter des redondances, mais aussi pour pouvoir effectuer nos requêtes plus aisément sur nos différentes pages.
Voici notre schéma entité-relation :

#image("shafoin-typst-template/assets/images/BDD.drawio-1.png",width: 90%)

#info("Veuillez noter que la table utilisateur a été modifiée suite à l'implémentation des fonctionnalités d'authentification de Firebase")

= Organisation du projet

== Outils collaboratifs
Comme décrit plus tôt dans notre cahier des charges, nous avons utilisé plusieurs outils afin de collaborer plus efficacement.
En effet, nous travaillons en groupe avec un nombre important de personnes (ici 4).
Il est donc important de s'organiser afin d'avoir un cycle de développement le plus fluide possible.

=== Notion 
Pour la répartition des différentes tâches, nous avons utilisé l'outil Notion, qui nous permet de suivre les tâches en cours ou finies, et de mettre en place une deadline pour chaque tâche.

=== Git et GitHub
Pour sauvegarder et partager notre code, nous avons utilisé l'outil GitHub.
Cet outil nous permet aussi de fusionner nos différents programmes et de récupérer ceux des autres à distance.
Voici le GitHub que nous avons utilisé pour ce projet : #link("https://github.com/Ipios02D/D-veloppement-mobile")

== Répartition des tâches
Comme expliqué plus haut, notre application est composée de plusieurs pages qui seront affichées à tour de rôle.
Nous pouvons donc nous répartir les différentes pages à développer.
Ainsi nous pouvons tous travailler de manière indépendante et fusionner nos projets plus tard.
Cela nous permet de nous organiser correctement et de pouvoir travailler en parallèle, plutôt que d'attendre que certaines parties de notre projet soient finies pour continuer.
Émilien a fait la page d'accueil et la carte, Antoine la barre de navigation et le système de changement de page, Clément la page de vote, de news et la console admin, et Louis l'authentification avec la base de données.

= Détails des pages

== Page d'accueil et création de compte

La page d'accueil et la page de création de compte sont très similaires techniquement parlant.
On utilise ici des contrôleurs pour chaque champ que l'utilisateur doit remplir, puis on récupère les données que l'on envoie directement sur notre base de données Firebase.
Pour l'authentification, nous utilisons les services déjà disponibles avec Firebase qui sont _*createUserWithEmailAndPassword*_, ce qui nous permet de ne pas avoir à gérer le cryptage des informations, ou de devoir créer des fonctions de vérification des identifiants pour la connexion.
Cela nous sert aussi de token afin de certifier le rôle de l'utilisateur pour contrôler l'accès à d'autres fonctionnalités.
Ce contrôle s'effectue à chaque changement de page.

== Barre de navigation

Nous avons implémenté dans notre application une barre de navigation qui reste présente sur toutes les pages disponibles.
Nous avons donc dû créer plusieurs fonctions afin de pouvoir changer de page sans que la barre de navigation disparaisse (_*changePage*_).
C'est aussi sur cette barre que vous pouvez changer le thème de l'application (thème clair ou thème sombre).

== Carte
Pour la carte, notre page doit uniquement afficher les points contenus dans notre base de données ainsi que la carte en elle-même.
On réutilise l'API de l'application météo puisque nous connaissons son fonctionnement.
Ainsi nous avons juste à stocker une adresse sous forme de chaîne de caractères dans la base de données, que nous envoyons à l'API et qui nous renvoie ensuite les coordonnées géographiques du point.

== Page de vote

C'est sur cette page que les utilisateurs peuvent voter sur des sondages ou les modifier/supprimer en tant qu'administrateur.
Chaque personne ne peut voter qu'une seule fois grâce aux identifiants uniques que nous avons dans notre base de données.
Les administrateurs et les associations quant à eux peuvent créer de nouveaux sondages ou voir les votes et résultats.

== Console administrateur

C'est ici que l'administrateur peut modifier des événements, des sondages et, de manière plus générale, superviser l'utilisation de l'application.
Cette console étant bien évidemment réservée à l'administrateur, on vérifie son rôle dans la base de données.

== Page News

Sur cette page, les associations ainsi que l'administrateur peuvent créer des annonces et des événements avec un titre, un lieu et un tag selon le type d'événement.
Toutes les données sont stockées dans la base de données, et peuvent être modifiées par l'association qui les a créées ou alors par l'administrateur.