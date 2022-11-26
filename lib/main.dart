import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

/// 1
final actionCodeSettings = ActionCodeSettings(
  url: 'https://my-flutter-sign.firebaseapp.com',
  handleCodeInApp: true,
  androidInstallApp: true,
  androidMinimumVersion: '1',
  androidPackageName: 'com.example.flutter_sign',
  iOSBundleId: 'com.example.flutterSign',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    PhoneAuthProvider(),
    GoogleProvider(
      clientId:
          '835328413024-fu8m54huocipu8tfvf4fhhilhir1ecij.apps.googleusercontent.com',
      redirectUri: 'https://my-flutter-sign.firebaseapp.com/__/auth/handler',
    ),
    // AppleProvider(),
    FacebookProvider(clientId: '16dbbdf0cfb309034a6ad98ac2a21688'),
    TwitterProvider(
      apiKey: 'jgt9i9Ec6TZ3jFxfCqL4WnYqv',
      apiSecretKey: '8SckWVyew4jo5usmpfqIWDFeNu9U3Lk6IrckmEjrFsT6I6En0k',
      redirectUri: 'https://my-flutter-sign.firebaseapp.com/__/auth/handler',
    ),
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// 2
  String get initialRoute {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      return '/';
    }

    if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
      return '/verify-email';
    }

    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localizationsDelegates: [
        FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FirebaseUILocalizations.delegate,
      ],

      /// 2
      initialRoute: initialRoute,
      // initialRoute:
      // FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home',
      routes: {
        '/': (context) {
          // '/sign-in': (context) {
          return SignInScreen(
            styles: const {
              EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
            },
            headerBuilder: (context, constraints, _) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset('assets/images/flutterfire_logo.png'),
              );
            },
            sideBuilder: (context, constraints) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(constraints.maxWidth / 4),
                  child: Image.asset('assets/images/flutterfire_logo.png'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  action == AuthAction.signIn
                      ? 'Welcome to Firebase UI! Please sign in to continue.'
                      : 'Welcome to Firebase UI! Please create an account to continue',
                ),
              );
            },
            footerBuilder: (context, action) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    action == AuthAction.signIn
                        ? 'By signing in, you agree to our terms and conditions.'
                        : 'By registering, you agree to our terms and conditions.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            },
            actions: [
              ForgotPasswordAction((context, email) {
                Navigator.of(context).pushNamed(
                  '/forgot-password',
                  arguments: {'email': email},
                );
              }),

              /// 3
              AuthStateChangeAction<SignedIn>((context, state) {
                if (!state.user!.emailVerified) {
                  Navigator.pushNamed(context, '/verify-email');
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              }),
              AuthStateChangeAction<UserCreated>((context, state) {
                if (!state.credential.user!.emailVerified) {
                  Navigator.pushNamed(context, '/verify-email');
                } else {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              }),
              VerifyPhoneAction((context, _) {
                Navigator.pushNamed(context, '/phone');
              }),
            ],
          );
        },
        '/profile': (context) => const ProfileScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const Home(),
        '/phone': (context) => PhoneInputScreen(
              actions: [
                SMSCodeRequestedAction((context, action, flowKey, phone) {
                  Navigator.of(context).pushReplacementNamed(
                    '/sms',
                    arguments: {
                      'action': action,
                      'flowKey': flowKey,
                      'phone': phone,
                    },
                  );
                }),
              ],
            ),
        '/sms': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return SMSCodeInputScreen(
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                Navigator.of(context).pushReplacementNamed('/home');
              })
            ],
            flowKey: arguments?['flowKey'],
            action: arguments?['action'],
          );
        },

        /// 4
        '/verify-email': (context) {
          return EmailVerificationScreen(
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20).copyWith(top: 40),
                child: Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: constraints.maxWidth / 4 * (1 - shrinkOffset),
                ),
              );
            },
            sideBuilder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.verified,
                  color: Colors.blue,
                  size: constraints.maxWidth / 3,
                ),
              );
            },
            actionCodeSettings: actionCodeSettings,
            actions: [
              EmailVerifiedAction(() {
                Navigator.pushReplacementNamed(context, '/home');
              }),
              AuthCancelledAction((context) {
                FirebaseUIAuth.signOut(context: context);
                Navigator.pushReplacementNamed(context, '/');
              }),
            ],
          );
        },
      },
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                            appBar: AppBar(  title: const Text('Profile'),
                                backgroundColor: Colors.red),
                            actions: [
                              SignedOutAction((context) {
                                Navigator.of(context).pushReplacementNamed('/');
                              }),
                            ],

                            /// 5
                            actionCodeSettings: actionCodeSettings,

                            showMFATile: true,
                          )),
                );
              },
              color: Colors.white,
              icon: const Icon(Icons.account_box_sharp),
            ),
          ),
        ],
      ),
    );
  }
}

class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();

  @override
  String get emailInputLabel => 'Enter your email';
}

// // // import 'package:firebase_auth/firebase_auth.dart'
// // //     hide PhoneAuthProvider, EmailAuthProvider;
// // // import 'package:firebase_core/firebase_core.dart';
// // // import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// // // import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
// // // import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
// // // import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
// // // import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
// // // import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_localizations/flutter_localizations.dart';
// // //
// // // import 'decorations.dart';
// // // import 'firebase_options.dart';
// // //
// // //
// // //
// // // Future<void> main() async {
// // //   WidgetsFlutterBinding.ensureInitialized();
// // //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// // //
// // //   FirebaseUIAuth.configureProviders([
// // //     EmailAuthProvider(),
// // //     emailLinkProviderConfig,
// // //     PhoneAuthProvider(),
// // //     GoogleProvider(
// // //       clientId:
// // //           '876171996036-f8k8gsq3uinfnjerkarm88kj30287q81.apps.googleusercontent.com',
// // //       redirectUri: 'https://flu-cli-appsmaker.firebaseapp.com/__/auth/handler',
// // //     ),
// // //     AppleProvider(),
// // //     FacebookProvider(clientId: '16dbbdf0cfb309034a6ad98ac2a21688'),
// // //     TwitterProvider(
// // //       apiKey: 'ufnRq7uKHnxi2Mhece74Hhlgj',
// // //       apiSecretKey: 'nN4DiSEtMldas9DZitCmVU0S1jz7ofT5FHbIzlQMyVimKlaHNj',
// // //       redirectUri:
// // //           'https://multiple-auth-e3d84.firebaseapp.com/__/auth/handler',
// // //     ),
// // //   ]);
// // //
// // //   runApp(const MyApp());
// // // }
// // //
// // //
// // //
// // // class MyApp extends StatelessWidget {
// // //   const MyApp({Key? key}) : super(key: key);
// // //
// // //   String get initialRoute {
// // //     final auth = FirebaseAuth.instance;
// // //
// // //     if (auth.currentUser == null) {
// // //       return '/';
// // //     }
// // //
// // //     if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
// // //       return '/verify-email';
// // //     }
// // //
// // //     return '/profile';
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final buttonStyle = ButtonStyle(
// // //       padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
// // //       shape: MaterialStateProperty.all(
// // //         RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// // //       ),
// // //     );
// // //
// // //     final mfaAction = AuthStateChangeAction<MFARequired>(
// // //       (context, state) async {
// // //         final nav = Navigator.of(context);
// // //
// // //         await startMFAVerification(
// // //           resolver: state.resolver,
// // //           context: context,
// // //         );
// // //
// // //         nav.pushReplacementNamed('/profile');
// // //       },
// // //     );
// // //
// // //     return MaterialApp(
// // //       theme: ThemeData(
// // //         brightness: Brightness.light,
// // //         visualDensity: VisualDensity.standard,
// // //         inputDecorationTheme: const InputDecorationTheme(
// // //           border: OutlineInputBorder(),
// // //         ),
// // //         elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
// // //         textButtonTheme: TextButtonThemeData(style: buttonStyle),
// // //         outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
// // //       ),
// // //       title: 'Firebase UI demo',
// // //       debugShowCheckedModeBanner: false,
// // //       locale: const Locale('en'),
// // //       localizationsDelegates: [
// // //         FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
// // //         GlobalMaterialLocalizations.delegate,
// // //         GlobalWidgetsLocalizations.delegate,
// // //         FirebaseUILocalizations.delegate,
// // //       ],
// // //       initialRoute: initialRoute,
// // //       routes: {
// // //         '/': (context) {
// // //           return SignInScreen(
// // //             actions: [
// // //               ForgotPasswordAction((context, email) {
// // //                 Navigator.pushNamed(
// // //                   context,
// // //                   '/forgot-password',
// // //                   arguments: {'email': email},
// // //                 );
// // //               }),
// // //               VerifyPhoneAction((context, _) {
// // //                 Navigator.pushNamed(context, '/phone');
// // //               }),
// // //               AuthStateChangeAction<SignedIn>((context, state) {
// // //                 if (!state.user!.emailVerified) {
// // //                   Navigator.pushNamed(context, '/verify-email');
// // //                 } else {
// // //                   Navigator.pushReplacementNamed(context, '/profile');
// // //                 }
// // //               }),
// // //               AuthStateChangeAction<UserCreated>((context, state) {
// // //                 if (!state.credential.user!.emailVerified) {
// // //                   Navigator.pushNamed(context, '/verify-email');
// // //                 } else {
// // //                   Navigator.pushReplacementNamed(context, '/profile');
// // //                 }
// // //               }),
// // //               mfaAction,
// // //               EmailLinkSignInAction((context) {
// // //                 Navigator.pushReplacementNamed(context, '/email-link-sign-in');
// // //               }),
// // //             ],
// // //             styles: const {
// // //               EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
// // //             },
// // //             headerBuilder: headerImage('assets/images/flutterfire_logo.png'),
// // //             sideBuilder: sideImage('assets/images/flutterfire_logo.png'),
// // //             subtitleBuilder: (context, action) {
// // //               return Padding(
// // //                 padding: const EdgeInsets.only(bottom: 8),
// // //                 child: Text(
// // //                   action == AuthAction.signIn
// // //                       ? 'Welcome to Firebase UI! Please sign in to continue.'
// // //                       : 'Welcome to Firebase UI! Please create an account to continue',
// // //                 ),
// // //               );
// // //             },
// // //             footerBuilder: (context, action) {
// // //               return Center(
// // //                 child: Padding(
// // //                   padding: const EdgeInsets.only(top: 16),
// // //                   child: Text(
// // //                     action == AuthAction.signIn
// // //                         ? 'By signing in, you agree to our terms and conditions.'
// // //                         : 'By registering, you agree to our terms and conditions.',
// // //                     style: const TextStyle(color: Colors.grey),
// // //                   ),
// // //                 ),
// // //               );
// // //             },
// // //           );
// // //         },
// // //         '/verify-email': (context) {
// // //           return EmailVerificationScreen(
// // //             headerBuilder: headerIcon(Icons.verified),
// // //             sideBuilder: sideIcon(Icons.verified),
// // //             actionCodeSettings: actionCodeSettings,
// // //             actions: [
// // //               EmailVerifiedAction(() {
// // //                 Navigator.pushReplacementNamed(context, '/profile');
// // //               }),
// // //               AuthCancelledAction((context) {
// // //                 FirebaseUIAuth.signOut(context: context);
// // //                 Navigator.pushReplacementNamed(context, '/');
// // //               }),
// // //             ],
// // //           );
// // //         },
// // //         '/phone': (context) {
// // //           return PhoneInputScreen(
// // //             actions: [
// // //               SMSCodeRequestedAction((context, action, flowKey, phone) {
// // //                 Navigator.of(context).pushReplacementNamed(
// // //                   '/sms',
// // //                   arguments: {
// // //                     'action': action,
// // //                     'flowKey': flowKey,
// // //                     'phone': phone,
// // //                   },
// // //                 );
// // //               }),
// // //             ],
// // //             headerBuilder: headerIcon(Icons.phone),
// // //             sideBuilder: sideIcon(Icons.phone),
// // //           );
// // //         },
// // //         '/sms': (context) {
// // //           final arguments = ModalRoute.of(context)?.settings.arguments
// // //               as Map<String, dynamic>?;
// // //
// // //           return SMSCodeInputScreen(
// // //             actions: [
// // //               AuthStateChangeAction<SignedIn>((context, state) {
// // //                 Navigator.of(context).pushReplacementNamed('/profile');
// // //               })
// // //             ],
// // //             flowKey: arguments?['flowKey'],
// // //             action: arguments?['action'],
// // //             headerBuilder: headerIcon(Icons.sms_outlined),
// // //             sideBuilder: sideIcon(Icons.sms_outlined),
// // //           );
// // //         },
// // //         '/forgot-password': (context) {
// // //           final arguments = ModalRoute.of(context)?.settings.arguments
// // //               as Map<String, dynamic>?;
// // //
// // //           return ForgotPasswordScreen(
// // //             email: arguments?['email'],
// // //             headerMaxExtent: 200,
// // //             headerBuilder: headerIcon(Icons.lock),
// // //             sideBuilder: sideIcon(Icons.lock),
// // //           );
// // //         },
// // //         '/email-link-sign-in': (context) {
// // //           return EmailLinkSignInScreen(
// // //             actions: [
// // //               AuthStateChangeAction<SignedIn>((context, state) {
// // //                 Navigator.pushReplacementNamed(context, '/');
// // //               }),
// // //             ],
// // //             provider: emailLinkProviderConfig,
// // //             headerMaxExtent: 200,
// // //             headerBuilder: headerIcon(Icons.link),
// // //             sideBuilder: sideIcon(Icons.link),
// // //           );
// // //         },
// // //         '/profile': (context) {
// // //           return ProfileScreen(
// // //             appBar: AppBar(
// // //                 centerTitle: true,
// // //                 title: const Text(
// // //                   'profile',
// // //                   style: TextStyle(color: Colors.white),
// // //                 )),
// // //             actions: [
// // //               SignedOutAction((context) {}),
// // //               mfaAction,
// // //             ],
// // //             actionCodeSettings: actionCodeSettings,
// // //             showMFATile: true,
// // //             children: [
// // //               ElevatedButton(
// // //                 onPressed: () {
// // //                   Navigator.push(
// // //                     context,
// // //                     MaterialPageRoute(builder: (context) => const Home()),
// // //                   );
// // //                 },
// // //                 child: const Text('Go Home'),
// // //               )
// // //             ],
// // //           );
// // //         },
// // //       },
// // //
// // //     );
// // //   }
// // // }
// // //
// // // class LabelOverrides extends DefaultLocalizations {
// // //   const LabelOverrides();
// // //
// // //   @override
// // //   String get emailInputLabel => 'Enter your email';
// // // }
// // //
// // // final actionCodeSettings = ActionCodeSettings(
// // //   url: 'https://multiple-auth-e3d84.firebaseapp.com',
// // //   handleCodeInApp: true,
// // //   androidMinimumVersion: '1',
// // //   androidPackageName: 'com.example.untitled',
// // //   iOSBundleId: 'com.example.untitled',
// // // );
// // // final emailLinkProviderConfig = EmailLinkAuthProvider(
// // //   actionCodeSettings: actionCodeSettings,
// // // );
// // //
// // // class Home extends StatefulWidget {
// // //   const Home({Key? key}) : super(key: key);
// // //
// // //   @override
// // //   State<Home> createState() => _HomeState();
// // // }
// // //
// // // class _HomeState extends State<Home> {
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Container(
// // //       color: Colors.white,
// // //     );
// // //   }
// // // }
// //
// //
// // import 'package:firebase_auth/firebase_auth.dart'
// //     hide PhoneAuthProvider, EmailAuthProvider;
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// // import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
// // import 'package:flutter/material.dart';
// //
// // import 'firebase_options.dart';
// //
// //
// //
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// //
// //   FirebaseUIAuth.configureProviders([
// //     EmailAuthProvider(),
// //     PhoneAuthProvider(),
// //     GoogleProvider(clientId:
// //          '835328413024-fu8m54huocipu8tfvf4fhhilhir1ecij.apps.googleusercontent.com',
// //       redirectUri: 'https://my-flutter-sign.firebaseapp.com/__/auth/handler',
// //     ),
// //     // AppleProvider(),
// //     // FacebookProvider(clientId: '16dbbdf0cfb309034a6ad98ac2a21688'),
// //     // TwitterProvider(
// //     //   apiKey: 'ufnRq7uKHnxi2Mhece74Hhlgj',
// //     //   apiSecretKey: 'nN4DiSEtMldas9DZitCmVU0S1jz7ofT5FHbIzlQMyVimKlaHNj',
// //     //   redirectUri:
// //     //   'https://my-flutter-sign.firebaseapp.com/__/auth/handler',
// //     // ),
// //   ]);
// //
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //
// //     return MaterialApp(
// //       theme: ThemeData(
// //         brightness: Brightness.light,
// //         visualDensity: VisualDensity.standard,
// //         inputDecorationTheme: const InputDecorationTheme(
// //           border: OutlineInputBorder(),
// //         ),
// //       ),
// //       debugShowCheckedModeBanner: false,
// //
// //       // locale: const Locale('en'),
// //       // localizationsDelegates: [
// //       //   FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
// //       //   GlobalMaterialLocalizations.delegate,
// //       //   GlobalWidgetsLocalizations.delegate,
// //       //   FirebaseUILocalizations.delegate,
// //       // ],
// //
// //       initialRoute:
// //           FirebaseAuth.instance.currentUser == null ? '/sign-in' : '/home',
// //       routes: {
// //         '/sign-in': (context) {
// //           return SignInScreen(
// //             // styles: const {
// //             //   EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
// //             // },
// //             // headerBuilder: (context, constraints, _) {
// //             //   return Padding(
// //             //     padding: const EdgeInsets.all(20),
// //             //     child: Image.asset('assets/images/flutterfire_logo.png'),
// //             //   );
// //             // },
// //             // sideBuilder: (context, constraints) {
// //             //   return
// //             //     Center(
// //             //       child: Padding(
// //             //         padding: EdgeInsets.all(constraints.maxWidth / 4),
// //             //         child: Image.asset('assets/images/flutterfire_logo.png'),
// //             //       ),
// //             //     );
// //             // },
// //             // subtitleBuilder: (context, action) {
// //             //   return Padding(
// //             //     padding: const EdgeInsets.only(bottom: 8),
// //             //     child: Text(
// //             //       action == AuthAction.signIn
// //             //           ? 'Welcome to Firebase UI! Please sign in to continue.'
// //             //           : 'Welcome to Firebase UI! Please create an account to continue',
// //             //     ),
// //             //   );
// //             // },
// //             // footerBuilder: (context, action) {
// //             //   return Center(
// //             //     child: Padding(
// //             //       padding: const EdgeInsets.only(top: 16),
// //             //       child: Text(
// //             //         action == AuthAction.signIn
// //             //             ? 'By signing in, you agree to our terms and conditions.'
// //             //             : 'By registering, you agree to our terms and conditions.',
// //             //         style: const TextStyle(color: Colors.grey),
// //             //       ),
// //             //     ),
// //             //   );
// //             // },
// //
// //             actions: [
// //               ForgotPasswordAction((context, email) {
// //                 Navigator.of(context).pushNamed(
// //                   '/forgot-password',
// //                   arguments: {'email': email},
// //                 );
// //               }),
// //               AuthStateChangeAction<SignedIn>((context, _) {
// //                 Navigator.of(context).pushReplacementNamed('/home');
// //               }),
// //               AuthStateChangeAction<UserCreated>((context, _) {
// //                 Navigator.of(context).pushReplacementNamed('/home');
// //               }),
// //               VerifyPhoneAction((context, _) {
// //                 Navigator.pushNamed(context, '/phone');
// //               }),
// //             ],
// //           );
// //         },
// //         '/profile': (context) => const ProfileScreen(),
// //         '/forgot-password': (context) => const ForgotPasswordScreen(),
// //         '/home': (context) => const Home(),
// //
// //         '/phone': (context) => PhoneInputScreen(
// //               actions: [
// //                 SMSCodeRequestedAction((context, action, flowKey, phone) {
// //                   Navigator.of(context).pushReplacementNamed(
// //                     '/sms',
// //                     arguments: {
// //                       'action': action,
// //                       'flowKey': flowKey,
// //                       'phone': phone,
// //                     },
// //                   );
// //                 }),
// //               ],
// //             ),
// //         '/sms': (context) {
// //           final arguments = ModalRoute.of(context)?.settings.arguments
// //               as Map<String, dynamic>?;
// //
// //           return SMSCodeInputScreen(
// //             actions: [
// //               AuthStateChangeAction<SignedIn>((context, state) {
// //                 Navigator.of(context).pushReplacementNamed('/home');
// //               })
// //             ],
// //             flowKey: arguments?['flowKey'],
// //             action: arguments?['action'],
// //           );
// //
// //         },
// //       },
// //     );
// //   }
// // }
// //
// // class Home extends StatefulWidget {
// //   const Home({Key? key}) : super(key: key);
// //
// //   @override
// //   State<Home> createState() => _HomeState();
// // }
// //
// // class _HomeState extends State<Home> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         actions: [
// //           Align(
// //             alignment: Alignment.topRight,
// //             child: IconButton(
// //               onPressed: () {
// //                 Navigator.push(
// //                   context,
// //                   MaterialPageRoute(
// //                       builder: (context) => ProfileScreen(
// //                             appBar: AppBar(backgroundColor: Colors.red),
// //                             actions: [
// //                               SignedOutAction((context) {
// //                                 Navigator.of(context)
// //                                     .pushReplacementNamed('/sign-in');
// //                               }),
// //                             ],
// //                           )),
// //                 );
// //               },
// //               color: Colors.white,
// //               icon: const Icon(Icons.account_box_sharp),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // class LabelOverrides extends DefaultLocalizations {
// // //   const LabelOverrides();
// // //
// // //   @override
// // //   String get emailInputLabel => 'Enter your email';
// // //
// // // }
//
// // import 'package:firebase_auth/firebase_auth.dart'
// //     hide PhoneAuthProvider, EmailAuthProvider;
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// // import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
// // import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
// // import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
// // import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
// // import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_localizations/flutter_localizations.dart';
// //
// // import 'firebase_options.dart';
// //
// //
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// //
// //   FirebaseUIAuth.configureProviders([
// //     EmailAuthProvider(),
// //     emailLinkProviderConfig,
// //     PhoneAuthProvider(),
// //     GoogleProvider(
// //       clientId:
// //           '876171996036-f8k8gsq3uinfnjerkarm88kj30287q81.apps.googleusercontent.com',
// //       redirectUri: 'https://flu-cli-appsmaker.firebaseapp.com/__/auth/handler',
// //     ),
// //     AppleProvider(),
// //     FacebookProvider(clientId: '16dbbdf0cfb309034a6ad98ac2a21688'),
// //     TwitterProvider(
// //       apiKey: 'ufnRq7uKHnxi2Mhece74Hhlgj',
// //       apiSecretKey: 'nN4DiSEtMldas9DZitCmVU0S1jz7ofT5FHbIzlQMyVimKlaHNj',
// //       redirectUri:
// //           'https://multiple-auth-e3d84.firebaseapp.com/__/auth/handler',
// //     ),
// //   ]);
// //
// //   runApp(const MyApp());
// // }
// //
// //
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({Key? key}) : super(key: key);
// //
// //   String get initialRoute {
// //     final auth = FirebaseAuth.instance;
// //
// //     if (auth.currentUser == null) {
// //       return '/';
// //     }
// //
// //     if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
// //       return '/verify-email';
// //     }
// //
// //     return '/profile';
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final buttonStyle = ButtonStyle(
// //       padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
// //       shape: MaterialStateProperty.all(
// //         RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
// //       ),
// //     );
// //
// //     final mfaAction = AuthStateChangeAction<MFARequired>(
// //       (context, state) async {
// //         final nav = Navigator.of(context);
// //
// //         await startMFAVerification(
// //           resolver: state.resolver,
// //           context: context,
// //         );
// //
// //         nav.pushReplacementNamed('/profile');
// //       },
// //     );
// //
// //     return MaterialApp(
// //       theme: ThemeData(
// //         brightness: Brightness.light,
// //         visualDensity: VisualDensity.standard,
// //         inputDecorationTheme: const InputDecorationTheme(
// //           border: OutlineInputBorder(),
// //         ),
// //         elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
// //         textButtonTheme: TextButtonThemeData(style: buttonStyle),
// //         outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
// //       ),
// //       title: 'Firebase UI demo',
// //       debugShowCheckedModeBanner: false,
// //       locale: const Locale('en'),
// //       localizationsDelegates: [
// //         FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
// //         GlobalMaterialLocalizations.delegate,
// //         GlobalWidgetsLocalizations.delegate,
// //         FirebaseUILocalizations.delegate,
// //       ],
// //       initialRoute: initialRoute,
// //       routes: {
// //         '/': (context) {
// //           return SignInScreen(
// //             actions: [
// //               ForgotPasswordAction((context, email) {
// //                 Navigator.pushNamed(
// //                   context,
// //                   '/forgot-password',
// //                   arguments: {'email': email},
// //                 );
// //               }),
// //               VerifyPhoneAction((context, _) {
// //                 Navigator.pushNamed(context, '/phone');
// //               }),
// //               AuthStateChangeAction<SignedIn>((context, state) {
// //                 if (!state.user!.emailVerified) {
// //                   Navigator.pushNamed(context, '/verify-email');
// //                 } else {
// //                   Navigator.pushReplacementNamed(context, '/profile');
// //                 }
// //               }),
// //               AuthStateChangeAction<UserCreated>((context, state) {
// //                 if (!state.credential.user!.emailVerified) {
// //                   Navigator.pushNamed(context, '/verify-email');
// //                 } else {
// //                   Navigator.pushReplacementNamed(context, '/profile');
// //                 }
// //               }),
// //               mfaAction,
// //               EmailLinkSignInAction((context) {
// //                 Navigator.pushReplacementNamed(context, '/email-link-sign-in');
// //               }),
// //             ],
// //             styles: const {
// //               EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
// //             },
// //             headerBuilder: headerImage('assets/images/flutterfire_logo.png'),
// //             sideBuilder: sideImage('assets/images/flutterfire_logo.png'),
// //             subtitleBuilder: (context, action) {
// //               return Padding(
// //                 padding: const EdgeInsets.only(bottom: 8),
// //                 child: Text(
// //                   action == AuthAction.signIn
// //                       ? 'Welcome to Firebase UI! Please sign in to continue.'
// //                       : 'Welcome to Firebase UI! Please create an account to continue',
// //                 ),
// //               );
// //             },
// //             footerBuilder: (context, action) {
// //               return Center(
// //                 child: Padding(
// //                   padding: const EdgeInsets.only(top: 16),
// //                   child: Text(
// //                     action == AuthAction.signIn
// //                         ? 'By signing in, you agree to our terms and conditions.'
// //                         : 'By registering, you agree to our terms and conditions.',
// //                     style: const TextStyle(color: Colors.grey),
// //                   ),
// //                 ),
// //               );
// //             },
// //           );
// //         },
// //         '/verify-email': (context) {
// //           return EmailVerificationScreen(
// //             headerBuilder: headerIcon(Icons.verified),
// //             sideBuilder: sideIcon(Icons.verified),
// //             actionCodeSettings: actionCodeSettings,
// //             actions: [
// //               EmailVerifiedAction(() {
// //                 Navigator.pushReplacementNamed(context, '/profile');
// //               }),
// //               AuthCancelledAction((context) {
// //                 FirebaseUIAuth.signOut(context: context);
// //                 Navigator.pushReplacementNamed(context, '/');
// //               }),
// //             ],
// //           );
// //         },
// //         '/phone': (context) {
// //           return PhoneInputScreen(
// //             actions: [
// //               SMSCodeRequestedAction((context, action, flowKey, phone) {
// //                 Navigator.of(context).pushReplacementNamed(
// //                   '/sms',
// //                   arguments: {
// //                     'action': action,
// //                     'flowKey': flowKey,
// //                     'phone': phone,
// //                   },
// //                 );
// //               }),
// //             ],
// //             headerBuilder: headerIcon(Icons.phone),
// //             sideBuilder: sideIcon(Icons.phone),
// //           );
// //         },
// //         '/sms': (context) {
// //           final arguments = ModalRoute.of(context)?.settings.arguments
// //               as Map<String, dynamic>?;
// //
// //           return SMSCodeInputScreen(
// //             actions: [
// //               AuthStateChangeAction<SignedIn>((context, state) {
// //                 Navigator.of(context).pushReplacementNamed('/profile');
// //               })
// //             ],
// //             flowKey: arguments?['flowKey'],
// //             action: arguments?['action'],
// //             headerBuilder: headerIcon(Icons.sms_outlined),
// //             sideBuilder: sideIcon(Icons.sms_outlined),
// //           );
// //         },
// //         '/forgot-password': (context) {
// //           final arguments = ModalRoute.of(context)?.settings.arguments
// //               as Map<String, dynamic>?;
// //
// //           return ForgotPasswordScreen(
// //             email: arguments?['email'],
// //             headerMaxExtent: 200,
// //             headerBuilder: headerIcon(Icons.lock),
// //             sideBuilder: sideIcon(Icons.lock),
// //           );
// //         },
// //         '/email-link-sign-in': (context) {
// //           return EmailLinkSignInScreen(
// //             actions: [
// //               AuthStateChangeAction<SignedIn>((context, state) {
// //                 Navigator.pushReplacementNamed(context, '/');
// //               }),
// //             ],
// //             provider: emailLinkProviderConfig,
// //             headerMaxExtent: 200,
// //             headerBuilder: headerIcon(Icons.link),
// //             sideBuilder: sideIcon(Icons.link),
// //           );
// //         },
// //         '/profile': (context) {
// //           return ProfileScreen(
// //             appBar: AppBar(
// //                 centerTitle: true,
// //                 title: const Text(
// //                   'profile',
// //                   style: TextStyle(color: Colors.white),
// //                 )),
// //             actions: [
// //               SignedOutAction((context) {}),
// //               mfaAction,
// //             ],
// //             actionCodeSettings: actionCodeSettings,
// //             showMFATile: true,
// //             children: [
// //               ElevatedButton(
// //                 onPressed: () {
// //                   Navigator.push(
// //                     context,
// //                     MaterialPageRoute(builder: (context) => const Home()),
// //                   );
// //                 },
// //                 child: const Text('Go Home'),
// //               )
// //             ],
// //           );
// //         },
// //       },
// //
// //     );
// //   }
// // }
// //
// // class LabelOverrides extends DefaultLocalizations {
// //   const LabelOverrides();
// //
// //   @override
// //   String get emailInputLabel => 'Enter your email';
// // }
// //
// // final actionCodeSettings = ActionCodeSettings(
// //   url: 'https://multiple-auth-e3d84.firebaseapp.com',
// //   handleCodeInApp: true,
// //   androidMinimumVersion: '1',
// //   androidPackageName: 'com.example.untitled',
// //   iOSBundleId: 'com.example.untitled',
// // );
// // final emailLinkProviderConfig = EmailLinkAuthProvider(
// //   actionCodeSettings: actionCodeSettings,
// // );
// //
// // class Home extends StatefulWidget {
// //   const Home({Key? key}) : super(key: key);
// //
// //   @override
// //   State<Home> createState() => _HomeState();
// // }
// //
// // class _HomeState extends State<Home> {
// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       color: Colors.white,
// //     );
// //   }
// // }
//
// import 'package:firebase_auth/firebase_auth.dart'
//     hide PhoneAuthProvider, EmailAuthProvider;
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
// import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
// import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
// import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';
//
// import 'firebase_options.dart';
//
// final actionCodeSettings = ActionCodeSettings(
//   url: 'https://my-flutter-sign.firebaseapp.com',
//   handleCodeInApp: true,
//   androidInstallApp: true,
//   androidMinimumVersion: '1',
//   androidPackageName: 'com.example.flutter_sign',
//   iOSBundleId: 'com.example.flutterSign',
//   // dynamicLinkDomain:'https://fluttersign.page.link'
// );
// final emailLinkProviderConfig = EmailLinkAuthProvider(
//   actionCodeSettings: actionCodeSettings,
// );
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//   FirebaseUIAuth.configureProviders([
//     EmailAuthProvider(),
//     emailLinkProviderConfig,
//     PhoneAuthProvider(),
//     GoogleProvider(
//       clientId:
//           '835328413024-fu8m54huocipu8tfvf4fhhilhir1ecij.apps.googleusercontent.com',
//       redirectUri: 'https://my-flutter-sign.firebaseapp.com/__/auth/handler',
//     ),
//     AppleProvider(scopes: {'email', 'fullName'}),
//     FacebookProvider(clientId: '16dbbdf0cfb309034a6ad98ac2a21688'),
//     TwitterProvider(
//       apiKey: 'jgt9i9Ec6TZ3jFxfCqL4WnYqv',
//       apiSecretKey: '8SckWVyew4jo5usmpfqIWDFeNu9U3Lk6IrckmEjrFsT6I6En0k',
//       redirectUri: 'https://my-flutter-sign.firebaseapp.com/__/auth/handler',
//     ),
//   ]);
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   String get initialRoute {
//     final auth = FirebaseAuth.instance;
//
//     if (auth.currentUser == null) {
//       return '/';
//     }
//
//     if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
//       return '/verify-email';
//     }
//
//     return '/home';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final mfaAction = AuthStateChangeAction<MFARequired>(
//       (context, state) async {
//         final nav = Navigator.of(context);
//
//         await startMFAVerification(
//           resolver: state.resolver,
//           context: context,
//         );
//
//         nav.pushReplacementNamed('/home');
//       },
//     );
//     return MaterialApp(
//       theme: ThemeData(
//         brightness: Brightness.light,
//         visualDensity: VisualDensity.standard,
//         inputDecorationTheme: const InputDecorationTheme(
//           border: OutlineInputBorder(),
//         ),
//       ),
//       debugShowCheckedModeBanner: false,
//       locale: const Locale('en'),
//       localizationsDelegates: [
//         FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
//         GlobalMaterialLocalizations.delegate,
//         GlobalWidgetsLocalizations.delegate,
//         FirebaseUILocalizations.delegate,
//       ],
//       initialRoute: initialRoute,
//       routes: {
//         '/': (context) {
//           return SignInScreen(
//             styles: const {
//               EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
//             },
//             headerBuilder: (context, constraints, _) {
//               return Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Image.asset('assets/images/flutterfire_logo.png'),
//               );
//             },
//             sideBuilder: (context, constraints) {
//               return Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(constraints.maxWidth / 4),
//                   child: Image.asset('assets/images/flutterfire_logo.png'),
//                 ),
//               );
//             },
//             subtitleBuilder: (context, action) {
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 8),
//                 child: Text(
//                   action == AuthAction.signIn
//                       ? 'Welcome to Firebase UI! Please sign in to continue.'
//                       : 'Welcome to Firebase UI! Please create an account to continue',
//                 ),
//               );
//             },
//             footerBuilder: (context, action) {
//               return Center(
//                 child: Padding(
//                   padding: const EdgeInsets.only(top: 16),
//                   child: Text(
//                     action == AuthAction.signIn
//                         ? 'By signing in, you agree to our terms and conditions.'
//                         : 'By registering, you agree to our terms and conditions.',
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 ),
//               );
//             },
//             actions: [
//               ForgotPasswordAction((context, email) {
//                 Navigator.of(context).pushNamed(
//                   '/forgot-password',
//                   arguments: {'email': email},
//                 );
//               }),
//               AuthStateChangeAction<SignedIn>((context, state) {
//                 if (!state.user!.emailVerified) {
//                   Navigator.pushNamed(context, '/verify-email');
//                 } else {
//                   Navigator.of(context).pushReplacementNamed('/home');
//                 }
//               }),
//               AuthStateChangeAction<UserCreated>((context, state) {
//                 if (!state.credential.user!.emailVerified) {
//                   Navigator.pushNamed(context, '/verify-email');
//                 } else {
//                   Navigator.of(context).pushReplacementNamed('/home');
//                 }
//               }),
//               VerifyPhoneAction((context, _) {
//                 Navigator.pushNamed(context, '/phone');
//               }),
//               EmailLinkSignInAction((context) {
//                 Navigator.pushReplacementNamed(context, '/email-link-sign-in');
//               }),
//               mfaAction,
//             ],
//           );
//         },
//         '/profile': (context) => const ProfileScreen(),
//         '/forgot-password': (context) => const ForgotPasswordScreen(),
//         '/home': (context) => const Home(),
//         '/custom-email-link': (context) => const MyCustomWidget(),
//         '/phone': (context) => PhoneInputScreen(
//               actions: [
//                 SMSCodeRequestedAction((context, action, flowKey, phone) {
//                   Navigator.of(context).pushReplacementNamed(
//                     '/sms',
//                     arguments: {
//                       'action': action,
//                       'flowKey': flowKey,
//                       'phone': phone,
//                     },
//                   );
//                 }),
//               ],
//             ),
//         '/sms': (context) {
//           final arguments = ModalRoute.of(context)?.settings.arguments
//               as Map<String, dynamic>?;
//
//           return SMSCodeInputScreen(
//             actions: [
//               AuthStateChangeAction<SignedIn>((context, state) {
//                 Navigator.of(context).pushReplacementNamed('/home');
//               })
//             ],
//             flowKey: arguments?['flowKey'],
//             action: arguments?['action'],
//           );
//         },
//         '/verify-email': (context) {
//           return EmailVerificationScreen(
//
//             headerBuilder: (context, constraints, shrinkOffset) {
//               return Padding(
//                 padding: const EdgeInsets.all(20).copyWith(top: 40),
//                 child: Icon(
//                   Icons.verified,
//                   color: Colors.blue,
//                   size: constraints.maxWidth / 4 * (1 - shrinkOffset),
//                 ),
//               );
//             },
//             sideBuilder: (context, constraints) {
//               return Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Icon(
//                   Icons.verified,
//                   color: Colors.blue,
//                   size: constraints.maxWidth / 3,
//                 ),
//               );
//             },
//             actionCodeSettings: actionCodeSettings,
//             actions: [
//               EmailVerifiedAction(() {
//                 Navigator.pushReplacementNamed(context, '/home');
//               }),
//               AuthCancelledAction((context) {
//                 FirebaseUIAuth.signOut(context: context);
//                 Navigator.pushReplacementNamed(context, '/');
//               }),
//             ],
//           );
//         },
//         '/email-link-sign-in': (context) {
//           return EmailLinkSignInScreen(
//
//             actions: [
//               AuthStateChangeAction<SignedIn>((context, state) {
//                 Navigator.pushNamed(context, '/custom-email-link');
//               }),
//             ],
//             provider: emailLinkProviderConfig,
//             headerMaxExtent: 200,
//             headerBuilder: (context, constraints, shrinkOffset) {
//               return Padding(
//                 padding: const EdgeInsets.all(20).copyWith(top: 40),
//                 child: Icon(
//                   Icons.link,
//                   color: Colors.blue,
//                   size: constraints.maxWidth / 4 * (1 - shrinkOffset),
//                 ),
//               );
//             },
//             sideBuilder: (context, constraints) {
//               return Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Icon(
//                   Icons.link,
//                   color: Colors.blue,
//                   size: constraints.maxWidth / 3,
//                 ),
//               );
//             },
//           );
//         },
//       },
//     );
//   }
// }
//
// class Home extends StatefulWidget {
//   const Home({Key? key}) : super(key: key);
//
//   @override
//   State<Home> createState() => _HomeState();
// }
//
// class _HomeState extends State<Home> {
//   @override
//   Widget build(BuildContext context) {
//     final mfaAction = AuthStateChangeAction<MFARequired>(
//       (context, state) async {
//         final nav = Navigator.of(context);
//
//         await startMFAVerification(
//           resolver: state.resolver,
//           context: context,
//         );
//
//         nav.pushReplacementNamed('/home');
//       },
//     );
//     return Scaffold(
//       appBar: AppBar(
//         actions: [
//           Align(
//             alignment: Alignment.topRight,
//             child: IconButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => ProfileScreen(
//                             appBar: AppBar(backgroundColor: Colors.red),
//                             actions: [
//                               SignedOutAction((context) {
//                                 Navigator.of(context)
//                                     .pushReplacementNamed('/sign-in');
//                               }),
//                               mfaAction,
//                             ],
//                             actionCodeSettings: actionCodeSettings,
//                             showMFATile: true,
//                           )),
//                 );
//               },
//               color: Colors.white,
//               icon: const Icon(Icons.account_box_sharp),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class LabelOverrides extends DefaultLocalizations {
//   const LabelOverrides();
//
//   @override
//   String get emailInputLabel => 'Enter your email';
// }
//
// class MyCustomWidget extends StatelessWidget {
//   const MyCustomWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return AuthFlowBuilder<EmailLinkAuthController>(
//       provider: emailLinkProviderConfig,
//       listener: (oldState, newState, ctrl) {
//         if (newState is SignedIn) {
//           Navigator.of(context).pushReplacementNamed('/home');
//         }
//       },
//       builder: (context, state, ctrl, child) {
//         if (state is Uninitialized) {
//           return TextField(
//             decoration: const InputDecoration(label: Text('Email')),
//             onSubmitted: (email) {
//               ctrl.sendLink(email);
//             },
//           );
//         } else if (state is AwaitingDynamicLink) {
//           return const CircularProgressIndicator();
//         } else if (state is AuthFailed) {
//           return ErrorText(exception: state.exception);
//         } else {
//           return Text('Unknown state $state');
//         }
//       },
//     );
//   }
// }
