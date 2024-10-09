import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TruthDareApp());
}

class TruthDareApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Truth or Dare Game',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Montserrat', // Custom font
      ),
      home: TruthDareScreen(),
    );
  }
}

class TruthDareScreen extends StatefulWidget {
  @override
  _TruthDareScreenState createState() => _TruthDareScreenState();
}

class _TruthDareScreenState extends State<TruthDareScreen>
    with TickerProviderStateMixin {
  String selectedLevel = 'friendly'; // Default level
  String selectedType = 'truth'; // Default type
  String result = 'Let\'s start the game!';
  final AudioPlayer player = AudioPlayer();
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _loadCachedResult();

    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Initialize the fade-in animation
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  Future<void> _loadCachedResult() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      result = prefs.getString('cachedResult') ?? 'No result yet';
    });
  }

  Future<void> _saveCachedResult(String newResult) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cachedResult', newResult);
  }

  Future<void> _playButtonSound() async {
    await player.play(AssetSource('sounds/button_click.mp3'));
  }

  Future<void> fetchTruthOrDare() async {
    const url = 'https://randommer.io/truth-dare-generator';

    Map<String, String> headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
      'X-Requested-With': 'XMLHttpRequest',
    };

    Map<String, String> body = {
      'category': selectedLevel,
      'type': selectedType,
      '__RequestVerificationToken':
          'CfDJ8BMaUclgZEpGmqozLqF4rd1ykMQsMfAfUfIWxSCU1sci3cXT3Dbs40vGFbqD0aX8qvgaM-ZBdB09w4FkH-tpKX9gR3JmkaiAAX6Y4dlYaWWEeCva2EUquhw7uifMzoPFCT1RCoSV9hexUrOF5ETbCuk',
    };

    try {
      final response =
          await http.post(Uri.parse(url), headers: headers, body: body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          result = data['text'];
          _controller.forward(from: 0); // Trigger fade-in animation
        });
        _saveCachedResult(result);
        _playButtonSound(); // Play sound when result is fetched
      } else {
        setState(() {
          result = 'Failed to fetch data. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        result = 'Network error: Could not fetch data.';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller
    super.dispose();
  }

  // Function to show description dialog
  void _showDescriptionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Description'),
          content: const Text(
            'This is a Truth or Dare game where you can select levels and challenge yourself with fun tasks. Choose between friendly and dirty questions and enjoy the game with friends!',
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Truth or Dare',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            Colors.deepPurple, // Rich purple color for the background
        elevation: 4, // Slight shadow for depth
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              size: 28, // Increase the size of the icon
              color:
                  Colors.white, // Ensure the icon color is white for visibility
            ),
            onPressed: _showDescriptionDialog, // Show description dialog
          ),
          const SizedBox(width: 16), // Add spacing between icons
        ],
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.vertical(
        //     bottom: Radius.circular(30), // Rounded corners at the bottom
        //   ),
        // ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Level Dropdown
              _buildDropdownField(
                label: "Choose Level",
                value: selectedLevel,
                items: ['friendly', 'dirty'],
                onChanged: (String? newValue) {
                  setState(() {
                    selectedLevel = newValue!;
                  });
                },
              ),

              // Truth/Dare Dropdown
              _buildDropdownField(
                label: "Truth or Dare",
                value: selectedType,
                items: ['truth', 'dare'],
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Fetch Button
              _buildCustomButton('Get Challenge', fetchTruthOrDare),

              const SizedBox(height: 40),

              // Display result with fade animation
              FadeTransition(
                opacity: _fadeInAnimation,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Dropdown builder
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
            style: const TextStyle(color: Colors.black, fontSize: 16),
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item.capitalize()),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Custom button builder
  Widget _buildCustomButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8.0,
        shadowColor: Colors.black54,
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
