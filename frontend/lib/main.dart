import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MentalHealthApp());

class MentalHealthApp extends StatelessWidget {
  const MentalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MentalHealthHome(),
    );
  }
}

class MentalHealthHome extends StatefulWidget {
  const MentalHealthHome({super.key});

  @override
  State<MentalHealthHome> createState() => _MentalHealthHomeState();
}

class _MentalHealthHomeState extends State<MentalHealthHome> {
  final TextEditingController _controller = TextEditingController();
  String _quote = "";
  bool _loading = false;

  Future<void> getQuote(String userInput) async {
    setState(() {
      _loading = true;
      _quote = "";
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/docs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': userInput}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quote = data['quote'] ?? "Kein Zitat gefunden.";
        });
      } else {
        setState(() {
          _quote = "Serverfehler: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _quote = "Fehler: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mental Health App")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "Wie fühlst du dich?"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : () => getQuote(_controller.text),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Zitat finden"),
            ),
            const SizedBox(height: 20),
            Text(_quote, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
