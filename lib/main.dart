import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EvoSystems Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MyHomePage(title: 'EvoSystems - Movie List Project'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = TextEditingController();
  List<dynamic> _movies = [];
  int? hoveredIndex;

  Future<void> searchMovies() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    final movies = await fetchMovies(query);

    movies.sort((a, b) {
      String? dateA = a["release_date"];
      String? dateB = b["release_date"];

      if (dateA == null || dateA.isEmpty) return 1;
      if (dateB == null || dateB.isEmpty) return -1;

      return dateA.compareTo(dateB);
    });

    setState(() {
      _movies = movies;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search for a movie...",
                hintStyle: TextStyle(color: Colors.white60),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.white),
                  onPressed: searchMovies,
                ),
              ),
              onSubmitted: (_) => searchMovies(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _movies.isEmpty
                  ? Center(
                      child: Text(
                        "No movies found, try using another word",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        final movie = _movies[index];
                        return MouseRegion(
                          onEnter: (_) => setState(() => hoveredIndex = index),
                          onExit: (_) => setState(() => hoveredIndex = null),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: hoveredIndex == index
                                  ? Colors.deepPurple[700]
                                  : Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                "${movie["release_date"]?.split("-")[0] ?? "Unknown"} - ${movie["title"]}",
                                style: TextStyle(color: Colors.grey[200]),
                              ),
                              onTap: () => showMovieDetails(movie),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // modal

  void showMovieDetails(dynamic movie) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(movie["title"], style: TextStyle(color: Colors.grey[100])),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (movie["poster_path"] != null)
                Image.network(
                  "https://image.tmdb.org/t/p/w500${movie["poster_path"]}",
                  height: 250,
                ),
              const SizedBox(height: 10),
              Text(
                "${movie["release_date"]?.split("-")[0] ?? "Unknown"}",
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 10),
              FutureBuilder(
                future: fetchMovieCast(movie["id"]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Failed to load cast", style: TextStyle(color: Colors.red));
                  } else {
                    return Text(
                      "${snapshot.data}",
                      style: TextStyle(color: Colors.red[200]),
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              movie["overview"] != null
                  ? Text(
                      "${movie["overview"]}",
                      style: TextStyle(color: Colors.grey[200]),
                    )
                  : Container(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }
}

Future<List<dynamic>> fetchMovies(String query) async {
  final apiKey = "c680677afad09b0af93c05b441f260eb";
  final url = Uri.https("api.themoviedb.org", "/3/search/movie", {
    "api_key": apiKey,
    "query": query
  });

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["results"] ?? [];
    } else {
      throw Exception("Failed to load movies");
    }
  } catch (e) {
    throw Exception("Network error");
  }
}

Future<String> fetchMovieCast(int movieId) async {
  final apiKey = "c680677afad09b0af93c05b441f260eb";
  final url = Uri.https("api.themoviedb.org", "/3/movie/$movieId/credits", {
    "api_key": apiKey,
  });

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final cast = data["cast"]?.take(5).map((actor) => actor["name"]).join(", ") ?? "Unknown";
      return cast;
    } else {
      throw Exception("Failed to load cast");
    }
  } catch (e) {
    return "Unknown";
  }
}
