"use client"

import styles from "./page.module.css"
import React, { useEffect, useState } from "react"

export default function CheckUserPage() {
	const [loading, setLoading] = useState(false)
	const [error, setError] = useState<string | null>(null)
	const [success, setSuccess] = useState<string | null>(null)

	// profile state
	type Profile = {
		user_id: number;
		username: string;
		displayname?: string | null;
		email: string;
		image?: string | null;
		about_me?: string | null;
		education_level?: string | null;
		education_history?: string | null;
		work_experience?: string | null;
		money?: number | null;
		suspended?: number | null;
	}
	const [profile, setProfile] = useState<Profile | null>(null)

	function getApiBase() {
		if (typeof window !== 'undefined' && (window as any).__API_BASE) return String((window as any).__API_BASE);
		return (process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:4000');
	}

	// read user_id from query string ?user_id=123
	function getUserIdFromQuery() {
		try {
			const s = typeof window !== 'undefined' ? window.location.search : '';
			const params = new URLSearchParams(s);
			const v = params.get('user_id') ?? params.get('uid') ?? '';
			const n = Number(v);
			return Number.isFinite(n) ? n : null;
		} catch {
			return null;
		}
	}

	useEffect(() => {
		const id = getUserIdFromQuery();
		if (!id) {
			setError('user_id missing in query string');
			return;
		}
		const apiBase = getApiBase();
		let mounted = true;
		;(async () => {
			setLoading(true); setError(null);
			try {
				const res = await fetch(`${apiBase}/admin/users/${id}`);
				if (!res.ok) throw new Error(`API error ${res.status}`);
				const json = await res.json();
				let data = json?.data ?? json;
				// normalize numeric money field (may come as string/null)
				const rawMoney = data?.money ?? data?.amount ?? 0;
				const parsedMoney = Number(rawMoney);
				data = { ...(data ?? {}), money: Number.isFinite(parsedMoney) ? parsedMoney : 0 };
				if (mounted) setProfile(data);
			} catch (e: any) {
				if (mounted) setError(String(e?.message ?? e));
			} finally {
				if (mounted) setLoading(false);
			}
		})();
		return () => { mounted = false };
	}, [])

	// handlers
	const goBack = () => { window.location.href = '/admin/account_user' }

	const onChange = (k: keyof Profile, v: any) => {
		setProfile(prev => prev ? ({ ...prev, [k]: v }) : prev);
	}

	const saveProfile = async () => {
		if (!profile) return;
		setLoading(true); setError(null); setSuccess(null);
		try {
			const apiBase = getApiBase();
			const payload = {
				user_id: profile.user_id,
				displayname: profile.displayname ?? null,
				about_me: profile.about_me ?? null,
				education_level: profile.education_level ?? null,
				education_history: profile.education_history ?? null,
				work_experience: profile.work_experience ?? null,
			};
			const res = await fetch(`${apiBase}/account/profile`, {
				method: 'PUT',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify(payload)
			});
			if (!res.ok) {
				const txt = await res.text();
				throw new Error(`Save failed: ${res.status} ${txt}`);
			}
			const json = await res.json();
			// server may return updated profile object; preserve suspended and normalize money
			const returned = json ?? {};
			const merged = {
				...profile,
				...returned,
				money: (() => {
					const raw = returned?.money ?? profile.money ?? 0;
					const n = Number(raw);
					return Number.isFinite(n) ? n : 0;
				})(),
				suspended: typeof returned?.suspended !== 'undefined' ? returned.suspended : profile.suspended
			};
			setProfile(merged);
			setSuccess('บันทึกเรียบร้อย');
		} catch (e: any) {
			setError(String(e?.message ?? e));
		} finally { setLoading(false) }
	}

	const toggleSuspend = async () => {
		if (!profile) return;
		const id = profile.user_id;
		const want = !(profile.suspended && Number(profile.suspended) === 1);
		setLoading(true); setError(null); setSuccess(null);
		try {
			const apiBase = getApiBase();
			const res = await fetch(`${apiBase}/admin/users/${id}/suspend`, {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify({ suspended: want })
			});
			if (!res.ok) {
				const txt = await res.text();
				throw new Error(`Suspend failed: ${res.status} ${txt}`);
			}
			const json = await res.json();
			// update local state
			setProfile(p => p ? ({ ...p, suspended: want ? 1 : 0 }) : p);
			setSuccess(want ? 'ระงับผู้ใช้เรียบร้อย' : 'ยกเลิกการระงับเรียบร้อย');
		} catch (e: any) {
			setError(String(e?.message ?? e));
		} finally { setLoading(false) }
	}

	// render
	return (
		<div className={styles.pageWrap}>
			<header className={styles.topbar}>
				<div className={styles.logo}>Get Work!</div>
				<nav className={styles.nav}>
					<button className={styles.navItem}>จัดการโพสต์</button>
					<button className={`${styles.navItem} ${styles.navItemActive}`}>บัญชีผู้ใช้</button>
					<button className={styles.navItem}>ระบบการเงิน</button>
					<button className={styles.navItem}>รายงานปัญหา</button>
				</nav>
				<button className={styles.logoutBtn}>ออกจากระบบ</button>
			</header>

			<main className={styles.container}>
				<button className={styles.backBtn} onClick={goBack}>ย้อนกลับ</button>

				{loading ? <div>กำลังโหลด...</div> : null}
				{error ? <div style={{ color: 'red' }}>{error}</div> : null}
				{success ? <div style={{ color: 'green' }}>{success}</div> : null}

				{profile ? (
					<form className={styles.formWrap} onSubmit={(e) => { e.preventDefault(); saveProfile(); }}>
						<div className={styles.imgBox}>
							{profile.image ? <img src={profile.image.startsWith('http') ? profile.image : (getApiBase().replace(/\/$/, '') + profile.image)} alt="avatar" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : 'รูปโปรไฟล์'}
						</div>

						<div className={styles.label}>ชื่อผู้ใช้งาน</div>
						<input className={styles.input} value={profile.displayname ?? profile.username} onChange={e => onChange('displayname', e.target.value)} />

						<div className={styles.label}>ชื่อผู้ใช้ (username)</div>
						<input className={styles.input} value={profile.username} readOnly />

						<div className={styles.label}>อีเมล</div>
						<input className={styles.input} value={profile.email} readOnly />

						<div className={styles.sectionTitle}>การศึกษา</div>
						<select className={styles.input} value={profile.education_level ?? ''} onChange={e => onChange('education_level', e.target.value || null)}>
							<option value="">- ระดับการศึกษา -</option>
							<option value="มัธยมศึกษาต้น">มัธยมศึกษาต้น</option>
							<option value="มัธยมศึกษาปลาย">มัธยมศึกษาปลาย</option>
							<option value="ปริญญาตรี">ปริญญาตรี</option>
							<option value="ปริญญาโท">ปริญญาโท</option>
							<option value="ปริญญาเอก">ปริญญาเอก</option>
						</select>
						<textarea className={styles.textarea} placeholder="ประวัติการศึกษา" value={profile.education_history ?? ''} onChange={e => onChange('education_history', e.target.value)} />

						<div className={styles.sectionTitle}>ประสบการณ์ทำงาน</div>
						<textarea className={styles.textarea} placeholder="ประสบการณ์ทำงาน" value={profile.work_experience ?? ''} onChange={e => onChange('work_experience', e.target.value)} />

						<div style={{ marginTop: 12 }}>
							<div>ยอดเงิน: {Number(profile.money ?? 0).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })} THB</div>
							<div>สถานะ: {profile.suspended && Number(profile.suspended) === 1 ? 'ระงับ' : 'ปกติ'}</div>
						</div>

						<div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
							<button type="button" className={styles.navItem} onClick={saveProfile} disabled={loading}>บันทึก</button>
							<button type="button" className={styles.navItem} onClick={toggleSuspend} disabled={loading}>
								{profile.suspended && Number(profile.suspended) === 1 ? 'ยกเลิกการระงับ' : 'ระงับผู้ใช้'}
							</button>
						</div>
					</form>
				) : null}
			</main>
		</div>
	)
}
