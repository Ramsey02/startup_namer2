import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:provider/provider.dart';


// ChangeNotifier: this class is responsible for managing the favorites 
class FavoritesNotifier with ChangeNotifier {
  final Set<WordPair> _favorites = {};
  
  Set<WordPair> get favorites => _favorites;
  
  void toggleFavorite(WordPair pair) {
    if (_favorites.contains(pair)) {
      _favorites.remove(pair);
    } else {
      _favorites.add(pair);
    }
    notifyListeners();
  }
}
// infinity stones: ios, android, web, windows, macos, linux
void main() async {
  // new
   WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();

// this is to use for auth emulator, might be really helpful in the future
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoritesNotifier()),
      ],
      child: App(),
    ),
  );
}

// new
class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(snapshot.error.toString(), textDirection: TextDirection.ltr),
            ),
          );
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
  // final _saved = <WordPair>{}; // now we maintain it in the provider
  final _biggerFont = const TextStyle(fontSize: 18); // NEW

  void _pushSaved() {
  Navigator.of(context).push(
    // Add lines from here...
      MaterialPageRoute<void>(
        builder: (context) {
          // here we return dissmissible instead of list tile
          // final tiles = _saved.map this was also changed due to adding the provider
          final favorites = context.watch<FavoritesNotifier>().favorites;
          final tiles = favorites.map(
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
                      content: Text('Deletion is not implemented yet'),
                    
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
                        showCloseIcon: true,
                        backgroundColor: Colors.greenAccent,

                      ),
                    );
                  },
                  child: const Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle login logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sign up is not implemented yet!'),
                        
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onLongPress: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.amberAccent,
                        content: Text('bro i told you its stil not implemented for now'),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.green,
                    child: const Text('Sign up'),
                  ), 
                )
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
        // final alreadySaved = _saved.contains(_suggestions[index]); // this needed to be changed since now i maintain it in the provider
        final alreadySaved = context.watch<FavoritesNotifier>().favorites.contains(_suggestions[index]);
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
            context.read<FavoritesNotifier>().toggleFavorite(_suggestions[index]);
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
              context.read<FavoritesNotifier>().toggleFavorite(_suggestions[index]);
            },
          ),
        );
      },
      
    )
  );
  
  }
}
