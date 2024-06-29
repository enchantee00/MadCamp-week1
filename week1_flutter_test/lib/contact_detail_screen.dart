import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactDetailScreen extends StatefulWidget {
  final Contact contact;
  final Function(Contact) onUpdate;

  ContactDetailScreen({required this.contact, required this.onUpdate});

  @override
  _ContactDetailScreenState createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _studentIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.displayName);
    _phoneController = TextEditingController(text: widget.contact.phones?.isNotEmpty == true ? widget.contact.phones!.first.value : '');
    _emailController = TextEditingController(text: widget.contact.emails?.isNotEmpty == true ? widget.contact.emails!.first.value : '');
    _studentIdController = TextEditingController(text: widget.contact.company);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    widget.contact.displayName = _nameController.text;

    if (widget.contact.phones != null && widget.contact.phones!.isNotEmpty) {
      widget.contact.phones!.first.value = _phoneController.text;
    } else {
      widget.contact.phones = [Item(label: 'mobile', value: _phoneController.text)];
    }

    if (widget.contact.emails != null && widget.contact.emails!.isNotEmpty) {
      widget.contact.emails!.first.value = _emailController.text;
    } else {
      widget.contact.emails = [Item(label: 'work', value: _emailController.text)];
    }

    widget.contact.company = _studentIdController.text;

    if (await Permission.contacts.request().isGranted) {
      await ContactsService.updateContact(widget.contact);
      setState(() {
        _isEditing = false;
      });
      widget.onUpdate(widget.contact);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission to access contacts is denied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contact' : 'Contact Details'),
        actions: [
          _isEditing
              ? IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveContact,
          )
              : IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = true;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: (widget.contact.avatar != null && widget.contact.avatar!.isNotEmpty)
                    ? CircleAvatar(
                  backgroundImage: MemoryImage(widget.contact.avatar!),
                  radius: 50,
                )
                    : CircleAvatar(
                  child: Text(widget.contact.initials()),
                  radius: 50,
                ),
              ),
              SizedBox(height: 20),
              _isEditing
                  ? TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                enabled: false, // 이름 수정 비활성화
              )
                  : Text('Name: ${widget.contact.displayName ?? 'No Name'}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              )
                  : Text('Phone: ${widget.contact.phones?.isNotEmpty == true ? widget.contact.phones!.first.value : 'No Phone'}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              )
                  : Text('Email: ${widget.contact.emails?.isNotEmpty == true ? widget.contact.emails!.first.value : 'No Email'}', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              _isEditing
                  ? TextField(
                controller: _studentIdController,
                decoration: InputDecoration(labelText: 'Student ID'),
              )
                  : Text('Student ID: ${widget.contact.company ?? 'No Student ID'}', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}