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

  String get loading => _pick(en: 'Loading...', sr: 'Ucitavanje...');
  String get hint => _pick(en: 'Hint', sr: 'Pomoc');
  String get retry => _pick(en: 'Retry', sr: 'Pokusaj ponovo');
  String get play => _pick(en: 'Play', sr: 'Igraj');
  String get settings => _pick(en: 'Settings', sr: 'Podesavanja');
  String get gotIt => _pick(en: 'Got it', sr: 'Razumem');

  String get loginTitle => _pick(en: 'Login', sr: 'Prijava');
  String get loginFailed =>
      _pick(en: 'Login failed. Try again.', sr: 'Prijava nije uspela.');
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
  String get noAccount => _pick(en: "Don't have an account?", sr: 'Nemas nalog?');
  String get register => _pick(en: 'Register', sr: 'Registruj se');

  String get learningTopics => _pick(en: 'Learning topics', sr: 'Teme za ucenje');
  String get missionTopics => _pick(en: 'Mission topics', sr: 'Teme misije');
  String get allTopics => _pick(en: 'All topics', sr: 'Sve teme');
  String get chooseTopic => _pick(en: 'Choose topic', sr: 'Izaberi temu');
  String get pickTopicAndStart =>
      _pick(en: 'Pick a topic and start the quiz', sr: 'Odaberi temu i kreni');
  String get chooseTopicAndContinueQuiz =>
      _pick(en: 'Pick a topic and continue quiz', sr: 'Izaberi temu i nastavi kviz');
  String noTopicsAvailable() =>
      _pick(en: 'No topics available.', sr: 'Nema dostupnih tema.');

  String get activity => _pick(en: 'Activity', sr: 'Aktivnost');
  String get badges => _pick(en: 'Badges', sr: 'Bedzevi');
  String streakDays(int value) => _pick(en: '$value days', sr: '$value dana');
  String streakInRowDays(int value) =>
      _pick(en: '$value-day streak', sr: '$value dana niza');

  String coins(int value) => _pick(en: '$value coins', sr: '$value coina');
  String level(int value) => _pick(en: 'Level $value', sr: 'Nivo $value');

    String get nextLevelHint => _pick(
            en: 'Earn XP to reach the next level', sr: 'Sakupljaj XP da dostignes sledeci nivo');

  String dailyGoal(int value) =>
      _pick(en: 'Daily goal: $value questions', sr: 'Dnevni cilj: $value pitanja');
  String dailyGoalShort(int done, int target) =>
      _pick(en: '$done / $target goal', sr: '$done / $target cilj');
  String todayProgress(int done, int target) =>
      _pick(en: '$done / $target today', sr: '$done / $target danas');

  String hello(String name) => _pick(en: 'Hi, $name', sr: 'Zdravo, $name');
  String get fallbackStudent => _pick(en: 'student', sr: 'ucenik');
  String get fallbackPlayer => _pick(en: 'player', sr: 'igrac');
  String get continueLearning =>
      _pick(en: 'Continue learning', sr: 'Nastavi ucenje');
  String get readyForNewRound =>
      _pick(en: 'Ready for a new round', sr: 'Spremno za novu rundu');
  String unlockAtLevel(int value) =>
      _pick(en: 'Unlocks at level $value', sr: 'Otkljucava se na nivou $value');
  String get homeAccessibilityPreview =>
      _pick(en: 'Accessibility preview', sr: 'Prikaz pristupacnosti');
  String get arenaAccessibilityPreview =>
      _pick(en: 'Arena accessibility preview', sr: 'Arena prikaz pristupacnosti');
  String get homeArena => _pick(en: 'Home Arena', sr: 'Pocetna Arena');
  String get launchNextQuiz =>
      _pick(en: 'Launch next quiz', sr: 'Pokreni sledeci kviz');
  String get navHome => _pick(en: 'Home', sr: 'Pocetna');
  String get navQuiz => _pick(en: 'Quiz', sr: 'Kviz');
  String get navRank => _pick(en: 'Rank', sr: 'Rang');
  String get navProfile => _pick(en: 'Profile', sr: 'Profil');

  String questionLabel(int value) =>
      _pick(en: 'Question $value', sr: 'Pitanje $value');
  String get noQuestions =>
      _pick(en: 'No questions available.', sr: 'Nema dostupnih pitanja.');
  String get wrongKeepGoing =>
      _pick(en: 'Incorrect, keep going', sr: 'Netacno, idemo dalje');
  String get finishQuiz => _pick(en: 'Finish quiz', sr: 'Zavrsi kviz');
  String get nextQuestion =>
      _pick(en: 'Next question', sr: 'Sledece pitanje');

  String correctXp(int xp) => _pick(en: 'Correct! +$xp XP', sr: 'Tacno! +$xp XP');
  String get readyForQuiz => _pick(en: 'Ready for quiz', sr: 'Spremno za kviz');
  String get readyToPlay => _pick(en: 'Ready to play', sr: 'Spremno za igranje');

  String get mathChallengeTitle =>
      _pick(en: 'Math challenge', sr: 'Matematicki izazov');
  String get mathChallengeSubtitle =>
      _pick(en: 'Choose the best answer', sr: 'Izaberi najbolji odgovor');
  String comboLabel(int value) =>
      _pick(en: '${value}x combo', sr: '${value}x combo');
  String noHintBonus(int xp) =>
      _pick(en: 'No-hint bonus +$xp XP', sr: 'Bonus bez pomoci +$xp XP');
  String get masteryLabel => _pick(en: 'Mastery', sr: 'Savladanost');
  String masteryMilestone(int percent) =>
      _pick(en: 'Mastery $percent% reached', sr: 'Savladanost $percent% dostignuta');
  String get masteryMax =>
      _pick(en: 'Mastery complete', sr: 'Savladanost kompletirana');
  String get tryAgain => _pick(en: 'Try again', sr: 'Pokusaj ponovo');

  String get qsTitle => _pick(en: 'Quiz Complete!', sr: 'Kviz zavrsen!');
  String qsSubtitle(int correct, int total) =>
      _pick(en: 'You got $correct out of $total correct.', sr: 'Tacno: $correct od $total.');
    String get qsErrorNoStats => _pick(en: 'No stats available.', sr: 'Nema statistike.');
    String get qsCorrect => _pick(en: 'Correct', sr: 'Tacno');
    String get qsTotal => _pick(en: 'Total', sr: 'Ukupno');
    String get qsXp => _pick(en: 'XP', sr: 'XP');
    String get qsRetry => _pick(en: 'Retry', sr: 'Pokusaj ponovo');
  String get qsStreak => _pick(en: 'Streak', sr: 'Niz');
  String get qsAccuracy => _pick(en: 'Accuracy', sr: 'Tacnost');
  String get qsMastery => _pick(en: 'Mastery', sr: 'Savladanost');
  String get qsPlayAgain => _pick(en: 'Play Again', sr: 'Igraj ponovo');
  String get qsBackHome => _pick(en: 'Back to Home', sr: 'Nazad na pocetnu');
  String get qsReviewTitle =>
      _pick(en: 'Questions to Review', sr: 'Pitanja za ponavljanje');
  String get qsMore => _pick(en: 'more', sr: 'vise');

  String get smallHint =>
      _pick(en: 'Small hint (-1 XP)', sr: 'Mala pomoc (-1 XP)');
  String get mediumHint =>
      _pick(en: 'Medium hint (-3 XP)', sr: 'Srednja pomoc (-3 XP)');
  String get fullHint => _pick(en: 'Full hint (-5 XP)', sr: 'Cela pomoc (-5 XP)');
  String get noHintAvailable =>
      _pick(en: 'No hint available', sr: 'Pomoc nije dostupna');

  String get formulaHintTitle => _pick(en: 'Formula hint', sr: 'Formula pomoc');
  String get formulaHintSubtitle =>
      _pick(en: 'Use this pattern', sr: 'Iskoristi sablon');
  String formulaStepCounter(int current, int total) =>
      _pick(en: 'Step $current of $total', sr: 'Korak $current od $total');
  String get showNextStep =>
      _pick(en: 'Show next step', sr: 'Prikazi sledeci korak');
  String get showAllSteps => _pick(en: 'Show all steps', sr: 'Prikazi sve korake');
  String get formulaBonusTip => _pick(
    en: 'Tip: solve next without hints to keep combo.',
    sr: 'Tip: sledeci zadatak bez pomoci cuva combo niz.',
  );

  String get sectionProfile => _pick(en: 'Profile', sr: 'Profil');
  String get profileCardSubtitle =>
      _pick(en: 'Manage your account info', sr: 'Uredi informacije o nalogu');
  String get sectionQuizExperience =>
      _pick(en: 'Quiz experience', sr: 'Kviz iskustvo');
  String get hintsToggleTitle => _pick(en: 'Hints', sr: 'Pomoci');
  String get hintsToggleSubtitle =>
      _pick(en: 'Enable hints during quiz', sr: 'Ukljuci pomoci tokom kviza');
  String get formulaToggleSubtitle =>
      _pick(en: 'Show formula pattern hints', sr: 'Prikazi formula pomoci');
  String get clueToggleTitle => _pick(en: 'Clue hints', sr: 'Hint tragovi');
  String get clueToggleSubtitle =>
      _pick(en: 'Enable clue-based hints', sr: 'Ukljuci hintove sa tragovima');
  String get eliminateToggleTitle =>
      _pick(en: 'Eliminate option', sr: 'Uklanjanje opcije');
  String get eliminateToggleSubtitle =>
      _pick(en: 'Hide one wrong answer', sr: 'Sakrij jedan netacan odgovor');
  String get sectionNotifications =>
      _pick(en: 'Notifications', sr: 'Obavestenja');
  String get dailyReminderTitle =>
      _pick(en: 'Daily reminder', sr: 'Dnevni podsetnik');
  String get dailyReminderSubtitle =>
      _pick(en: 'Get a reminder every day', sr: 'Dobijaj podsetnik svaki dan');
  String get allowNotificationsMessage => _pick(
    en: 'Allow notifications in browser settings.',
    sr: 'Dozvoli obavestenja u podesavanjima pregledaca.',
  );
  String get reminderTime => _pick(en: 'Reminder time', sr: 'Vreme podsetnika');
  String get reminderSavedButNoPermission => _pick(
    en: 'Time saved, but notification permission is missing.',
    sr: 'Vreme sacuvano, ali nedostaje dozvola za obavestenja.',
  );
  String get sectionThemeAndApp =>
      _pick(en: 'Theme and app', sr: 'Tema i aplikacija');
  String get advancedThemeTitle =>
      _pick(en: 'Advanced themes', sr: 'Napredne teme');
  String get advancedThemeSubtitle =>
      _pick(en: 'Explore more visual styles', sr: 'Istrazi vise vizuelnih stilova');
  String get sectionAudioHaptics =>
      _pick(en: 'Audio and haptics', sr: 'Zvuk i vibracija');
  String get soundEffectsTitle =>
      _pick(en: 'Sound effects', sr: 'Zvucni efekti');
  String get soundEffectsSubtitle =>
      _pick(en: 'Play sounds for actions', sr: 'Pusti zvuk za akcije');
  String get vibrationTitle => _pick(en: 'Vibration', sr: 'Vibracija');
  String get vibrationSubtitle =>
      _pick(en: 'Use haptic feedback', sr: 'Koristi vibracioni feedback');
  String get dailyTip => _pick(
    en: 'Tip: enable reminders to build a daily habit.',
    sr: 'Tip: ukljuci podsetnike za dnevnu rutinu.',
  );
  String get settingsQuest => _pick(en: 'Setup Quest', sr: 'Setup misija');
  String levelMissionProgress(int level, int done, int total) => _pick(
    en: 'Level $level setup progress: $done/$total',
    sr: 'Nivo $level setup napredak: $done/$total',
  );
  String get profileSetupQuest =>
      _pick(en: 'Set up your profile', sr: 'Podesi profil');
  String get reminderDecisionQuest =>
      _pick(en: 'Choose reminder preference', sr: 'Izaberi podsetnik opciju');
  String get themeChoiceQuest => _pick(en: 'Pick a theme', sr: 'Izaberi temu');
  String get hintsPrefQuest =>
      _pick(en: 'Set hint preferences', sr: 'Podesi preference pomoci');
  String get soundVibrationQuest =>
      _pick(en: 'Set sound and vibration', sr: 'Podesi zvuk i vibraciju');
  String get languageLabel => _pick(en: 'Language', sr: 'Jezik');
  String get darkLightMode =>
      _pick(en: 'Dark / Light mode', sr: 'Tamni / Svetli rezim');
  String get light => _pick(en: 'Light', sr: 'Svetlo');
  String get dark => _pick(en: 'Dark', sr: 'Tamno');
  String get quickLightHint => _pick(
    en: 'Quick switch between light and dark presets.',
    sr: 'Brzo prebacivanje izmedju svetlih i tamnih tema.',
  );
  String get visualTheme => _pick(en: 'Visual theme', sr: 'Vizuelna tema');

    String get networkError => _pick(
        en: 'Network error',
        sr: 'Došlo je do greške u mreži.',
    );

  String get obWelcomeTitle => _pick(en: 'Welcome!', sr: 'Dobrodosli!');
  String get obWelcomeSubtitle => _pick(
    en: "Let's level up your math skills",
    sr: 'Poboljsacemo tvoje matematicke vestine',
  );
  String get obLanguageTitle => _pick(en: 'Choose language', sr: 'Izaberi jezik');
  String get obLanguageSubtitle =>
      _pick(en: 'Pick the interface language', sr: 'Izaberi jezik aplikacije');
  String get obDifficultyTitle => _pick(en: 'Difficulty', sr: 'Tezina');
  String get obDifficultySubtitle =>
      _pick(en: 'Choose difficulty', sr: 'Izaberi tezinu');
  String get obEasy => _pick(en: 'Easy', sr: 'Lako');
  String get obNormal => _pick(en: 'Normal', sr: 'Normalno');
  String get obHard => _pick(en: 'Hard', sr: 'Tesko');
  String get obDailyTitle => _pick(en: 'Daily Review', sr: 'Dnevno ponavljanje');
  String get obDailySubtitle =>
      _pick(en: 'Enable spaced repetition', sr: 'Ukljuci ponavljanje');
  String get obEnableReminder =>
      _pick(en: 'Enable daily reminder', sr: 'Ukljuci dnevni podsetnik');
  String get obContinue => _pick(en: 'Continue', sr: 'Nastavi');
  String get obStartLearning =>
      _pick(en: 'Start Learning', sr: 'Pocni da ucis');
}

extension AppI18nContextX on BuildContext {
  AppI18n get t {
    final language = Provider.of<SettingsProvider>(this, listen: false).language;
    return AppI18n(language);
  }
}

