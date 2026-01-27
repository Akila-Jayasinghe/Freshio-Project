import 'dart:io';
import 'package:flutter/material.dart';
import '../db_service.dart';
import '../image_utils.dart';

class FeedbackSheet extends StatefulWidget {
  final File imageFile;
  final String aiResult;
  final double confidence;

  const FeedbackSheet({
    super.key,
    required this.imageFile,
    required this.aiResult,
    required this.confidence,
  });

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  // State variables
  String _selectedQuality = 'Fresh';
  bool _isSaving = false;

  // New Toggle: Is this actually a fruit?
  bool _isInvalidObject = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Logic to save data to SQLite
  Future<void> _submitFeedback() async {
    // Only validate the text field if it's visible (i.e., it IS a fruit)
    if (!_isInvalidObject && !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Resize the image
      final String optimizedPath = await ImageUtils.saveOptimizedImage(
        widget.imageFile,
      );
      print("✅ Image successfully saved at: $optimizedPath");

      // Determine values based on the toggle
      String finalName;
      String finalQuality;

      if (_isInvalidObject) {
        // If user says it's not a fruit, we label it as "Non-Fruit" / "N/A"
        finalName = "Non-Fruit";
        finalQuality = "N/A";
      } else {
        // Otherwise, use their input
        finalName = _nameController.text.trim();
        finalQuality = _selectedQuality;
      }

      // Save metadata to SQLite Database
      await DBService().insertInspection(
        imagePath: optimizedPath,
        aiResult: widget.aiResult,
        userFruitName: finalName,
        userQuality: finalQuality,
        confidence: widget.confidence,
      );

      // Close the sheet
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanks! Feedback saved for future training.'),
          ),
        );
      }
    } catch (e) {
      print("❌ Error saving feedback: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving feedback: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Help us improve",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                "AI saw: ${widget.aiResult}",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const Divider(height: 20),

              // The "Not a Fruit" Switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "This is NOT a fruit/vegetable",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("e.g. hand, wall, table..."),
                value: _isInvalidObject,
                activeColor: Colors.orange,
                onChanged: (bool value) {
                  setState(() {
                    _isInvalidObject = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // Conditional Inputs (Only show if it IS a fruit)
              if (!_isInvalidObject) ...[
                const Text(
                  "What is this item actually?",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "e.g. Carrot, Green Apple...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (value) {
                    // Only validate if visible
                    if (!_isInvalidObject && (value == null || value.isEmpty)) {
                      return 'Please enter the fruit/vegetable name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  "What is its condition?",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildChoiceChip("Fresh", Colors.green),
                    const SizedBox(width: 15),
                    _buildChoiceChip("Rotten", Colors.red),
                  ],
                ),
              ] else ...[
                // Show a message confirming no input needed
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "We will mark this image as 'Non-Fruit' to teach the AI to ignore it next time.",
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Feedback",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the selection chips
  Widget _buildChoiceChip(String label, Color color) {
    final bool isSelected = _selectedQuality == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: color,
      onSelected: (bool selected) {
        setState(() {
          _selectedQuality = label;
        });
      },
    );
  }
}
