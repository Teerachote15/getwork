import omise from 'omise';
import { createPool, Pool } from 'mysql2/promise';

//1. QR CODE PAYMENT
type CreateQRChargeInput = {
  amount: number;
  returnUri?: string;
};

export async function createQRCharge({ amount, returnUri = 'http://localhost/complete_payment' }: CreateQRChargeInput) {
  const publicKey = process.env.OMISE_PUBLIC_KEY;
  const secretKey = process.env.OMISE_SECRET_KEY;

  if (!publicKey || !secretKey) {
    throw new Error('Missing OMISE_PUBLIC_KEY or OMISE_SECRET_KEY');
  }

  const client = omise({ publicKey, secretKey });

  try {
    // Ensure amount is integer (satang)
    const amt = Math.round(Number(amount));
    if (!Number.isFinite(amt) || amt <= 0) throw new Error('Invalid amount for QR');

    const source = await client.sources.create({
      amount: amt,
      currency: 'thb',
      type: 'promptpay',
    });

    const charge = await client.charges.create({
      amount: amt,
      currency: 'thb',
      source: source.id,
      return_uri: returnUri,
    });

    if (charge.authorize_uri) {
      return { authorizeUri: charge.authorize_uri, chargeId: charge.id };
    }

    throw new Error('ไม่พบ authorize_uri ในการสร้าง Charge');
  } catch (error: any) {
    // เพิ่ม log สำหรับ debug
    console.error('Omise QR error:', error?.message ?? error, error);
    // ส่ง error message ที่อ่านง่ายขึ้น
    throw new Error(error?.message ?? 'เกิดข้อผิดพลาดในการสร้าง QR');
  }
}

// 2. CHAT API
type CometChatConfig = {
  appId: string;
  region: string; // e.g., us, eu
  apiKey: string; // REST API key (server-side only)
};

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';

async function cometFetch<T>(path: string, method: HttpMethod, body?: unknown, extraHeaders?: Record<string, string>): Promise<T> {
  const appId = process.env.COMETCHAT_APP_ID;
  const region = process.env.COMETCHAT_REGION;
  const apiKey = process.env.COMETCHAT_REST_API_KEY;

  if (!appId || !region || !apiKey) {
    throw new Error('Missing COMETCHAT_APP_ID, COMETCHAT_REGION or COMETCHAT_REST_API_KEY');
  }

  const endpoint = `https://${appId}.api-${region}.cometchat.io/v3${path}`;

  const res = await fetch(endpoint, {
    method,
    headers: {
      accept: 'application/json',
      'content-type': 'application/json',
      apikey: apiKey,
      ...(extraHeaders ?? {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  } as RequestInit);

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`CometChat API error ${res.status}: ${text}`);
  }

  return (await res.json()) as T;
}

// Normalize bcryptjs import across CJS/ESM interop
async function loadBcrypt() {
  const mod: any = await import('bcryptjs');
  return mod?.default ?? mod;
}

function getPublicBaseUrl(): string {
  const raw = process.env.PUBLIC_BASE_URL ?? '';
  const base = typeof raw === 'string' && raw.trim().length > 0 ? raw.trim() : 'http://localhost:4000';
  return base.endsWith('/') ? base.slice(0, -1) : base;
}

function normalizeAvatarUrl(image: string | null | undefined): string | undefined {
  if (!image) return undefined;
  const val = String(image).trim();
  if (!val) return undefined;
  if (val.startsWith('http://') || val.startsWith('https://')) return val;
  if (val.startsWith('/')) return `${getPublicBaseUrl()}${val}`;
  return `${getPublicBaseUrl()}/${val}`;
}

//2. Users (internal functions for sync)
// Create a new user in CometChat (used internally by syncDbUserToCometChat)
export async function createChatUser({ uid, name, avatar }: { uid: string; name: string; avatar?: string }) {
  return await cometFetch(`/users`, 'POST', { uid, name, avatar });
}

export async function getChatUser(uid: string) {
  return await cometFetch(`/users/${encodeURIComponent(uid)}`, 'GET');
}

export async function updateChatUser(uid: string, updates: { name?: string; avatar?: string; metadata?: unknown }) {
  return await cometFetch(`/users/${encodeURIComponent(uid)}`, 'PUT', updates);
}

// Auth Tokens (User auth tokens for Chat SDK login)
export async function createUserAuthToken(uid: string) {
  return await cometFetch(`/users/${encodeURIComponent(uid)}/auth_tokens`, 'POST');
}

export async function revokeUserAuthToken(uid: string, authToken: string) {
  return await cometFetch(`/users/${encodeURIComponent(uid)}/auth_tokens/${encodeURIComponent(authToken)}`, 'DELETE');
}


export async function sendTextMessageOnBehalfOf({ senderUid, receiver, text, receiverType }: { senderUid: string; receiver: string; text: string; receiverType: 'user' }) {
  const trimmedText = typeof text === 'string' ? text.trim() : '';
  if (!trimmedText) throw new Error('text required');
  return await cometFetch(`/messages`, 'POST', {
    receiver,
    receiverType,
    category: 'message',
    type: 'text',
    data: { text: trimmedText }
  }, { onBehalfOf: senderUid });
}


export async function sendImageMessageByUrlOnBehalfOf({ senderUid, receiver, receiverType, url, caption }: { senderUid: string; receiver: string; receiverType: 'user'; url: string; caption?: string }) {
  // Build data.attachments as per CometChat media message contract
  const trimmedUrl = typeof url === 'string' ? url.trim() : '';
  if (!trimmedUrl) {
    throw new Error('Image URL is required');
  }
  const attachmentName = caption && typeof caption === 'string' && caption.trim().length > 0 ? caption.trim() : 'image';
  const inferred = (() => {
    try {
      const u = new URL(trimmedUrl);
      const pathname = u.pathname.toLowerCase();
      if (pathname.endsWith('.png')) return { extension: 'png', mimeType: 'image/png' };
      if (pathname.endsWith('.jpg') || pathname.endsWith('.jpeg')) return { extension: 'jpg', mimeType: 'image/jpeg' };
      if (pathname.endsWith('.gif')) return { extension: 'gif', mimeType: 'image/gif' };
      return { extension: 'jpg', mimeType: 'image/jpeg' };
    } catch {
      return { extension: 'jpg', mimeType: 'image/jpeg' };
    }
  })();

  return await cometFetch(`/messages`, 'POST', {
    receiver,
    receiverType,
    category: 'message',
    type: 'image',
    data: {
      caption,
      attachments: [
        {
          name: attachmentName,
          extension: inferred.extension,
          mimeType: inferred.mimeType,
          url: trimmedUrl
        }
      ]
    }
  }, { onBehalfOf: senderUid });
}

// Fetch chat messages - Note: CometChat doesn't filter by uid properly
// Use getChatMessagesByConversation instead for better filtering
export async function getChatMessages({ uid, limit = 50, beforeId }: { uid: string; limit?: number; beforeId?: string }) {
  if (!uid) {
    throw new Error('uid is required');
  }
  
  // CometChat Messages API doesn't properly filter by uid
  // It returns all messages in the app
  // Use getChatMessagesByConversation for proper filtering
  const params = new URLSearchParams();
  if (limit) params.append('limit', String(limit));
  if (beforeId) params.append('beforeId', beforeId);
  
  const queryString = params.toString();
  const path = `/messages${queryString ? `?${queryString}` : ''}`;
  
  const allMessages = await cometFetch(path, 'GET');
  
  // Filter messages manually based on uid
  if (allMessages && (allMessages as any).data && Array.isArray((allMessages as any).data)) {
    const filteredMessages = (allMessages as any).data.filter((message: any) => {
      // Check if message is between the specified uid and any other user
      return (message.sender === uid || message.receiver === uid) && 
             message.receiverType === 'user';
    });
    
    return {
      ...allMessages,
      data: filteredMessages,
      meta: {
        ...(allMessages as any).meta,
        current: {
          ...(allMessages as any).meta?.current,
          count: filteredMessages.length
        }
      }
    };
  }
  
  return allMessages;
}

// Fetch chat messages for a specific conversation
export async function getChatMessagesByConversation({ conversationId, limit = 50, beforeId }: { conversationId: string; limit?: number; beforeId?: string }) {
  if (!conversationId) {
    throw new Error('conversationId is required');
  }
  
  const params = new URLSearchParams();
  params.append('conversationId', conversationId);
  if (limit) params.append('limit', String(limit));
  if (beforeId) params.append('beforeId', beforeId);
  
  const queryString = params.toString();
  const path = `/messages${queryString ? `?${queryString}` : ''}`;
  
  return await cometFetch(path, 'GET');
}

// 3. SQL Integration helpers
type DbUser = {
  user_id: number;
  username: string;
  password?: string; // nullable in selects that omit password
  email: string;
  image: string | null;
  role: 'user' | 'admin';
};

export type EducationLevel = 'มัธยมศึกษาต้น' | 'มัธยมศึกษาปลาย' | 'ปริญญาตรี' | 'ปริญญาโท' | 'ปริญญาเอก';

export type DbUserProfile = {
  user_id: number;
  username: string;
  displayname: string | null;
  email: string;
  image: string | null;
  about_me: string | null;
  education_level: EducationLevel | null;
  education_history: string | null;
  work_experience: string | null;
  money?: number | null; // added wallet field
};

let _dbPool: Pool | null = null;

function getDbPool(): Pool {
  if (_dbPool) return _dbPool;
  const host = process.env.DB_HOST ?? 'localhost';
  const user = process.env.DB_USER ?? 'root';
  const password = process.env.DB_PASSWORD ?? '';
  const database = process.env.DB_NAME ?? 'getworks_app';
  const port = Number(process.env.DB_PORT ?? 3306);

  // create a single shared pool for the entire process
  _dbPool = createPool({
    host,
    user,
    password,
    database,
    port,
    waitForConnections: true,
    connectionLimit: Number(process.env.DB_CONN_LIMIT ?? 10), // allow override via env
    queueLimit: 0
  });
  return _dbPool;
}

export async function getUserById(userId: number): Promise<DbUser | null> {
  const pool = getDbPool();
  const [rows] = await pool.query(
    'SELECT user_id, username, email, image, role FROM users WHERE user_id = ? LIMIT 1',
    [userId]
  );
  const list = rows as any[];
  if (!list || list.length === 0) return null;
  return list[0] as DbUser;
}

export async function getUserByUsername(username: string, withPassword = true): Promise<DbUser | null> {
  const pool = getDbPool();
  const fields = withPassword
    ? 'user_id, username, password, email, image, role'
    : 'user_id, username, email, image, role';
  const [rows] = await pool.query(
    `SELECT ${fields} FROM users WHERE username = ? LIMIT 1`,
    [username]
  );
  const list = rows as any[];
  if (!list || list.length === 0) return null;
  return list[0] as DbUser;
}

// เพิ่มฟังก์ชันสำหรับตรวจสอบ email ซ้ำ
export async function getUserByEmail(email: string): Promise<DbUser | null> {
  const pool = getDbPool();
  const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
  if (Array.isArray(rows) && rows.length > 0) {
    return rows[0] as DbUser;
  }
  return null;
}

export type CreateDbUserInput = {
  username: string;
  password: string;
  email: string;
  role?: 'user' | 'admin';
};

export async function createDbUser(input: CreateDbUserInput): Promise<DbUser> {
  const username = String(input.username).trim();
  const rawPassword = String(input.password);
  const email = String(input.email).trim();
  const role: 'user' | 'admin' = input.role ?? 'user';

  if (!username || !rawPassword || !email) {
    throw new Error('username, password, email required');
  }

  const pool = getDbPool();

  // Hash password with bcryptjs (ESM/CJS safe)
  const bcrypt = await loadBcrypt();
  const saltRounds = 10;
  const hashed = await bcrypt.hash(rawPassword, saltRounds);

  try {
    const [result] = await pool.query(
      'INSERT INTO users (username, password, email, role) VALUES (?, ?, ?, ?)',
      [username, hashed, email, role]
    );
    const insertId = (result as any)?.insertId as number;
    const created = await getUserById(insertId);
    if (!created) throw new Error('Failed to fetch created user');
    return created;
  } catch (err: any) {
    const msg = String(err?.message ?? 'Insert failed');
    // MySQL duplicate key
    if (err?.code === 'ER_DUP_ENTRY') {
      throw new Error('Username or email already exists');
    }
    throw new Error(msg);
  }
}

// Sync a DB user to CometChat (create or update)
export async function syncDbUserToCometChat(userId: number) {
  const dbUser = await getUserById(userId);
  if (!dbUser) throw new Error('User not found');

  const uid = String(userId); // map user_id as CometChat uid
  try {
    // Try get; if not exists, create
    await getChatUser(uid);
    await updateChatUser(uid, { name: dbUser.username, avatar: normalizeAvatarUrl(dbUser.image) });
  } catch (_e) {
    await createChatUser({ uid, name: dbUser.username, avatar: normalizeAvatarUrl(dbUser.image) });
  }

  return { uid, name: dbUser.username, avatar: dbUser.image };
}

// Issue CometChat user auth token by DB user_id
export async function issueAuthTokenForUserId(userId: number) {
  const dbUser = await getUserById(userId);
  if (!dbUser) throw new Error('User not found');
  const uid = String(userId);
  // Ensure user exists in CometChat first
  await syncDbUserToCometChat(userId);
  return await createUserAuthToken(uid);
}

export async function issueAuthTokenForUsernamePassword(username: string, password: string) {
  const dbUser = await getUserByUsername(username, true);
  if (!dbUser || typeof dbUser.user_id !== 'number') {
    throw new Error('Invalid credentials');
  }

  // 2) Verify password: support bcrypt hash or plaintext (dev only)
  const stored = dbUser.password ?? '';
  const isMatch = await (async () => {
    try {
      // Lazy load bcrypt with ESM/CJS interop normalization
      const bcrypt = await loadBcrypt();
      // Detect bcrypt hash roughly by prefix $2
      if (typeof stored === 'string' && stored.startsWith('$2')) {
        return await bcrypt.compare(password, stored);
      }
    } catch {}
    // Fallback to plaintext compare if bcrypt not available or not a hash
    return stored === password;
  })();

  if (!isMatch) {
    throw new Error('Invalid credentials');
  }

  // 3) Sync to CometChat and issue token
  const userId = dbUser.user_id;
  await syncDbUserToCometChat(userId);
  return await createUserAuthToken(String(userId));
}

// 4. Account/Profile helpers
export async function getUserProfile(userId: number): Promise<DbUserProfile | null> {
  const pool = getDbPool();
  const [rows] = await pool.query(
    `SELECT 
       user_id, username,
       COALESCE(displayname, NULL) AS displayname,
       email,
       COALESCE(image, NULL) AS image,
       COALESCE(about_me, NULL) AS about_me,
       COALESCE(education_level, NULL) AS education_level,
       COALESCE(education_history, NULL) AS education_history,
       COALESCE(work_experience, NULL) AS work_experience,
       COALESCE(money, 0.00) AS money
     FROM users WHERE user_id = ? LIMIT 1`,
    [userId]
  );
  const list = rows as any[];
  if (!list || list.length === 0) return null;
  return list[0] as DbUserProfile;
}

export type UpdateUserProfileInput = {
  displayname?: string | null;
  about_me?: string | null;
  education_level?: EducationLevel | null;
  education_history?: string | null;
  work_experience?: string | null;
  image?: string | null; // path or URL
};

export async function updateUserProfile(userId: number, updates: UpdateUserProfileInput): Promise<DbUserProfile> {
  const allowedLevels: EducationLevel[] = ['มัธยมศึกษาต้น', 'มัธยมศึกษาปลาย', 'ปริญญาตรี', 'ปริญญาโท', 'ปริญญาเอก'];
  const fields: string[] = [];
  const values: any[] = [];

  if (Object.prototype.hasOwnProperty.call(updates, 'displayname')) {
    const v = updates.displayname == null ? null : String(updates.displayname).trim();
    fields.push('displayname = ?');
    values.push(v && v.length > 0 ? v : null);
  }
  if (Object.prototype.hasOwnProperty.call(updates, 'about_me')) {
    const v = updates.about_me == null ? null : String(updates.about_me);
    fields.push('about_me = ?');
    values.push(v);
  }
  if (Object.prototype.hasOwnProperty.call(updates, 'education_level')) {
    const v = updates.education_level;
    if (v != null && !allowedLevels.includes(v)) {
      throw new Error('Invalid education_level');
    }
    fields.push('education_level = ?');
    values.push(v ?? null);
  }
  if (Object.prototype.hasOwnProperty.call(updates, 'education_history')) {
    const v = updates.education_history == null ? null : String(updates.education_history);
    fields.push('education_history = ?');
    values.push(v);
  }
  if (Object.prototype.hasOwnProperty.call(updates, 'work_experience')) {
    const v = updates.work_experience == null ? null : String(updates.work_experience);
    fields.push('work_experience = ?');
    values.push(v);
  }
  if (Object.prototype.hasOwnProperty.call(updates, 'image')) {
    const v = updates.image == null ? null : String(updates.image);
    fields.push('image = ?');
    values.push(v);
  }

  if (fields.length === 0) {
    // Nothing to update, just return current profile
    const current = await getUserProfile(userId);
    if (!current) throw new Error('User not found');
    return current;
  }

  const pool = getDbPool();
  values.push(userId);
  await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE user_id = ?`, values);
  const updated = await getUserProfile(userId);
  if (!updated) throw new Error('Failed to fetch updated profile');
  return updated;
}

// 4.1 Change Password
export async function changeUserPassword(input: { username?: string; email?: string; oldPassword: string; newPassword: string }): Promise<{ success: boolean }>
{
  const username = input.username && String(input.username).trim().length > 0 ? String(input.username).trim() : undefined;
  const email = input.email && String(input.email).trim().length > 0 ? String(input.email).trim() : undefined;
  const oldPassword = String(input.oldPassword ?? '');
  const newPassword = String(input.newPassword ?? '');

  if (!username || !email) throw new Error('username and email required');
  if (!oldPassword || !newPassword) throw new Error('oldPassword and newPassword required');

  const pool = getDbPool();

  // Fetch user by username or email with password
  let user: DbUser | null = null;
  const [rows] = await pool.query('SELECT user_id, username, password, email, image, role FROM users WHERE username = ? AND email = ? LIMIT 1', [username, email]);
  const list = rows as any[];
  user = list && list.length > 0 ? (list[0] as DbUser) : null;
  if (!user || typeof user.user_id !== 'number') throw new Error('User not found');

  // Verify old password
  const stored = user.password ?? '';
  const isMatch = await (async () => {
    try {
      const bcrypt = await loadBcrypt();
      if (typeof stored === 'string' && stored.startsWith('$2')) {
        return await bcrypt.compare(oldPassword, stored);
      }
    } catch {}
    return stored === oldPassword;
  })();
  if (!isMatch) throw new Error('Invalid old password');

  // Hash and update
  const bcrypt = await loadBcrypt();
  const hashed = await bcrypt.hash(newPassword, 10);
  await pool.query('UPDATE users SET password = ? WHERE user_id = ?', [hashed, user.user_id]);
  return { success: true };
}

// 5. Job Categories & Posts
export type DbJobCategory = { category_id: number; name: string; description: string | null };
// make status optional to support older schemas without the column
export type DbPost = {
  post_id: number;
  user_id: number;
  image_post: string | null;
  post_name: string;
  post_category: number | null;
  wage: number | null;
  description?: string | null;
  post_type: 'employer' | 'worker'; // เพิ่ม post_type
  status?: 'pending' | 'approved' | 'rejected';
  created_at: string;
};

// NOTE: Fixed/seeding job categories removed. Categories are managed directly
// in the `job_categories` table and should be inserted/updated via migrations
// or admin tooling. The API will only read what's present in the DB.

export async function listJobCategories(): Promise<DbJobCategory[]> {
  const pool = getDbPool();
  const [rows] = await pool.query('SELECT category_id, name, description FROM job_categories ORDER BY category_id ASC');
  return rows as DbJobCategory[];
}

// List posts with optional status filter (admin view)
export async function listJobPosts(status?: string | null): Promise<DbPost[]> {
  const pool = getDbPool();
  if (status == null) {
    const [rows] = await pool.query('SELECT * FROM posts ORDER BY created_at DESC');
    return rows as DbPost[];
  } else {
    const [rows] = await pool.query('SELECT * FROM posts WHERE status = ? ORDER BY created_at DESC', [status]);
    return rows as DbPost[];
  }
}

// Update post status (admin approve/reject)
export async function updateJobPostStatus(postId: number, status: 'pending' | 'approved' | 'rejected'): Promise<boolean> {
  const pool = getDbPool();
  const [result] = await pool.query(
    'UPDATE posts SET status = ? WHERE post_id = ?',
    [status, postId]
  );
  // result.affectedRows > 0 means update succeeded
  return (result as any)?.affectedRows > 0;
}

// Create a new job post
export type CreateJobPostInput = {
  user_id: number;
  post_name: string;
  post_category: number | null;
  wage: number | null;
  image_post: string | null;
  description: string | null;
  post_type: 'employer' | 'worker'; // เพิ่ม post_type
};

export async function createJobPost(input: CreateJobPostInput): Promise<{ post_id: number }> {
  const pool = getDbPool();
  const { user_id, post_name, post_category, wage, image_post, description, post_type } = input; // เพิ่ม post_type

  const [result] = await pool.query(
    `INSERT INTO posts (user_id, post_name, post_category, wage, image_post, description, post_type, status)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')`,
    [user_id, post_name, post_category, wage, image_post, description, post_type]
  );

  const insertId = (result as any)?.insertId;
  if (!insertId) {
    throw new Error('Failed to create job post');
  }

  return { post_id: insertId };
}

// Helper to fetch a user (without password) by username for server usage
export async function getUserPublicByUsername(username: string) {
  // reuse getUserByUsername but request without password field
  return await getUserByUsername(username, false);
}

// --- Transactions / Wallet helpers ---
export async function createTopupTransaction(user_id: number, amount: number, via = 'omise') {
  const pool = getDbPool();
  // amount expected from payment provider is in satang (integer). Store THB decimal in DB.
  const decimalAmount = Number(amount) / 100;
  const [result] = await pool.query(
    'INSERT INTO transactions (user_id, amount, type, status, via) VALUES (?, ?, ?, ?, ?)',
    [user_id, decimalAmount, 'topup', 'pending', via]
  );
  const insertId = (result as any)?.insertId as number;
  return { transaction_id: insertId };
}

export async function getTransactionById(transactionId: number) {
  const pool = getDbPool();
  const [rows] = await pool.query('SELECT * FROM transactions WHERE transaction_id = ? LIMIT 1', [transactionId]);
  const list = rows as any[];
  if (!list || list.length === 0) return null;
  return list[0];
}

export async function markTransactionCompleted(transactionId: number) {
  const pool = getDbPool();
  const [result] = await pool.query('UPDATE transactions SET status = ? WHERE transaction_id = ?', ['completed', transactionId]);
  return (result as any)?.affectedRows > 0;
}

export async function creditUserWallet(userId: number, amount: number) {
  const pool = getDbPool();
  // ensure money is not null and increment atomically
  await pool.query('UPDATE users SET money = COALESCE(money, 0) + ? WHERE user_id = ?', [amount, userId]);
}

export async function retrieveOmiseCharge(chargeId: string) {
  const publicKey = process.env.OMISE_PUBLIC_KEY;
  const secretKey = process.env.OMISE_SECRET_KEY;
  if (!publicKey || !secretKey) throw new Error('Missing OMISE_PUBLIC_KEY or OMISE_SECRET_KEY');
  const client = omise({ publicKey, secretKey });
  return await client.charges.retrieve(chargeId);
}

// Create a payout/transfer to a recipient in Omise (amount in satang)
export async function createOmisePayout(recipientId: string, amountSatang: number) {
  const secretKey = process.env.OMISE_SECRET_KEY;
  if (!secretKey) throw new Error('Missing OMISE_SECRET_KEY');
  if (!recipientId) throw new Error('recipientId required for payout');
  if (!Number.isFinite(amountSatang) || amountSatang <= 0) throw new Error('amountSatang must be a positive number');

  // Prefer using secretKey only for server-side operations
  const client = omise({ secretKey });

  const payload = { amount: Math.round(amountSatang), currency: 'thb', recipient: recipientId };

  try {
    // Most Omise SDKs expose transfers.create for account transfers
    if ((client as any).transfers && typeof (client as any).transfers.create === 'function') {
      const r = await (client as any).transfers.create(payload);
      return r;
    }

    // Some versions use payouts API
    if ((client as any).payouts && typeof (client as any).payouts.create === 'function') {
      const r = await (client as any).payouts.create(payload);
      return r;
    }

    // Fallback: use low-level request to POST /transfers
    if (typeof (client as any).request === 'function') {
      const r = await (client as any).request('post', '/transfers', payload);
      return r;
    }

    throw new Error('Omise SDK does not expose transfers/payouts API in this environment');
  } catch (err: any) {
    console.error('createOmisePayout error:', err?.message ?? err, err);
    // Normalize error for callers
    throw new Error(String(err?.message ?? err));
  }
}

// Link an external provider reference (e.g., Omise charge id) to a transaction row
export async function setTransactionExternalRef(transactionId: number, externalRef: string): Promise<boolean> {
  const pool = getDbPool();
  const [result] = await pool.query('ALTER TABLE transactions'); // noop to satisfy TS if pool isn't used
  // Try to update; if the column doesn't exist, create it first
  try {
    await pool.query('UPDATE transactions SET external_ref = ? WHERE transaction_id = ?', [externalRef, transactionId]);
    return true;
  } catch (err: any) {
    // attempt to add the column and retry
    try {
      await pool.query("ALTER TABLE transactions ADD COLUMN IF NOT EXISTS external_ref VARCHAR(255) NULL");
    } catch (e: any) {
      // Some MySQL versions do not support IF NOT EXISTS for ALTER TABLE ADD COLUMN
      try {
        await pool.query("ALTER TABLE transactions ADD COLUMN external_ref VARCHAR(255) NULL");
      } catch (_) {
        // ignore
      }
    }
    try {
      await pool.query('UPDATE transactions SET external_ref = ? WHERE transaction_id = ?', [externalRef, transactionId]);
      return true;
    } catch (e: any) {
      return false;
    }
  }
}

export async function getTransactionByExternalRef(externalRef: string) {
  const pool = getDbPool();
  const [rows] = await pool.query('SELECT * FROM transactions WHERE external_ref = ? LIMIT 1', [externalRef]);
  const list = rows as any[];
  if (!list || list.length === 0) return null;
  return list[0];
}

// --- Withdraw helpers ---
// Create a withdraw transaction (status = 'pending')
export async function createWithdrawTransaction(user_id: number, amount: number, via = 'bank') {
  const pool = getDbPool();
  // amount is expected in THB decimal
  const [result] = await pool.query(
    'INSERT INTO transactions (user_id, amount, type, status, via) VALUES (?, ?, ?, ?, ?)',
    [user_id, amount, 'withdraw', 'pending', via]
  );
  const insertId = (result as any)?.insertId ?? null;
  return { transaction_id: insertId, user_id, amount, type: 'withdraw', status: 'pending', via };
}

// Debit user's wallet. Returns true if debit succeeded (sufficient balance), false otherwise.
export async function debitUserWallet(userId: number, amount: number): Promise<boolean> {
  if (!Number.isFinite(amount) || amount <= 0) return false;
  const pool = getDbPool();
  const [result] = await pool.query('UPDATE users SET money = money - ? WHERE user_id = ? AND money >= ?', [amount, userId, amount]);
  const affected = (result as any)?.affectedRows ?? (result as any)?.changedRows ?? 0;
  return affected > 0;
}

// เพิ่ม helper สำหรับ lookup category id by name (ถ้ายังไม่มี)
export async function getCategoryIdByName(name: string): Promise<number | null> {
  const pool = getDbPool();
  const [rows] = await pool.query('SELECT category_id FROM job_categories WHERE name = ? LIMIT 1', [name]);
  if (Array.isArray(rows) && rows.length > 0) {
    return rows[0].category_id as number;
  }
  return null;
}

// --- JOB POST HELPERS เพิ่มเติม ---

// ดึงโพสต์ตาม ID
export async function getJobPostById(postId: number): Promise<DbPost | null> {
  const pool = getDbPool();
  const [rows] = await pool.query('SELECT * FROM posts WHERE post_id = ? LIMIT 1', [postId]);
  const list = rows as any[];
  if (!list || list.length === 0) return null;
  return list[0] as DbPost;
}

// ลบโพสต์งานตาม ID
export async function deleteJobPost(postId: number): Promise<boolean> {
  const pool = getDbPool();
  const [result] = await pool.query('DELETE FROM posts WHERE post_id = ?', [postId]);
  return (result as any)?.affectedRows > 0;
}

// อนุมัติโพสต์งาน (status = 'approved')
export async function approveJobPost(postId: number): Promise<boolean> {
  return await updateJobPostStatus(postId, 'approved');
}

// ปฏิเสธโพสต์งาน (status = 'rejected')
export async function rejectJobPost(postId: number): Promise<boolean> {
  return await updateJobPostStatus(postId, 'rejected');
}

// seedJobCategories: ใช้ตอนต้องการสร้าง category เริ่มต้น (optional)
export async function seedJobCategories(): Promise<void> {
  const pool = getDbPool();
  const defaults = [
    ['ทั่วไป', 'งานทั่วไป เช่น พนักงานร้านอาหาร แม่บ้าน'],
    ['IT / Programmer', 'งานสายเทคโนโลยีและโปรแกรมเมอร์'],
    ['การตลาด / ขาย', 'งานเกี่ยวกับการขายและการตลาด'],
    ['บัญชี / การเงิน', 'งานทางด้านบัญชี การเงิน'],
  ];
  for (const [name, description] of defaults) {
    await pool.query(
      'INSERT IGNORE INTO job_categories (name, description) VALUES (?, ?)',
      [name, description]
    );
  }
}

// =======================
// New: Admin user management helpers
// =======================

export type DbUserSummary = {
  user_id: number;
  username: string;
  displayname: string | null;
  email: string;
  image: string | null;
  role: string | null;
  money?: number | null;
  suspended?: number | null; // 0/1
};

/**
 * List users with optional search (matches username or displayname), pagination.
 */
export async function listUsers(options?: { search?: string | null; limit?: number; offset?: number }): Promise<DbUserSummary[]> {
  const pool = getDbPool();
  const limit = Number(options?.limit ?? 200);
  const offset = Number(options?.offset ?? 0);
  const search = options?.search ? String(options?.search).trim() : '';

  // Inspect table columns to avoid selecting non-existent columns (prevents SQL errors)
  let cols: string[] = [];
  try {
    const [colRows] = await pool.query("SHOW COLUMNS FROM users");
    cols = Array.isArray(colRows) ? (colRows as any[]).map(c => String(c.Field)) : [];
  } catch (e) {
    // If SHOW COLUMNS fails for any reason, fall back to a safe default projection
    cols = [];
  }

  const hasDisplay = cols.includes('displayname');
  const hasSuspended = cols.includes('suspended');
  const hasMoney = cols.includes('money');
  const hasImage = cols.includes('image');

  const selectParts: string[] = [
    'user_id',
    'username',
    hasDisplay ? 'displayname' : 'NULL AS displayname',
    'email',
    hasImage ? 'image' : 'NULL AS image',
    'role',
    hasMoney ? 'COALESCE(money,0) AS money' : 'NULL AS money',
    hasSuspended ? 'COALESCE(suspended,0) AS suspended' : '0 AS suspended'
  ];

  const selectSql = selectParts.join(', ');

  // Build WHERE clause components safely
  const whereClauses: string[] = [`role = 'user'`];
  const params: any[] = [];

  if (search && search.length > 0) {
    // If displayname doesn't exist, only search username
    if (hasDisplay) {
      whereClauses.push('(username LIKE ? OR displayname LIKE ?)');
      const q = `%${search}%`;
      params.push(q, q);
    } else {
      whereClauses.push('(username LIKE ?)');
      params.push(`%${search}%`);
    }
  }

  const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

  // Final SQL with limit/offset
  const sql = `SELECT ${selectSql} FROM users ${whereSql} ORDER BY user_id DESC LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  try {
    const [rows] = await pool.query(sql, params);
    // Normalize result to DbUserSummary[] (TS narrowing)
    return (rows as any[])?.map(r => ({
      user_id: Number(r.user_id),
      username: r.username,
      displayname: r.displayname ?? null,
      email: r.email,
      image: r.image ?? null,
      role: r.role ?? null,
      money: typeof r.money !== 'undefined' ? r.money : null,
      suspended: typeof r.suspended !== 'undefined' ? Number(r.suspended) : 0
    })) as DbUserSummary[];
  } catch (err: any) {
    // bubble up error to caller (server route will log). Provide helpful message.
    throw new Error(`DB error listing users: ${String(err?.message ?? err)}`);
  }
}

/**
 * Set suspended flag for a user. If the `suspended` column doesn't exist,
 * attempt to add it (best-effort). Returns true when update affected a row.
 */
export async function setUserSuspended(userId: number, suspended: boolean): Promise<boolean> {
  const pool = getDbPool();
  const s = suspended ? 1 : 0;

  try {
    const [result] = await pool.query('UPDATE users SET suspended = ? WHERE user_id = ?', [s, userId]);
    if ((result as any)?.affectedRows > 0) return true;
    return false;
  } catch (err: any) {
    // If column missing, try to add it and retry
    try {
      // Try with IF NOT EXISTS first (some MySQL variants support it)
      await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS suspended TINYINT(1) DEFAULT 0");
    } catch (_) {
      // Fallback try without IF NOT EXISTS; ignore failures
      try { await pool.query("ALTER TABLE users ADD COLUMN suspended TINYINT(1) DEFAULT 0"); } catch (_) {}
    }
    try {
      const [result2] = await pool.query('UPDATE users SET suspended = ? WHERE user_id = ?', [s, userId]);
      return (result2 as any)?.affectedRows > 0;
    } catch (_) {
      return false;
    }
  }
}

// --- Transaction helpers ---
export type DbTransaction = {
  transaction_id: number;
  user_id: number;
  amount: number;
  type: string;
  status: string;
  via?: string | null;
  external_ref?: string | null;
  created_at: string;
};

/**
 * List transactions with optional filters:
 *  - type: 'topup' | 'withdraw' | 'payment'
 *  - status: 'pending' | 'completed' | 'failed' etc.
 *  - user_id: number (optional)
 *  - limit, offset: pagination
 */
export async function listTransactions(options?: { type?: string | null; status?: string | null; user_id?: number | null; limit?: number; offset?: number }): Promise<DbTransaction[]> {
  const pool = getDbPool();
  const limit = Math.max(1, Math.min(1000, Number(options?.limit ?? 200)));
  const offset = Math.max(0, Number(options?.offset ?? 0));
  const type = options?.type ? String(options.type).trim() : undefined;
  const status = options?.status ? String(options.status).trim() : undefined;
  const userId = options?.user_id != null && Number.isFinite(Number(options.user_id)) ? Number(options.user_id) : undefined;

  // Inspect columns to avoid selecting non-existing columns
  let cols: string[] = [];
  try {
    const [colRows] = await pool.query("SHOW COLUMNS FROM transactions");
    cols = Array.isArray(colRows) ? (colRows as any[]).map(c => String(c.Field)) : [];
  } catch (e) {
    cols = [];
  }
  const hasExternal = cols.includes('external_ref');
  const hasVia = cols.includes('via');

  const selectParts = [
    'transaction_id',
    'user_id',
    'amount',
    'type',
    'status',
    hasVia ? 'via' : 'NULL AS via',
    hasExternal ? 'external_ref' : 'NULL AS external_ref',
    'created_at'
  ];
  const selectSql = selectParts.join(', ');

  const where: string[] = [];
  const params: any[] = [];

  if (type) {
    where.push('type = ?');
    params.push(type);
  }
  if (status) {
    where.push('status = ?');
    params.push(status);
  }
  if (userId != null) {
    where.push('user_id = ?');
    params.push(userId);
  }

  const whereSql = where.length > 0 ? `WHERE ${where.join(' AND ')}` : '';

  const sql = `SELECT ${selectSql} FROM transactions ${whereSql} ORDER BY transaction_id DESC LIMIT ? OFFSET ?`;
  params.push(limit, offset);

  try {
    const [rows] = await pool.query(sql, params);
    return (rows as any[]).map(r => ({
      transaction_id: Number(r.transaction_id),
      user_id: Number(r.user_id),
      amount: Number(r.amount),
      type: String(r.type),
      status: String(r.status),
      via: r.via ?? null,
      external_ref: r.external_ref ?? null,
      created_at: r.created_at ? String(r.created_at) : ''
    })) as DbTransaction[];
  } catch (err: any) {
    throw new Error(`DB error listing transactions: ${String(err?.message ?? err)}`);
  }
}

// --- JOB DETAILS & ESCROW helpers (new) ---
export type CreateJobDetailInput = {
  post_id: number;
  detail?: string | null;
  deadline?: string | Date | null; // ISO date string or Date
  image?: string | null;
  contact?: string | null;
};

export async function createJobDetail(input: CreateJobDetailInput): Promise<{ job_id: number }> {
  const pool = getDbPool();
  const postId = Number(input.post_id);
  if (!Number.isFinite(postId)) throw new Error('post_id required');

  // Normalize values
  const detail = input.detail == null ? null : String(input.detail);
  let deadlineVal: string | null = null;
  if (input.deadline != null && String(input.deadline).trim() !== '') {
    const d = new Date(String(input.deadline));
    if (isNaN(d.getTime())) throw new Error('deadline invalid date');
    // Store as YYYY-MM-DD
    deadlineVal = d.toISOString().slice(0, 10);
  }
  const image = input.image == null ? null : String(input.image);
  const contact = input.contact == null ? null : String(input.contact);

  // Insert job detail (map status to DB enum; use 'waiting' by default)
  const [result] = await pool.query(
    // note: DB enum for job_details.status = ('waiting','in_progress','completed')
    'INSERT INTO job_details (post_id, detail, deadline, image, contact, status) VALUES (?, ?, ?, ?, ?, ?)',
    [postId, detail, deadlineVal, image, contact, 'waiting']
  );

  const insertId = (result as any)?.insertId as number | undefined;
  if (!insertId) throw new Error('Failed to create job detail');
  return { job_id: insertId };
}

// Minimal escrow creation helper used by server routes.
// Best-effort insertion into `escrow_payments` table.
export type CreateEscrowInput = {
  escrow_id: string;
  employer_id: number;
  worker_id: number;
  job_id: number;
  amount: number; // THB decimal
  description?: string | null;
  status?: string | null;
};

export async function createEscrowPayment(input: CreateEscrowInput): Promise<{ escrow_id: string }> {
  const pool = getDbPool();
  if (!input || !input.escrow_id) throw new Error('escrow_id required');
  const escrowId = String(input.escrow_id);
  const employerId = Number(input.employer_id);
  const workerId = Number(input.worker_id);
  const jobId = Number(input.job_id);
  const amount = Number(input.amount);
  if (!Number.isFinite(employerId) || !Number.isFinite(workerId) || !Number.isFinite(jobId) || !Number.isFinite(amount)) {
    throw new Error('invalid escrow input');
  }
  const description = input.description ?? null;
  const status = input.status ?? 'held';

  try {
    const [result] = await pool.query(
      `INSERT INTO escrow_payments (escrow_id, employer_id, worker_id, job_id, amount, description, status)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [escrowId, employerId, workerId, jobId, amount, description, status]
    );
    const inserted = (result as any)?.insertId;
    if (!inserted) throw new Error('Failed to create escrow payment');
    return { escrow_id: escrowId };
  } catch (err: any) {
    // If table or column doesn't exist, surface a readable error
    throw new Error(String(err?.message ?? 'Failed to create escrow payment'));
  }
}

/**
 * Mark user online/offline. Best-effort: if columns don't exist, attempt to add them.
 * - online: TINYINT(1) 0/1
 * - last_logout: DATETIME (set when going offline)
 */
export async function setUserOnline(userId: number, online: boolean): Promise<boolean> {
  const pool = getDbPool();
  const uid = Number(userId);
  if (!Number.isFinite(uid)) return false;
  const s = online ? 1 : 0;

  try {
    if (online) {
      const [r] = await pool.query('UPDATE users SET online = ? WHERE user_id = ?', [s, uid]);
      return ((r as any)?.affectedRows ?? 0) > 0;
    } else {
      const [r] = await pool.query('UPDATE users SET online = ?, last_logout = NOW() WHERE user_id = ?', [s, uid]);
      return ((r as any)?.affectedRows ?? 0) > 0;
    }
  } catch (err: any) {
    // Try to add missing columns and retry (best-effort)
    try {
      await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS online TINYINT(1) DEFAULT 0");
    } catch (_) {
      try { await pool.query("ALTER TABLE users ADD COLUMN online TINYINT(1) DEFAULT 0"); } catch (_) {}
    }
    try {
      await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS last_logout DATETIME NULL");
    } catch (_) {
      try { await pool.query("ALTER TABLE users ADD COLUMN last_logout DATETIME NULL"); } catch (_) {}
    }

    try {
      if (online) {
        const [r2] = await pool.query('UPDATE users SET online = ? WHERE user_id = ?', [s, uid]);
        return ((r2 as any)?.affectedRows ?? 0) > 0;
      } else {
        const [r2] = await pool.query('UPDATE users SET online = ?, last_logout = NOW() WHERE user_id = ?', [s, uid]);
        return ((r2 as any)?.affectedRows ?? 0) > 0;
      }
    } catch (_) {
      return false;
    }
  }
}

// ======================
// Notifications helpers
// ======================

export type DbNotification = {
  notification_id: number;
  user_id: number;
  message: string;
  is_read: number; // stored as 0/1 in DB
  created_at: string;
};

// Extended notification shape returned to the mobile client. Includes
// job-related fields when the notification maps to a job_details row.
export type NotificationItem = DbNotification & {
  job_id?: number;
  deadline?: string;
  image?: string;
  contact?: string;
};

/**
 * List notifications for a given DB user id, ordered newest first.
 */
export async function listNotifications(userId: number): Promise<NotificationItem[]> {
  const pool = getDbPool();
  // Return recent job_details that target posts owned by this user (freelancer)
  // Map job_details -> notification-like shape so frontend can reuse same contract.
  // Fields:
  //  - notification_id: job_id
  //  - user_id: owner (posts.user_id)
  //  - message: detail (job_details.detail)
  //  - is_read: always 0 (no read-tracking in job_details)
  //  - created_at: use job_details.created_at if present, otherwise NULL

  // We attempt to select created_at from job_details; if column doesn't exist in this DB,
  // the query will still work if we alias an empty string via COALESCE(job_details.created_at, '')
  const sql = `
    SELECT jd.job_id AS notification_id,
           jd.job_id AS job_id,
           p.user_id AS user_id,
           COALESCE(jd.detail, '') AS message,
           COALESCE(CAST(jd.deadline AS CHAR), '') AS deadline,
           COALESCE(jd.image, '') AS image,
           COALESCE(jd.contact, '') AS contact,
           0 AS is_read,
           COALESCE(CAST(jd.created_at AS CHAR), '') AS created_at
    FROM job_details jd
    JOIN posts p ON p.post_id = jd.post_id
    WHERE p.user_id = ?
    ORDER BY COALESCE(jd.created_at, jd.job_id) DESC
    LIMIT 200
  `;
  const [rows] = await pool.query(sql, [userId]);
  return (rows as any) as DbNotification[];
}

/**
 * Accept a job detail: mark status = 'in_progress'. Returns true when updated.
 */
export async function acceptJobDetail(jobId: number): Promise<boolean> {
  const pool = getDbPool();
  const [result] = await pool.query('UPDATE job_details SET status = ? WHERE job_id = ?', ['in_progress', jobId]);
  const affected = (result as any).affectedRows as number;
  return affected > 0;
}

/**
 * Reject a job detail: mark status = 'rejected'. Returns true when updated.
 */
export async function rejectJobDetail(jobId: number): Promise<boolean> {
  const pool = getDbPool();
  const [result] = await pool.query('UPDATE job_details SET status = ? WHERE job_id = ?', ['rejected', jobId]);
  const affected = (result as any).affectedRows as number;
  return affected > 0;
}

/**
 * Create a notification for a user. Returns inserted id.
 */
export async function createNotification(userId: number, message: string): Promise<{ notification_id: number }> {
  const pool = getDbPool();
  const [result] = await pool.query('INSERT INTO notifications (user_id, message, is_read, created_at) VALUES (?, ?, 0, CURRENT_TIMESTAMP)', [userId, message]);
  const insertId = (result as any).insertId as number;
  return { notification_id: insertId };
}

/**
 * Mark a notification as read (is_read = 1). Returns true if updated.
 */
export async function markNotificationRead(notificationId: number): Promise<boolean> {
  const pool = getDbPool();
  const [result] = await pool.query('UPDATE notifications SET is_read = 1 WHERE notification_id = ?', [notificationId]);
  const affected = (result as any).affectedRows as number;
  return affected > 0;
}
