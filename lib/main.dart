import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:page_connexion/firebase_options.dart';



void main() async {
  // 1. S'assurer que les widgets Flutter sont liés avant d'initialiser Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Lancement de l'application
  runApp(const MyApp());
}




class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(title: 'Créer un compte'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});
  

  final String title;
  final emailController = TextEditingController();
  final nomController = TextEditingController();
  final siretController = TextEditingController();
  final mdpController = TextEditingController();
  final mdpConfirmationController = TextEditingController();

  
void dispose() {
  emailController.dispose();
  nomController.dispose();
  siretController.dispose();
  mdpController.dispose();
}

void initState() {
  emailController.text = '';
  nomController.text = ''; 
  siretController.text = '';
  mdpController.text = '';
  mdpConfirmationController.text = '';
}

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedStatus;

  Future<void> addUserToFirestore() async {
  // On crée une instance de Firestore
  CollectionReference users = FirebaseFirestore.instance.collection('utilisateurs');

  try {

    await users.add({
      'email': widget.emailController.text,
      'nom': widget.nomController.text,
      'siret': widget.siretController.text,
      'statut': selectedStatus == 'Citoyen' ? 1 : 2, // 1 pour Citoyen, 2 pour Association
      'mot_de_passe': widget.mdpController.text, // Note : stocker les mots de passe en clair n'est pas recommandé pour une application réelle
    });
    print("Utilisateur ajouté !");
  } catch (e) {
    print("Erreur lors de l'ajout : $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            DropdownButtonFormField<String>(
              hint: const Text('Statut'),
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'Citoyen', child: Text('Citoyen')),
                DropdownMenuItem(
                    value: 'Association', child: Text('Association')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.emailController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Adresse e-mail',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (selectedStatus == 'Association')
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.nomController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Nom Association',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (selectedStatus == 'Association')
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.siretController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Numéro SIRET',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,        // chiffres uniquement
                            LengthLimitingTextInputFormatter(14),           // max 10 caractères
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // pas d'espaces
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            Column(children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.mdpController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Mot de passe',
                      ),
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ]),
            Column(children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.mdpConfirmationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Confirmer le mot de passe'
                      ),
                      obscureText: true,
                    )
                  ), 
                ],
              ),
            ]),
            Column(children: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
  onPressed: () {
    // On vérifie si les mots de passe correspondent
    if (widget.mdpController.text != widget.mdpConfirmationController.text) {
      // Si non, on affiche une erreur
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Erreur'),
          content: const Text('Les mots de passe ne sont pas identiques.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else if (widget.mdpController.text.isEmpty) {
      // Optionnel : on vérifie si le champ n'est pas vide
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un mot de passe')),
      );
    } else {
      addUserToFirestore();
      // Si tout est bon, on affiche le message de succès
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Compte créé'),
          content: Text(
              'Email : ${widget.emailController.text} \nNom : ${widget.nomController.text}'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('Yepeee'),
            ),
          ],
        ),
      );
    }
  },
  child: const Text('Créer un compte'),
)
              ),
            ])
          ]
        ),
      ]
      ),
    ),
    );
  }
}
