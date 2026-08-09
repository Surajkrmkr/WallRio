import 'package:flutter/material.dart';
import 'package:wallrio/model/export.dart';

class RecommendationService {
  static List<Walls> getRecommendedWalls(Walls currentWall, List<Walls> allWalls, {int limit = 12}) {
    if (allWalls.isEmpty) return [];

    final scores = <Walls, double>{};
    final seenSubjectIds = <String>{};

    for (final candidate in allWalls) {
      if (candidate.id == currentWall.id) continue;

      double score = 0;

      if (currentWall.subjectId.isNotEmpty && candidate.subjectId == currentWall.subjectId) {
        score += 50;
      }

      if (candidate.category.isNotEmpty && candidate.category == currentWall.category) {
        score += 25;
      }

      final sharedTags = candidate.tags.where((t) => currentWall.tags.contains(t)).length;
      score += sharedTags * 15;

      final sharedColors = candidate.colorsString.where((c) => currentWall.colorsString.contains(c)).length;
      score += sharedColors * 8;

      if (score > 0) {
        scores[candidate] = score;
      }
    }

    final sortedCandidates = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final results = <Walls>[];
    for (final wall in sortedCandidates) {
      if (wall.subjectId.isNotEmpty) {
        if (seenSubjectIds.contains(wall.subjectId)) continue;
        seenSubjectIds.add(wall.subjectId);
      }
      results.add(wall);
      if (results.length >= limit) break;
    }

    // Fallback if score matches are under limit
    if (results.length < limit) {
      for (final wall in allWalls) {
        if (wall.id == currentWall.id) continue;
        if (!results.contains(wall)) {
          if (wall.subjectId.isNotEmpty && seenSubjectIds.contains(wall.subjectId)) continue;
          if (wall.subjectId.isNotEmpty) seenSubjectIds.add(wall.subjectId);
          results.add(wall);
          if (results.length >= limit) break;
        }
      }
    }

    return results;
  }

  static List<LiveWallpaper> getRecommendedLiveWalls(
      LiveWallpaper currentWall, List<LiveWallpaper> allLive,
      {int limit = 12}) {
    if (allLive.isEmpty) return [];

    final scores = <LiveWallpaper, double>{};
    final seenSubjectIds = <String>{};

    for (final candidate in allLive) {
      if (candidate.id == currentWall.id) continue;

      double score = 0;

      if (currentWall.subjectId.isNotEmpty && candidate.subjectId == currentWall.subjectId) {
        score += 50;
      }

      if (candidate.category.isNotEmpty && candidate.category == currentWall.category) {
        score += 25;
      }

      final sharedTags = candidate.tags.where((t) => currentWall.tags.contains(t)).length;
      score += sharedTags * 15;

      final sharedColors = candidate.colorsString.where((c) => currentWall.colorsString.contains(c)).length;
      score += sharedColors * 8;

      if (score > 0) {
        scores[candidate] = score;
      }
    }

    final sortedCandidates = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final results = <LiveWallpaper>[];
    for (final wall in sortedCandidates) {
      if (wall.subjectId.isNotEmpty) {
        if (seenSubjectIds.contains(wall.subjectId)) continue;
        seenSubjectIds.add(wall.subjectId);
      }
      results.add(wall);
      if (results.length >= limit) break;
    }

    if (results.length < limit) {
      for (final wall in allLive) {
        if (wall.id == currentWall.id) continue;
        if (!results.contains(wall)) {
          if (wall.subjectId.isNotEmpty && seenSubjectIds.contains(wall.subjectId)) continue;
          if (wall.subjectId.isNotEmpty) seenSubjectIds.add(wall.subjectId);
          results.add(wall);
          if (results.length >= limit) break;
        }
      }
    }

    return results;
  }

  static List<Walls> getRecommendedStaticForLive(
      LiveWallpaper currentLive, List<Walls> allWalls,
      {int limit = 12}) {
    if (allWalls.isEmpty) return [];

    final scores = <Walls, double>{};
    final seenSubjectIds = <String>{};

    for (final candidate in allWalls) {
      double score = 0;

      if (currentLive.subjectId.isNotEmpty && candidate.subjectId == currentLive.subjectId) {
        score += 50;
      }

      if (candidate.category.isNotEmpty && candidate.category == currentLive.category) {
        score += 25;
      }

      final sharedTags = candidate.tags.where((t) => currentLive.tags.contains(t)).length;
      score += sharedTags * 15;

      final sharedColors = candidate.colorsString.where((c) => currentLive.colorsString.contains(c)).length;
      score += sharedColors * 8;

      if (score > 0) {
        scores[candidate] = score;
      }
    }

    final sortedCandidates = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    final results = <Walls>[];
    for (final wall in sortedCandidates) {
      if (wall.subjectId.isNotEmpty) {
        if (seenSubjectIds.contains(wall.subjectId)) continue;
        seenSubjectIds.add(wall.subjectId);
      }
      results.add(wall);
      if (results.length >= limit) break;
    }

    if (results.length < limit) {
      for (final wall in allWalls) {
        if (!results.contains(wall)) {
          if (wall.subjectId.isNotEmpty && seenSubjectIds.contains(wall.subjectId)) continue;
          if (wall.subjectId.isNotEmpty) seenSubjectIds.add(wall.subjectId);
          results.add(wall);
          if (results.length >= limit) break;
        }
      }
    }

    return results;
  }
}
