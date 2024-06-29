import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'contact_detail_screen.dart';

class ContactsTab extends StatefulWidget {
  final List<Contact> contacts;
  final bool isLoading;
  final Function(Contact) updateContact;

  ContactsTab({
    required this.contacts,
    required this.isLoading,
    required this.updateContact,
  });

  @override
  _ContactsTabState createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  void _handleContactUpdate(Contact updatedContact) {
    setState(() {
      int index = widget.contacts.indexWhere((contact) => contact.identifier == updatedContact.identifier);
      if (index != -1) {
        widget.contacts[index] = updatedContact;
      }
    });
    widget.updateContact(updatedContact);
  }

  @override
  Widget build(BuildContext context) {
    return widget.isLoading
        ? Center(child: CircularProgressIndicator())
        : widget.contacts.isEmpty
        ? Center(child: Text('Empty Contacts'))
        : ListView.builder(
      itemCount: widget.contacts.length,
      itemBuilder: (context, index) {
        Contact contact = widget.contacts[index];
        return ListTile(
          leading: (contact.avatar != null && contact.avatar!.isNotEmpty)
              ? CircleAvatar(backgroundImage: MemoryImage(contact.avatar!))
              : CircleAvatar(child: Text(contact.initials())),
          title: Text(contact.displayName ?? ''),
          subtitle: Text(
            contact.phones!.isNotEmpty ? contact.phones!.first.value! : 'No phone number',
          ),
          onTap: () async {
            final updatedContact = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactDetailScreen(
                  contact: contact,
                  onUpdate: _handleContactUpdate,
                ),
              ),
            );

            if (updatedContact != null) {
              _handleContactUpdate(updatedContact);
            }
          },
        );
      },
    );
  }
}