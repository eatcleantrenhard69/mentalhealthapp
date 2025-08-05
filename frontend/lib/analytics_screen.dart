// Simple Habit Tracker App
// This is a complete Flutter app in one file

import 'package:flutter/material.dart';

// STEP 1: Main function - This is where the app starts
void main() {
  runApp(HabitTrackerApp()); // Start the app
}

// STEP 2: Main App Widget - This sets up the overall app theme and structure
class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Habit Tracker', // App title
      theme: ThemeData.dark(), // Use dark theme
      home: HabitScreen(), // The main screen of our app
    );
  }
}

// STEP 3: Habit Data Model - This defines what a habit looks like
class Habit {
  final String id; // Unique identifier
  final String name; // Name of the habit (e.g., "Read books")
  final String category; // Category (e.g., "Learning")
  final Color color; // Color for visual identification
  
  // Constructor - how to create a new habit
  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.color,
  });
}

// STEP 4: Main Screen - This is a StatefulWidget because data can change
class HabitScreen extends StatefulWidget {
  @override
  _HabitScreenState createState() => _HabitScreenState();
}

// STEP 5: Screen State - This holds all the data and logic
class _HabitScreenState extends State<HabitScreen> {
  // This list holds all our habits
  List<Habit> habits = [];
  
  // This map tracks daily values for each habit
  // Format: "habitId_date" -> hours spent
  Map<String, double> dailyValues = {};

  // STEP 6: Helper function to get today's date as a string
  String getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // STEP 7: Helper function to create a key for storing daily values
  String getDailyKey(String habitId, String date) {
    return '${habitId}_$date';
  }

  // STEP 8: Function to add a new habit
  void addHabit(String name, String category, Color color) {
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID using timestamp
      name: name,
      category: category,
      color: color,
    );
    
    setState(() {
      habits.add(habit); // Add to the list
    });
  }

  // STEP 9: Function to remove a habit
  void removeHabit(String habitId) {
    setState(() {
      habits.removeWhere((habit) => habit.id == habitId); // Remove from list
      // Also remove all daily values for this habit
      dailyValues.removeWhere((key, value) => key.startsWith(habitId));
    });
  }

  // STEP 10: Function to update daily value for a habit
  void updateDailyValue(String habitId, double value) {
    final key = getDailyKey(habitId, getTodayKey());
    setState(() {
      if (value <= 0) {
        dailyValues.remove(key); // Remove if zero or negative
      } else {
        dailyValues[key] = value; // Store the value
      }
    });
  }

  // STEP 11: Function to get today's value for a habit
  double getTodayValue(String habitId) {
    final key = getDailyKey(habitId, getTodayKey());
    return dailyValues[key] ?? 0.0; // Return 0 if no value stored
  }
  // NEW: Get value for a specific habit on a specific date
double getValueForDate(String habitId, DateTime date) {
  final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  final key = getDailyKey(habitId, dateKey);
  return dailyValues[key] ?? 0.0;
}

// NEW: Get color intensity based on hours (0-4+ hours)
Color getGridColor(double value, Color baseColor) {
  if (value == 0) return Colors.grey.shade800;
  if (value < 1) return baseColor.withOpacity(0.3);
  if (value < 2) return baseColor.withOpacity(0.5);
  if (value < 3) return baseColor.withOpacity(0.7);
  return baseColor;
}

  // STEP 12: Build the main UI
 @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text('My Habits'),
        backgroundColor: Colors.blueGrey.shade900,
        bottom: TabBar(
          tabs: [
            Tab(icon: Icon(Icons.list), text: 'Habits'),
            Tab(icon: Icon(Icons.grid_view), text: 'Grid'),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey.shade900,
        child: TabBarView(
          children: [
            // First tab - existing habits list
            habits.isEmpty ? _buildEmptyState() : _buildHabitsList(),
            // Second tab - new grid view
            _buildGridView(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    ),
  );
}
// NEW: Build the grid view
Widget _buildGridView() {
  if (habits.isEmpty) {
    return Center(
      child: Text(
        'Add some habits first!',
        style: TextStyle(color: Colors.white70, fontSize: 18),
      ),
    );
  }

  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      children: habits.map((habit) => _buildHabitGrid(habit)).toList(),
    ),
  );
}

// NEW: Build grid for individual habit
Widget _buildHabitGrid(Habit habit) {
  final now = DateTime.now();
  final startDate = now.subtract(Duration(days: 364)); // Last 365 days
  
  return Card(
    color: Colors.grey.shade800,
    margin: EdgeInsets.only(bottom: 20),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Habit header
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: habit.color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                habit.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Grid
          Container(
            height: 120,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // 7 days per week
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 365,
              itemBuilder: (context, index) {
                final date = startDate.add(Duration(days: index));
                final value = getValueForDate(habit.id, date);
                return Container(
                  decoration: BoxDecoration(
                    color: getGridColor(value, habit.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            ),
          ),
          
          // Legend
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(width: 4),
              ...List.generate(5, (i) => Container(
                width: 10,
                height: 10,
                margin: EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: i == 0 ? Colors.grey.shade800 : habit.color.withOpacity(0.2 + (i * 0.2)),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              SizedBox(width: 4),
              Text('More', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    ),
  );
}
  // STEP 13: Build empty state (when no habits exist)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'No habits yet!',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add your first habit',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // STEP 14: Build the list of habits
  Widget _buildHabitsList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return _buildHabitCard(habit);
      },
    );
  }

  // STEP 15: Build individual habit card
  Widget _buildHabitCard(Habit habit) {
    final todayValue = getTodayValue(habit.id);
    
    return Card(
      color: Colors.grey.shade800,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Color indicator circle
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: habit.color,
                shape: BoxShape.circle,
              ),
            ),
            
            SizedBox(width: 16),
            
            // Habit info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    habit.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            // Value controls
            Row(
              children: [
                // Decrease button
                IconButton(
                  onPressed: () {
                    updateDailyValue(habit.id, todayValue - 0.5);
                  },
                  icon: Icon(Icons.remove_circle_outline),
                  color: Colors.white70,
                ),
                
                // Current value display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${todayValue.toStringAsFixed(1)}h',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Increase button
                IconButton(
                  onPressed: () {
                    updateDailyValue(habit.id, todayValue + 0.5);
                  },
                  icon: Icon(Icons.add_circle_outline),
                  color: Colors.white70,
                ),
              ],
            ),
            
            // Delete button
            IconButton(
              onPressed: () => _showDeleteDialog(habit),
              icon: Icon(Icons.delete_outline),
              color: Colors.red.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // STEP 16: Show dialog to add new habit
  void _showAddHabitDialog() {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    Color selectedColor = Colors.blue; // Default color
    
    // Predefined colors to choose from
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: Text(
            'Add New Habit',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Habit name input
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Habit Name (e.g., "Read books")',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Category input
              TextField(
                controller: categoryController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category (e.g., "Learning")',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Color selection
              Text(
                'Choose a color:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colors.map((color) => GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selectedColor == color
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
          actions: [
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            
            // Add button
            TextButton(
              onPressed: () {
                // Check if fields are filled
                if (nameController.text.trim().isNotEmpty &&
                    categoryController.text.trim().isNotEmpty) {
                  addHabit(
                    nameController.text.trim(),
                    categoryController.text.trim(),
                    selectedColor,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // STEP 17: Show confirmation dialog before deleting
  void _showDeleteDialog(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: Text(
          'Delete Habit',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${habit.name}"?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              removeHabit(habit.id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}