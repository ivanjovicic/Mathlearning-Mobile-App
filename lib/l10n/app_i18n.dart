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

  String get loading => _pick(en: 'Loading...', sr: 'Učitavanje...');
  String get hint => _pick(en: 'Hint', sr: 'Pomoć');
  String get retry => _pick(en: 'Retry', sr: 'Pokušaj ponovo');
  String get play => _pick(en: 'Play', sr: 'Igraj');
  String get settings => _pick(en: 'Settings', sr: 'Podešavanja');
  String get gotIt => _pick(en: 'Got it', sr: 'Razumem');

  String get loginTitle => _pick(en: 'Login', sr: 'Prijava');
  String get loginFailed =>
      _pick(en: 'Login failed. Try again.', sr: 'Prijava nije uspela.');
  String get authLoginFailed =>
      _pick(en: 'Login failed. Try again.', sr: 'Prijava nije uspela.');
  String get authInvalidCredentials =>
      _pick(en: 'Invalid credentials.', sr: 'Pogrešni podaci za prijavu.');
  String get authUsernameTaken =>
      _pick(en: 'Username is already taken.', sr: 'Korisničko ime je zauzeto.');
  String get authEmailTaken => _pick(
    en: 'Email address is already taken.',
    sr: 'Imejl adresa je već zauzeta.',
  );
  String get authNetworkError =>
      _pick(en: 'Network error.', sr: 'Došlo je do greške u mreži.');
  String get demoMode => _pick(en: 'Demo mode', sr: 'Demo režim');
  String get demoAccountsHint => _pick(
    en: 'Local test accounts: test/test123, student/student123',
    sr: 'Lokalni test nalozi: test/test123, student/student123',
  );
  String get username => _pick(en: 'Username', sr: 'Korisničko ime');
  String get password => _pick(en: 'Password', sr: 'Lozinka');
  String get enterUsername =>
      _pick(en: 'Enter username', sr: 'Unesi korisničko ime');
  String get enterPassword => _pick(en: 'Enter password', sr: 'Unesi lozinku');
  String get signIn => _pick(en: 'Sign in', sr: 'Prijavi se');
  String get noAccount =>
      _pick(en: "Don't have an account?", sr: 'Nemaš nalog?');
  String get register => _pick(en: 'Register', sr: 'Registruj se');

  String get learningTopics =>
      _pick(en: 'Learning topics', sr: 'Teme za učenje');
  String get missionTopics => _pick(en: 'Mission topics', sr: 'Teme misije');
  String get allTopics => _pick(en: 'All topics', sr: 'Sve teme');
  String get chooseTopic => _pick(en: 'Choose topic', sr: 'Izaberi temu');
  String get pickTopicAndStart =>
      _pick(en: 'Pick a topic and start the quiz', sr: 'Odaberi temu i kreni');
  String get chooseTopicAndContinueQuiz => _pick(
    en: 'Pick a topic and continue quiz',
    sr: 'Izaberi temu i nastavi kviz',
  );
  String get learningInsightsTitle =>
      _pick(en: 'Learning Insights', sr: 'Uvid u učenje');
  String get overview => _pick(en: 'Overview', sr: 'Pregled');
  String get weakTopics => _pick(en: 'Weak Topics', sr: 'Slabe teme');
  String get openMap => _pick(en: 'Open Map', sr: 'Otvori mapu');
  String get completed => _pick(en: 'Completed', sr: 'Završeno');
  String get avgMastery => _pick(en: 'Avg Mastery', sr: 'Prosečna savladanost');
  String get dueReviews => _pick(en: 'Due Reviews', sr: 'Za ponavljanje');
  String get upNext => _pick(en: 'Up Next', sr: 'Sledeće');
  String get pathProgress => _pick(en: 'Path Progress', sr: 'Napredak putanje');
  String get noNodesLoadedYet =>
      _pick(en: 'No nodes loaded yet', sr: 'Čvorovi još nisu učitani');
  String learningPathDonePercent(int percent) => _pick(
    en: '$percent% of your learning path done',
    sr: '$percent% tvoje putanje učenja je završeno',
  );
  String get showingOfflinePath => _pick(
    en: 'Showing offline path — connect to sync with your progress.',
    sr: 'Prikazuje se oflajn putanja — poveži se radi sinhronizacije napretka.',
  );
  String get noMasteryDataYet =>
      _pick(en: 'No mastery data yet', sr: 'Još nema podataka o savladanosti');
  String get noWeakTopicsGreatWork => _pick(
    en: 'No weak topics — great work!',
    sr: 'Nema slabih tema — sjajan posao!',
  );
  String get keepPracticingMastery => _pick(
    en: 'Keep practicing to maintain your mastery.',
    sr: 'Nastavi da vežbaš kako bi održao savladanost.',
  );
  String get needsWork => _pick(en: 'Needs Work', sr: 'Treba doraditi');
  String topicsBelowAccuracy(int count, int threshold) => _pick(
    en: '$count topic${count == 1 ? '' : 's'} below $threshold% accuracy',
    sr: '$count tema ispod $threshold% tačnosti',
  );
  String noTopicsAvailable() =>
      _pick(en: 'No topics available.', sr: 'Nema dostupnih tema.');
  String learningMapTitleWithUsername(String username) =>
      _pick(en: "$username's Adventure Map", sr: 'Mapa avanture: $username');
  String get learningMapTitleDefault =>
      _pick(en: 'Your Adventure Map', sr: 'Tvoja mapa avanture');
  String get learningMapOfflineProgressBanner => _pick(
    en: "You're offline — showing your saved progress.",
    sr: 'Nisi na mreži — prikazujemo sačuvani napredak.',
  );
  String get learningMapQuests => _pick(en: 'Quests', sr: 'Misije');
  String get learningMapYourLevels =>
      _pick(en: 'Your Levels', sr: 'Tvoji nivoi');
  String get learningMapLockedLevelHint => _pick(
    en: 'Beat the level before this one to unlock it!',
    sr: 'Pobedi prethodni nivo da otključaš ovaj!',
  );
  String get learningMapOnlineRequired => _pick(
    en: 'You need Wi-Fi or data to play this round!',
    sr: 'Potreban ti je Wi-Fi ili mobilni internet za ovu rundu!',
  );
  String get learningMapDailyRewardNotConfirmed => _pick(
    en: 'Daily reward is not confirmed right now. Please try again.',
    sr: 'Dnevna nagrada trenutno nije potvrđena. Pokušaj ponovo.',
  );
  String learningMapItemEquipped(String itemName) =>
      _pick(en: '$itemName equipped!', sr: 'Opremljeno: $itemName!');
  String get learningMapTomorrowChestTeaser => _pick(
    en: "Tomorrow's chest is even better 👀",
    sr: 'Sutra te čeka još bolja škrinja 👀',
  );
  String learningMapRecommendationReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'low_mastery':
        return _pick(
          en: "You're almost there — keep training!",
          sr: 'Skoro si tu — nastavi da vežbaš!',
        );
      case 'weak':
        return _pick(
          en: 'Time to level up your weak spot!',
          sr: 'Vreme je da ojačaš svoju slabiju oblast!',
        );
      case 'review':
        return _pick(
          en: 'Quick review — lock in what you learned!',
          sr: 'Kratko ponavljanje — učvrsti naučeno!',
        );
      default:
        return _pick(
          en: "You're on a roll — keep it up! 🔥",
          sr: 'Ide ti odlično — samo nastavi! 🔥',
        );
    }
  }

  String get learningMapDifficultyPromptEasy => _pick(
    en: 'Perfect starting point — jump in! 🎯',
    sr: 'Odlično za početak — kreni! 🎯',
  );
  String get learningMapDifficultyPromptMedium => _pick(
    en: "You've got this — go for it! ⚡",
    sr: 'Možeš ti to — samo napred! ⚡',
  );
  String get learningMapDifficultyPromptHard => _pick(
    en: 'Boss level unlocked — do you dare? 🏆',
    sr: 'Boss nivo je otključan — da li si spreman? 🏆',
  );
  String get learningMapConnectWifiPrompt => _pick(
    en: 'Connect to Wi-Fi to play! 📶',
    sr: 'Poveži se na Wi-Fi da bi nastavio igru! 📶',
  );
  String get learningMapUpNextForYou =>
      _pick(en: 'Up Next for You', sr: 'Sledeće za tebe');
  String get learningMapPlayArrow => _pick(en: 'Play →', sr: 'Igraj →');
  String get learningMapBuildYourMapHint => _pick(
    en: 'Do a few practice rounds to build your map!',
    sr: 'Odradi nekoliko rundi vežbe da izgradiš svoju mapu!',
  );

  String get activity => _pick(en: 'Activity', sr: 'Aktivnost');
  String get badges => _pick(en: 'Badges', sr: 'Bedževi');
  String streakDays(int value) => _pick(en: '$value days', sr: '$value dana');
  String streakInRowDays(int value) =>
      _pick(en: '$value-day streak', sr: '$value dana niza');

  String coins(int value) => _pick(en: '$value coins', sr: '$value novčića');
  String level(int value) => _pick(en: 'Level $value', sr: 'Nivo $value');
  String xpProgressShort(int current, int target) =>
      _pick(en: '$current / $target XP', sr: '$current / $target XP');

  String get nextLevelHint => _pick(
    en: 'Earn XP to reach the next level',
    sr: 'Sakupljaj XP da dostigneš sledeći nivo',
  );

  String dailyGoal(int value) => _pick(
    en: 'Daily goal: $value questions',
    sr: 'Dnevni cilj: $value pitanja',
  );
  String dailyGoalShort(int done, int target) =>
      _pick(en: '$done / $target goal', sr: '$done / $target cilj');
  String todayProgress(int done, int target) =>
      _pick(en: '$done / $target today', sr: '$done / $target danas');
  String get homeNoTopicsTitle =>
      _pick(en: 'No topics available', sr: 'Nema dostupnih tema');
  String get homeNoTopicsSubtitle => _pick(
    en: 'Refresh the screen or try again later.',
    sr: 'Osveži ekran ili pokušaj ponovo kasnije.',
  );
  String get homeDailyReviewTitle =>
      _pick(en: 'Daily Review', sr: 'Dnevno ponavljanje');
  String get homeDailyReviewLoading => _pick(
    en: 'Loading daily review...',
    sr: 'Učitavam dnevno ponavljanje...',
  );
  String get homeDailyReviewEmpty =>
      _pick(en: 'No SRS questions for today', sr: 'Nema SRS pitanja za danas');
  String homeDailyReviewSubtitle(int count, int minutes) => _pick(
    en: 'Today you have $count SRS questions - ~$minutes min',
    sr: 'Danas imaš $count SRS pitanja - ~$minutes min',
  );
  String get homeNoQuestionsToday =>
      _pick(en: 'No questions for today.', sr: 'Nema pitanja za danas.');
  String get homeRefresh => _pick(en: 'Refresh', sr: 'Osveži');
  String get dailyMissions => _pick(en: 'Daily missions', sr: 'Dnevne misije');
  String dailyMissionSemantics(String title, int percent, int xpReward) => _pick(
    en: '$title, $percent% complete, +$xpReward XP',
    sr: '$title, $percent% završeno, +$xpReward XP',
  );
  String xpRewardShort(int value) => _pick(en: '+$value XP', sr: '+$value XP');
  String get homeLearningMapOpen =>
      _pick(en: 'Open Learning Map', sr: 'Otvori mapu učenja');
  String get homeLearningPathStart =>
      _pick(en: 'Start your path', sr: 'Započni svoj put');
  String get homeLearningPathContinue =>
      _pick(en: 'Continue where you left off', sr: 'Nastavi gde si stao');
  String get homeLearningPathBuild => _pick(
    en: 'Build skills step by step',
    sr: 'Gradi veštine korak po korak',
  );

  String hello(String name) => _pick(en: 'Hi, $name', sr: 'Zdravo, $name');
  String get fallbackStudent => _pick(en: 'student', sr: 'učenik');
  String get fallbackPlayer => _pick(en: 'player', sr: 'igrač');
  String get continueLearning =>
      _pick(en: 'Continue learning', sr: 'Nastavi učenje');
  String get readyForNewRound =>
      _pick(en: 'Ready for a new round', sr: 'Spremno za novu rundu');
  String unlockAtLevel(int value) =>
      _pick(en: 'Unlocks at level $value', sr: 'Otključava se na nivou $value');
  String get homeAccessibilityPreview =>
      _pick(en: 'Accessibility preview', sr: 'Prikaz pristupacnosti');
  String get arenaAccessibilityPreview => _pick(
    en: 'Arena accessibility preview',
    sr: 'Arena prikaz pristupacnosti',
  );
  String get homeArena => _pick(en: 'Home Arena', sr: 'Početna arena');
  String get leaderboardTitle => _pick(en: 'Leaderboard', sr: 'Rang lista');
  String get seeAll => _pick(en: 'All', sr: 'Sve');
  String myRankTop(int rank, int percentile) =>
      _pick(en: 'My rank: #$rank, Top $percentile%', sr: 'Moj rang: #$rank, Top $percentile%');
  String myRank(int rank) => _pick(en: 'My rank: #$rank', sr: 'Moj rang: #$rank');
  String topPercent(int percentile) =>
      _pick(en: 'Top $percentile%', sr: 'Top $percentile%');
  String get noData => _pick(en: 'No data', sr: 'Nema podataka');
  String get viewFullLeaderboard =>
      _pick(en: 'View full leaderboard', sr: 'Pogledaj celu rang listu');
  String get unlockedLabel => _pick(en: 'unlocked', sr: 'otključano');
  String progressPercent(int percent) =>
      _pick(en: '$percent% progress', sr: '$percent% napretka');
  String get learningProgressTitle =>
      _pick(en: 'Learning progress', sr: 'Napredak učenja');
  String get launchNextQuiz =>
      _pick(en: 'Launch next quiz', sr: 'Pokreni sledeći kviz');
  String get navHome => _pick(en: 'Home', sr: 'Početna');
  String get navQuiz => _pick(en: 'Quiz', sr: 'Kviz');
  String get navRank => _pick(en: 'Rank', sr: 'Rang');
  String get navProfile => _pick(en: 'Profile', sr: 'Profil');

  String questionLabel(int value) =>
      _pick(en: 'Question $value', sr: 'Pitanje $value');
  String get noQuestions =>
      _pick(en: 'No questions available.', sr: 'Nema dostupnih pitanja.');
  String get wrongKeepGoing =>
      _pick(en: 'Incorrect, keep going', sr: 'Netačno, idemo dalje');
  String get finishQuiz => _pick(en: 'Finish quiz', sr: 'Završi kviz');
  String get nextQuestion => _pick(en: 'Next question', sr: 'Sledeće pitanje');

  String correctXp(int xp) =>
      _pick(en: 'Correct! +$xp XP', sr: 'Tačno! +$xp XP');
  String get readyForQuiz => _pick(en: 'Ready for quiz', sr: 'Spremno za kviz');
  String get readyToPlay =>
      _pick(en: 'Ready to play', sr: 'Spremno za igranje');

  String get mathChallengeTitle =>
      _pick(en: 'Math challenge', sr: 'Matematički izazov');
  String get mathChallengeSubtitle =>
      _pick(en: 'Choose the best answer', sr: 'Izaberi najbolji odgovor');
  String comboLabel(int value) =>
      _pick(en: '${value}x combo', sr: '${value}x niz');
  String noHintBonus(int xp) =>
      _pick(en: 'No-hint bonus +$xp XP', sr: 'Bonus bez pomoći +$xp XP');
  String get masteryLabel => _pick(en: 'Mastery', sr: 'Savladanost');
  String masteryMilestone(int percent) => _pick(
    en: 'Mastery $percent% reached',
    sr: 'Savladanost $percent% dostignuta',
  );
  String masteryPercentLabel(int percent) =>
      _pick(en: '$percent% Mastery', sr: '$percent% savladanost');
  String get masteryMax =>
      _pick(en: 'Mastery complete', sr: 'Savladanost završena');
  String get tryAgain => _pick(en: 'Try again', sr: 'Pokušaj ponovo');

  String get qsTitle => _pick(en: 'Quiz Complete!', sr: 'Kviz završen!');
  String get quizQuickTitle => _pick(en: 'Quick Quiz', sr: 'Brzi kviz');
  String get quizQuestionLabel => _pick(en: 'Question', sr: 'Pitanje');
  String get quizXpProgress => _pick(en: 'XP progress', sr: 'XP napredak');
  String get quizNext => _pick(en: 'Next', sr: 'Sledeće');
  String get quizConfirm => _pick(en: 'Confirm', sr: 'Potvrdi');
  String qsSubtitle(int correct, int total) => _pick(
    en: 'You got $correct out of $total correct.',
    sr: 'Tačno: $correct od $total.',
  );
  String get qsErrorNoStats =>
      _pick(en: 'No stats available.', sr: 'Nema statistike.');
  String get qsCorrect => _pick(en: 'Correct', sr: 'Tačno');
  String get qsTotal => _pick(en: 'Total', sr: 'Ukupno');
  String get qsXp => _pick(en: 'XP', sr: 'XP');
  String get qsRetry => _pick(en: 'Retry', sr: 'Pokušaj ponovo');
  String get qsStreak => _pick(en: 'Streak', sr: 'Niz');
  String get qsAccuracy => _pick(en: 'Accuracy', sr: 'Tačnost');
  String get qsMastery => _pick(en: 'Mastery', sr: 'Savladanost');
  String get qsPlayAgain => _pick(en: 'Play Again', sr: 'Igraj ponovo');
  String get qsBackHome => _pick(en: 'Back to Home', sr: 'Nazad na početnu');
  String get qsReviewTitle =>
      _pick(en: 'Questions to Review', sr: 'Pitanja za ponavljanje');
  String get qsMore => _pick(en: 'more', sr: 'više');

  String get smallHint =>
      _pick(en: 'Small hint (-1 XP)', sr: 'Mala pomoć (-1 XP)');
  String get mediumHint =>
      _pick(en: 'Medium hint (-3 XP)', sr: 'Srednja pomoć (-3 XP)');
  String get fullHint =>
      _pick(en: 'Full hint (-5 XP)', sr: 'Cela pomoć (-5 XP)');
  String get noHintAvailable =>
      _pick(en: 'No hint available', sr: 'Pomoć nije dostupna');

  String get formulaHintTitle => _pick(en: 'Formula hint', sr: 'Formula pomoć');
  String get formulaHintSubtitle =>
      _pick(en: 'Use this pattern', sr: 'Iskoristi šablon');
  String formulaStepCounter(int current, int total) =>
      _pick(en: 'Step $current of $total', sr: 'Korak $current od $total');
  String get showNextStep =>
      _pick(en: 'Show next step', sr: 'Prikaži sledeći korak');
  String get showAllSteps =>
      _pick(en: 'Show all steps', sr: 'Prikaži sve korake');
  String get formulaBonusTip => _pick(
    en: 'Tip: solve next without hints to keep combo.',
    sr: 'Tip: sledeći zadatak bez pomoći čuva niz.',
  );

  String get sectionProfile => _pick(en: 'Profile', sr: 'Profil');
  String get profileMenu => _pick(en: 'Menu', sr: 'Meni');
  String get sectionSettings => _pick(en: 'Settings', sr: 'Podešavanja');
  String get sectionThemeAndMotion =>
      _pick(en: 'Theme and motion', sr: 'Tema i kretanje');
  String get userSearch =>
      _pick(en: 'User search', sr: 'Pretraga korisnika');
  String get editProfile => _pick(en: 'Edit profile', sr: 'Izmeni profil');
  String get customizeAvatar =>
      _pick(en: 'Customize avatar', sr: 'Prilagodi avatar');
  String get logout => _pick(en: 'Logout', sr: 'Odjava');
  String get profileCardSubtitle =>
      _pick(en: 'Manage your account info', sr: 'Uredi informacije o nalogu');
  String get cosmeticShowcase =>
      _pick(en: 'Cosmetic showcase', sr: 'Prikaz kozmetike');
  String get playerIdentity =>
      _pick(en: 'Player identity', sr: 'Identitet igrača');
  String get profileAccessibilityPreview => _pick(
    en: 'Profile: accessibility preview',
    sr: 'Profil: pregled pristupačnosti',
  );
  String get defaultUser => _pick(en: 'User', sr: 'Korisnik');
  String get quickOptions => _pick(en: 'Quick options', sr: 'Brze opcije');
  String get myFeedback => _pick(en: 'My feedback', sr: 'Moj feedback');
  String get feedbackHistorySubtitle => _pick(
    en: 'Overview of submitted UX/UI feedback',
    sr: 'Pregled poslatih UX/UI povratnih informacija',
  );
  String get playerStats =>
      _pick(en: 'Player statistics', sr: 'Statistika igrača');
  String get rank => _pick(en: 'Rank', sr: 'Rang');
  String get noBadgesYet => _pick(
    en: 'No badges yet. Play more quizzes!',
    sr: 'Još uvek nema bedževa. Odigraj još kvizova!',
  );
  String get editProfileDialogTitle =>
      _pick(en: 'Edit profile', sr: 'Izmena profila');
  String get displayName =>
      _pick(en: 'Display name', sr: 'Prikazano ime');
  String get enterNewDisplayName =>
      _pick(en: 'Enter new display name', sr: 'Unesi novo prikazano ime');
  String get emailLabel => _pick(en: 'Email', sr: 'Imejl');
  String get enterNewEmail =>
      _pick(en: 'Enter new email', sr: 'Unesi novi imejl');
  String get cancel => _pick(en: 'Cancel', sr: 'Otkaži');
  String get save => _pick(en: 'Save', sr: 'Sačuvaj');
  String get profileUpdatedSuccess => _pick(
    en: 'Profile updated successfully!',
    sr: 'Profil je uspešno ažuriran!',
  );
  String profileUpdateFailedWithError(String error) => _pick(
    en: 'Profile update failed: $error',
    sr: 'Ažuriranje profila nije uspelo: $error',
  );
  String get chaseRace => _pick(en: 'Chase Race', sr: 'Trka potere');
  String get firstToUnlock => _pick(
    en: 'First to unlock! 🏆',
    sr: 'Prvi do otključavanja! 🏆',
  );
  String raceRank(int rank, int total) => _pick(
    en: 'Race rank: #$rank of $total',
    sr: 'Rang trke: #$rank od $total',
  );
  String get viewRace => _pick(en: 'View race', sr: 'Prikaži trku');
  String get equippedCosmetics =>
      _pick(en: 'Equipped cosmetics', sr: 'Opremljena kozmetika');
  String get defaultAvatar =>
      _pick(en: 'Default avatar', sr: 'Podrazumevani avatar');
  String get unlockCosmeticsHint => _pick(
    en: 'Unlock and equip frames, trails, and gear to show off here.',
    sr: 'Otključaj i opremi okvire, tragove i opremu da se prikažu ovde.',
  );
  String get recentUnlocks =>
      _pick(en: 'Recent unlocks', sr: 'Nedavna otključavanja');
  String get noCosmeticUnlocksYet => _pick(
    en: 'No cosmetic unlocks yet. Daily Run chests can change that.',
    sr: 'Još nema otključane kozmetike. Kovčezi Dnevnog izazova to mogu promeniti.',
  );
  String levelWithValue(int value) =>
      _pick(en: 'Level $value', sr: 'Nivo $value');
  String get sectionQuizExperience =>
      _pick(en: 'Quiz experience', sr: 'Kviz iskustvo');
  String get hintsToggleTitle => _pick(en: 'Hints', sr: 'Pomoći');
  String get hintsToggleSubtitle =>
      _pick(en: 'Enable hints during quiz', sr: 'Uključi pomoći tokom kviza');
  String get formulaToggleSubtitle =>
      _pick(en: 'Show formula pattern hints', sr: 'Prikaži formula pomoći');
  String get clueToggleTitle => _pick(en: 'Clue hints', sr: 'Hint tragovi');
  String get clueToggleSubtitle =>
      _pick(en: 'Enable clue-based hints', sr: 'Uključi hintove sa tragovima');
  String get eliminateToggleTitle =>
      _pick(en: 'Eliminate option', sr: 'Uklanjanje opcije');
  String get eliminateToggleSubtitle =>
      _pick(en: 'Hide one wrong answer', sr: 'Sakrij jedan netačan odgovor');
  String get sectionNotifications =>
      _pick(en: 'Notifications', sr: 'Obaveštenja');
  String get dailyReminderTitle =>
      _pick(en: 'Daily reminder', sr: 'Dnevni podsetnik');
  String get dailyReminderSubtitle =>
      _pick(en: 'Get a reminder every day', sr: 'Dobijaj podsetnik svaki dan');
  String get allowNotificationsMessage => _pick(
    en: 'Allow notifications in browser settings.',
    sr: 'Dozvoli obaveštenja u podešavanjima pregledača.',
  );
  String get reminderTime => _pick(en: 'Reminder time', sr: 'Vreme podsetnika');
  String get reminderSavedButNoPermission => _pick(
    en: 'Time saved, but notification permission is missing.',
    sr: 'Vreme sačuvano, ali nedostaje dozvola za obaveštenja.',
  );
  String get sectionThemeAndApp =>
      _pick(en: 'Theme and app', sr: 'Tema i aplikacija');
  String get advancedThemeTitle =>
      _pick(en: 'Advanced themes', sr: 'Napredne teme');
  String get advancedThemeSubtitle => _pick(
    en: 'Explore more visual styles',
    sr: 'Istrazi vise vizuelnih stilova',
  );
  String get sectionAudioHaptics =>
      _pick(en: 'Audio and haptics', sr: 'Zvuk i vibracija');
  String get soundEffectsTitle =>
      _pick(en: 'Sound effects', sr: 'Zvucni efekti');
  String get soundEffectsSubtitle =>
      _pick(en: 'Play sounds for actions', sr: 'Pusti zvuk za akcije');
  String get vibrationTitle => _pick(en: 'Vibration', sr: 'Vibracija');
  String get vibrationSubtitle =>
      _pick(en: 'Use haptic feedback', sr: 'Koristi vibracioni odziv');
  String get dailyTip => _pick(
    en: 'Tip: enable reminders to build a daily habit.',
    sr: 'Tip: uključi podsetnike za dnevnu rutinu.',
  );
  String get settingsQuest =>
      _pick(en: 'Setup Quest', sr: 'Misija podešavanja');
  String levelMissionProgress(int level, int done, int total) => _pick(
    en: 'Level $level setup progress: $done/$total',
    sr: 'Nivo $level napredak podešavanja: $done/$total',
  );
  String get profileSetupQuest =>
      _pick(en: 'Set up your profile', sr: 'Podesi profil');
  String get reminderDecisionQuest =>
      _pick(en: 'Choose reminder preference', sr: 'Izaberi podsetnik opciju');
  String get themeChoiceQuest => _pick(en: 'Pick a theme', sr: 'Izaberi temu');
  String get hintsPrefQuest =>
      _pick(en: 'Set hint preferences', sr: 'Podesi preference pomoći');
  String get soundVibrationQuest =>
      _pick(en: 'Set sound and vibration', sr: 'Podesi zvuk i vibraciju');
  String get languageLabel => _pick(en: 'Language', sr: 'Jezik');
  String get darkLightMode =>
      _pick(en: 'Dark / Light mode', sr: 'Tamni / Svetli režim');
  String get light => _pick(en: 'Light', sr: 'Svetlo');
  String get dark => _pick(en: 'Dark', sr: 'Tamno');
  String get quickLightHint => _pick(
    en: 'Quick switch between light and dark presets.',
    sr: 'Brzo prebacivanje između svetlih i tamnih tema.',
  );
  String get visualTheme => _pick(en: 'Visual theme', sr: 'Vizuelna tema');

  String get networkError =>
      _pick(en: 'Network error', sr: 'Došlo je do greške u mreži.');

  String get obWelcomeTitle => _pick(en: 'Welcome!', sr: 'Dobrodošli!');
  String get obWelcomeSubtitle => _pick(
    en: "Let's level up your math skills",
    sr: 'Poboljšaćemo tvoje matematičke veštine',
  );
  String get obLanguageTitle =>
      _pick(en: 'Choose language', sr: 'Izaberi jezik');
  String get obLanguageSubtitle =>
      _pick(en: 'Pick the interface language', sr: 'Izaberi jezik aplikacije');
  String get obDifficultyTitle => _pick(en: 'Difficulty', sr: 'Težina');
  String get obDifficultySubtitle =>
      _pick(en: 'Choose difficulty', sr: 'Izaberi težinu');
  String get obEasy => _pick(en: 'Easy', sr: 'Lako');
  String get obNormal => _pick(en: 'Normal', sr: 'Normalno');
  String get obHard => _pick(en: 'Hard', sr: 'Teško');
  String get obDailyTitle =>
      _pick(en: 'Daily Review', sr: 'Dnevno ponavljanje');
  String get obDailySubtitle =>
      _pick(en: 'Enable spaced repetition', sr: 'Uključi ponavljanje');
  String get obEnableReminder =>
      _pick(en: 'Enable daily reminder', sr: 'Uključi dnevni podsetnik');
  String get obReminderTimeDefault => _pick(en: '18:00', sr: '18:00');
  String get obContinue => _pick(en: 'Continue', sr: 'Nastavi');
  String get obStartLearning =>
      _pick(en: 'Start Learning', sr: 'Počni da učiš');
}

extension AppI18nContextX on BuildContext {
  // Non-reactive lookup: safe for callbacks and one-off reads.
  AppI18n get t {
    final language = Provider.of<SettingsProvider>(
      this,
      listen: false,
    ).language;
    return AppI18n(language);
  }

  // Reactive lookup: use inside build methods when UI must rebuild on language change.
  AppI18n get tw {
    final language = watch<SettingsProvider>().language;
    return AppI18n(language);
  }
}
