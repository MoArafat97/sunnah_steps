import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { Habit, Bundle } from '../models';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Sample habits data converted from the Flutter sample_habits.dart
 */
const sampleHabits: Omit<Habit, 'createdAt'>[] = [
  {
    id: 'h21',
    title: 'Use Miswak before every prayer',
    hadithArabic: 'المسواك مطهرة للفم مرضاة للرب',
    hadithEnglish: '"The Miswak is a means of purifying the mouth and is pleasing to the Lord." (An-Nasa\'i, Sahih). And "If I had not found it hard for my followers or the people, I would have ordered them to use the Miswak for every prayer." (Bukhari)',
    benefits: 'Purifies the mouth, pleases Allah, earns extra reward for prayer.',
    tags: ['miswak', 'prayer', 'salah', 'oral hygiene', 'purification', 'sunnah', 'wudu'],
    category: 'occasional',
    priority: 8,
    contextTags: ['worship', 'prayer', 'religious']
  },
  {
    id: 'h22',
    title: 'Recite Du\'a when leaving home: "Bismillāhi tawakkaltu \'alā Allāh"',
    hadithArabic: 'بِسْمِ اللَّهِ تَوَكَّلْتُ عَلَى اللَّهِ، لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    hadithEnglish: '"In the name of Allah, I place my trust in Allah, there is no might or power except with Allah." (Abu Dawood, Tirmidhi - Sahih)',
    benefits: 'Seeks Allah\'s protection and guidance when outside, angels are appointed to protect you.',
    tags: ['dua', 'supplication', 'leaving home', 'protection', 'trust in Allah', 'daily', 'dhikr'],
    category: 'daily',
    priority: 7,
    contextTags: ['travel', 'protection']
  },
  {
    id: 'h26',
    title: 'Make ablution (Wudu) before going to bed',
    hadithArabic: 'الوضوء للنوم',
    hadithEnglish: 'The Prophet ﷺ said: "When you go to bed, perform ablution as you would for prayer..." (Bukhari, Muslim)',
    benefits: 'Sleep in a state of purity, angels pray for you.',
    tags: ['wudu', 'ablution', 'sleep', 'purity', 'sunnah', 'night', 'prayer'],
    category: 'occasional',
    priority: 6,
    contextTags: ['sleep', 'purity']
  },
  {
    id: 'h27',
    title: 'Recite Ayat al-Kursi after every obligatory prayer',
    hadithArabic: 'آيَةُ الْكُرْسِيِّ',
    hadithEnglish: 'The Prophet ﷺ said: "Whoever recites Ayat al-Kursi immediately after each prescribed prayer, there will be nothing standing between him and his entering Paradise except death." (An-Nasa\'i, Sahih)',
    benefits: 'Protection from Shaytan, a means to enter Paradise.',
    tags: ['ayatul kursi', 'quran', 'prayer', 'salah', 'dhikr', 'protection', 'paradise', 'daily'],
    category: 'daily',
    priority: 9,
    contextTags: ['worship', 'prayer']
  },
  {
    id: 'h30',
    title: 'Greet people with "As-salāmu \'alaykum"',
    hadithArabic: 'السَّلَامُ عَلَيْكُمْ',
    hadithEnglish: 'The Prophet ﷺ said: "You will not enter Paradise until you believe, and you will not believe until you love one another. Shall I not tell you about something which, if you do it, you will love one another? Spread Salam among yourselves." (Muslim)',
    benefits: 'Spreads peace, love, and brotherhood; earns reward.',
    tags: ['salam', 'greeting', 'community', 'etiquette', 'peace', 'brotherhood', 'daily'],
    category: 'daily',
    priority: 8,
    contextTags: ['social', 'community']
  },
  {
    id: 'h31',
    title: 'Shake hands when greeting',
    hadithArabic: 'المُصَافَحَةُ',
    hadithEnglish: 'The Prophet ﷺ said: "When two Muslims meet and shake hands, their sins are forgiven before they part." (Abu Dawood, Tirmidhi - Hasan)',
    benefits: 'Forgiveness of sins, strengthens bonds of brotherhood.',
    tags: ['handshake', 'greeting', 'community', 'etiquette', 'forgiveness', 'brotherhood'],
    category: 'occasional',
    priority: 7,
    contextTags: ['social', 'community']
  },
  {
    id: 'h32',
    title: 'Smile at others',
    hadithArabic: 'تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ',
    hadithEnglish: '"Your smiling in the face of your brother is charity (Sadaqah)." (Tirmidhi - Hasan)',
    benefits: 'An easy act of charity, spreads positivity and kindness.',
    tags: ['smile', 'charity', 'sadaqah', 'kindness', 'community', 'etiquette', 'daily'],
    category: 'daily',
    priority: 6,
    contextTags: ['social', 'charity']
  },
  {
    id: 'h33',
    title: 'Remove harmful objects from the road',
    hadithArabic: 'إِمَاطَةُ الْأَذَى عَنِ الطَّرِيقِ صَدَقَةٌ',
    hadithEnglish: '"Removing a harmful thing from the path is charity (Sadaqah)." (Bukhari, Muslim)',
    benefits: 'An act of charity, ensures safety for others, part of faith.',
    tags: ['charity', 'sadaqah', 'community', 'safety', 'environment', 'faith'],
    category: 'occasional',
    priority: 5,
    contextTags: ['charity', 'community']
  },
  {
    id: 'h34',
    title: 'Guide someone who is lost',
    hadithArabic: 'إِرْشَادُكَ الرَّجُلَ فِي أَرْضِ الضَّلَالِ لَكَ صَدَقَةٌ',
    hadithEnglish: '"Guiding a person in a land where he is lost is charity for you." (Tirmidhi - Hasan, part of a longer hadith)',
    benefits: 'An act of charity, helps fellow humans, earns reward.',
    tags: ['charity', 'sadaqah', 'helping others', 'guidance', 'community', 'kindness'],
    category: 'occasional',
    priority: 6,
    contextTags: ['charity', 'helping']
  },
  {
    id: 'h35',
    title: 'Feed the hungry',
    hadithArabic: 'أَطْعِمُوا الْجَائِعَ',
    hadithEnglish: 'The Prophet ﷺ said: "Feed the hungry, visit the sick, and free the captive." (Bukhari)',
    benefits: 'Great act of charity, alleviates suffering, earns immense reward.',
    tags: ['charity', 'sadaqah', 'feeding', 'hungry', 'community', 'kindness', 'social welfare'],
    category: 'occasional',
    priority: 8,
    contextTags: ['charity', 'helping']
  },
  {
    id: 'h39',
    title: 'Speak kindly or remain silent',
    hadithArabic: 'الْكَلِمَةُ الطَّيِّبَةُ صَدَقَةٌ',
    hadithEnglish: '"A good word is charity (Sadaqah)." (Bukhari, Muslim). And "Whoever believes in Allah and the Last Day, let him speak good or remain silent." (Bukhari, Muslim)',
    benefits: 'Prevents harm, earns reward, maintains good relations.',
    tags: ['speech', 'kindness', 'charity', 'sadaqah', 'etiquette', 'akhlaq', 'daily'],
    category: 'daily',
    priority: 7,
    contextTags: ['social', 'communication']
  },
  {
    id: 'h42',
    title: 'Enter the Masjid with the right foot',
    hadithArabic: 'دُخُولُ الْمَسْجِدِ بِالْيُمْنَى',
    hadithEnglish: 'The Prophet ﷺ used to prefer to start with the right side in all his affairs: in wearing shoes, combing hair, and in purification. (Bukhari, Muslim) This extends to entering noble places.',
    benefits: 'Follows Sunnah, an act of respect for the Masjid.',
    tags: ['masjid', 'mosque', 'etiquette', 'right foot', 'sunnah', 'prayer'],
    category: 'occasional',
    priority: 8,
    contextTags: ['worship', 'prayer', 'religious']
  },
  {
    id: 'h44',
    title: 'Pray two Rak\'ahs of Tahiyyat al-Masjid upon entering',
    hadithArabic: 'رَكْعَتَا تَحِيَّةِ الْمَسْجِدِ',
    hadithEnglish: 'The Prophet ﷺ said: "If any one of you enters a mosque, he should pray two Rak\'ahs before sitting." (Bukhari, Muslim)',
    benefits: 'Greeting the mosque, earns reward, an act of worship.',
    tags: ['tahiyyatul masjid', 'prayer', 'salah', 'nafl', 'masjid', 'mosque', 'worship'],
    category: 'occasional',
    priority: 9,
    contextTags: ['worship', 'prayer', 'religious']
  },
  {
    id: 'h49',
    title: 'Eat with the right hand',
    hadithArabic: 'الأَكْلُ بِالْيَدِ الْيُمْنَى',
    hadithEnglish: 'The Prophet ﷺ said to Umar ibn Abi Salama: "O boy, mention the Name of Allah, and eat with your right hand, and eat of the dish what is nearer to you." (Bukhari, Muslim)',
    benefits: 'Follows Sunnah, distinguishes from Shaytan\'s way.',
    tags: ['eating', 'food', 'right hand', 'etiquette', 'sunnah', 'daily', 'bismillah'],
    category: 'daily',
    priority: 7,
    contextTags: ['food', 'eating', 'dining', 'meal']
  },
  {
    id: 'h50',
    title: 'Eat moderately (likened to "three breaths/portions")',
    hadithArabic: 'الأَكْلُ فِي ثَلَاثِ أَنْفَاسٍ',
    hadithEnglish: 'The Prophet ﷺ said: "A human being fills no worse vessel than his stomach. It is sufficient for a human being to eat a few mouthfuls to keep his spine straight. But if he must (fill it), then one third for his food, one third for his drink, and one third for his breath." (Tirmidhi - Sahih)',
    benefits: 'Promotes health, prevents overeating, aids digestion and worship.',
    tags: ['eating', 'food', 'moderation', 'health', 'sunnah', 'stomach', 'daily'],
    category: 'daily',
    priority: 6,
    contextTags: ['food', 'health']
  },
  {
    id: 'h51',
    title: 'Lick fingers after eating',
    hadithArabic: 'لَعْقُ الأَصَابِعِ',
    hadithEnglish: 'The Prophet ﷺ used to lick his three fingers after finishing meals. (Muslim)',
    benefits: 'Ensures no food (blessing) is wasted, follows Sunnah.',
    tags: ['eating', 'food', 'etiquette', 'sunnah', 'blessing', 'barakah', 'daily'],
    category: 'daily',
    priority: 5,
    contextTags: ['food', 'eating']
  },
  {
    id: 'h52',
    title: 'Sit while eating and drinking',
    hadithArabic: 'الْجُلُوسُ لِلأَكْلِ وَالشُّرْبِ',
    hadithEnglish: 'Anas (RA) reported that the Prophet ﷺ forbade drinking while standing. Qatadah said, "We asked Anas about eating (while standing)." He said, "That is worse." (Muslim, Tirmidhi)',
    benefits: 'Follows Sunnah, better for digestion and mindfulness.',
    tags: ['eating', 'drinking', 'food', 'etiquette', 'sunnah', 'health', 'daily'],
    category: 'daily',
    priority: 6,
    contextTags: ['food', 'health']
  },
  {
    id: 'h60',
    title: 'Say "Lā ḥawla wa lā quwwata illā billāh" frequently',
    hadithArabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    hadithEnglish: 'The Prophet ﷺ said: "Shall I not tell you of a word which is one of the treasures of Paradise?" I said: "Yes, O Messenger of Allah." He said: "Lā ḥawla wa lā quwwata illā billāh." (Bukhari, Muslim)',
    benefits: 'A treasure of Paradise, expresses reliance on Allah, source of strength.',
    tags: ['dhikr', 'dua', 'hawqala', 'paradise', 'strength', 'reliance on Allah', 'daily'],
    category: 'daily',
    priority: 8,
    contextTags: ['dhikr', 'remembrance']
  },
  {
    id: 'h61',
    title: 'Say "Subḥānallāh wa bi-ḥamdihī" 100 times daily',
    hadithArabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    hadithEnglish: 'The Prophet ﷺ said: "Whoever says \'Subḥānallāhi wa biḥamdihī\' one hundred times a day, his sins will be forgiven even if they are like the foam of the sea." (Bukhari, Muslim)',
    benefits: 'Forgiveness of sins, weighty on the scales.',
    tags: ['dhikr', 'tasbeeh', 'subhanallah', 'forgiveness', 'reward', 'daily'],
    category: 'daily',
    priority: 7,
    contextTags: ['dhikr', 'remembrance']
  },
  {
    id: 'h62',
    title: 'Say "Subḥānallāh, wal-ḥamdu lillāh, wa lā ilāha illallāh, wa-llāhu akbar"',
    hadithArabic: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
    hadithEnglish: 'The Prophet ﷺ said: "The most beloved words to Allah are four: Subhanallah (Glory be to Allah), Alhamdulillah (Praise be to Allah), La ilaha illallah (There is no god but Allah), and Allahu Akbar (Allah is the Greatest)." (Muslim)',
    benefits: 'Most beloved words to Allah, fill the scales, act as charity.',
    tags: ['dhikr', 'tasbeeh', 'tahmeed', 'tahleel', 'takbeer', 'reward', 'daily'],
    category: 'daily',
    priority: 8,
    contextTags: ['dhikr', 'remembrance']
  },
  {
    id: 'h63',
    title: 'Recite morning Adhkar (remembrances)',
    hadithArabic: 'أَذْكَارُ الصَّبَاحِ',
    hadithEnglish: 'Various authentic supplications are prescribed for the morning (after Fajr until sunrise). Example: "We have reached the morning and at this very time all sovereignty belongs to Allah, Lord of the worlds..."',
    benefits: 'Protection throughout the day, peace of mind, closeness to Allah.',
    tags: ['adhkar', 'dhikr', 'morning', 'fajr', 'supplication', 'protection', 'daily'],
    category: 'daily',
    priority: 9,
    contextTags: ['dhikr', 'morning', 'protection']
  },
  {
    id: 'h67',
    title: 'Sit after Salah for Dhikr',
    hadithArabic: 'الذِّكْرُ بَعْدَ الصَّلَاةِ',
    hadithEnglish: 'The Prophet ﷺ used to make Istighfar three times and say "Allahumma Antas-Salam..." after the obligatory prayers. (Muslim) And other specific Adhkar.',
    benefits: 'Completes the prayer with remembrance, earns reward, forgiveness.',
    tags: ['dhikr', 'salah', 'prayer', 'adhkar', 'tasbeeh', 'istighfar', 'worship', 'daily'],
    category: 'daily',
    priority: 8,
    contextTags: ['worship', 'prayer', 'dhikr']
  },
  {
    id: 'h68',
    title: 'Pray Duha (forenoon) prayer (2 or more Rak\'ahs)',
    hadithArabic: 'صَلَاةُ الضُّحَى',
    hadithEnglish: 'The Prophet ﷺ said: "In the morning, charity is due on every joint of the body of any one of you... and two Rak\'ahs which one prays in the forenoon (Duha) will suffice for that." (Muslim)',
    benefits: 'Counts as charity for every joint, source of great blessing and reward.',
    tags: ['duha', 'ishraq', 'salah', 'prayer', 'nafl', 'charity', 'sunnah', 'daily'],
    category: 'daily',
    priority: 7,
    contextTags: ['worship', 'prayer']
  },
  {
    id: 'h78',
    title: 'Recite Surah al-Kahf on Fridays',
    hadithArabic: 'سُورَةُ الْكَهْفِ يَوْمَ الْجُمُعَةِ',
    hadithEnglish: 'The Prophet ﷺ said: "Whoever reads Surah al-Kahf on the day of Jumu\'ah (Friday), will have a light that will shine from him from one Friday to the next." (Al-Hakim, Al-Bayhaqi - Sahih)',
    benefits: 'Illumination and light for the week, protection from Dajjal (Antichrist).',
    tags: ['quran', 'surah kahf', 'jumuah', 'friday', 'light', 'protection', 'dajjal', 'weekly'],
    category: 'weekly',
    priority: 8,
    contextTags: ['worship', 'friday']
  },
  {
    id: 'h79',
    title: 'Send Salawat on Prophet ﷺ abundantly on Fridays',
    hadithArabic: 'أَكْثِرُوا الصَّلَاةَ عَلَيَّ يَوْمَ الْجُمُعَةِ',
    hadithEnglish: 'The Prophet ﷺ said: "Among the best of your days is Friday. So, invoke more Salawat upon me on it, for your Salawat are presented to me." (Abu Dawood - Sahih)',
    benefits: 'Salawat presented to the Prophet ﷺ, earns his intercession, great reward.',
    tags: ['salawat', 'durood', 'prophet muhammad', 'jumuah', 'friday', 'intercession', 'reward', 'weekly'],
    category: 'weekly',
    priority: 7,
    contextTags: ['worship', 'friday']
  },
  {
    id: 'h80',
    title: 'Wear best clothes for Friday prayer (Jumu\'ah)',
    hadithArabic: '',
    hadithEnglish: 'The Prophet ﷺ encouraged taking a Ghusl (bath), using Miswak, applying perfume (if available), and wearing one\'s best clothes for Jumu\'ah prayer. (Bukhari, Muslim - compiled from various narrations)',
    benefits: 'Shows respect for Jumu\'ah, follows Sunnah, pleasant for oneself and others.',
    tags: ['jumuah', 'friday', 'prayer', 'salah', 'clothing', 'etiquette', 'sunnah', 'hygiene', 'weekly'],
    category: 'weekly',
    priority: 6,
    contextTags: ['worship', 'friday']
  },
  {
    id: 'h84',
    title: 'Say "Alḥamdu lillāh" when things go well or for blessings received',
    hadithArabic: 'الْحَمْدُ لِلَّهِ',
    hadithEnglish: 'The Prophet ﷺ, when he saw something that pleased him, would say: "Alḥamdu lillāhil-ladhī bi-ni\'matihī tatimmus-ṣāliḥāt" (Praise is to Allah by Whose grace good deeds are completed). (Ibn Majah - Hasan)',
    benefits: 'Expresses gratitude to Allah for His blessings and favors.',
    tags: ['dhikr', 'tahmeed', 'alhamdulillah', 'gratitude', 'shukr', 'blessings', 'daily'],
    category: 'daily',
    priority: 6,
    contextTags: ['dhikr', 'gratitude']
  },
  {
    id: 'h88',
    title: 'Give charity secretly',
    hadithArabic: 'صَدَقَةُ السِّرِّ تُطْفِئُ غَضَبَ الرَّبِّ',
    hadithEnglish: 'The Prophet ﷺ mentioned among the seven shaded on a Day when there is no shade: "a man who gives charity and conceals it so that his left hand does not know what his right hand has given." (Bukhari, Muslim). "Secret charity extinguishes the Lord\'s anger." (Tabarani - Sahih)',
    benefits: 'Greater sincerity, protection from showing off, extinguishes Allah\'s anger.',
    tags: ['charity', 'sadaqah', 'secret', 'sincerity', 'ikhlas', 'reward', 'akhlaq'],
    category: 'occasional',
    priority: 8,
    contextTags: ['charity', 'sincerity']
  },
  {
    id: 'h41',
    title: 'Wear perfume (Attar) to the Masjid (for men)',
    hadithArabic: 'الطِّيبُ لِلْمَسْجِدِ',
    hadithEnglish: 'The Prophet ﷺ said: "Taking a bath on Friday is compulsory for every male who has attained the age of puberty, and (also) the cleaning of his teeth with Miswak, and the use of perfume if it is available." (Bukhari)',
    benefits: 'Pleasant for oneself and others, follows Sunnah, respect for Masjid.',
    tags: ['perfume', 'attar', 'masjid', 'mosque', 'jumuah', 'friday', 'hygiene', 'etiquette'],
    category: 'occasional',
    priority: 6,
    contextTags: ['worship', 'hygiene']
  }
];

/**
 * Sample bundles data
 */
const sampleBundles: Omit<Bundle, 'createdAt'>[] = [
  {
    id: 'bundle_morning',
    name: 'Morning Routine',
    description: 'Essential Sunnah practices to start your day with blessings',
    habitIds: ['h22', 'h63', 'h68'], // leaving home dua, morning adhkar, duha prayer
    displayOrder: 1
  },
  {
    id: 'bundle_prayer',
    name: 'Prayer Etiquette',
    description: 'Sunnah practices related to Salah and mosque etiquette',
    habitIds: ['h21', 'h42', 'h44', 'h67'], // miswak, enter mosque right foot, tahiyyat al-masjid, dhikr after salah
    displayOrder: 2
  },
  {
    id: 'bundle_sleep',
    name: 'Sleep & Night',
    description: 'Peaceful Sunnah practices for bedtime and night',
    habitIds: ['h23', 'h24', 'h25', 'h26'], // sleep duas, right side, hand position, wudu before sleep
    displayOrder: 3
  },
  {
    id: 'bundle_eating',
    name: 'Eating Etiquette',
    description: 'Blessed Sunnah practices for meals and food',
    habitIds: ['h49', 'h50', 'h51', 'h52'], // eat with right hand, moderation, lick fingers, sit while eating
    displayOrder: 4
  },
  {
    id: 'bundle_social',
    name: 'Social Interactions',
    description: 'Beautiful Sunnah for community and relationships',
    habitIds: ['h30', 'h31', 'h32', 'h39'], // greet with salam, handshake, smile, speak kindly
    displayOrder: 5
  },
  {
    id: 'bundle_charity',
    name: 'Acts of Charity',
    description: 'Simple ways to earn reward through helping others',
    habitIds: ['h33', 'h34', 'h35', 'h88'], // remove harmful objects, guide lost person, feed hungry, secret charity
    displayOrder: 6
  },
  {
    id: 'bundle_dhikr',
    name: 'Daily Remembrance',
    description: 'Essential dhikr and supplications for daily life',
    habitIds: ['h60', 'h61', 'h62', 'h84'], // hawqala, subhanallah 100x, four beloved words, alhamdulillah
    displayOrder: 7
  },
  {
    id: 'bundle_friday',
    name: 'Friday Specials',
    description: 'Special Sunnah practices for Jumu\'ah',
    habitIds: ['h78', 'h79', 'h80', 'h41'], // surah kahf, salawat on prophet, best clothes, perfume
    displayOrder: 8
  }
];

/**
 * Check if collection is empty or has minimal data
 */
async function isCollectionEmpty(collectionName: string): Promise<boolean> {
  const snapshot = await db.collection(collectionName).limit(1).get();
  return snapshot.empty;
}

/**
 * Seed habits collection
 */
async function seedHabits(): Promise<void> {
  console.log('Checking habits collection...');

  const isEmpty = await isCollectionEmpty('habits');
  if (!isEmpty) {
    console.log('Habits collection already has data. Skipping seed.');
    return;
  }

  console.log('Seeding habits collection...');
  const batch = db.batch();

  for (const habit of sampleHabits) {
    const docRef = db.collection('habits').doc(habit.id);
    batch.set(docRef, {
      ...habit,
      createdAt: admin.firestore.Timestamp.now()
    });
  }

  await batch.commit();
  console.log(`Seeded ${sampleHabits.length} habits successfully.`);
}

/**
 * Seed bundles collection
 */
async function seedBundles(): Promise<void> {
  console.log('Checking bundles collection...');

  const isEmpty = await isCollectionEmpty('bundles');
  if (!isEmpty) {
    console.log('Bundles collection already has data. Skipping seed.');
    return;
  }

  console.log('Seeding bundles collection...');
  const batch = db.batch();

  for (const bundle of sampleBundles) {
    const docRef = db.collection('bundles').doc(bundle.id);
    batch.set(docRef, {
      ...bundle,
      createdAt: admin.firestore.Timestamp.now()
    });
  }

  await batch.commit();
  console.log(`Seeded ${sampleBundles.length} bundles successfully.`);
}

/**
 * Main seed function
 */
export async function seedDatabase(): Promise<void> {
  try {
    console.log('Starting database seeding...');

    await seedHabits();
    await seedBundles();

    console.log('Database seeding completed successfully!');
  } catch (error) {
    console.error('Error seeding database:', error);
    throw error;
  }
}

/**
 * Cloud Function for seeding (can be called via HTTP)
 */
export const seedDatabaseFunction = functions
  .runWith({
    memory: '256MB',
    timeoutSeconds: 120
  })
  .https.onRequest(async (req, res) => {
  try {
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    // Check for development bypass
    const isDevelopment = process.env.NODE_ENV === 'development' ||
                         process.env.FUNCTIONS_EMULATOR === 'true' ||
                         req.headers['x-development-bypass'] === 'true';

    if (isDevelopment) {
      console.log('Development mode: Bypassing authentication for seeding');
      await seedDatabase();
      res.json({
        success: true,
        message: 'Database seeded successfully (development mode)',
        mode: 'development'
      });
      return;
    }

    // Firebase Auth token verification for production
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing or invalid authorization header. Please provide: Authorization: Bearer <firebase-id-token>'
      });
      return;
    }

    const token = authHeader.split('Bearer ')[1];

    if (!token) {
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Missing Firebase ID token'
      });
      return;
    }

    // Verify the Firebase ID token
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(token);
    } catch (authError) {
      console.error('Token verification failed:', authError);
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid or expired Firebase ID token'
      });
      return;
    }

    console.log(`Seed database request from authenticated user: ${decodedToken.uid} (${decodedToken.email})`);

    await seedDatabase();

    res.json({
      success: true,
      message: 'Database seeded successfully',
      user: {
        uid: decodedToken.uid,
        email: decodedToken.email
      }
    });
  } catch (error) {
    console.error('Seed function error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to seed database'
    });
  }
});

// For direct execution
if (require.main === module) {
  seedDatabase()
    .then(() => {
      console.log('Seed completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Seed failed:', error);
      process.exit(1);
    });
}
