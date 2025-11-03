"use client"

import styles from "./page.module.css"
import React, { useState, useEffect, useRef } from "react"

type UserRow = {
	user_id: number;
	username: string;
	displayname: string | null;
	email: string;
	image: string | null;
	role: string | null;
	money?: number | null;
	suspended?: number | null; // 0/1
}

export default function AccountUserPage() {
	const [search, setSearch] = useState("")
	const [adminName, setAdminName] = useState<string | null>(null)

	// New: users state, loading and error
	const [users, setUsers] = useState<UserRow[]>([])
	const [loading, setLoading] = useState(false)
	const [error, setError] = useState<string | null>(null)
	// search debounce ref
	const searchRef = useRef<number | null>(null)

	// api base ref (do NOT compute using window during render)
	const apiBaseRef = useRef<string | null>(null);

	// safe helper to compute default API base without throwing on server
	const getApiBase = () => {
		try {
			const env = (process.env.NEXT_PUBLIC_API_BASE ?? '').toString().trim();
			if (env) return env.replace(/\/$/, '');
		} catch (_) {}
		// if window is not available (SSR), return a safe default
		if (typeof window === 'undefined') return 'http://localhost:4000';
		// client runtime: build base from current origin but default to port 4000
		try {
			const { protocol, hostname } = window.location;
			return `${protocol}//${hostname}:4000`;
		} catch (_) {
			return 'http://localhost:4000';
		}
	};

	useEffect(() => {
		try { const n = localStorage.getItem('admin_username'); if (n) setAdminName(n) } catch (_) {}

		// initialize api base on client and perform initial load (client-only)
		if (apiBaseRef.current === null) {
			apiBaseRef.current = getApiBase();
		}
		fetchUsers();
		// eslint-disable-next-line react-hooks/exhaustive-deps
	}, [])

	// debounce search
	useEffect(() => {
		if (searchRef.current) window.clearTimeout(searchRef.current)
		searchRef.current = window.setTimeout(() => {
			fetchUsers();
		}, 350) as unknown as number
		// cleanup
		return () => { if (searchRef.current) window.clearTimeout(searchRef.current) }
	}, [search])

	const getAuthHeaders = () => {
		const headers: Record<string,string> = { 'content-type': 'application/json' }
		try {
			const token = localStorage.getItem('admin_token')
			if (token) headers['authorization'] = `Bearer ${token}`
		} catch (_) {}
		return headers
	}

	const buildPublicUrl = (img: string | null | undefined) => {
		if (!img) return ''
		const s = String(img)
		if (s.startsWith('http://') || s.startsWith('https://')) return s
		if (typeof window === 'undefined') return s // fallback during SSR (shouldn't be used)
		if (s.startsWith('/')) return `${window.location.origin}${s}`
		return `${window.location.origin}/${s}`
	}

	async function fetchUsers() {
		setLoading(true); setError(null)
		try {
			const params = new URLSearchParams()
			if (search && search.trim().length > 0) params.set('search', search.trim())
			params.set('limit', '200')
			const base = apiBaseRef.current ?? getApiBase()
			const url = `${base}/admin/users?${params.toString()}`
			const res = await fetch(url, { headers: getAuthHeaders() })
			if (!res.ok) throw new Error(`Server ${res.status}`)
			const body = await res.json()
			// backend returns { data: users }
			const data: UserRow[] = Array.isArray(body?.data) ? body.data : (Array.isArray(body) ? body : [])
			setUsers(data)
		} catch (err: any) {
			console.error('fetchUsers error', err)
			setError(err?.message ?? 'Failed to load users')
		} finally {
			setLoading(false)
		}
	}

	const go = (path: string) => { window.location.href = path }
	const handleLogout = () => {
		try { localStorage.removeItem('admin_token'); localStorage.removeItem('admin_username') } catch (_) {}
		window.location.href = '/admin/login'
	}

	// toggle suspend state
	const toggleSuspend = async (u: UserRow) => {
		const target = !(Number(u.suspended ?? 0) === 1)
		try {
			const base = apiBaseRef.current ?? getApiBase()
			const res = await fetch(`${base}/admin/users/${u.user_id}/suspend`, {
				method: 'POST',
				headers: getAuthHeaders(),
				body: JSON.stringify({ suspended: target })
			})
			if (!res.ok) {
				const txt = await res.text()
				throw new Error(txt || `Status ${res.status}`)
			}
			// optimistic update
			setUsers(prev => prev.map(p => p.user_id === u.user_id ? { ...p, suspended: target ? 1 : 0 } : p))
		} catch (err: any) {
			console.error('suspend error', err)
			alert('ไม่สามารถเปลี่ยนสถานะบัญชีได้: ' + (err?.message ?? 'error'))
		}
	}

	return (
		<div className={styles.pageWrap}>
			<header className={styles.topbar}>
				<div className={styles.logo}>Get Work!</div>
				<nav className={styles.nav}>
					<button className={styles.navItem} onClick={() => go('/admin/manage_posts')}>จัดการโพสต์</button>
					<button className={`${styles.navItem} ${styles.navItemActive}`} onClick={() => go('/admin/account_user')}>บัญชีผู้ใช้</button>
					<button className={styles.navItem} onClick={() => go('/admin/finance')}>ระบบการเงิน</button>
				</nav>
				<div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
					{adminName && <div style={{ color: '#173F4E' }}>{adminName}</div>}
					<button className={styles.logoutBtn} onClick={handleLogout}>ออกจากระบบ</button>
				</div>
			</header>

			<main className={styles.container}>
				<div className={styles.pageTitle}>บัญชีผู้ใช้</div>
				<div className={styles.searchBox}>
					<input
						className={styles.searchInput}
						placeholder="ค้นหารายชื่อ"
						value={search}
						onChange={e => setSearch(e.target.value)}
					/>
				</div>

				{loading && <div>กำลังโหลด...</div>}
				{error && <div style={{ color: 'red' }}>{error}</div>}

				<div className={styles.tableWrap}>
					<table className={styles.table}>
						<thead className={styles.thead}>
							<tr>
								<th className={styles.th}>รายชื่อผู้ใช้งาน</th>
								<th className={styles.th}>ข้อมูลบัญชี</th>
								<th className={styles.th}>ระงับบัญชี</th>
							</tr>
						</thead>
						<tbody>
							{users.length === 0 && !loading ? (
								<tr><td colSpan={3} className={styles.td}>ไม่พบผู้ใช้งาน</td></tr>
							) : users.map((user) => (
								<tr key={user.user_id}>
									<td className={styles.td}>
										<div className={styles.userCell}>
											{user.image ? (
												<img src={buildPublicUrl(user.image)} alt="avatar" style={{ width:32, height:32, borderRadius:16, objectFit:'cover', marginRight:8 }} />
											) : (
												<span className={styles.avatar}></span>
											)}
											<div>
												<div style={{ fontWeight: 600 }}>{user.displayname ?? user.username}</div>
												<div style={{ fontSize: 12, color: '#666' }}>{user.email}</div>
											</div>
										</div>
									</td>
									<td className={styles.td}>
										<button className={styles.btnCheck} onClick={() => go(`/admin/account_user/check_user?user_id=${user.user_id}`)}>ตรวจสอบข้อมูล</button>
									</td>
									<td className={styles.td}>
										<button
											className={styles.btnBan}
											onClick={() => toggleSuspend(user)}
											style={{ background: (Number(user.suspended ?? 0) === 1) ? '#c0392b' : undefined }}
										>
											{Number(user.suspended ?? 0) === 1 ? 'ยกเลิกระงับ' : 'ระงับบัญชี'}
										</button>
									</td>
								</tr>
							))}
						</tbody>
					</table>
				</div>
			</main>
		</div>
	)
}
