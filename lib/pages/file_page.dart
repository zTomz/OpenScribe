import 'package:flutter/material.dart';
import 'package:openscribe/pages/note_editing_page.dart';

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NoteEditingPage(),
              ),
            );
          },
          child: const Text("Go to first page"),
        ),
      ),
    );
  }
}
