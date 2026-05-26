import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:grw_laser/configuration/app_colors.dart';
import 'package:grw_laser/services/device_info_manager.dart';
import 'package:grw_laser/services/messenger.dart';
import 'package:grw_laser/services/pager.dart';
import 'package:grw_laser/services/user_session_nest.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFFF0F4F8);
    const Color surface = Colors.white;
    const Color accent = AppColors.sagaBlue;

    Widget item({
      required Widget leading,
      required String label,
      required VoidCallback onTap,
      Color? labelColor,
      bool showChevron = true,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                SizedBox(width: 24, height: 24, child: Center(child: leading)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    style: TextStyle(
                      color: labelColor ?? Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showChevron)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: Drawer(
          width: double.infinity,
          backgroundColor: bg,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HEADER ──────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent,
                        Color(0xFF143F6B),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.grey,
                          backgroundImage: UserSessionNest.utente?.avatar !=
                                      null &&
                                  (UserSessionNest.utente?.avatar ?? "")
                                          .trim() !=
                                      ""
                              ? NetworkImage(UserSessionNest.utente!.avatar!)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "${UserSessionNest.utente?.nome ?? ""} ${UserSessionNest.utente?.cognome ?? ""}",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        UserSessionNest.utente?.email ?? "",
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── LOGOUT ──────────────────────────────────────────────
                item(
                  leading: Icon(Icons.logout, color: Colors.red[700], size: 20),
                  label: "Logout",
                  onTap: logoutPressed,
                  labelColor: Colors.red[700],
                  showChevron: false,
                ),
                const SizedBox(height: 16),
                // ── CLOSE ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextButton.icon(
                    onPressed: () => Pager.pop(context),
                    icon: const Icon(FontAwesomeIcons.circleXmark,
                        color: Colors.black38, size: 18),
                    label: const Text("Chiudi",
                        style: TextStyle(
                            color: Colors.black45,
                            fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.black.withValues(alpha: 0.05),
                      minimumSize: const Size(double.infinity, 0),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ── VERSION ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      "v${DeviceInfoManager.appversion}",
                      style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> logoutPressed() async {
    final confirmed = await Messenger.showDefaultConfirm(
        context, "Conferma", "Effettuare il logout?", "Sì", "No");
    if (confirmed == true) {
      await UserSessionNest.eraseSession();
      Pager.setFirstPageLogin(context: context);
    }
  }
}
