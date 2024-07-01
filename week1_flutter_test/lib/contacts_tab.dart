import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'contact_detail_screen.dart';
import 'dart:typed_data';
import 'dart:convert';

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

  Uint8List? _convertAvatar(dynamic avatar) {
    if (avatar == null) return null;
    try {
      if (avatar is Uint8List) return avatar;
      if (avatar is String) return base64Decode(avatar);
      if (avatar is List<dynamic>) return Uint8List.fromList(avatar.cast<int>());
    } catch (e) {
      print("Invalid avatar data: $e");
    }
    return null;
  }

  bool _isValidImage(Uint8List? data) {
    if (data == null || data.isEmpty) return false;
    try {
      final image = MemoryImage(data);
      image.resolve(ImageConfiguration()).addListener(
        ImageStreamListener(
              (info, _) {},
          onError: (error, _) {
            throw Exception('Invalid image data');
          },
        ),
      );
      return true;
    } catch (e) {
      print("Invalid image data: $e");
      return false;
    }
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
        Uint8List? avatar = _convertAvatar(contact.avatar);

        // 이미지 데이터를 검증하고 유효하지 않은 경우 기본 아바타를 사용합니다.
        Widget leadingAvatar;
        if (avatar != null && _isValidImage(avatar)) {
          try {
            leadingAvatar = CircleAvatar(backgroundImage: MemoryImage(avatar));
          } catch (e) {
            print("Invalid image data for contact ${contact.displayName}: $e");
            leadingAvatar = CircleAvatar(child: Text(contact.initials()));
          }
        } else {
          leadingAvatar = CircleAvatar(child: Text(contact.initials()));
        }

        return ListTile(
          leading: leadingAvatar,
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
