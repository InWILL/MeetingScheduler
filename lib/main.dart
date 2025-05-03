import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meeting Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MeetingListPage(),
    );
  }
}

class MeetingListPage extends StatefulWidget {
  @override
  _MeetingListPageState createState() => _MeetingListPageState();
}

class _MeetingListPageState extends State<MeetingListPage> {
  late Future<List<Meeting>> _futureMeetings;

  @override
  void initState() {
    super.initState();
    _futureMeetings = fetchMeetings();
  }

  Future<List<Meeting>> fetchMeetings() async {
    final url = Uri.parse(
        'https://uxo0tjm9g9.execute-api.eu-north-1.amazonaws.com/GetMeeting');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Meeting.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load meetings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meeting Scheduler')),
      body: FutureBuilder<List<Meeting>>(
        future: _futureMeetings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No meetings available.'));
          }

          final meetings = snapshot.data!;
          return ListView.builder(
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16.0),
                    title: Text(
                      meeting.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Start: ${DateFormat.yMd().add_jm().format(meeting.startTime)}\n'
                      'End: ${DateFormat.yMd().add_jm().format(meeting.endTime)}\n'
                      'Location: ${meeting.location}',
                      style: TextStyle(fontSize: 16),
                    ),
                    trailing: Icon(Icons.access_time),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // Navigate to CreateMeetingPage and refresh list when return
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateMeetingPage()),
          );
          if (result == true) {
            setState(() {
              _futureMeetings = fetchMeetings();
            });
          }
        },
      ),
    );
  }

}

class Meeting {
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;

  Meeting({
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      title: json['Title'],
      location: json['Location'],
      startTime: DateTime.parse(json['StartTime']),
      endTime: DateTime.parse(json['EndTime']),
    );
  }
}

class CreateMeetingPage extends StatefulWidget {
  @override
  _CreateMeetingPageState createState() => _CreateMeetingPageState();
}

class _CreateMeetingPageState extends State<CreateMeetingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final url = Uri.parse('https://uxo0tjm9g9.execute-api.eu-north-1.amazonaws.com/CreateMeeting');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Title': _titleController.text,
        'Location': _locationController.text,
        'StartTime': _startTime!.toUtc().toIso8601String(),
        'EndTime': _endTime!.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true); // return to list and trigger refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create meeting')));
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dateTime;
      } else {
        _endTime = dateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Meeting')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) => value == null || value.isEmpty ? 'Enter location' : null,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text(_startTime == null
                    ? 'Select Start Time'
                    : 'Start: ${DateFormat.yMd().add_jm().format(_startTime!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(isStart: true),
              ),
              ListTile(
                title: Text(_endTime == null
                    ? 'Select End Time'
                    : 'End: ${DateFormat.yMd().add_jm().format(_endTime!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(isStart: false),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Create Meeting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
