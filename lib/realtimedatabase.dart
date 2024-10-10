import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeDatabase extends StatefulWidget {
  const RealtimeDatabase({super.key});

  @override
  State<RealtimeDatabase> createState() => _RealTimeDatabaseState();
}

// tham chiếu tới products trong firebase, nơi lưu trữ thông tin sp
final databaseRf = FirebaseDatabase.instance.ref("products");

class _RealTimeDatabaseState extends State<RealtimeDatabase> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  String? _message; // Biến để lưu trữ thông báo
  XFile? _imageFile; // Biến để lưu trữ ảnh đã chọn
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 215, 241, 207),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.green,
        title: const Text(
          "Product Manage ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_message != null)
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.green[300],
              child: Text(
                _message!,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
//  FirebaseAnimatedList hiển thị danh sách sp dưới dạng Card
          Expanded(
            child: FirebaseAnimatedList(
              query: databaseRf,
              itemBuilder: (context, snapshot, animation, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  // listTile hiển thị thông tin sp gồm nút edit, delete
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        snapshot.child("image_url").value.toString(),
                      ),
                      child: snapshot.child("image_url").value == null
                          ? Text((index + 1).toString())
                          : null,
                    ),
                    title: Text(
                      'Name: ${snapshot.child("name").value.toString()} ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // if (snapshot.child("image_url").value != null)
                        //   Image.network(
                        //     snapshot.child("image_url").value.toString(),
                        //     height: 100,
                        //     fit: BoxFit.cover,
                        //   ),
                        Text(
                          'Category: ${snapshot.child("category").value.toString()} ',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Price: ${snapshot.child("price").value.toString()} VND',
                          style: const TextStyle(
                              color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Color.fromARGB(255, 59, 226, 126)),
                          onPressed: () {
                            _showEditDialog(snapshot);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(
                                snapshot.child("id").value.toString());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
// Nút add SP mới
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

// pickImage chọn hình ảnh từ thư viện-> image được chọn lưu trong imageFile
  Future<void> _pickImage() async {
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);

    if (selectedImage != null) {
      setState(() {
        _imageFile = selectedImage; // Lưu ảnh đã chọn
      });
    }
  }

// Hộp thoại Add sản phẩm
  void _showAddDialog() {
    nameController.clear();
    categoryController.clear();
    priceController.clear();
    _imageFile = null; // Reset ảnh
    _showDialog(
      title: "Add Product",
      actionText: "Add",
      onPressed: () {
        _addProduct();
        Navigator.pop(context);
      },
    );
  }

// Hộp thoại Edit
  void _showEditDialog(DataSnapshot snapshot) {
    nameController.text = snapshot.child("name").value.toString();
    priceController.text = snapshot.child("price").value.toString();
    categoryController.text = snapshot.child("category").value.toString();
    _imageFile = null; // Reset ảnh
    _showDialog(
      title: "Update Product",
      actionText: "Update",
      onPressed: () {
        _updateProduct(snapshot.child("id").value.toString());
        Navigator.pop(context);
      },
    );
  }

  void _showDialog({
    required String title,
    required String actionText,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.blue[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Enter Name",
                    hintText: "e.g Sunflower ",
                  ),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: "Enter Price",
                    hintText: "e.g. 100",
                  ),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: "Enter Category",
                    hintText: "e.g. Flower",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image'),
                ),
                if (_imageFile != null) ...[
                  const SizedBox(height: 10),
                  Image.file(
                    File(_imageFile!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onPressed,
                  child: Text(actionText),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

// phương thức addProduct để thêm sp mới vào Firebase
  Future<void> _addProduct() async {
    String? downloadURL;

    if (_imageFile != null) {
      final String fileName = _imageFile!.name;
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');

      await storageRef.putFile(File(_imageFile!.path));
      downloadURL = await storageRef.getDownloadURL();
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    databaseRf.child(id).set({
      'category': categoryController.text,
      'image_url': downloadURL ?? "placeholder_image_url",
      'name': nameController.text,
      'price': priceController.text,
      'id': id,
    });

    _showMessage("Product added successfully!");
  }

// phương thức updateProduct để cập nhật sp đã tồn tại
  Future<void> _updateProduct(String productId) async {
    String? downloadURL;

    if (_imageFile != null) {
      final String fileName = _imageFile!.name;
      final Reference storageRef =
          FirebaseStorage.instance.ref().child('images/$fileName');

      await storageRef.putFile(File(_imageFile!.path));
      downloadURL = await storageRef.getDownloadURL();
    }

    databaseRf.child(productId).update({
      'category': categoryController.text,
      'name': nameController.text,
      'price': priceController.text,
      'image_url': downloadURL ?? "placeholder_image_url",
    }).then((_) {
      _showMessage("Product updated successfully!");
    });
  }

  void _showDeleteConfirmationDialog(String productId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this product?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                databaseRf.child(productId).remove().then((_) {
                  _showMessage("Product deleted successfully!");
                });
                Navigator.of(context).pop();
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    setState(() {
      _message = message;
    });

    Timer(const Duration(seconds: 2), () {
      setState(() {
        _message = null;
      });
    });
  }
}
