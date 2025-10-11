import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Musify/providers/search_provider.dart';
import 'package:Musify/core/constants/app_colors.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: TextField(
        onSubmitted: (String value) {
          onSearch();
        },
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: AppColors.accent,
        ),
        cursorColor: Colors.green[50],
        decoration: InputDecoration(
          fillColor: AppColors.backgroundSecondary,
          filled: true,
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(100),
            ),
            borderSide: BorderSide(
              color: AppColors.backgroundSecondary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(100),
            ),
            borderSide: BorderSide(color: AppColors.accent),
          ),
          suffixIcon: Consumer<SearchProvider>(
            builder: (context, searchProvider, child) {
              return IconButton(
                icon: Icon(
                  Icons.search,
                  color: AppColors.accent,
                ),
                color: AppColors.accent,
                onPressed: searchProvider.isSearching
                    ? null
                    : () {
                        onSearch();
                      },
              );
            },
          ),
          border: InputBorder.none,
          hintText: "Search...",
          hintStyle: TextStyle(
            color: AppColors.accent,
          ),
          contentPadding: const EdgeInsets.only(
            left: 18,
            right: 20,
            top: 14,
            bottom: 14,
          ),
        ),
      ),
    );
  }
}
