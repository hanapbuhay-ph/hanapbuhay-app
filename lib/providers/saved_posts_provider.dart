import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/job_post_model.dart';

class SavedPostsProvider extends ChangeNotifier {
  String? _activeUserId;
  String? _loadingUserId;
  bool _isLoaded = false;
  List<JobPostListing> _savedPosts = [];
  Future<void>? _loadOperation;

  List<JobPostListing> get savedPosts => List.unmodifiable(_savedPosts);
  bool get isLoaded => _isLoaded;

  bool isSaved(String postId) =>
      _savedPosts.any((listing) => listing.post.id == postId);

  Future<void> loadForUser(String? userId) {
    if (userId == null || userId.isEmpty) {
      _activeUserId = null;
      _isLoaded = true;
      _savedPosts = [];
      notifyListeners();
      return Future<void>.value();
    }
    if (_activeUserId == userId && _isLoaded) {
      return Future<void>.value();
    }
    if (_loadingUserId == userId && _loadOperation != null) {
      return _loadOperation!;
    }

    _activeUserId = userId;
    _loadingUserId = userId;
    _isLoaded = false;
    _savedPosts = [];
    notifyListeners();
    final operation = _readSavedPosts(userId);
    _loadOperation = operation;
    return operation;
  }

  Future<void> _readSavedPosts(String userId) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encodedPosts =
          preferences.getStringList(_storageKey(userId)) ?? const [];
      final posts = encodedPosts
          .map(
            (encoded) => JobPostListing.fromJson(
              jsonDecode(encoded) as Map<String, dynamic>,
            ),
          )
          .toList();

      if (_activeUserId != userId) return;
      _savedPosts = posts;
      _isLoaded = true;
      notifyListeners();
    } finally {
      if (_loadingUserId == userId) {
        _loadingUserId = null;
        _loadOperation = null;
      }
    }
  }

  Future<void> toggleSavedPost({
    required String userId,
    required JobPostListing listing,
  }) async {
    await loadForUser(userId);
    if (_activeUserId != userId || !_isLoaded) {
      throw StateError('Saved services are not available for this account.');
    }

    final updatedPosts = List<JobPostListing>.from(_savedPosts);
    final existingIndex = updatedPosts.indexWhere(
      (saved) => saved.post.id == listing.post.id,
    );
    if (existingIndex >= 0) {
      updatedPosts.removeAt(existingIndex);
    } else {
      updatedPosts.insert(0, listing);
    }

    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(
      _storageKey(userId),
      updatedPosts.map((post) => jsonEncode(post.toJson())).toList(),
    );
    if (!saved) {
      throw StateError('Unable to save this service on this device.');
    }
    if (_activeUserId != userId) return;
    _savedPosts = updatedPosts;
    notifyListeners();
  }

  static String _storageKey(String userId) => 'saved_services_$userId';
}
