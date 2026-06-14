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
  logo: image("./shafoin-typst-template/example/insa-hdf.png", width: 33%),
  doc
)

= Cahier des charges

== Contexte et besoins
Dans l'optique d'améliorer la qualité de vie urbaines pour tous, nous avons décidé de créer une application nommé *_CityMove_*. Son objectif est simple : informer les habitants des différents évenements présent dans leur ville ou aux alentours. 

Un seconde partie de l'application permettra à la mairie et aux associations inscrites sur l'application de sonder la habitants afin d'obtenir des retours importants sur des évenements ou des sujets clé pour la municipalité.

Notre application doit donc être ergonomique et intuitive car elle pourra être utilisé par des personnes qui ne sont pas familières avec les nouvelles technologies. 

== Périmètre Technique 
Afin de répondre au mieux à nos besoins, nous allons utiliser diverses solutions techniques.

=== Outils collaboratif
- GitHub pour le partage du code et des documents : #link("https://github.com/Ipios02D/D-veloppement-mobile")
- Notion pour la répartition des tâches : #link("https://app.notion.com/p/322cd6fc0740801d8d53d0fca77ca2ac?v=322cd6fc0740801c8926000cc454b211&source=copy_link ")

=== Technologies utilisé

Le langage de proggramation flutter nous est imposé pour le développement de notre application.

L'application que nous souhaitons concevoir devra utiliser de nombreuses données, tel que les emails et mot de passe des utilisateurs, ou encore les différents évenements affiché sur la carte. Nous allons donc devoir utiliser une Système de Gestion de Base de Données. Nous avons choisi *Firebase* pour notre projet car ce SGBD à été conçu pour une integration avec Flutter simple, et possède de nombreuses fonctionalités comme la gestion des authentifications integré, ou le hachage des mots de passe de manière automatique.



= Conception
Avant de nous lancer dans la proggramation de notre application, nous devons réaliser une maquette générale ainsi qu'un diagramme de notre base de données.

== Maquette de l'application

Afin d'avoir une idée claire sur le développement de notre application, nous avons creer une maquette (rudimentaire).
Cette maquette nous permettra de savoir quoi proggramer et où, et aussi de nous répartir le travail de manière plus efficace.
#image("shafoin-typst-template/assets/images/maquette.png",width: 90%)

== Architecture de l'application 
Maintenant que notre maquette est fin prête, nous pouvons nous lancer dans l'architecture technique de notre application.
Le nombreux d'écrans différents étant conséquents, chaque page de l'application aura sont propre fichier dart. 
Nous avons donc les pages suivantes : 
- Page d'authentification ou de création de compte
- Barre de navigation présente sur toutes les autres pages 
- Page d'acceuil 
- Page de vote pour les différents sondages
- Page de new pour les informations diffusé
- La carte avec les différents points des évenements 
- Page administrateur (console) pour la modération de l'application

Au delà d'avoir des programmes plus propres et lisibles, nous pouvons nour répartir le travail de manière plus simple.


== Schéma entité-relation
Lors de la création d'une base de données, il est impératif de créer un schéma complet de la base de données, afin d'éviter des redondances, mais aussi pour pouvoir effectuer nos requêtes plus aisement sur nos différentes pages.


Voici notre schéma entité-relation :

#image("shafoin-typst-template/assets/images/BDD.drawio-1.png",width: 90%)

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
Emilien a fait la page d'acceuil et la carte, Antoine la barre de navigation et lke système de changement de page, Clément la page de vote, de new et la console admin, et Louis l'authentifiaction avec la base de données

= Détails des pages

== Page d'acceuil et création de compte

La page d'acceuil et la page de création de compte sont trés similaire techniquement parlant.
On utilise ici des controlleurs pour chaque champs que l'utilisateur doit remplir, puis on récupère les données que l'on envoie directement sur note base de données Firebase.

Pour l'authentification, nous utilisons les services déjà disponibles avec Firebase qui est _*createUserWithEmailAndPassword*_, ce qui nous permet de ne pas avoir à gérer le cryptage des informations, ou de devoir créer des fonctions de vérification des identifiants pour la connexion. Cela nous sert aussi de token afin de certifier le rôle de l'utilisateur pour controller l'accés à d'autres fonctionalités. Ce controlle s'effectue a chaque changement de page.

== Barre de navigation

Nous avons implémenté dans notre application une barre de navigation qui reste présente sur toutes les pages disponibles. Nous avons donc dû créer plusieures fonction afin de pouvoir changer de pages sans que la barre de navigation disparaisse.(_*changePage*_)
C'est aussi sur cette barre que vous pouvez changer le thème de l'application (thème clair ou thème sombre).

== Carte
Pour la carte, notre page doit uniquement aficher les points contenus dans notre base de données ainsi que la carte en elle même. On réutilise l'api de l'application météo puisque nous connaissons son fonctionnement. 
Ainsi nous avons juste à stocker une adresse sous forme de chaine de caractère dans la base de données, que nous envoyons à l'API et qui nous renvoie ensuite les coordonées géographiques du point.

== Page de vote

C'est sur cette page que les utilisateurs peuvent voter sur des sondages ou les modifier/supprimer en tant qu'administrateur. Chaque personne ne peut voter qu'une seule fois grâce aux identifiants uniques que nous avons dans notre base de données. Les administrateurs et les associations quand à eux peuvent créer de nouveaux sondages ou voir les votes et résultats.

== Console administrateur

C'est ici que l'administrateur peut modifier des evenements, des sondages et de manière plus général, supervisé l'utilisation de l'application.
Cette console étant bien évidement reservé à l'administrateur, on vérifie son rôle dans la base de donnée.

== Page News

Sur cette page, les associations ainsi que l'administrateur peuvent créer des annonces et des évenements avec un titre, un lieu et un tag selon le type d'évenement. Toutes les données sont stocké dans la base de données, et peuvent êtres modifié par l'association qui l'a créé ou alors par l'administrateur.


