import 'package:flutter/material.dart';
import 'package:wallrio/ui/views/export.dart';

List<Widget> pages = [
  const HomePage(),
  const LivePage(isTab: true),
  const CollectionPage(),
  const CategoryPage(),
  const DesktopWallpapersPage(isTab: true),
];
