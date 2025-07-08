import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MentalHealthApp());

class MentalHealthApp extends StatelessWidget {
  const MentalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B73FF),
          brightness: Brightness.light,
        ),
      ),
      home: const MentalHealthHome(),
    );
  }
}

class MentalHealthHome extends StatefulWidget {
  const MentalHealthHome({super.key});

  @override
  State<MentalHealthHome> createState() => _MentalHealthHomeState();
}

class _MentalHealthHomeState extends State<MentalHealthHome> 
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  String _quote = "";
  bool _loading = false;
  
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start header animation
    _slideController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> getQuote(String userInput) async {
    setState(() {
      _loading = true;
      _quote = "";
    });

    // Reset animations
    _bounceController.reset();
    _fadeController.reset();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/get_quote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': userInput}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _quote = data['quote_info'] ?? "Kein Zitat gefunden.";
        });
        
        // Trigger animations
        _fadeController.forward();
        _bounceController.forward();
      } else {
        setState(() {
          _quote = "Serverfehler: ${response.statusCode}\n${response.body}";
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Animated Header
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Animated Icon with glow effect
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white38,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(51),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Animated Title
                      const Text(
                        "Mental Health",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      
                      const Text(
                        "Companion",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Main Content Card
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 60,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Input Section with animation
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.mood,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Wie fühlst du dich heute?",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Text Input
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  maxLines: 4,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Erzähl mir von deinen Gefühlen...",
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(20),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 20),
                              
                              // Animated Button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea).withAlpha(102),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: _loading ? null : () => getQuote(_controller.text),
                                    child: Center(
                                      child: _loading
                                          ? const SizedBox(
                                              width: 28,
                                              height: 28,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.auto_awesome,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  "Zitat finden",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 30),
                        
                        // Animated Quote Display
                        if (_quote.isNotEmpty)
                          Expanded(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: ScaleTransition(
                                scale: _bounceAnimation,
                                child: Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFE8F0FE),
                                        Color(0xFFF3E5F5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(0xFF667eea).withAlpha(77),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF667eea).withAlpha(51),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: const Icon(
                                              Icons.format_quote,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          const Text(
                                            "Dein inspirierendes Zitat",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 20),
                                      
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Text(
                                            _quote,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              height: 1.7,
                                              color: Color(0xFF2C3E50),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Empty State
                        if (_quote.isEmpty && !_loading)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 600),
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade100,
                                          Colors.grey.shade50,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.sentiment_satisfied_alt,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  Text(
                                    "Erzähl mir, wie du dich fühlst",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  Text(
                                    "Ich werde dir ein passendes Zitat finden",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}