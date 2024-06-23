import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';

import '../models/grocery_item.dart';
import 'new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var isLoading = true;
  String? _error;

  @override
  void initState() {
    loadItems();
    super.initState();
  }

  void _addItem() async {
    final newItem =
        await Navigator.of(context).push<GroceryItem>(MaterialPageRoute(
      builder: (context) => const NewItem(),
    ));

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
      isLoading = false;
    });
  }

  void _removeItem(item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https("flutter-prep-dd7a1-default-rtdb.firebaseio.com",
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  void loadItems() async {
    final url = Uri.https(
        "flutter-prep-dd7a1-default-rtdb.firebaseio.com", 'shopping-list.json');
    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = "failed to fetch data please try later";
        });
        return;
      }
      if (response.body == 'null') {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      final List<GroceryItem> loadedItems = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (element) => element.value.title == item.value['category'])
            .value;
        loadedItems.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }

      setState(() {
        _groceryItems = loadedItems;
      });
    } catch (error) {
      setState(() {
        _error = "failed to fetch data please try later";
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
        child: Text(
      "The Grocery List is Empty !!",
      style: Theme.of(context).textTheme.headlineSmall,
    ));

    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (context, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            onTap: () {},
            title: Text(_groceryItems[index].name),
            trailing: Text(_groceryItems[index].quantity.toString()),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
          ),
        ),
      );
    }
    if (_error != null) {
      content = Center(child: Text(_error!));
    }

    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
        title: const Text("Your Groceries"),
      ),
      body: content,
    );
  }
}
