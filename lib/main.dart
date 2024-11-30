import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("taskBox");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  List showAll = [];
  List filteredList = [];
  var taskBox = Hive.box("taskBox");

  createData(Map<String, dynamic> row) async {
    await taskBox.add(row);
    readAll();
  }

  updateData(int? key, Map<String, dynamic> row) async {
    await taskBox.put(key, row);
    readAll();
  }

  readAll() async {
    var data = taskBox.keys.map(
      (e) {
        final items = taskBox.get(e);
        return {
          "key": e,
          "name": items["name"],
          "email": items["email"],
          "title": items["title"],
          "desc": items["desc"],
          "date": items["date"],
          "time": items["time"]
        };
      },
    ).toList();

    setState(() {
      showAll = data.reversed.toList();
      filteredList = showAll;
    });
  }

  void filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredList = showAll;
      } else {
        filteredList = showAll
            .where((element) =>
                element["name"].toLowerCase().contains(query.toLowerCase()) ||
                element["email"].toLowerCase().contains(query.toLowerCase()) ||
                element["title"].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    readAll();
    searchController.addListener(() {
      filterList(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CRUD with Search"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Search by name, email, or title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openModal(0);
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(filteredList[index]["title"]),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${filteredList[index]["name"]}"),
                Text("Email: ${filteredList[index]["email"]}"),
                Text("Date: ${filteredList[index]["date"]}"),
                Text("Time: ${filteredList[index]["time"]}"),
                Text("Description: ${filteredList[index]["desc"]}")
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    var updateKey = filteredList[index]["key"];
                    openModal(updateKey);
                  },
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  onPressed: () {
                    var deleteKey = filteredList[index]["key"];
                    taskBox.delete(deleteKey);
                    readAll();
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        timeController.text = picked.format(context);
      });
    }
  }

  void openModal(int id) {
    nameController.clear();
    emailController.clear();
    titleController.clear();
    descController.clear();
    dateController.clear();
    timeController.clear();

    if (id != 0) {
      final item = showAll.firstWhere((element) => element["key"] == id);
      nameController.text = item["name"];
      emailController.text = item["email"];
      titleController.text = item["title"];
      descController.text = item["desc"];
      dateController.text = item["date"];
      timeController.text = item["time"];
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            32,
            32,
            32,
            MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Enter Name"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: "Enter Email"),
              ),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: "Enter Title"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(hintText: "Enter Description"),
              ),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(hintText: "Enter Date"),
                onTap: () => pickDate(context),
              ),
              TextField(
                controller: timeController,
                readOnly: true,
                decoration: const InputDecoration(hintText: "Enter Time"),
                onTap: () => pickTime(context),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  var data = {
                    "name": nameController.text,
                    "email": emailController.text,
                    "title": titleController.text,
                    "desc": descController.text,
                    "date": dateController.text,
                    "time": timeController.text
                  };
                  if (id == 0) {
                    createData(data);
                  } else {
                    updateData(id, data);
                  }
                  Navigator.pop(context);
                },
                child: Text(id == 0 ? "Add" : "Update"),
              ),
            ],
          ),
        );
      },
    );
  }
}
