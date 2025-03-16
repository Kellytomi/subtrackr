import 'package:flutter/material.dart';
import 'package:subtrackr/data/services/notification_service.dart';

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _titleController = TextEditingController(text: 'Subscription Renewal');
  final TextEditingController _bodyController = TextEditingController(text: 'Your Netflix subscription is due for renewal tomorrow.');
  DateTime _scheduledDate = DateTime.now().add(const Duration(seconds: 10));

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Notification Body',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Scheduled Date: '),
                Text(
                  '${_scheduledDate.toLocal()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  final TimeOfDay? timePicked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_scheduledDate),
                  );
                  if (timePicked != null) {
                    setState(() {
                      _scheduledDate = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                        timePicked.hour,
                        timePicked.minute,
                      );
                    });
                  }
                }
              },
              child: const Text('Select Date & Time'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _notificationService.showNotification(
                  id: 0,
                  title: _titleController.text,
                  body: _bodyController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Immediate notification sent!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Send Immediate Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _notificationService.scheduleRenewalReminder(
                  id: 1,
                  title: _titleController.text,
                  body: _bodyController.text,
                  scheduledDate: _scheduledDate,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Notification scheduled for ${_scheduledDate.toLocal()}'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Schedule Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _notificationService.cancelAllNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cancelled')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cancel All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
} 