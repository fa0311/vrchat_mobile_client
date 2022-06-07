// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Project imports:
import 'package:vrchat_mobile_client/api/main.dart';
import 'package:vrchat_mobile_client/assets/error.dart';
import 'package:vrchat_mobile_client/assets/storage.dart';
import 'package:vrchat_mobile_client/scenes/json_viewer.dart';
import 'package:vrchat_mobile_client/widgets/drawer.dart';
import 'package:vrchat_mobile_client/widgets/profile.dart';
import 'package:vrchat_mobile_client/widgets/share.dart';
import 'package:vrchat_mobile_client/widgets/world.dart';

class VRChatMobileUser extends StatefulWidget {
  final String userId;

  const VRChatMobileUser({Key? key, required this.userId}) : super(key: key);

  @override
  State<VRChatMobileUser> createState() => _UserHomeState();
}

class _UserHomeState extends State<VRChatMobileUser> {
  late Column column = Column(
    children: <Widget>[
      Text(AppLocalizations.of(context)!.loading),
    ],
  );
  Widget? dial;
  Widget? popupMenu;

  _UserHomeState() {
    getLoginSession("LoginSession").then((cookie) {
      VRChatAPI(cookie: cookie).users(widget.userId).then((user) {
        if (user.containsKey("error")) {
          error(context, user["error"]["message"]);
          return;
        }

        setState(() {
          column = Column(children: <Widget>[
            profile(context, user),
            Column(),
            Column(),
            TextButton(
              style: ElevatedButton.styleFrom(
                onPrimary: Colors.grey,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => VRChatMobileJsonViewer(obj: user),
                    ));
              },
              child: Text(AppLocalizations.of(context)!.viewInJsonViewer),
            ),
          ]);
        });
        VRChatAPI(cookie: cookie).friendStatus(widget.userId).then((status) {
          if (status.containsKey("error")) {
            error(context, status["error"]["message"]);
            return;
          }
          setState(() {
            dial = profileAction(context, status, widget.userId);
          });
        });
        if (!["", "private", "offline"].contains(user["location"])) {
          column.children[2] = TextButton(
            style: ElevatedButton.styleFrom(
              onPrimary: Colors.grey,
            ),
            onPressed: () {
              VRChatAPI(cookie: cookie).selfInvite(user["location"]).then((response) {
                if (response.containsKey("error")) {
                  error(context, response["error"]["message"]);
                  return;
                }
                showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      title: Text(AppLocalizations.of(context)!.sendInvite),
                      content: Text(AppLocalizations.of(context)!.selfInviteDetails),
                      actions: <Widget>[
                        TextButton(
                          child: Text(AppLocalizations.of(context)!.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                  },
                );
              });
            },
            child: Text(AppLocalizations.of(context)!.joinInstance),
          );

          VRChatAPI(cookie: cookie).worlds(user["location"].split(":")[0]).then((world) {
            if (world.containsKey("error")) {
              error(context, world["error"]["message"]);
              return;
            }
            setState(() {
              column = Column(children: column.children);
              column.children[1] = Column(children: [Container(padding: const EdgeInsets.only(top: 30)), worldSlim(context, world)]);
            });
            VRChatAPI(cookie: cookie).instances(user["location"]).then((instance) {
              if (instance.containsKey("error")) {
                error(context, instance["error"]["message"]);
                return;
              }
              setState(() {
                column = Column(children: column.children);
                column.children[1] = Column(children: [Container(padding: const EdgeInsets.only(top: 30)), worldSlimPlus(context, world, instance)]);
              });
            });
          });
        }
        if (user["location"] == "private") {
          setState(() {
            column = Column(children: [profile(context, user), Container(padding: const EdgeInsets.only(top: 30)), privateWorldSlim(context)]);
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.user), actions: <Widget>[share("https://vrchat.com/home/user/${widget.userId}")]),
      drawer: drawr(context),
      body: SafeArea(child: SingleChildScrollView(child: Container(padding: const EdgeInsets.only(top: 10, bottom: 50, right: 30, left: 30), child: column))),
      floatingActionButton: dial,
    );
  }
}
