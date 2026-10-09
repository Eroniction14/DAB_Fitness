import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/providers/auth_model.dart';
import 'package:dab_fitness/providers/booking_model.dart';
import 'package:dab_fitness/screens/auth/login_page.dart';

class ProfilePage extends StatelessWidget {
  /// The signed-in `UserProfile` or `Trainer`; both have a `name`.
  final dynamic user;
  const ProfilePage(this.user, {super.key});
  static const routeName = '/profile';
  @override
  Widget build(BuildContext context) {
    final appoinments =
        Provider.of<BookingModel>(context, listen: false).getAppoinments;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.lightBlue,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 50,
                ),
                Text(user.name),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: Text("My Appointments"),
            onTap: () => showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: SizedBox(
                    height: 100,
                    child: appoinments.isNotEmpty
                        ? ListView.separated(
                            itemBuilder: (context, index) {
                              return Dismissible(
                                key: ValueKey(index),
                                background: Container(
                                  color: Theme.of(context).colorScheme.error,
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 4,
                                  ),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) {
                                  return showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(
                                        'Are you sure?',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      content: Text(
                                        'Do you want to cancel the appoinment',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text(
                                            'No',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          onPressed: () {
                                            Navigator.of(ctx).pop(false);
                                          },
                                        ),
                                        TextButton(
                                          child: Text(
                                            'Yes',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge,
                                          ),
                                          onPressed: () {
                                            Navigator.of(ctx).pop(true);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) {},
                                child: Card(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 4,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(8),
                                    child: ListTile(
                                      leading: Icon(Icons.alarm_on),
                                      title: Text(
                                        appoinments[index].date,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      subtitle: Text(
                                        appoinments[index].time,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      // trailing: Text(),
                                    ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (context, index) => SizedBox(
                              height: 10,
                            ),
                            itemCount: appoinments.length,
                          )
                        : Center(
                            child: Text("No Appoinments scheduled",
                                style: Theme.of(context).textTheme.bodyMedium),
                          ),
                  ),
                );
              },
            ),
          ),
          Divider(
            color: Colors.grey,
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text("Logout of this app"),
            onTap: () {
              final navigator = Navigator.of(context);
              Provider.of<AuthModel>(context, listen: false).logout().then(
                  (_) => navigator.pushReplacementNamed(LoginPage.routeName));
            },
          ),
        ],
      ),
    );
  }
}
