/* Public Firebase configuration only. Do not add service-account, APNs, or
 * user-session credentials to this worker. */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBOIoD-Jj4Wbro5P-Af7PDkx0LOg-8OHOc',
  authDomain: 'shengyu-im-fcm.firebaseapp.com',
  projectId: 'shengyu-im-fcm',
  storageBucket: 'shengyu-im-fcm.firebasestorage.app',
  messagingSenderId: '937731218980',
  appId: '1:937731218980:web:05917270bad37d6e2a42b1',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const data = payload.data || {};
  const title = '钰信';
  const body = data.kind === 'call_invite' ? '来电提醒' : '你收到一条新消息';
  self.registration.showNotification(title, {
    body,
    tag: data.eventId || 'im-notification',
    data: {
      eventId: data.eventId || '',
      chatId: data.chatId || '',
      kind: data.kind || '',
    },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = new URL('/', self.location.origin);
  const data = event.notification.data || {};
  if (data.eventId) url.searchParams.set('fcmEventId', data.eventId);
  if (data.chatId) url.searchParams.set('chatId', data.chatId);
  event.waitUntil(
    clients.matchAll({type: 'window', includeUncontrolled: true}).then((windows) => {
      const existing = windows.find((client) => client.url.startsWith(self.location.origin));
      return existing ? existing.focus() : clients.openWindow(url.toString());
    }),
  );
});
