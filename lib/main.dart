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
      appBar: AppBar(title: Text('Meeting Schedule')),
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
