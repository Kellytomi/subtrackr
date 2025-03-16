import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<dynamic> _pendingNotifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadPendingNotifications();
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    try {
      await _notificationService.init();
      final bool granted = await _notificationService.requestPermissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification permissions ${granted ? 'granted' : 'denied'}'),
            backgroundColor: granted ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      if (mounted) {
        setState(() {
          _pendingNotifications = pending;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending notifications: $e');
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingNotifications,
            tooltip: 'Refresh pending notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade800),
                                const SizedBox(width: 8),
                                Text(
                                  'Permission Required',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(_errorMessage!),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () async {
                                await _notificationService.openAlarmPermissionSettings();
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Open Settings'),
                            ),
                          ],
                        ),
                      ),
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
                        _notificationService.showTestNotification();
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
                      onPressed: () async {
                        try {
                          setState(() {
                            _errorMessage = null;
                          });
                          
                          final tenSecondsFromNow = DateTime.now().add(const Duration(seconds: 10));
                          await _notificationService.scheduleNotification(
                            id: 1,
                            title: "${_titleController.text} (10s)",
                            body: "${_bodyController.text} (10s test)",
                            scheduledDate: tenSecondsFromNow,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notification scheduled for 10 seconds from now'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadPendingNotifications();
                          }
                        } catch (e) {
                          if (mounted) {
                            if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
                              setState(() {
                                _errorMessage = 'This app needs permission to schedule exact alarms. '
                                    'Please open settings and grant the "Schedule Exact Alarms" permission.';
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error scheduling notification: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Schedule in 10 Seconds'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          setState(() {
                            _errorMessage = null;
                          });
                          
                          await _notificationService.scheduleNotification(
                            id: 2,
                            title: _titleController.text,
                            body: _bodyController.text,
                            scheduledDate: _scheduledDate,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Notification scheduled for ${_scheduledDate.toLocal()}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadPendingNotifications();
                          }
                        } catch (e) {
                          if (mounted) {
                            if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
                              setState(() {
                                _errorMessage = 'This app needs permission to schedule exact alarms. '
                                    'Please open settings and grant the "Schedule Exact Alarms" permission.';
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error scheduling notification: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Schedule Custom Notification'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _notificationService.cancelAllNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications cancelled'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        _loadPendingNotifications();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel All Notifications'),
                    ),
                    if (_pendingNotifications.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Pending Notifications:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        _pendingNotifications.length,
                        (index) {
                          final notification = _pendingNotifications[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(notification.title ?? 'No title'),
                              subtitle: Text(notification.body ?? 'No body'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _notificationService.cancelNotification(notification.id);
                                  _loadPendingNotifications();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Notification ${notification.id} cancelled'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
} 