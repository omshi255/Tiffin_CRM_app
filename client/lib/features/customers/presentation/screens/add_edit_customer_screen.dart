// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../../data/customer_repository.dart';
// import '../../../../models/customer_model.dart';

// class AddEditCustomerScreen extends StatefulWidget {
//   final Customer? customer;

//   const AddEditCustomerScreen({super.key, this.customer});

//   @override
//   State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
// }

// class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
//   final CustomerRepository repo = CustomerRepository();

//   final _formKey = GlobalKey<FormState>();

//   final nameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final emailController = TextEditingController();
//   final addressController = TextEditingController();

//   bool loading = false;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.customer != null) {
//       nameController.text = widget.customer!.name;
//       phoneController.text = widget.customer!.phone;
//       emailController.text = widget.customer!.email;
//       addressController.text = widget.customer!.address;
//     }
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     addressController.dispose();
//     super.dispose();
//   }

//   Future<void> saveCustomer() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       loading = true;
//     });

//     final customer = Customer(
//       id: widget.customer?.id ?? "",
//       name: nameController.text.trim(),
//       phone: phoneController.text.trim(),
//       email: emailController.text.trim(),
//       address: addressController.text.trim(),
//       status: "active",
//     );

//     try {
//       if (widget.customer == null) {
//         await repo.createCustomer(customer);
//       } else {
//         await repo.updateCustomer(widget.customer!.id, customer);
//       }

//       if (!mounted) return;

//       Navigator.pop(context);
//     } catch (e) {
//       setState(() {
//         loading = false;
//       });

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.customer == null ? "Add Customer" : "Edit Customer"),
//       ),

//       body: Padding(
//         padding: const EdgeInsets.all(20),

//         child: Form(
//           key: _formKey,

//           child: Column(
//             children: [
//               /// NAME
//               TextFormField(
//                 controller: nameController,
//                 decoration: const InputDecoration(labelText: "Name"),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) {
//                     return "Name required";
//                   }
//                   return null;
//                 },
//               ),

//               const SizedBox(height: 16),

//               /// PHONE
//               TextFormField(
//                 controller: phoneController,
//                 keyboardType: TextInputType.phone,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                   LengthLimitingTextInputFormatter(10),
//                 ],
//                 decoration: const InputDecoration(labelText: "Phone"),
//                 validator: (v) {
//                   if (v == null || v.isEmpty) {
//                     return "Phone required";
//                   }

//                   if (v.length != 10) {
//                     return "Enter valid 10 digit number";
//                   }

//                   return null;
//                 },
//               ),

//               const SizedBox(height: 16),

//               /// EMAIL
//               TextFormField(
//                 controller: emailController,
//                 decoration: const InputDecoration(
//                   labelText: "Email (optional)",
//                 ),
//               ),

//               const SizedBox(height: 16),

//               /// ADDRESS
//               TextFormField(
//                 controller: addressController,
//                 decoration: const InputDecoration(labelText: "Address"),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) {
//                     return "Address required";
//                   }
//                   return null;
//                 },
//               ),

//               const SizedBox(height: 30),

//               /// SAVE BUTTON
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: loading ? null : saveCustomer,
//                   child: loading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text(widget.customer == null ? "Save" : "Update"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/customer_repository.dart';
import '../../../../models/customer_model.dart';
import '../widgets/contact_picker_bottom_sheet.dart';
import '../widgets/contacts_permission_sheet.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final CustomerRepository repo = CustomerRepository();

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();

    if (widget.customer != null) {
      nameController.text = widget.customer!.name;
      phoneController.text = widget.customer!.phone;
      emailController.text = widget.customer!.email;
      addressController.text = widget.customer!.address;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  /// IMPORT CONTACT FROM PHONE
  Future<void> importFromContacts() async {
    final status = await Permission.contacts.request();

    if (!mounted) return;

    if (status.isGranted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => ContactPickerBottomSheet(
          onContactSelected: (name, phone) {
            nameController.text = name;
            phoneController.text = phone;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Contact imported")),
            );
          },
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => ContactsPermissionSheet(
          onCancel: () => Navigator.pop(ctx),
        ),
      );
    }
  }

  /// SAVE CUSTOMER
  Future<void> saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final customer = Customer(
      id: widget.customer?.id ?? "",
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      address: addressController.text.trim(),
      status: "active",
    );

    try {
      if (widget.customer == null) {
        await repo.createCustomer(customer);
      } else {
        await repo.updateCustomer(widget.customer!.id, customer);
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? "Add Customer" : "Edit Customer"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              /// CONTACT IMPORT BUTTON
              if (widget.customer == null)
                OutlinedButton.icon(
                  onPressed: importFromContacts,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Import from Contacts"),
                ),

              if (widget.customer == null) const SizedBox(height: 20),

              /// NAME
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Name required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// PHONE
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: const InputDecoration(labelText: "Phone"),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Phone required";
                  }

                  if (v.length != 10) {
                    return "Enter valid 10 digit number";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// EMAIL
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email (optional)",
                ),
              ),

              const SizedBox(height: 16),

              /// ADDRESS
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Address required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              /// SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : saveCustomer,
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.customer == null ? "Save" : "Update"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}