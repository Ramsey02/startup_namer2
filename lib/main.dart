import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 

// infinity stones: ios, android, web, windows, macos, linux
void main() {
  // new
  WidgetsFlutterBinding.ensureInitialized(); 

  runApp(const MyApp());
}

// new
class App extends StatelessWidget { 
 final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  App({super.key}); 
 
 @override 
 Widget build(BuildContext context) { 
   return FutureBuilder( 
     future: _initialization, 
     builder: (context, snapshot) { 
       if (snapshot.hasError) { 
         return Scaffold( 
             body: Center( 
                 child: Text(snapshot.error.toString(), 
                     textDirection: TextDirection.ltr))); 
       } 
 
       if (snapshot.connectionState == ConnectionState.done) { 
         return MyApp(); 
       } 
 
       return Center(child: CircularProgressIndicator()); 
     }, 
   ); 
 } 
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(          // MODIFY with const
      title: 'Startup Name Generator' , 
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.greenAccent,
          foregroundColor: Colors.black, // Text color
        ),
      ),
      home: const RandomWords(),
      
    );
  }
}

class RandomWords extends StatefulWidget {
  const RandomWords({super.key});

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[]; // NEW
  final _saved = <WordPair>{}; // NEW
  final _biggerFont = const TextStyle(fontSize: 18); // NEW

  void _pushSaved() {
  Navigator.of(context).push(
    // Add lines from here...
      MaterialPageRoute<void>(
        builder: (context) {
          // here we return dissmissible instead of list tile
          final tiles = _saved.map(
            (pair) {
              return Dismissible(
                key: Key(pair.asPascalCase),
                background: Container(
                  color: Colors.deepPurple,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8.0),
                      Text('Delete suggestion', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                confirmDismiss: (direction) async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('“Deletion is not implemented yet'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return false; // Prevents the item from being dismissed
                },
                child: ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                ),
              );
            },
          );
          // Convert the iterable into a list of widgets
          // and then use ListTile.divideTiles to add dividers between them.
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(
                  context: context,
                  tiles: tiles,
                ).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        },
      ), // ...to here.
  );
  }
  
  void _pushLoginPage() {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Login'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to the Startup Name Generator!',
                  style: TextStyle(fontSize: 24.0),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Handle login logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Login is not implemented yet!'),
                      ),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(   // NEW from here ...
      appBar: AppBar(  
        title: const Text('Startup Name Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
        
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: _pushLoginPage,
            tooltip: 'Login',
          ),],
      ),               
      body: ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        /// so that the even list view items contain the values - word pairs -
        /// while the odd list view items are dividers
        if (i.isOdd) return const Divider();
        final index = i ~/ 2;
        if (index >= _suggestions.length) {
          _suggestions.addAll(generateWordPairs().take(10));}
        final alreadySaved = _saved.contains(_suggestions[index]); // NEW
        return Dismissible(
          key: Key(_suggestions[index].asPascalCase),
          background: Container(
            color: Colors.deepPurple,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
          Icon(Icons.favorite, color: Colors.white),
          SizedBox(width: 8.0),
          Text('Add to favorite', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (direction) async {
            setState(() {
              if (!alreadySaved) {
          _saved.add(_suggestions[index]);
              }
            });
            return false; // Prevents the item from being dismissed
          },
          child: ListTile(
            title: Text(_suggestions[index].asPascalCase, style: _biggerFont),
            trailing: Icon(
              alreadySaved ? Icons.favorite : Icons.favorite_border,
              color: alreadySaved ? Colors.red : null,
              semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
            ),
            onTap: () {
              setState(() {
          if (alreadySaved) {
            _saved.remove(_suggestions[index]);
          } else {
            _saved.add(_suggestions[index]);
          }
              });
            },
          ),
        );
      },
      
    )
  );
  
  }
}
