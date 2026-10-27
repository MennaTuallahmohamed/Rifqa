// Rifqa Community V8 — independent Cloudflare Worker, NOT a replacement for
// your existing group-chat notification Worker.
// No secret keys or Firebase admin credentials should ever go into Flutter.
const textEncoder = new TextEncoder();
let cachedAccessToken;
let tokenExpiresAt = 0;

function output(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8',
      'cache-control': 'no-store', 'x-content-type-options': 'nosniff' },
  });
}
function bytesToBase64Url(bytes) {
  let result = '';
  for (const b of bytes) result += String.fromCharCode(b);
  return btoa(result).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function fromBase64Url(data) {
  const normalized = data.replace(/-/g, '+').replace(/_/g, '/');
  return Uint8Array.from(atob(normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=')),
    (character) => character.charCodeAt(0));
}
function decodeJwtSection(section) {
  return JSON.parse(new TextDecoder().decode(fromBase64Url(section)));
}

// Verify Firebase ID token signature against Google's published rotating keys.
async function verifyFirebaseIdToken(raw, projectId) {
  if (typeof raw !== 'string' || raw.length > 8192) throw new Error('invalid token');
  const sections = raw.split('.');
  if (sections.length !== 3) throw new Error('invalid token');
  const header = decodeJwtSection(sections[0]);
  const claims = decodeJwtSection(sections[1]);
  if (header.alg !== 'RS256' || !header.kid ||
      claims.aud !== projectId ||
      claims.iss !== `https://securetoken.google.com/${projectId}` ||
      !claims.sub || typeof claims.sub !== 'string' ||
      claims.sub.length > 128 ||
      !Number.isFinite(claims.exp) || claims.exp <= Date.now() / 1000 ||
      !Number.isFinite(claims.iat) || claims.iat > Date.now() / 1000 + 60) {
    throw new Error('invalid token claims');
  }
  const certResponse = await fetch(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  );
  if (!certResponse.ok) throw new Error('Google token keys unavailable');
  const certs = await certResponse.json();
  const jwk = certs.keys?.find((item) => item.kid === header.kid);
  if (!jwk) throw new Error('unknown token signature');
  const key = await crypto.subtle.importKey('jwk', jwk, {
    name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256',
  }, false, ['verify']);
  const verified = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key,
    fromBase64Url(sections[2]), textEncoder.encode(`${sections[0]}.${sections[1]}`));
  if (!verified) throw new Error('invalid token signature');
  return claims.sub;
}

async function getServerToken(env) {
  if (cachedAccessToken && Date.now() + 60_000 < tokenExpiresAt) {
    return cachedAccessToken;
  }
  const sa = JSON.parse(env.GOOGLE_SERVICE_ACCOUNT_JSON || '{}');
  if (!sa.client_email || !sa.private_key || sa.project_id !== env.FIREBASE_PROJECT_ID) {
    throw new Error('Service account secret is missing or for the wrong project');
  }
  const now = Math.floor(Date.now() / 1000);
  const header = bytesToBase64Url(textEncoder.encode(JSON.stringify({
    alg: 'RS256', typ: 'JWT',
  })));
  const payload = bytesToBase64Url(textEncoder.encode(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3500,
  })));
  const toSign = `${header}.${payload}`;
  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, '');
  const privateKey = await crypto.subtle.importKey('pkcs8',
    Uint8Array.from(atob(pem), (c) => c.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', privateKey,
    textEncoder.encode(toSign));
  const assertion = `${toSign}.${bytesToBase64Url(new Uint8Array(signature))}`;
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion,
    }),
  });
  if (!response.ok) throw new Error(`OAuth rejected: ${response.status}`);
  const result = await response.json();
  cachedAccessToken = result.access_token;
  tokenExpiresAt = Date.now() + Math.min(result.expires_in || 3000, 3500) * 1000;
  return cachedAccessToken;
}

function dbBase(project) {
  return `https://firestore.googleapis.com/v1/projects/${encodeURIComponent(project)}/databases/(default)/documents`;
}
async function getDocument(path, token) {
  const response = await fetch(path, {
    headers: { authorization: `Bearer ${token}` },
  });
  if (response.status === 404) return null;
  if (!response.ok) throw new Error(`Firestore read failed: ${response.status}`);
  return response.json();
}
function field(doc, name) {
  const raw = doc?.fields?.[name];
  return raw?.stringValue ?? raw?.timestampValue ?? raw?.booleanValue ?? '';
}
function copyPreview(value) {
  if (typeof value !== 'string') return '';
  return value.replace(/\s+/g, ' ').slice(0, 120);
}
function activityTitle(sender, kind) {
  const action = {
    comment: 'علّق على منشورك',
    reply: 'ردّ على تعليقك',
    post_like: 'أعجب بمنشورك',
    comment_like: 'أعجب بتعليقك',
    post_dislike: 'تفاعل مع منشورك',
    friend_request: 'أرسل لك طلب صداقة',
  }[kind];
  return action ? `${sender} ${action}` : `${sender} تفاعل في مجتمع رفقة`;
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST' || new URL(request.url).pathname !== '/community') {
      return output({ error: 'not found' }, 404);
    }
    if (!env.FIREBASE_PROJECT_ID || !env.GOOGLE_SERVICE_ACCOUNT_JSON) {
      return output({ error: 'server not configured' }, 503);
    }
    let senderUid;
    try {
      const match = /^Bearer (\S+)$/i.exec(request.headers.get('authorization') || '');
      if (!match) return output({ error: 'unauthorized' }, 401);
      senderUid = await verifyFirebaseIdToken(match[1], env.FIREBASE_PROJECT_ID);
    } catch (_) {
      return output({ error: 'unauthorized' }, 401);
    }
    let payload;
    try { payload = await request.json(); } catch (_) {
      return output({ error: 'invalid json' }, 400);
    }
    const recipientId = payload?.recipientId;
    const notificationId = payload?.notificationId;
    if (typeof recipientId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(recipientId) ||
        typeof notificationId !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(notificationId) ||
        senderUid === recipientId) {
      return output({ error: 'invalid target' }, 400);
    }
    try {
      const serverToken = await getServerToken(env);
      const base = dbBase(env.FIREBASE_PROJECT_ID);
      const path = `${base}/users/${recipientId}/community_notifications/${notificationId}`;
      const notification = await getDocument(path, serverToken);
      if (!notification || field(notification, 'senderId') !== senderUid ||
          field(notification, 'recipientId') !== recipientId) {
        return output({ error: 'not permitted' }, 403);
      }
      const createdAt = Date.parse(field(notification, 'createdAt'));
      if (!Number.isFinite(createdAt) || Math.abs(Date.now() - createdAt) > 10 * 60_000) {
        return output({ error: 'notification expired' }, 409);
      }
      const kind = field(notification, 'kind');
      if (!['comment', 'reply', 'post_like', 'post_dislike', 'comment_like',
            'friend_request'].includes(kind)) {
        return output({ error: 'invalid notification kind' }, 403);
      }
      // Deduplication ledger: Firestore create-only reservation. A user cannot
      // re-trigger old events by re-posting the same notificationId.
      const dispatchId = `${recipientId}_${notificationId}`;
      const claimResponse = await fetch(
        `${base}/community_push_dispatches/${dispatchId}?currentDocument.exists=false`, {
          method: 'PATCH',
          headers: { authorization: `Bearer ${serverToken}`,
            'content-type': 'application/json' },
          body: JSON.stringify({ fields: {
            senderId: { stringValue: senderUid },
            recipientId: { stringValue: recipientId },
            createdAt: { timestampValue: new Date().toISOString() },
          } }),
        });
      if (!claimResponse.ok) {
        const info = await claimResponse.json().catch(() => ({}));
        if (info.error?.status === 'FAILED_PRECONDITION' ||
            claimResponse.status === 409) {
          return output({ ok: true, duplicate: true });
        }
        throw new Error(`Firestore dispatch reservation failed: ${claimResponse.status}`);
      }
      const tokenResponse = await fetch(`${base}/users/${recipientId}/fcm_tokens?pageSize=25`, {
        headers: { authorization: `Bearer ${serverToken}` },
      });
      if (!tokenResponse.ok) throw new Error(`FCM token read failed: ${tokenResponse.status}`);
      const tokenDocs = (await tokenResponse.json()).documents || [];
      const senderName = copyPreview(field(notification, 'senderName')) || 'عضو رفقة';
      const body = copyPreview(field(notification, 'body')) || 'عندك تفاعل جديد في مجتمع رفقة';
      const postId = field(notification, 'postId');
      let sent = 0;
      for (const tokenDoc of tokenDocs) {
        const token = field(tokenDoc, 'token');
        if (typeof token !== 'string' || !token) continue;
        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`, {
            method: 'POST',
            headers: { authorization: `Bearer ${serverToken}`,
              'content-type': 'application/json' },
            body: JSON.stringify({ message: {
              token,
              notification: { title: activityTitle(senderName, kind), body },
              data: { type: 'community_activity', postId,
                notificationId, kind },
              android: { priority: 'HIGH', notification: {
                channel_id: 'rifqa_messages',
              } },
            } }),
          });
        if (fcmResponse.ok) sent++;
      }
      return output({ ok: true, sent });
    } catch (error) {
      // Do not leak auth tokens, FCM recipient tokens, or service account keys.
      console.error('Community push failed', String(error?.message || error));
      return output({ error: 'push delivery unavailable' }, 503);
    }
  },
};
