import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// ChangeNotifier: this class is responsible for managing the favorites 
class FavoritesNotifier with ChangeNotifier {
  final Set<WordPair> _favorites = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;

  
  //getter
  Set<WordPair> get favorites => _favorites;
  bool get isLoading => _isLoading;

  void toggleFavorite(WordPair pair) {
    if (_favorites.contains(pair)) {
      _favorites.remove(pair);
      if (_user != null) {
        _deleteFavoriteFromFirestore(pair);
      }
    } else {
      _favorites.add(pair);
      if (_user != null) {
        _saveFavoriteToFirestore(pair);
      }
    }
    notifyListeners();
  }

  void clearFavorites() {
  _favorites.clear();
  notifyListeners();
}

void setUser(User? user) {
  // If user state is changing (either logging in or out)
  if (_user != user) {
    // Clear local favorites first
    clearFavorites();
    
    // Set the new user
    _user = user;
    
    // If user logs in, load their favorites from Firestore
    if (user != null) {
      _loadFavoritesFromFirestore();
    }
  }
  notifyListeners();
}

  Future<void> _loadFavoritesFromFirestore() async {
    if (_user == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Get favorites from Firestore
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('favorites')
          .get();
      
      // Create a temporary set to hold Firestore favorites
      Set<WordPair> cloudFavorites = {};
      
      // Convert Firestore documents to WordPairs
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('first') && data.containsKey('second')) {
          cloudFavorites.add(
            WordPair(data['first'], data['second'])
          );
        }
      }
      
      // Combine local and cloud favorites
      _favorites.addAll(cloudFavorites);
      
      // If there were local favorites, save them to Firestore
      Set<WordPair> localOnlyFavorites = {..._favorites};
      localOnlyFavorites.removeAll(cloudFavorites);
      
      for (var pair in localOnlyFavorites) {
        _saveFavoriteToFirestore(pair);
      }
      
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveFavoriteToFirestore(WordPair pair) async {
    if (_user == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('favorites')
          .doc(pair.asPascalCase)
          .set({
            'first': pair.first,
            'second': pair.second,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error saving favorite: $e');
    }
  }

  Future<void> _deleteFavoriteFromFirestore(WordPair pair) async {
    if (_user == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('favorites')
          .doc(pair.asPascalCase)
          .delete();
    } catch (e) {
      debugPrint('Error deleting favorite: $e');
    }
  }

}
// ////////////////////////////////////////////////////////////////////////////////////////////

enum Status { unauthenticated, authenticating, authenticated }

class AuthProvider with ChangeNotifier {
  // the three types of instances we needed to create
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  Status _status = Status.unauthenticated;
  final FavoritesNotifier _favoritesNotifier;

  AuthProvider(this._favoritesNotifier) {
    // Initialize by checking current user
    _user = _auth.currentUser;
    _status = _user == null ? Status.unauthenticated : Status.authenticated;
    
    // Update FavoritesNotifier with current user
    _favoritesNotifier.setUser(_user);
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
    
    // ! check this
    _favoritesNotifier._loadFavoritesFromFirestore();
  }

  // Getters
  User? get user => _user;
  Status get status => _status;
  bool get isAuthenticated => _status == Status.authenticated;

  // Auth state changes listener
  void _onAuthStateChanged(User? firebaseUser) {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.authenticated;
    }
    
    _favoritesNotifier.setUser(_user);
    notifyListeners();
  }

  // Sign in 
  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password
      );
      return true;
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  // Sign up
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      debugPrint('Sign up error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // authStateChanges listener will handle the rest
      // check if it actually does
      _user = null;
      _status = Status.unauthenticated;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}


// ////////////////////////////////////////////////////////////////////////////////////////////
// infinity stones: ios, android, web, windows, macos, linux

void main() async {
  // new
   WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();
  final favoritesNotifier = FavoritesNotifier();
// this is to use for auth emulator, might be really helpful in the future
  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => favoritesNotifier),
        ChangeNotifierProvider(create: (_) => AuthProvider(favoritesNotifier)),
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
        backgroundColor: Colors.purple,
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
      MaterialPageRoute<void>(
        builder: (context) {
          final favorites = context.watch<FavoritesNotifier>().favorites;
          final isLoading = context.watch<FavoritesNotifier>().isLoading;
          if (isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Saved Suggestions'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
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
                // adding the AlertDialog implementation
                confirmDismiss: (direction) async {
                  // Show an AlertDialog asking for confirmation
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Delete Suggestion'),
                        content: Text(
                          'Are you sure you want to delete ${pair.asPascalCase} from your saved suggestions?'
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false); // User pressed No
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(true); // User pressed Yes
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      );
                    },
                  );
                },
                // This will only be called if confirmDismiss returns true
                onDismissed: (direction) {
                  context.read<FavoritesNotifier>().toggleFavorite(pair);
                  // For now, we don't actually delete the item since it's only UI
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${pair.asPascalCase} deletion confirmed, but not implemented yet'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
      ),
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
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return auth.status == Status.authenticating
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () async {
                              bool success = await context.read<AuthProvider>().signIn(
                                    emailController.text,
                                    passwordController.text,
                                  );
                              if (success) {
                                Navigator.of(context).pop(); // Return to main screen
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('There was an error logging into the app'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Login'),
                          );
                  },
                ),
                const SizedBox(height: 8.0),
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return auth.status == Status.authenticating
                        ? Container() // Empty container when authenticating
                        : ElevatedButton(
                            onPressed: () async {
                              UserCredential? result = await context.read<AuthProvider>().signUp(
                                    emailController.text,
                                    passwordController.text,
                                  );
                              if (result != null) {
                                Navigator.of(context).pop(); // Return to main screen
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('There was an error signing up'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Sign up'),
                          );
                  },
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
        title: Consumer<AuthProvider>(
    builder: (context, auth, child) {
      return auth.isAuthenticated
          ? Text('Hello, ${auth.user?.email?.split('@')[0] ?? 'User'}')
          : const Text('Startup Name Generator');
    },
  ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star, color: Colors.redAccent,),
            onPressed: _pushSaved,
            tooltip: 'Saved Suggestions',
          ),
        Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Show login or logout based on authentication state
        return auth.isAuthenticated
            ? IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.green),
                onPressed: () {
                  context.read<AuthProvider>().signOut();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully logged out'),
                    ),
                  );
                },
                tooltip: 'Logout',
              )
            : IconButton(
                icon: const Icon(Icons.login),
                onPressed: _pushLoginPage,
                tooltip: 'Login',
              );
      },
    ),
          ],
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
              children: [
          Icon(alreadySaved ? Icons.favorite_border : Icons.favorite, color: Colors.white),
          SizedBox(width: 8.0),
          Text(
            alreadySaved ? 'Remove from favorites' : 'Add to favorite',
           style: TextStyle(color: Colors.white)),
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
