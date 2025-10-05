importScripts("https://www.gstatic.com/firebasejs/9.6.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAPWdZ8dgaC5HjcGapRoMJwOxBmmz50d-4",
  authDomain: "cipher-7791c.firebaseapp.com",
  databaseURL: "https://cipher-7791c-default-rtdb.firebaseio.com",
  projectId: "cipher-7791c",
  storageBucket: "cipher-7791c.firebasestorage.app",
  messagingSenderId: "720039098644",
  appId: "1:720039098644:web:c6ffce28a65aedb546ea01",
  measurementId: "G-YOUR_MEASUREMENT_ID"
});

const messaging = firebase.messaging();