import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../utils/review_service.dart';
import '../../utils/validators.dart';

class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({
    super.key,
    required this.bookingId,
    required this.serviceId,
    required this.providerId,
  });

  final String bookingId;
  final String serviceId;
  final String providerId;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      await ReviewService.submitReview(
        bookingId: widget.bookingId,
        serviceId: widget.serviceId,
        providerId: widget.providerId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting review: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _rating,
              items: List.generate(5, (index) {
                final value = index + 1;
                return DropdownMenuItem(
                  value: value,
                  child: Text('$value Stars'),
                );
              }),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _rating = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Rating'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Comment'),
              maxLines: 3,
              validator: (value) =>
                  Validators.minLengthField(value, 10, 'Comment'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving...' : 'Submit Review'),
            ),
          ],
        ),
      ),
    );

    if (kIsWeb) {
      return WebPageScaffold(
        title: 'Leave a Review',
        subtitle: 'Share quality feedback about your completed booking.',
        useScaffold: true,
        child: body,
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Leave a Review')), body: body);
  }
}
