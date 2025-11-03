import 'dotenv/config';
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import path from 'path';
import fs from 'fs';
import multer, { DiskStorageOptions } from 'multer';
import axios from 'axios';
import FormData from 'form-data';
import { fileURLToPath } from 'url';
import * as API from './api/api';
import { createPool } from 'mysql2/promise';

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Static serving for uploaded images
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
app.use('/uploads', express.static(uploadsDir));

// Multer setup for profile image uploads (hardened)
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const safeName = `${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname || '')}`;
    cb(null, safeName);
  }
} as DiskStorageOptions);

// Accept only common image types and limit file size to 5MB
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    // Allow a broader set of image MIME types (common camera formats)
    const allowed = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/gif',
      'image/heic',
      'image/heif',
      'image/bmp'
    ];
    const mt = (file.mimetype || '').toLowerCase();
    if (allowed.includes(mt)) return cb(null, true);
    // Some clients may not set mimetype reliably; also allow based on extension as fallback
    const ext = path.extname(file.originalname || '').toLowerCase();
    const allowedExt = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic', '.heif', '.bmp'];
    if (ext && allowedExt.includes(ext)) return cb(null, true);
    // Return a typed error to be handled by error middleware
    return cb(new Error('Invalid file type') as any, false);
  }
});

// Notifications endpoints
// GET /notifications?user_id=123  -> list notifications for a user
app.get('/notifications', async (req, res) => {
  try {
    // support both ?user_id and ?userid
    const raw = req.query.user_id ?? req.query.userid ?? req.query.userId;
    const userId = Number(raw);
    if (!Number.isFinite(userId) || userId <= 0) return res.status(400).json({ error: 'user_id required' });
    const notifs = await API.listNotifications(userId);
    res.json({ data: notifs });
  } catch (err: any) {
    console.error('GET /notifications error', err?.message ?? err);
    res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

// POST /notifications  body: { user_id, message }
app.post('/notifications', async (req, res) => {
  try {
    const body = req.body ?? {};
    const rawUser = body.user_id ?? body.userid ?? body.userId;
    const message = body.message ?? body.msg ?? body.text;
    const userId = Number(rawUser);
    if (!Number.isFinite(userId) || userId <= 0) return res.status(400).json({ error: 'user_id required' });
    if (!message || String(message).trim().length === 0) return res.status(400).json({ error: 'message required' });
    const created = await API.createNotification(userId, String(message));
    res.json({ success: true, notification_id: created.notification_id });
  } catch (err: any) {
    console.error('POST /notifications error', err?.message ?? err);
    res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

// POST /notifications/:id/read  -> mark notification as read
app.post('/notifications/:id/read', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: 'id invalid' });
    const ok = await API.markNotificationRead(id);
    if (!ok) return res.status(404).json({ error: 'Notification not found' });
    res.json({ success: true });
  } catch (err: any) {
    console.error('POST /notifications/:id/read error', err?.message ?? err);
    res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

function getModelBaseUrlFromEnv(): string {
  const raw = process.env.MODEL_BASE_URL ?? '';
  const base = typeof raw === 'string' && raw.trim().length > 0 ? raw.trim() : 'http://localhost:5000';
  return base.endsWith('/') ? base.slice(0, -1) : base;
}

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

// AUTH
app.post('/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body ?? {};
    if (!username || !password) {
      return res.status(400).json({ error: 'username and password required' });
    }
    const token = await API.issueAuthTokenForUsernamePassword(String(username), String(password));
    // Lookup DB user to include user_id (reliable)
    const dbUser = await API.getUserPublicByUsername(String(username));
    const user_id = dbUser?.user_id;

    // mark user online (non-blocking: await to ensure DB updated)
    if (typeof user_id === 'number') {
      try { await API.setUserOnline(user_id, true); } catch (e) { console.warn('API.setUserOnline failed', e); }
    }

    res.json({
      ...token,
      data: {
        ...token.data,
        userid: user_id,
        username: username
      }
    });
  } catch (error: any) {
    // Avoid leaking whether username exists
    const msg = error?.message === 'Invalid credentials' ? 'Invalid credentials' : (error?.message ?? 'Internal error');
    const code = msg === 'Invalid credentials' ? 401 : 500;
    res.status(code).json({ error: msg });
  }
});

app.post('/auth/register', async (req, res) => {
  try {
    const { username, password, email } = req.body ?? {};
    if (!username || !password || !email) {
      return res.status(400).json({ success: false, error: 'username, password, email required' });
    }
    const user = await API.createDbUser({ username, password, email });
    await API.syncDbUserToCometChat(user.user_id);
    await API.issueAuthTokenForUserId(user.user_id);
    // สำเร็จ
    res.status(200).json({ success: true, user_id: user.user_id }); // << ต้องมี user_id ตรงนี้
  } catch (error: any) {
    const msg = error?.message ?? 'Internal error';
    const code = msg === 'Username or email already exists' ? 409 : 400;
    res.status(code).json({ success: false, error: msg });
  }
});

// Change password: accepts username or email plus oldPassword, newPassword, confirmNewPassword
app.post('/auth/change-password', async (req, res) => {
  try {
    const { username, email, oldPassword, newPassword, confirmNewPassword } = req.body ?? {};
    if (!username || !email || !oldPassword || !newPassword || !confirmNewPassword) {
      return res.status(400).json({ success: false, error: 'username, email, oldPassword, newPassword, confirmNewPassword required' });
    }
    if (newPassword !== confirmNewPassword) {
      return res.status(400).json({ success: false, error: 'confirmNewPassword mismatch' });
    }
    const out = await API.changeUserPassword({ username, email, oldPassword, newPassword });
    res.json({ success: out.success });
  } catch (error: any) {
    const msg = error?.message ?? 'Internal error';
    const code = ['User not found','Invalid old password','username and email required','newPassword too short','oldPassword and newPassword required'].includes(msg) ? 400 : 500;
    res.status(code).json({ success: false, error: msg });
  }
});

app.post('/qr-charge', async (req, res) => {
  try {
    const amount = Number(req.body?.amount ?? 100000);
    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    // Expect user_id to credit wallet after success. Must be provided by client.
    const userId = Number(req.body?.user_id ?? req.query?.user_id ?? NaN);
    if (!Number.isFinite(userId)) {
      return res.status(400).json({ error: 'user_id required' });
    }

    // Create a pending transaction record (store amount as THB decimal)
    const tx = await API.createTopupTransaction(userId, amount, 'omise');

    // Build a returnUri that contains the transaction id so we can reconcile after Omise redirects
    const base = getPublicBaseUrlFromEnv();
    const returnUri = `${base}/complete_payment?transaction_id=${tx.transaction_id}`;

    const result = await API.createQRCharge({ amount, returnUri });
    // attempt to capture an Omise charge id from the result and save it to the transaction
    const chargeId = (result as any)?.chargeId ?? (result as any)?.charge_id ?? (result as any)?.id ?? null;
    if (chargeId) {
      try { await API.setTransactionExternalRef(tx.transaction_id, String(chargeId)); } catch (_) {}
    }
    // return authorizeUri, chargeId and transaction id to client
    res.json({ ...result, transaction_id: tx.transaction_id, external_ref: chargeId });
  } catch (error: any) {
    // เพิ่ม log ฝั่ง server
    console.error('POST /qr-charge error:', error?.message ?? error, error);
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Return page for Omise to redirect after payment attempt
app.get('/complete_payment', async (req, res) => {
  try {
    const transactionId = Number(req.query?.transaction_id ?? NaN);
    const chargeId = String(req.query?.chargeId ?? req.query?.charge_id ?? req.query?.id ?? '');
    if (!Number.isFinite(transactionId)) return res.status(400).send('<h3>Missing transaction_id</h3>');

    const tx = await API.getTransactionById(transactionId);
    if (!tx) return res.status(404).send('<h3>Transaction not found</h3>');

    if (!chargeId) {
      // If Omise did not provide charge id, show pending page and let client poll
      return res.send(`<h3>Payment processing</h3><p>Transaction: ${transactionId}</p>`);
    }

    // Retrieve charge from Omise
    try {
      const charge = await API.retrieveOmiseCharge(chargeId);
      // Omise charge.amount is in satang and charge.status can be 'successful' when paid
      const status = charge?.status;
      if (status === 'successful') {
        // Mark transaction completed if not already
        if (tx.status !== 'completed') {
          await API.markTransactionCompleted(transactionId);
          // Tx.amount in DB is THB decimal (we stored amount/100 earlier), credit wallet
          const creditAmount = Number(tx.amount ?? 0);
          if (creditAmount > 0) {
            await API.creditUserWallet(tx.user_id, creditAmount);
          }
        }
        return res.send(`<h3>Payment successful</h3><p>Amount: ${tx.amount} THB</p>`);
      }
      // else pending/failed
      return res.send(`<h3>Payment status: ${String(status)}</h3><p>Transaction: ${transactionId}</p>`);
    } catch (err: any) {
      console.error('Error retrieving Omise charge:', err?.message ?? err);
      return res.status(500).send('<h3>Error verifying payment</h3>');
    }
  } catch (error: any) {
    console.error('/complete_payment error', error);
    return res.status(500).send('<h3>Internal error</h3>');
  }
});

// Development helper: mark a pending topup transaction as completed and credit user's wallet
// NOTE: This endpoint intentionally allows immediate crediting (no payment provider verification).
// Use only in dev or when you intentionally want instant crediting.
app.post('/transaction/complete', async (req, res) => {
  try {
    const transactionId = Number(req.body?.transaction_id ?? req.query?.transaction_id ?? NaN);
    if (!Number.isFinite(transactionId)) return res.status(400).json({ error: 'transaction_id is required' });

    const tx = await API.getTransactionById(transactionId);
    if (!tx) return res.status(404).json({ error: 'Transaction not found' });

    // Only allow topup transactions to be completed via this helper
    if (tx.type !== 'topup') return res.status(400).json({ error: 'Only topup transactions can be completed this way' });

    if (tx.status === 'completed') {
      const profile = await API.getUserProfile(tx.user_id);
      return res.json({ success: true, message: 'already completed', profile });
    }

    // Mark completed and credit user's wallet
    await API.markTransactionCompleted(transactionId);
    // tx.amount is stored as decimal THB in the DB
    const amt = Number(tx.amount ?? 0);
    if (amt > 0) await API.creditUserWallet(tx.user_id, amt);

    const profile = await API.getUserProfile(tx.user_id);
    return res.json({ success: true, profile });
  } catch (error: any) {
    console.error('POST /transaction/complete error:', error?.message ?? error);
    return res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Create a withdraw request (stores a pending withdraw transaction)
app.post('/withdraw', async (req, res) => {
  try {
    const userId = Number(req.body?.user_id ?? req.query?.user_id ?? NaN);
    const amount = Number(req.body?.amount ?? req.query?.amount ?? NaN);
    if (!Number.isFinite(userId)) return res.status(400).json({ error: 'user_id is required' });
    if (!Number.isFinite(amount) || amount <= 0) return res.status(400).json({ error: 'invalid amount' });

    const via = String(req.body?.via ?? 'bank');
    const tx = await API.createWithdrawTransaction(userId, amount, via);
    return res.json({ success: true, transaction_id: tx.transaction_id, status: tx.status });
  } catch (error: any) {
    console.error('POST /withdraw error:', error?.message ?? error);
    return res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Complete a withdraw (dev/admin action): debit user's wallet and mark transaction completed
app.post('/withdraw/:id/complete', async (req, res) => {
  try {
    const transactionId = Number(req.params?.id ?? Number(req.body?.transaction_id ?? NaN));
    if (!Number.isFinite(transactionId)) return res.status(400).json({ error: 'transaction_id is required' });

    const tx = await API.getTransactionById(transactionId);
    if (!tx) return res.status(404).json({ error: 'Transaction not found' });
    if (tx.type !== 'withdraw') return res.status(400).json({ error: 'Not a withdraw transaction' });

    if (tx.status === 'completed') {
      const profile = await API.getUserProfile(tx.user_id);
      return res.json({ success: true, message: 'already completed', profile });
    }

    const amt = Number(tx.amount ?? 0);
    if (amt <= 0) return res.status(400).json({ error: 'invalid amount' });

    // Always attempt to create an Omise payout/transfer for withdraws.
    // Require server to be configured with OMISE_SECRET_KEY and a recipient id to call Omise.
    const secretKey = process.env.OMISE_SECRET_KEY ?? '';
    if (!secretKey) {
      return res.status(500).json({ error: 'Server not configured for Omise payouts (missing OMISE_SECRET_KEY)' });
    }

    // recipient id priority:
    // 1) request body recipient_id
    // 2) tx.external_ref (previously stored recipient or payout id)
    // 3) DEFAULT_OMISE_RECIPIENT from env (convenience for testing / single account)
    let recipientId = String(req.body?.recipient_id ?? req.body?.recipient ?? tx.external_ref ?? '').trim();
    if (!recipientId) {
      recipientId = String(process.env.DEFAULT_OMISE_RECIPIENT ?? '').trim();
    }
    if (!recipientId) return res.status(400).json({ error: 'recipient_id required for Omise payout' });

    try {
      // Omise expects amount in satang
      const amtSatang = Math.round(amt * 100);
      const payout = await API.createOmisePayout(recipientId, amtSatang);
      // Optionally store payout id in transactions.external_ref
      try {
        if (payout && (payout as any).id) {
          await API.setTransactionExternalRef(transactionId, String((payout as any).id));
        }
      } catch (_) {}
    } catch (err: any) {
      console.error('Payout failed:', err?.message ?? err);
      return res.status(502).json({ error: 'Omise payout failed', detail: String(err?.message ?? err) });
    }

    // attempt to debit user's wallet atomically
    const ok = await API.debitUserWallet(tx.user_id, amt);
    if (!ok) return res.status(400).json({ error: 'insufficient funds' });

    await API.markTransactionCompleted(transactionId);
    const profile = await API.getUserProfile(tx.user_id);
    return res.json({ success: true, profile });
  } catch (error: any) {
    console.error('POST /withdraw/:id/complete error:', error?.message ?? error);
    return res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Omise webhook receiver — reconcile charge status automatically
// NOTE: For production, verify webhook signature from Omise
app.post('/webhooks/omise', express.json({ type: '*/*' }), async (req, res) => {
  try {
    const body = req.body ?? {};
    // Omise sends event object with data.object containing the charge
    const evtType = body?.key ?? body?.event ?? null;
    const charge = (body?.data && body.data.object) ? body.data.object : (body?.data ?? null);
    const chargeId = charge?.id ?? null;
    const status = charge?.status ?? null;
    if (!chargeId) return res.status(400).json({ error: 'missing charge id' });

    // find transaction linked to this external ref
    const tx = await API.getTransactionByExternalRef(String(chargeId));
    if (!tx) return res.status(404).json({ error: 'transaction not found' });

    if (status === 'successful' || status === 'paid' || status === 'captured') {
      if (tx.status !== 'completed') {
        await API.markTransactionCompleted(tx.transaction_id);
        const amt = Number(tx.amount ?? 0);
        if (amt > 0) await API.creditUserWallet(tx.user_id, amt);
      }
      return res.json({ success: true });
    }

    // not a final successful state — return OK
    return res.json({ success: true, note: 'ignored status' });
  } catch (err: any) {
    console.error('/webhooks/omise error', err?.message ?? err);
    return res.status(500).json({ error: 'internal error' });
  }
});

function getPublicBaseUrlFromEnv(): string {
	// mirror logic in api.ts
	const raw = process.env.PUBLIC_BASE_URL ?? '';
	const base = typeof raw === 'string' && raw.trim().length > 0 ? raw.trim() : 'http://localhost:4000';
	return base.endsWith('/') ? base.slice(0, -1) : base;
}

function normalizePublicUrl(imagePath: string | null | undefined): string | undefined {
	if (!imagePath) return undefined;
	const s = String(imagePath).trim();
	if (!s) return undefined;
	if (s.startsWith('http://') || s.startsWith('https://')) return s;
	if (s.startsWith('/')) return `${getPublicBaseUrlFromEnv()}${s}`;
	return `${getPublicBaseUrlFromEnv()}/${s}`;
}

// ACCOUNT PROFILE
// Get current user profile by user_id (from query or body for simplicity)
app.get('/account/profile', async (req, res) => {
  try {
    const userIdRaw = (req.query.user_id as string) ?? String((req.body as any)?.user_id ?? '');
    const userId = Number(userIdRaw);
    if (!Number.isFinite(userId)) return res.status(400).json({ error: 'user_id required' });
    const profile = await API.getUserProfile(userId);
    if (!profile) return res.status(404).json({ error: 'User not found' });
  // return stored image path as-is (relative path like /uploads/...) so client
  // can decide how to display it. Do NOT convert to absolute http URL here.
  res.json(profile);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Update profile fields (JSON)
app.put('/account/profile', async (req, res) => {
  try {
    const userId = Number((req.query.user_id as string) ?? String((req.body as any)?.user_id ?? ''));
    if (!Number.isFinite(userId)) return res.status(400).json({ error: 'user_id required' });
    const { displayname, about_me, education_level, education_history, work_experience, image } = req.body ?? {};
    const updated = await API.updateUserProfile(userId, { displayname, about_me, education_level, education_history, work_experience, image });
  // Return stored image path as-is (do not convert to absolute URL)
  res.json(updated);
  } catch (error: any) {
    const msg = error?.message ?? 'Internal error';
    const code = msg === 'Invalid education_level' ? 400 : 500;
    res.status(code).json({ error: msg });
  }
});

// Upload profile image
app.post('/account/profile/image', upload.single('image'), async (req, res) => {
  try {
    const userId = Number((req.query.user_id as string) ?? String((req.body as any)?.user_id ?? ''));
    if (!Number.isFinite(userId)) return res.status(400).json({ error: 'user_id required' });

    const file = (req as any).file as { fieldname?: string; filename: string; path?: string } | undefined;
    if (!file || !file.filename) return res.status(400).json({ error: 'image file required' });

    const filePath = path.join(uploadsDir, file.filename);

    // Call the image verification model (server-side) before committing to DB.
    // Verification enforcement is optional. Set ENFORCE_IMAGE_VERIFICATION=1 to
    // make the endpoint fail when verification fails. Default behaviour is to
    // log verification failures and accept the uploaded file (useful for dev).
    const enforceVerification = (process.env.ENFORCE_IMAGE_VERIFICATION === '1' || process.env.ENFORCE_IMAGE_VERIFICATION === 'true');
    const modelBase = getModelBaseUrlFromEnv();
    const modelUrl = `${modelBase}/check_profile_image`;

    try {
      const form = new FormData();
      form.append('file', fs.createReadStream(filePath));

      // Use axios to POST multipart/form-data with proper headers
      const headers = form.getHeaders();
      let mfResp: any;
      try {
        mfResp = await axios.post(modelUrl, form, { headers, timeout: 8000 });
      } catch (err: any) {
        mfResp = err?.response || null;
        if (!mfResp) {
          // verification call failed entirely
          console.warn('Image verification call failed:', err?.message ?? err);
          if (enforceVerification) {
            try { fs.unlinkSync(filePath); } catch (_) {}
            return res.status(502).json({ error: 'image verification error', detail: String(err?.message ?? err) });
          }
          // otherwise continue and accept upload
          mfResp = null;
        }
      }

      if (mfResp) {
        // Normalize axios response: response.data may already be parsed
        let respText = '';
        try {
          if (mfResp.data === undefined) {
            respText = '';
          } else if (typeof mfResp.data === 'string') {
            respText = mfResp.data;
          } else {
            try { respText = JSON.stringify(mfResp.data); } catch (_) { respText = String(mfResp.data); }
          }
        } catch (_) { respText = ''; }

        if (mfResp.status !== 200) {
          console.warn(`Model service returned non-200: ${mfResp.status} body=${respText}`);
          if (enforceVerification) {
            try { fs.unlinkSync(filePath); } catch (_) {}
            return res.status(502).json({ error: 'image verification failed', status: mfResp.status, body: respText });
          }
        } else {
          // Try to parse JSON from successful response
          let json: any;
          if (mfResp.data && typeof mfResp.data === 'object') {
            json = mfResp.data;
          } else {
            try { json = respText ? JSON.parse(respText) : null; } catch (_) { json = null; }
          }

          if (!json) {
            console.warn('Model service returned invalid/empty JSON:', respText);
            if (enforceVerification) {
              try { fs.unlinkSync(filePath); } catch (_) {}
              return res.status(502).json({ error: 'invalid verification response', body: respText });
            }
          } else if (json.status === 'rejected') {
            console.warn('Model service explicitly rejected image:', json.reasons ?? json);
            if (enforceVerification) {
              try { fs.unlinkSync(filePath); } catch (_) {}
              return res.status(400).json({ error: 'รูปภาพไม่เหมาะสม', reasons: json.reasons ?? [] });
            }
          }
          // otherwise approved or unclear -> proceed
        }
      }
    } catch (err: any) {
      // Unexpected verification error: decide based on enforcement flag
      console.error('Unexpected error during image verification:', err?.message ?? err);
      if (enforceVerification) {
        try { fs.unlinkSync(filePath); } catch (_) {}
        const isAbort = err && (err.name === 'AbortError' || err.type === 'aborted');
        return res.status(isAbort ? 504 : 502).json({ error: 'image verification error', detail: String(err?.message ?? err) });
      }
      // otherwise continue and accept upload
    }

    // If approved, update user profile and sync to CometChat so avatar is updated
    const publicPath = `/uploads/${file.filename}`;
    const updated = await API.updateUserProfile(userId, { image: publicPath });

    // Attempt to sync the DB user to CometChat so the avatar shows up there.
    // This uses the helper in api.ts which creates/updates the CometChat user.
    try {
      await API.syncDbUserToCometChat(userId);
    } catch (syncErr: any) {
      console.warn('Failed to sync user to CometChat after image upload:', syncErr?.message ?? syncErr);
      // don't fail the request — image upload succeeded and DB updated
    }

    // Return stored image path and absolute URL for client convenience
    return res.json({ success: true, image: publicPath, url: normalizePublicUrl(publicPath), profile: updated });
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// JOB CATEGORIES & POSTS
// list categories (ensure seeded on first call)
app.get('/job/categories', async (_req, res) => {
  try {
    // Return categories directly from the job_categories table.
    // Do NOT seed or inject fixed categories here — the caller requested
    // that we read only what exists in the DB.
    const cats = await API.listJobCategories();
    res.json(cats);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// create post with optional image upload
// Accepts multipart/form-data with fields:
// - user_id (number, required)
// - post_name (string, required)
// - category (string optional; will map by name) OR post_category_id (number)
// - wage (number optional)
// - description (string optional)
// - image or file (file optional)
app.post('/job/posts', upload.any(), async (req, res) => {
  try {
    // รองรับทั้ง multipart/form-data และ application/json
    const fields = req.body ?? {};
    const userId = Number((fields.user_id ?? (req.query.user_id as string) ?? ''));
    const postName = typeof fields.post_name === 'string' ? fields.post_name : '';
    const categoryName = typeof fields.category === 'string' ? fields.category : '';
    // รองรับ post_type จาก multipart หรือ JSON
    const postType = (fields.post_type === 'employer' || fields.post_type === 'worker')
      ? fields.post_type
      : (typeof req.body?.post_type === 'string' && (req.body.post_type === 'employer' || req.body.post_type === 'worker'))
        ? req.body.post_type
        : undefined;

    // Normalize post_category_id: treat '', 0, '0', NaN as "no category" (-> null in DB)
    const postCategoryIdRaw = fields.post_category_id ?? '';
    let postCategoryId = postCategoryIdRaw !== '' ? Number(postCategoryIdRaw) : undefined;
    if (!Number.isFinite(postCategoryId) || (typeof postCategoryId === 'number' && postCategoryId <= 0)) {
      postCategoryId = undefined;
    }

    const wage = fields.wage != null && String(fields.wage).trim() !== '' ? Number(fields.wage) : undefined;
    const description = typeof fields.description === 'string' ? fields.description : undefined; // เพิ่มบรรทัดนี้

    if (!Number.isFinite(userId)) return res.status(400).json({ error: 'user_id required' });
    if (typeof postName !== 'string' || postName.trim().length === 0) return res.status(400).json({ error: 'post_name required' });
    if (!postType) return res.status(400).json({ error: 'post_type required (employer or worker)' });

    let categoryId: number | undefined = postCategoryId;
    if (!categoryId && categoryName) {
      // Lookup by name directly in DB. Seeding of fixed categories was removed
      // to ensure API returns only values present in the job_categories table.
      categoryId = await API.getCategoryIdByName(categoryName) ?? undefined;
    }

    const files = (req as any).files as Array<{ fieldname?: string; filename: string }> | undefined;
    const picked = Array.isArray(files) && files.length > 0
      ? (files.find(f => (f.fieldname || '').toLowerCase() === 'image') || files.find(f => (f.fieldname || '').toLowerCase() === 'file') || files[0])
      : undefined;
    const imagePath = picked ? `/uploads/${picked.filename}` : undefined;

    // --- Fix: map post_category_id to post_category for DB ---
    const result = await API.createJobPost({
      user_id: userId,
      post_name: postName.trim(),
      post_category: categoryId == null ? null : categoryId,
      wage: wage ?? null,
      image_post: imagePath ?? null,
      description: description ?? null,
      post_type: postType // ส่ง post_type เสมอ
    });
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.get('/job/posts/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'id invalid' });
    const post = await API.getJobPostById(id);
    if (!post) return res.status(404).json({ error: 'Not found' });
    res.json(post);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// delete a post (optionally require user_id to match)
app.delete('/job/posts/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'id invalid' });
    const userIdRaw = (req.query.user_id as string) ?? String((req.body as any)?.user_id ?? '');
    const userId = userIdRaw ? Number(userIdRaw) : undefined;
    const out = await API.deleteJobPost(id, userId);
    if (!out.deleted) return res.status(404).json({ error: 'Not found or not owned by user' });
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ดูโพสทั้งหมด (GET /job/posts)
app.get('/job/posts', async (req, res) => {
  try {
    const posts = await API.listJobPosts();
    res.json(posts);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// CHAT API
app.post('/chat/users', async (req, res) => {
  try {
    const { uid, name, avatar } = req.body ?? {};
    if (!uid || !name) return res.status(400).json({ error: 'uid and name are required' });
    const user = await API.createChatUser({ uid, name, avatar });
    res.json(user);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Return a list of DB users for chat list (frontend calls GET /chat/users)
app.get('/chat/users', async (req, res) => {
  try {
    console.log('GET /chat/users invoked');
    const host = process.env.DB_HOST ?? 'localhost';
    const user = process.env.DB_USER ?? 'root';
    const password = process.env.DB_PASSWORD ?? '';
    const database = process.env.DB_NAME ?? 'getworks_app';
    const port = Number(process.env.DB_PORT ?? 3306);

    const pool = createPool({ host, user, password, database, port, waitForConnections: true, connectionLimit: 5 });
    const [rows] = await pool.query('SELECT user_id, username, image FROM users ORDER BY user_id ASC LIMIT 200');
    try { await pool.end(); } catch (_) {}

    const list = (rows as any[]).map(r => ({
      uid: String(r.user_id),
      name: r.username,
      avatar: r.image ? normalizePublicUrl(r.image) : null,
      lastMessage: '',
      time: ''
    }));

    return res.json(list);
  } catch (err: any) {
    console.error('/chat/users error', err?.message ?? err);
    return res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

// Return contacts (people this user has chatted with) for one-to-one chat
// Query params: ?user_id=123 or ?uid=123
app.get('/chat/contacts', async (req, res) => {
  try {
    const userIdParam = req.query.user_id ?? req.query.uid ?? (req.body && req.body.user_id);
    if (!userIdParam) return res.status(400).json({ error: 'user_id (or uid) query parameter is required' });
    const uid = String(userIdParam);

    // Use the API helper to fetch messages related to this uid and derive partners
    let msgs: any = [];
    try {
      msgs = await API.getChatMessages({ uid, limit: 200 });
    } catch (e) {
      console.warn('API.getChatMessages failed', e);
      msgs = [];
    }

    // Normalize to an array of message objects
    let arr: any[] = [];
    if (Array.isArray(msgs)) arr = msgs;
    else if (msgs && Array.isArray((msgs as any).data)) arr = (msgs as any).data;

    const partners = new Set<string>();
    for (const m of arr) {
      try {
        const senderUid = m?.sender?.uid ?? m?.from ?? m?.sender ?? null;
        const receiverUid = m?.receiver ?? m?.to ?? null;
        if (senderUid && String(senderUid) !== uid) partners.add(String(senderUid));
        if (receiverUid && String(receiverUid) !== uid) partners.add(String(receiverUid));
      } catch (_) { /* ignore malformed message */ }
    }

    const contacts: any[] = [];
    for (const p of partners) {
      let userRec: any = null;
      const n = Number(p);
      if (!Number.isNaN(n)) {
        try { userRec = await API.getUserById(n); } catch (_) { userRec = null; }
      }
      if (!userRec) {
        try {
          const chatUser = await API.getChatUser(p);
          if (chatUser) userRec = { user_id: p, username: chatUser?.name ?? p, image: chatUser?.avatar ?? null };
        } catch (_) { /* ignore */ }
      }

      contacts.push({
        uid: p,
        name: userRec?.username ?? userRec?.name ?? p,
        avatar: userRec?.image ?? userRec?.avatar ?? null
      });
    }

    return res.json(contacts);
  } catch (err: any) {
    console.error('/chat/contacts error', err?.message ?? err);
    return res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

// Fetch messages for a conversation
// Query options:
// - conversationId=...    (preferred if you have a conversation id)
// - uid=...&peer=...       (DB user id strings; returns messages exchanged between uid and peer)
// - limit=...              (optional, default 50)
app.get('/chat/messages', async (req, res) => {
  try {
    const conversationId = req.query.conversationId as string | undefined;
    const uid = (req.query.uid ?? req.query.user_id) as string | undefined;
    const peer = (req.query.peer ?? req.query.peerUid ?? req.query.peer_uid) as string | undefined;
    const limitRaw = req.query.limit as string | undefined;
    const limit = limitRaw ? Math.min(500, Math.max(1, Number(limitRaw))) : 200;

    if (conversationId && typeof conversationId === 'string' && conversationId.trim().length > 0) {
      // Use conversation-specific helper
      const msgs = await API.getChatMessagesByConversation({ conversationId: conversationId.trim(), limit });
      return res.json(msgs);
    }

    if (!uid || !peer) {
      return res.status(400).json({ error: 'conversationId or uid+peer query parameters required' });
    }

    // Fetch messages related to uid and then filter to only those between uid and peer
    const fetched = await API.getChatMessages({ uid: String(uid), limit });
    let arr: any[] = [];
    if (Array.isArray(fetched)) arr = fetched;
    else if (fetched && Array.isArray((fetched as any).data)) arr = (fetched as any).data;

    const filtered = arr.filter((m: any) => {
      try {
        const sender = String(m?.sender?.uid ?? m?.from ?? m?.sender ?? m?.senderUid ?? '');
        const receiver = String(m?.receiver ?? m?.to ?? m?.receiverUid ?? m?.receiverUid ?? '');
        return (sender === String(uid) && receiver === String(peer)) || (sender === String(peer) && receiver === String(uid));
      } catch (_) {
        return false;
      }
    });

    // Normalize messages into a simple canonical shape for clients
    const normalize = (m: any) => {
      if (!m || typeof m !== 'object') return null;

      // stable id
      const id = String(m?.id ?? m?.message_id ?? m?.msg_id ?? m?.data?.id ?? m?.data?.message_id ?? '') || '';

      // sender extraction (handle CometChat nested sender.entity)
      let senderUid = '';
      let senderName = '';
      try {
        const s = m?.sender;
        if (s && typeof s === 'object') {
          if (s.entity && typeof s.entity === 'object') {
            senderUid = String(s.entity.uid ?? s.entity.id ?? s.entity.user_id ?? '') || '';
            senderName = String(s.entity.name ?? s.entity.username ?? s.entity.displayname ?? '') || '';
          }
          // fallback to top-level sender fields
          if (!senderUid) senderUid = String(s.uid ?? s.id ?? s.user_id ?? s.from ?? '') || '';
          if (!senderName) senderName = String(s.name ?? s.username ?? s.displayname ?? '') || '';
        } else if (typeof s === 'string') {
          senderUid = s;
        }
      } catch (_) {}

      // message type and text
      const type = String(m?.type ?? m?.message_type ?? (m?.data && m.data.type) ?? '') || (m?.data && m.data.attachments ? 'image' : 'text');
      const text = String(m?.text ?? m?.data?.text ?? m?.message ?? '') || '';

      // attachments normalization
      let attachments: any[] = [];
      try {
        const rawAtt = m?.data?.attachments ?? m?.attachments ?? [];
        if (Array.isArray(rawAtt)) {
          attachments = rawAtt.map((a: any) => {
            const urlRaw = String(a?.url ?? a?.file ?? a?.uri ?? '') || '';
            // Safe normalization: prefer normalizePublicUrl function when available,
            // otherwise fall back to building an absolute URL from PUBLIC_BASE_URL
            let url = '';
            if (typeof normalizePublicUrl === 'function') {
              url = normalizePublicUrl(urlRaw);
            } else if (urlRaw) {
              url = urlRaw.startsWith('http') ? urlRaw : `${getPublicBaseUrlFromEnv()}${urlRaw.startsWith('/') ? urlRaw : '/' + urlRaw}`;
            } else {
              url = urlRaw;
            }
            return {
              name: a?.name ?? a?.filename ?? null,
              url,
              mimeType: a?.mimeType ?? a?.mime ?? null,
              extension: a?.extension ?? null,
              raw: a
            };
          });
        }
      } catch (_) { attachments = []; }

      // if attachments empty but top-level url exists, include it
      try {
        if (attachments.length === 0) {
          const possible = String(m?.url ?? m?.data?.url ?? m?.file ?? '');
          if (possible && possible.length > 0) {
            const url = (typeof normalizePublicUrl === 'function')
              ? normalizePublicUrl(possible)
              : (possible.startsWith('http') ? possible : `${getPublicBaseUrlFromEnv()}${possible.startsWith('/') ? possible : '/' + possible}`);
            attachments = [{ name: null, url, mimeType: null, extension: null, raw: null }];
          }
        }
      } catch (_) {}

      // createdAt / sentAt normalization
      let createdAt: string = '';
      try {
        const cand = m?.sentAt ?? m?.sent_at ?? m?.createdAt ?? m?.created_at ?? m?.data?.sentAt ?? m?.data?.createdAt ?? m?.updatedAt ?? m?.updated_at ?? '';
        if (cand !== undefined && cand !== null) {
          createdAt = String(cand);
        }
      } catch (_) { createdAt = ''; }

      return {
        raw: m,
        id,
        senderUid,
        senderName,
        type,
        text,
        attachments,
        // convenience top-level url for clients
        url: attachments.length > 0 ? String(attachments[0].url ?? '') : '',
        caption: (m?.data?.caption ?? m?.caption ?? '') || '',
        createdAt,
      };
    };

    const normalized = filtered.map(normalize).filter((x) => x !== null);

    // sort by createdAt when possible (numeric or ISO), otherwise keep original order
    normalized.sort((a: any, b: any) => {
      try {
        const A = a.createdAt ?? '';
        const B = b.createdAt ?? '';
        const na = Number(A);
        const nb = Number(B);
        if (Number.isFinite(na) && Number.isFinite(nb)) return na - nb;
        const da = Date.parse(A);
        const db = Date.parse(B);
        if (!isNaN(da) && !isNaN(db)) return da - db;
      } catch (_) {}
      return 0;
    });

    return res.json({ data: normalized });
  } catch (err: any) {
    console.error('/chat/messages error', err?.message ?? err);
    return res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

app.get('/chat/users/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const user = await API.getChatUser(uid);
    res.json(user);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.put('/chat/users/:uid', async (req, res) => {
  try {
    const { uid } = req.params;
    const updates = req.body ?? {};
    const user = await API.updateChatUser(uid, updates);
    res.json(user);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.post('/chat/users/:uid/tokens', async (req, res) => {
  try {
    const { uid } = req.params;
    const token = await API.createUserAuthToken(uid);
    res.json(token);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.delete('/chat/users/:uid/tokens/:token', async (req, res) => {
  try {
    const { uid, token } = req.params as { uid: string; token: string };
    const out = await API.revokeUserAuthToken(uid, token);
    res.json(out);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.post('/chat/groups', async (req, res) => {
  try {
    const { guid, name, type, password } = req.body ?? {};
    if (!guid || !name || !type) return res.status(400).json({ error: 'guid, name, type required' });
    const group = await API.createChatGroup({ guid, name, type, password });
    res.json(group);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.post('/chat/groups/:guid/members', async (req, res) => {
  try {
    const { guid } = req.params;
    const { members } = req.body ?? {};
    if (!Array.isArray(members) || members.length === 0) {
      return res.status(400).json({ error: 'members array required' });
    }
    const result = await API.addGroupMembers(guid, members);
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.delete('/chat/groups/:guid/members/:uid', async (req, res) => {
  try {
    const { guid, uid } = req.params as { guid: string; uid: string };
    const result = await API.removeGroupMember(guid, uid);
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.post('/chat/messages/text', async (req, res) => {
  try {
    const { receiver, text, receiverType } = req.body ?? {};
    const messageText = typeof text === 'string' ? text.trim() : '';
    if (!receiver || !messageText || !receiverType) {
      return res.status(400).json({ error: 'receiver, text, receiverType required' });
    }
    const msg = await API.sendTextMessage({ receiver, text: messageText, receiverType });
    res.json(msg);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Send a message as a specific user (on behalf of)
app.post('/chat/messages/text-as-user', async (req, res) => {
  try {
    const { senderUid, receiver, text, receiverType } = req.body ?? {};
    const messageText = typeof text === 'string' ? text.trim() : '';
    if (!senderUid || !receiver || !messageText || !receiverType) {
      return res.status(400).json({ error: 'senderUid, receiver, text, receiverType required' });
    }
    const msg = await API.sendTextMessageOnBehalfOf({ senderUid: String(senderUid), receiver: String(receiver), text: messageText, receiverType });
    res.json(msg);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.post('/chat/messages/image-url', async (req, res) => {
  try {
    const { receiver, receiverType, url, caption } = req.body ?? {};
    if (!receiver || !receiverType || !url) {
      return res.status(400).json({ error: 'receiver, receiverType, url required' });
    }
    const out = await API.sendImageMessageByUrl({ receiver, receiverType, url, caption });
    return res.json(out);
  } catch (error: any) {
    console.error('/chat/messages/image-url error', error);
    return res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Accept multipart image attachment and send as a chat image message (on behalf of sender)
// Form fields expected: senderUid (or sender_uid), receiver, receiverType (default 'user'), caption (optional)
// File field expected: image
app.post('/chat/messages/image', upload.single('image'), async (req, res) => {
  try {
    const senderUid = String((req.body && (req.body.senderUid || req.body.sender_uid)) || '').trim();
    const receiver = String((req.body && req.body.receiver) || '').trim();
    const receiverType = String((req.body && (req.body.receiverType || req.body.receiver_type)) || 'user');
    const caption = String((req.body && req.body.caption) || '');

    if (!senderUid || !receiver) {
      return res.status(400).json({ error: 'senderUid and receiver are required' });
    }

    const file = (req as any).file;
    if (!file) {
      return res.status(400).json({ error: 'image file (field name `image`) is required' });
    }

    const publicPath = `/uploads/${file.filename}`;
    const publicUrl = normalizePublicUrl ? normalizePublicUrl(publicPath) : `${getPublicBaseUrlFromEnv()}${publicPath}`;

    // Optionally perform image verification here (reuse existing verification flow) if desired.

    // Use server helper to send image message by URL on behalf of sender
    const out = await API.sendImageMessageByUrlOnBehalfOf({
      senderUid: String(senderUid),
      receiver: String(receiver),
      receiverType: String(receiverType || 'user'),
      url: String(publicUrl),
      caption: caption || undefined,
    });

    return res.status(201).json({ success: true, message: out, image: publicPath, url: publicUrl });
  } catch (err: any) {
    console.error('/chat/messages/image error', err);
    return res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

// DB-aligned routes
// Sync user by user_id from SQL to CometChat
app.post('/chat/sync-user', async (req, res) => {
  try {
    const { user_id } = req.body ?? {};
    const id = Number(user_id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'user_id required' });
    const result = await API.syncDbUserToCometChat(id);
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Issue CometChat token by user_id
app.post('/chat/users/:user_id/token', async (req, res) => {
  try {
    const id = Number(req.params.user_id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'user_id invalid' });
    const token = await API.issueAuthTokenForUserId(id);
    res.json(token);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

app.post('/auth/logout', async (req, res) => {
  try {
    const { user_id, authToken } = req.body ?? {};
    const id = user_id == null ? null : Number(user_id);
    // If provided, attempt to revoke a CometChat auth token for the user.
    if (id != null && Number.isFinite(id) && authToken) {
      try {
        await API.revokeUserAuthToken(String(id), String(authToken));
      } catch (err: any) {
        // Log but don't fail logout (idempotent)
        console.warn('Failed to revoke CometChat token:', err?.message ?? err);
      }
    }

    // Mark user offline and set last_logout
    if (id != null && Number.isFinite(id)) {
      try { await API.setUserOnline(id, false); } catch (e) { console.warn('Failed to mark offline', e); }
    }

    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ success: false, error: error?.message ?? 'Internal error' });
  }
});

// ADMIN login: only allow users with role = 'admin'
app.post('/auth/admin/login', async (req, res) => {
  try {
    const { username, password } = req.body ?? {};
    if (!username || !password) {
      return res.status(400).json({ error: 'username and password required' });
    }

    // Check user record and role first (do not issue token to non-admins)
    try {
      const dbUser = await API.getUserByUsername(String(username), false);
      if (!dbUser) return res.status(401).json({ error: 'Invalid credentials' });
      if (dbUser.role !== 'admin') return res.status(403).json({ error: 'Forbidden: admin only' });
    } catch (err) {
      // any DB error -> treat as server error
      return res.status(500).json({ error: String((err as any)?.message ?? 'Internal error') });
    }

    // Credentials verification + token issuance (reuses existing logic)
    try {
      const token = await API.issueAuthTokenForUsernamePassword(String(username), String(password));
      // include user_id and role in response for client convenience
      const dbUserFull = await API.getUserByUsername(String(username), false);
      res.json({
        ...token,
        data: {
          ...token.data,
          userid: dbUserFull?.user_id,
          username: String(username),
          role: dbUserFull?.role
        }
      });
    } catch (err: any) {
      const msg = err?.message === 'Invalid credentials' ? 'Invalid credentials' : (err?.message ?? 'Internal error');
      const code = msg === 'Invalid credentials' ? 401 : 500;
      res.status(code).json({ error: msg });
    }
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ADMIN: List posts by status (pending/approved/rejected)
app.get('/admin/posts', async (req, res) => {
  try {
    const status = typeof req.query.status === 'string' ? req.query.status : undefined;
    const posts = await API.listJobPosts(status);
    res.json(posts);
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ADMIN: Approve a post
app.post('/admin/posts/:id/approve', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'id invalid' });
    const updated = await API.updateJobPostStatus(id, 'approved');
    if (!updated) return res.status(404).json({ error: 'Post not found' });
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ADMIN: Reject a post
app.post('/admin/posts/:id/reject', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'id invalid' });
    const updated = await API.updateJobPostStatus(id, 'rejected');
    if (!updated) return res.status(404).json({ error: 'Post not found' });
    res.json({ success: true });
  } catch (error: any) {
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ADMIN: List transactions (new)
// GET /admin/transactions?type=topup&status=completed&user_id=123&limit=100&offset=...
app.get('/admin/transactions', async (req, res) => {
  try {
    const type = typeof req.query.type === 'string' ? req.query.type : undefined;
    const status = typeof req.query.status === 'string' ? req.query.status : undefined;
    const userId = req.query.user_id != null && String(req.query.user_id).trim().length > 0
      ? Number(req.query.user_id)
      : undefined;
    const limit = req.query.limit != null ? Math.max(1, Math.min(1000, Number(req.query.limit))) : undefined;
    const offset = req.query.offset != null ? Math.max(0, Number(req.query.offset)) : undefined;

    const opts: any = {};
    if (type) opts.type = type;
    if (status) opts.status = status;
    if (userId != null && Number.isFinite(Number(userId))) opts.user_id = Number(userId);
    if (limit != null && Number.isFinite(Number(limit))) opts.limit = Number(limit);
    if (offset != null && Number.isFinite(Number(offset))) opts.offset = Number(offset);

    const txs = await API.listTransactions(opts);
    // return array directly for frontend convenience
    res.json(txs);
  } catch (error: any) {
    console.error('GET /admin/transactions error:', error?.message ?? error);
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ---------------------------
// New: ADMIN user management endpoints
// ---------------------------

// GET /admin/users?search=...&limit=...&offset=...
app.get('/admin/users', async (req, res) => {
  try {
    const search = typeof req.query.search === 'string' ? req.query.search : undefined;
    const limit = Math.max(1, Math.min(1000, Number(req.query.limit ?? 200)));
    const offset = Math.max(0, Number(req.query.offset ?? 0));
    const users = await API.listUsers({ search, limit, offset });
    res.json({ data: users });
  } catch (error: any) {
    console.error('GET /admin/users error:', error?.message ?? error);
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// POST /admin/users/:id/suspend  body: { suspended: true|false }
app.post('/admin/users/:id/suspend', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'id invalid' });
    const suspendedBody = req.body && Object.prototype.hasOwnProperty.call(req.body, 'suspended') ? req.body.suspended : true;
    const suspended = Boolean(suspendedBody);
    const ok = await API.setUserSuspended(id, suspended);
    if (!ok) return res.status(404).json({ error: 'User not found or not modified' });
    res.json({ success: true, suspended });
  } catch (error: any) {
    console.error('POST /admin/users/:id/suspend error:', error?.message ?? error);
    res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// ---------------------------
// New: GET single admin user details
// ---------------------------
app.get('/admin/users/:id', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id)) return res.status(400).json({ error: 'id invalid' });

    // primary profile from API helper
    const profile = await API.getUserProfile(id);
    if (!profile) return res.status(404).json({ error: 'User not found' });

    // attempt to read suspended column if present
    try {
      const host = process.env.DB_HOST ?? 'localhost';
      const user = process.env.DB_USER ?? 'root';
      const password = process.env.DB_PASSWORD ?? '';
      const database = process.env.DB_NAME ?? 'getworks_app';
      const port = Number(process.env.DB_PORT ?? 3306);

      const pool = createPool({ host, user, password, database, port, waitForConnections: true, connectionLimit: 2 });
      const [rows] = await pool.query('SELECT suspended FROM users WHERE user_id = ? LIMIT 1', [id]);
      try { await pool.end(); } catch (_) {}
      const suspended = Array.isArray(rows) && rows.length > 0 ? (rows[0] as any).suspended : null;
      // return profile with suspended if available
      return res.json({ data: { ...profile, suspended: suspended == null ? 0 : Number(suspended) } });
    } catch (e) {
      // If DB check fails, still return profile without suspended
      return res.json({ data: { ...profile, suspended: 0 } });
    }
  } catch (err: any) {
    console.error('GET /admin/users/:id error', err?.message ?? err);
    res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

// Create job request / send details to freelancer
// Accepts multipart/form-data or application/json with optional file field "image"
// Required fields: post_id, employer_id, detail, deadline, contact
// Optional: amount (THB decimal) -> will create an escrow_payments record (status 'held')
app.post('/job/send_details', upload.single('image'), async (req, res) => {
  try {
    // multer puts form fields on req.body for multipart requests
    const fields = req.body ?? {};

    // Accept both snake_case and camelCase keys (frontend clients vary)
    const rawPostId = fields.post_id ?? fields.postId ?? req.query.post_id ?? req.query.postId;
    const rawEmployerId = fields.employer_id ?? fields.employerId ?? req.query.employer_id ?? req.query.employerId;
    const rawDetail = fields.detail ?? fields.description ?? fields.details ?? null;
    const rawDeadline = fields.deadline ?? fields.date ?? null;
    const rawContact = fields.contact ?? fields.contact_info ?? null;
    const rawAmount = fields.amount ?? req.query.amount ?? null;

    const parseNumber = (v: any) => {
      if (v == null) return NaN;
      const s = String(v).trim();
      if (s === '') return NaN;
      // support comma as decimal separator
      const normalized = s.replace(/,/g, '.');
      const n = Number(normalized);
      return Number.isFinite(n) ? n : NaN;
    };

    const postId = parseNumber(rawPostId);
    const employerId = parseNumber(rawEmployerId);
    const detail = typeof rawDetail === 'string' ? rawDetail : (rawDetail ? String(rawDetail) : '');
    const deadline = rawDeadline ?? null;
    const contact = typeof rawContact === 'string' ? rawContact : (rawContact ? String(rawContact) : null);
    const amount = ![null, undefined, ''].includes(rawAmount) ? parseNumber(rawAmount) : null;

    // Log inputs for easier debugging in development
    console.info('POST /job/send_details incoming:', { postId: rawPostId, employerId: rawEmployerId, detail: detail ? '<redacted>' : detail, deadline, contact, amount, file: (req as any).file ? (req as any).file.filename : null });

    if (!Number.isFinite(postId)) return res.status(400).json({ error: 'post_id required', received: rawPostId });
    if (!Number.isFinite(employerId)) return res.status(400).json({ error: 'employer_id required', received: rawEmployerId });
    if (!detail || String(detail).trim().length === 0) return res.status(400).json({ error: 'detail required' });

    // Ensure post exists and retrieve worker (freelancer)
    let post: any = null;
    try {
      post = await API.getJobPostById(postId);
    } catch (e: any) {
      console.error('Error fetching post in /job/send_details', e?.message ?? e);
      return res.status(500).json({ error: 'Failed to fetch post', detail: e?.message ?? String(e) });
    }

    if (!post) return res.status(404).json({ error: 'Post not found', post_id: postId });
    const workerId = post.user_id;

    // handle optional uploaded image
    const file = (req as any).file;
    const imagePath = file && file.filename ? `/uploads/${file.filename}` : null;

    // create job detail
    const jd = await API.createJobDetail({
      post_id: postId,
      detail: String(detail),
      deadline: deadline,
      image: imagePath,
      contact: contact ? String(contact) : null
    });

    // optionally create escrow record (if amount provided)
    let escrow: any = null;
    if (amount != null && Number.isFinite(Number(amount)) && Number(amount) > 0) {
      const amt = Number(amount);
      // Try to debit the employer's wallet first. If the employer lacks funds,
      // return 402 Payment Required so frontend can surface a clear message.
      try {
        const debited = await API.debitUserWallet(employerId, amt);
        if (!debited) {
          // Do not create job detail escrow if payment failed. Return 402.
          return res.status(402).json({ error: 'insufficient_funds', message: 'Not enough balance to pay for this job' });
        }
      } catch (e: any) {
        console.error('Error debiting user wallet in /job/send_details', e?.message ?? e);
        return res.status(500).json({ error: 'failed_payment', message: e?.message ?? String(e) });
      }

      // generate a stable-ish escrow id and create escrow record
      const escrowId = `esc_${Date.now()}_${Math.random().toString(36).slice(2,8)}`;
      try {
        await API.createEscrowPayment({
          escrow_id: escrowId,
          employer_id: employerId,
          worker_id: workerId,
          job_id: jd.job_id,
          amount: amt,
          description: `Escrow for job ${jd.job_id}`
        });
        escrow = { escrow_id: escrowId };
      } catch (e: any) {
        // If escrow creation fails after debit, attempt to refund (best-effort)
        console.warn('createEscrowPayment failed after debit', e?.message ?? e);
        try {
          // credit back the employer (best-effort)
          await API.creditUserWallet(employerId, amt);
        } catch (refundErr: any) {
          console.error('Failed to refund after escrow creation failure', refundErr?.message ?? refundErr);
        }
      }
    }

    return res.json({ success: true, job_id: jd.job_id, escrow });
  } catch (error: any) {
    console.error('POST /job/send_details error:', error?.message ?? error);
    return res.status(500).json({ error: error?.message ?? 'Internal error' });
  }
});

// Accept or reject a job detail (called by worker when viewing a job sent to them)
app.post('/job/details/:id/accept', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: 'invalid id' });
    const ok = await API.acceptJobDetail(id);
    if (!ok) return res.status(404).json({ error: 'job not found' });
    return res.json({ success: true });
  } catch (err: any) {
    console.error('POST /job/details/:id/accept error', err?.message ?? err);
    return res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

app.post('/job/details/:id/reject', async (req, res) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) return res.status(400).json({ error: 'invalid id' });
    const ok = await API.rejectJobDetail(id);
    if (!ok) return res.status(404).json({ error: 'job not found' });
    return res.json({ success: true });
  } catch (err: any) {
    console.error('POST /job/details/:id/reject error', err?.message ?? err);
    return res.status(500).json({ error: err?.message ?? 'Internal error' });
  }
});

const port = Number(process.env.PORT ?? 4000);
app.listen(port, () => {
  console.log(`API listening on http://localhost:${port}`);
});

// Generic error handler (catch multer/file errors and avoid HTML stack traces)
app.use((err: any, _req: any, res: any, _next: any) => {
  if (!err) return _next?.();
  // Multer file type/limit errors
  const msg = String(err?.message ?? err);
  if (err && (err.code === 'LIMIT_FILE_SIZE' || msg.toLowerCase().includes('invalid file type') || err instanceof multer.MulterError)) {
    console.warn('Upload error:', msg);
    return res.status(400).json({ error: msg });
  }
  console.error('Unhandled error:', err);
  return res.status(500).json({ error: 'Internal server error' });
});
