# Chiper - বাংলা ডকুমেন্টেশন

এই প্রজেক্টটি একটি ক্রস-প্ল্যাটফর্ম অ্যাপ্লিকেশন যা Flutter দিয়ে তৈরি করা হয়েছে। এই অ্যাপ্লিকেশনের মূল উদ্দেশ্য হলো ব্যবহারকারীদের দৈনন্দিন কাজ এবং নোট পরিচালনা করতে সাহায্য করা। এছাড়াও, এতে কিছু অতিরিক্ত টুলস রয়েছে যা ব্যবহারকারীদের জন্য সহায়ক হতে পারে।

## ফিচারসমূহ

- **calculator:** একটি সহজ এবং کاربردی ক্যালকুলেটর যা দৈনন্দিন গণনার জন্য ব্যবহার করা যেতে পারে।
- **Task Manager:** ব্যবহারকারীরা তাদের দৈনন্দিন কাজগুলো যোগ, সম্পাদনা এবং মুছে ফেলতে পারেন।
- **Notebook:** ব্যবহারকারীরা তাদের প্রয়োজনীয় নোটগুলো সংরক্ষণ করতে পারেন।
- **Hide Page:** একটি গোপন পেজ যা একটি নির্দিষ্ট গোপন কোড দিয়ে অ্যাক্সেস করা যায়।
- **Pc Controll:** এই ফিচারের মাধ্যমে ব্যবহারকারীরা তাদের পিসি শাটডাউন এবং ভলিউম নিয়ন্ত্রণ করতে পারেন।
- **Profile:** ব্যবহারকারীরা তাদের প্রোফাইল দেখতে এবং পরিচালনা করতে পারেন।
- **Theme:** অ্যাপ্লিকেশনটি লাইট এবং ডার্ক মোড সমর্থন করে।
- **Setting:** 


## ফাইল স্ট্রাকচার

এই প্রজেক্টের `lib` ফোল্ডারের মধ্যে থাকা ফাইলগুলোর একটি সংক্ষিপ্ত বিবরণ নিচে দেওয়া হলো:

- **`main.dart`:** এটি অ্যাপ্লিকেশনের মূল ফাইল। এখান থেকে অ্যাপ্লিকেশনটি শুরু হয়।
- **`auth_wrapper.dart`:** এই ফাইলটি ব্যবহারকারীর লগইন অবস্থা পরীক্ষা করে এবং সেই অনুযায়ী `WelcomePage` বা `UserHomePage`-এ নিয়ে যায়।
- **`auth/`:** এই ফোল্ডারে ব্যবহারকারীর লগইন এবং সাইন-আপ সম্পর্কিত ফাইলগুলো রয়েছে।
  - **`auth_screen.dart`:** লগইন এবং সাইন-আপ UI পরিচালনা করে।
  - **`log.dart`:** লগইন পেজের UI।
  - **`sign_up.dart`:** সাইন-আপ পেজের UI।
- **`calculator/`:** এই ফোল্ডারে ক্যালকুলেটর সম্পর্কিত ফাইলগুলো রয়েছে।
  - **`calculator_page.dart`:** ক্যালকুলেটরের মূল UI এবং কার্যকারিতা।
  - **`calculator_history_page.dart`:** ক্যালকুলেটরের গণনার ইতিহাস দেখায়।
- **`Hide/`:** এই ফোল্ডারে গোপন পেজ সম্পর্কিত ফাইল রয়েছে।
  - **`hide_page.dart`:** গোপন পেজের UI এবং কার্যকারিতা।
- **`memo/`:** এই ফোল্ডারে নোটবুক সম্পর্কিত ফাইলগুলো রয়েছে।
  - **`memo_home.dart`:** নোটগুলোর তালিকা দেখায়।
  - **`memo_editor.dart`:** নতুন নোট তৈরি বা সম্পাদনা করার জন্য।
  - **`memo_page.dart`:** একটি নির্দিষ্ট নোট দেখায়।
- **`Models/`:** এই ফোল্ডারে অ্যাপ্লিকেশনের ডেটা মডেলগুলো রয়েছে।
  - **`app_notification.dart`:** নোটিফিকেশন মডেল।
  - **`memo.dart`:** নোট মডেল।
  - **`task.dart`:** টাস্ক মডেল।
- **`notification/`:** এই ফোল্ডারে নোটিফিকেশন সম্পর্কিত ফাইলগুলো রয়েছে।
  - **`notification_page.dart`:** নোটিফিকেশনগুলো দেখায়।
  - **`notify.dart`:** নোটিফিকেশন সার্ভিস।
- **`pc_setting/`:** এই ফোল্ডারে পিসি সেটিংস সম্পর্কিত ফাইল রয়েছে।
  - **`pc_setting_page.dart`:** পিসি সেটিংস পেজের UI।
  - **`secret_code_change/`:** গোপন কোড পরিবর্তন করার জন্য।
- **`pc_tools/`:** এই ফোল্ডারে পিসি টুলস সম্পর্কিত ফাইল রয়েছে।
  - **`pc_tools.dart`:** পিসি টুলস পেজের UI।
  - **`shutdown_control.dart`:** পিসি শাটডাউন নিয়ন্ত্রণ করার জন্য।
- **`profile/`:** এই ফোল্ডারে ব্যবহারকারীর প্রোফাইল সম্পর্কিত ফাইল রয়েছে।
  - **`profile_page.dart`:** প্রোফাইল পেজের UI।
- **`Screens/`:** এই ফোল্ডারে অ্যাপ্লিকেশনের প্রধান স্ক্রিনগুলো রয়েছে।
  - **`home_page.dart`:** অ্যাপ্লিকেশনের হোমপেজ।
  - **`setting.dart`:** সেটিংস পেজ।
  - **`welcome_page.dart`:** অ্যাপ্লিকেশনের প্রথম স্ক্রিন।
- **`Services/`:** এই ফোল্ডারে অ্যাপ্লিকেশনের বিভিন্ন সার্ভিস রয়েছে।
  - **`auth_service.dart`:** Firebase Authentication সম্পর্কিত সার্ভিস।
  - **`firestore_service.dart`:** Firestore সম্পর্কিত সার্ভিস।
  - **`memo_service.dart`:** নোট সম্পর্কিত সার্ভিস।
  - **`secret_code_service.dart`:** গোপন কোড সম্পর্কিত সার্ভিস।
  - **`secret_page_tracker.dart`:** গোপন পেজ ট্র্যাক করার জন্য।
  - **`storage_notifier.dart`:** স্টোরেজ সম্পর্কিত নোটিഫায়ার।
  - **`theme_notifier.dart`:** থিম সম্পর্কিত নোটিഫায়ার।
- **`tasks/`:** এই ফোল্ডারে টাস্ক সম্পর্কিত ফাইলগুলো রয়েছে।
  - **`task_home_page.dart`:** টাস্কগুলোর তালিকা দেখায়।
  - **`task_edit_page.dart`:** নতুন টাস্ক তৈরি বা সম্পাদনা করার জন্য।
  - **`task_updater.dart`:** টাস্ক সিঙ্ক করার জন্য।
- **`uid_changer/`:** এই ফোল্ডারে UID পরিবর্তন করার জন্য ফাইল রয়েছে।
  - **`uid_change.dart`:** UID পরিবর্তন করার পেজের UI।

## কিভাবে চালাবেন

1.  এই রিপোজিটরিটি ক্লোন করুন।
2.  আপনার সিস্টেমে Flutter SDK ইনস্টল করা আছে কিনা তা নিশ্চিত করুন।
3.  প্রজেক্ট ডিরেক্টরিতে `flutter pub get` কমান্ডটি চালান।
4.  একটি এমুলেটর বা 실제 ডিভাইস কানেক্ট করে `flutter run` কমান্ডটি চালান。

## Issues and Bugs Fixes and Update All in the App

- fix: Applied consistent font style from Memo Edit Page title to Task Edit Page input field and Task Home Page displayed tasks.
- Applied consistent button text styling across Hide Page, Task Edit Page, and Secret Code Change Page. Also applied consistent header font style to PC Settings and Secret Code Change pages.
- Removed UID Changer option from Hide Page.
- Further reduced font size and ensured centering for 'no tasks' and 'no memos' messages.
- Task and calculator page updated and bugs fixed
- Update calculator Front style and Fix some issues
- Update Memo page issues and change the font styles
- Memo edit page save button postion fix
- Memo edit page color issue fix
- Update Profile page but not resolve issue
- fix: Fix google sign in error now working
- fix: Resolve multiple UI and auth issues
- Update README.md
- Initial commit
