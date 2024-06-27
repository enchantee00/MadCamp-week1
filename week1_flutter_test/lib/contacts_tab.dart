import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsTab extends StatefulWidget {
  @override
  _ContactsTabState createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _getPermissions();
  }

  Future<void> _getPermissions() async {
    var status = await Permission.contacts.status;
    if (status.isGranted) {
      _getAllContacts();
    } else if (status.isDenied || status.isRestricted) {
      if (await Permission.contacts.request().isGranted) {
        _getAllContacts();
      }
    }
  }

  Future<void> _getAllContacts() async {
    Iterable<Contact> _contacts = await ContactsService.getContacts();
    setState(() {
      contacts = _contacts.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
      ),
      body: contacts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          Contact contact = contacts[index];
          return ListTile(
            leading: (contact.avatar != null && contact.avatar!.isNotEmpty)
                ? CircleAvatar(backgroundImage: MemoryImage(contact.avatar!))
                : CircleAvatar(child: Text(contact.initials())),
            title: Text(contact.displayName ?? ''),
            subtitle: Text(
              contact.phones!.isNotEmpty ? contact.phones!.first.value! : 'No phone number',
            ),
          );
        },
      ),
    );
  }
}
