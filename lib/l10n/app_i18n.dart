import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/settings_provider.dart';

class AppI18n {
  final AppLanguage language;

  const AppI18n(this.language);

  String _pick({
    required String en,
    required String sr,
    String? de,
    String? es,
  }) {
    switch (language) {
      case AppLanguage.serbian:
        return sr;
      case AppLanguage.german:
        return de ?? en;
      case AppLanguage.spanish:
        return es ?? en;
      case AppLanguage.english:
        return en;
    }
  }

  String get loading => _pick(
    en: 'Loading...',
    sr: 'Ucitavanje...',
    de: 'Laden...',
    es: 'Cargando...',
  );

  String get loginTitle =>
      _pick(en: 'Login', sr: 'Prijava', de: 'Anmelden', es: 'Iniciar sesion');
  String get loginFailed => _pick(
    en: 'Login failed. Try again.',
    sr: 'Prijava nije uspela. Pokusaj ponovo.',
    de: 'Anmeldung fehlgeschlagen. Versuche es erneut.',
    es: 'Error de inicio de sesion. Intenta de nuevo.',
  );
  String get demoMode => _pick(en: 'Demo mode', sr: 'Demo rezim');
  String get demoAccountsHint => _pick(
    en: 'Use test accounts: demo/demo, test/test, admin/admin, user/123, alex/password',
    sr: 'Koristi test naloge: demo/demo, test/test, admin/admin, user/123, alex/password',
  );
  String get username => _pick(en: 'Username', sr: 'Korisnicko ime');
  String get password => _pick(en: 'Password', sr: 'Lozinka');
  String get enterUsername =>
      _pick(en: 'Enter username', sr: 'Unesi korisnicko ime');
  String get enterPassword => _pick(en: 'Enter password', sr: 'Unesi lozinku');
  String get signIn => _pick(en: 'Sign in', sr: 'Prijavi se');
  String get noAccount =>
      _pick(en: "Don't have an account? ", sr: 'Nemas nalog? ');
  String get register => _pick(en: 'Register', sr: 'Registruj se');

  String noTopicsAvailable() => _pick(
    en: 'No topics are available right now.',
    sr: 'Trenutno nema dostupnih tema.',
  );
  String hello(String fallbackName) =>
      _pick(en: 'Hello, $fallbackName', sr: 'Zdravo, $fallbackName');
  String get fallbackStudent => _pick(en: 'student', sr: 'ucenik');
  String get fallbackPlayer => _pick(en: 'player', sr: 'igrac');
  String get badges => _pick(en: 'Badges', sr: 'Bedzevi');
  String get activity => _pick(en: 'Activity', sr: 'Aktivnost');
  String streakDays(int value) => _pick(en: '$value days', sr: '$value dana');
  String streakInRowDays(int value) =>
      _pick(en: '$value day streak', sr: '$value dana niza');
  String coins(int value) => _pick(en: '$value coins', sr: '$value coina');
  String level(int value) => _pick(en: 'Level $value', sr: 'Nivo $value');
  String get continueLearning =>
      _pick(en: 'Continue learning', sr: 'Nastavi ucenje');
  String get readyForNewRound =>
      _pick(en: 'Ready for a new round?', sr: 'Spremno za novu rundu?');
  String get pickTopicAndStart => _pick(
    en: 'Pick a topic and start the quiz',
    sr: 'Odaberi temu i kreni na kviz',
  );
  String get chooseTopic => _pick(en: 'Choose topic', sr: 'Izaberi temu');
  String dailyGoal(int value) => _pick(
    en: 'Daily goal: $value questions',
    sr: 'Dnevni cilj: $value pitanja',
  );
  String dailyGoalShort(int done, int target) =>
      _pick(en: '$done / $target goal', sr: '$done / $target cilj');
  String todayProgress(int done, int target) =>
      _pick(en: '$done / $target today', sr: '$done / $target danas');
  String get homeAccessibilityPreview => _pick(
    en: 'Home: accessibility preview',
    sr: 'Pocetna: pregled pristupacnosti',
  );
  String get arenaAccessibilityPreview => _pick(
    en: 'Arena: accessibility preview',
    sr: 'Arena: pregled pristupacnosti',
  );
  String get learningTopics =>
      _pick(en: 'Learning topics', sr: 'Teme za ucenje');
  String get homeArena => _pick(en: 'Home Arena', sr: 'Pocetna arena');
  String get missionTopics => _pick(en: 'Mission topics', sr: 'Teme misije');
  String get allTopics => _pick(en: 'All topics', sr: 'Sve teme');
  String unlockAtLevel(int level) => _pick(
    en: 'Unlocks at level $level',
    sr: 'Otkljucava se na levelu $level',
  );
  String get readyForQuiz => _pick(en: 'Ready for quiz', sr: 'Spremna za kviz');
  String get readyToPlay =>
      _pick(en: 'Ready to play', sr: 'Spremno za igranje');
  String get play => _pick(en: 'Play', sr: 'Igraj');
  String get chooseTopicAndContinueQuiz => _pick(
    en: 'Pick a topic and continue quiz',
    sr: 'Odaberi temu i nastavi kviz',
  );
  String get launchNextQuiz =>
      _pick(en: 'Launch next quiz', sr: 'Pokreni sledeci kviz');
  String get navHome => _pick(en: 'Home', sr: 'Pocetna');
  String get navQuiz => _pick(en: 'Quiz', sr: 'Kviz');
  String get navRank => _pick(en: 'Rank', sr: 'Rang');
  String get navProfile => _pick(en: 'Profile', sr: 'Profil');

  String get noQuestions =>
      _pick(en: 'No questions available', sr: 'Nema dostupnih pitanja');
  String get retry => _pick(en: 'Retry', sr: 'Pokusaj ponovo');

  String questionLabel(int value) =>
      _pick(en: 'Question $value', sr: 'Pitanje $value');
  String correctXp(int xp) =>
      _pick(en: 'Correct! +$xp XP', sr: 'Tacno! +$xp XP');
  String get wrongKeepGoing =>
      _pick(en: 'Incorrect, keep going', sr: 'Netacno, idemo dalje');
  String get finishQuiz => _pick(en: 'Finish quiz', sr: 'Zavrsi kviz');
  String get nextQuestion => _pick(en: 'Next question', sr: 'Sledece pitanje');
  String get mathChallengeTitle =>
      _pick(en: 'Math Challenge', sr: 'Math izazov');
  String get mathChallengeSubtitle => _pick(
    en: 'Solve it for streak and XP',
    sr: 'Resi zadatak za streak i XP',
  );
  String comboLabel(int combo) =>
      _pick(en: 'Combo x$combo', sr: 'Combo x$combo');
  String noHintBonus(int xp) =>
      _pick(en: 'No-hint bonus +$xp XP', sr: 'Bonus bez pomoci +$xp XP');
  String get tryAgain => _pick(en: 'Try again', sr: 'Pokusaj opet');
  String get masteryLabel => _pick(en: 'Mastery', sr: 'Majstorstvo');
  String masteryMilestone(int percent) =>
      _pick(en: 'Mastery $percent%', sr: 'Majstorstvo $percent%');
  String get masteryMax => _pick(en: 'Mastery MAX!', sr: 'Majstorstvo MAX!');

  String get settings => _pick(en: 'Settings', sr: 'Podesavanja');
  String get settingsQuest => _pick(en: 'Settings Quest', sr: 'Settings Quest');
  String levelMissionProgress(int level, int done, int total) => _pick(
    en: 'Level $level - $done/$total quests',
    sr: 'Level $level - $done/$total misija',
  );
  String get sectionProfile => _pick(en: 'Profile', sr: 'Profil');
  String get profileCardSubtitle => _pick(
    en: 'Edit name, avatar and account',
    sr: 'Izmeni ime, avatar i nalog',
  );
  String get sectionQuizExperience =>
      _pick(en: 'Quiz experience', sr: 'Kviz iskustvo');
  String get hintsToggleTitle => _pick(en: 'Hints', sr: 'Hints');
  String get hintsToggleSubtitle => _pick(
    en: 'Global switch for all quiz hints',
    sr: 'Globalni prekidac za sve pomoci u kvizu',
  );
  String get formulaToggleSubtitle =>
      _pick(en: 'Allow formula hint', sr: 'Dozvoli formula hint');
  String get clueToggleTitle => _pick(en: 'Small clue', sr: 'Mali clue');
  String get clueToggleSubtitle =>
      _pick(en: 'Allow clue hint', sr: 'Dozvoli clue hint');
  String get eliminateToggleTitle =>
      _pick(en: 'Eliminate one', sr: 'Eliminacija odgovora');
  String get eliminateToggleSubtitle =>
      _pick(en: 'Allow 50/50 hint', sr: 'Dozvoli 50/50 hint');
  String get sectionNotifications =>
      _pick(en: 'Notifications', sr: 'Notifikacije');
  String get dailyReminderTitle =>
      _pick(en: 'Daily reminder', sr: 'Daily reminder');
  String get dailyReminderSubtitle => _pick(
    en: 'Reminder for daily training',
    sr: 'Podsetnik za dnevni trening',
  );
  String get reminderTime => _pick(en: 'Reminder time', sr: 'Vreme podsetnika');
  String get allowNotificationsMessage => _pick(
    en: 'Allow notifications so daily reminder can work.',
    sr: 'Dozvoli notifikacije da bi daily reminder radio.',
  );
  String get reminderSavedButNoPermission => _pick(
    en: 'Reminder time is saved, but notifications are not allowed.',
    sr: 'Reminder vreme je sacuvano, ali notifikacije nisu dozvoljene.',
  );
  String get sectionThemeAndApp => _pick(en: 'Theme and app', sr: 'Tema i app');
  String get advancedThemeTitle =>
      _pick(en: 'Advanced theme options', sr: 'Napredne tema opcije');
  String get advancedThemeSubtitle => _pick(
    en: 'Reduce motion, contrast and preview',
    sr: 'Reduce motion, contrast i preview',
  );
  String get sectionAudioHaptics =>
      _pick(en: 'Audio and haptics', sr: 'Audio i haptika');
  String get soundEffectsTitle =>
      _pick(en: 'Sound effects', sr: 'Sound effects');
  String get soundEffectsSubtitle =>
      _pick(en: 'Click and feedback sound', sr: 'Klik i feedback zvuk');
  String get vibrationTitle => _pick(en: 'Vibration', sr: 'Vibration');
  String get vibrationSubtitle => _pick(
    en: 'Haptic feedback on answers',
    sr: 'Haptic feedback pri odgovorima',
  );
  String get dailyTip => _pick(
    en: 'Tip: enable daily reminder and finish setup quest for +40 XP.',
    sr: 'Tip: ukljuci daily reminder i zavrsi setup misiju za +40 XP.',
  );
  String get languageLabel => _pick(en: 'Language', sr: 'Jezik');
  String get darkLightMode =>
      _pick(en: 'Dark / Light mode', sr: 'Dark / Light mode');
  String get light => _pick(en: 'Light', sr: 'Light');
  String get dark => _pick(en: 'Dark', sr: 'Dark');
  String get quickLightHint => _pick(
    en: 'Quick brightness choice. Detailed theme is below.',
    sr: 'Brzi izbor osvetljenja. Detaljnu temu biras ispod.',
  );
  String get visualTheme => _pick(en: 'Visual theme', sr: 'Vizuelna tema');
  String get profileSetupQuest =>
      _pick(en: 'Profile setup', sr: 'Profil podesavanje');
  String get reminderDecisionQuest =>
      _pick(en: 'Reminder decision', sr: 'Reminder odluka');
  String get themeChoiceQuest => _pick(en: 'Theme choice', sr: 'Tema izbor');
  String get hintsPrefQuest =>
      _pick(en: 'Hints preference', sr: 'Hints preference');
  String get soundVibrationQuest =>
      _pick(en: 'Sound & vibration', sr: 'Sound & vibration');
  String get formulaHintTitle =>
      _pick(en: 'Formula hint', sr: 'Formula pomoci');
  String get formulaHintSubtitle => _pick(
    en: 'Use this pattern and finish the challenge',
    sr: 'Iskoristi sablon i zavrsi izazov',
  );
  String get gotIt => _pick(en: 'Got it', sr: 'Razumem');
  String get formulaBonusTip => _pick(
    en: 'Tip: solving the next one without hints keeps your combo alive.',
    sr: 'Tip: sledeci zadatak bez pomoci cuva combo niz.',
  );
  String get showNextStep =>
      _pick(en: 'Show next step', sr: 'Prikazi sledeci korak');
  String get showAllSteps =>
      _pick(en: 'Show all steps', sr: 'Prikazi sve korake');
  String formulaStepCounter(int current, int total) =>
      _pick(en: 'Step $current of $total', sr: 'Korak $current od $total');
}

extension AppI18nContextX on BuildContext {
  AppI18n get t {
    final language = Provider.of<SettingsProvider>(
      this,
      listen: false,
    ).language;
    return AppI18n(language);
  }
}
