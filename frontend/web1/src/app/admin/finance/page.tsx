"use client"

import React, { useEffect, useState } from "react"
import styles from "./page.module.css"

export default function FinancePage(){
	const [adminName, setAdminName] = useState<string | null>(null)
	// new: transactions from API
	type TxRow = {
		transaction_id: number;
		user_id: number;
		username: string;
		typeLabel: 'เติม' | 'ถอน' | string;
		amount: number;
		rawType: string;
		created_at?: string;
	}
	const [rows, setRows] = useState<TxRow[]>([])
	const [loading, setLoading] = useState(false)
	const [error, setError] = useState<string | null>(null)

	// determine backend API base (use NEXT_PUBLIC_API_BASE if set, otherwise derive from window or fallback)
	function getApiBase() {
		try {
			const env = (process.env.NEXT_PUBLIC_API_BASE ?? '').toString().trim();
			if (env) return env.replace(/\/$/, '');
		} catch (_) {}
		// server-side / SSR fallback
		if (typeof window === 'undefined') return 'http://localhost:4000';
		// client runtime: prefer same host with port 4000 if no env provided
		try {
			const { protocol, hostname } = window.location;
			// if backend runs on same host but default port 4000
			return `${protocol}//${hostname}:4000`;
		} catch (_) {
			return 'http://localhost:4000';
		}
	}

	useEffect(() => {
		try { const n = localStorage.getItem('admin_username'); if (n) setAdminName(n) } catch (_) {}
	}, [])
	// fetch transactions + user list and map them
	useEffect(() => {
		let mounted = true
		;(async () => {
			setLoading(true); setError(null)
			try {
				const apiBase = getApiBase()
				const res = await fetch(`${apiBase}/admin/transactions`)
				if (!res.ok) throw new Error(`API error ${res.status}`)
				const json = await res.json()
				const data = Array.isArray(json) ? json : (Array.isArray(json.data) ? json.data : [])

				// filter only topup/withdraw
				const txs = (data as any[]).filter(t => t && (t.type === 'topup' || t.type === 'withdraw'))

				// get users to map user_id -> name
				let userMap = new Map<string, string>()
				try {
					const ures = await fetch(`${apiBase}/chat/users`)
					if (ures.ok) {
						const ujson = await ures.json()
						const users = Array.isArray(ujson) ? ujson : (Array.isArray(ujson.data) ? ujson.data : [])
						for (const u of users as any[]) {
							if (u && u.uid != null) userMap.set(String(u.uid), String(u.name ?? `ผู้ใช้ ${u.uid}`))
						}
					}
				} catch (_) { /* ignore user list failure */ }

				const mapped: TxRow[] = txs.map(t => ({
					transaction_id: Number(t.transaction_id ?? t.id ?? 0),
					user_id: Number(t.user_id ?? 0),
					username: userMap.get(String(t.user_id)) ?? `ผู้ใช้ ${t.user_id}`,
					typeLabel: t.type === 'topup' ? 'เติม' : (t.type === 'withdraw' ? 'ถอน' : String(t.type)),
					amount: Number(t.amount ?? 0),
					rawType: String(t.type ?? ''),
					created_at: t.created_at ?? t.createdAt ?? ''
				}))

				if (mounted) setRows(mapped)
			} catch (e: any) {
				if (mounted) setError(String(e?.message ?? e))
			} finally {
				if (mounted) setLoading(false)
			}
		})()
		return () => { mounted = false }
	}, [])

	const go = (path: string) => { window.location.href = path }
	const handleLogout = () => {
		try { localStorage.removeItem('admin_token'); localStorage.removeItem('admin_username') } catch (_) {}
		window.location.href = '/admin/login'
	}

	return (
		<div className={styles.pageWrap}>
			<header className={styles.topbar}>
				<div className={styles.logo}>Get Work!</div>
				<nav className={styles.nav}>
					<button className={styles.navItem} onClick={() => go('/admin/manage_posts')}>จัดการโพสต์</button>
					<button className={styles.navItem} onClick={() => go('/admin/account_user')}>บัญชีผู้ใช้</button>
					<button className={`${styles.navItem} ${styles.navItemActive}`} onClick={() => go('/admin/finance')}>ระบบการเงิน</button>
				</nav>
				<div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
					{adminName && <div style={{ color: '#173F4E' }}>{adminName}</div>}
					<button className={styles.logoutBtn} onClick={handleLogout}>ออกจากระบบ</button>
				</div>
			</header>

			<main className={styles.container}>
				<div className={styles.tableWrap}>
					{loading ? <div>กำลังโหลด...</div> : null}
					{error ? <div style={{ color: 'red' }}>{error}</div> : null}
					<table className={styles.table}>
						<thead className={styles.thead}>
							<tr>
								<th className={styles.th}>รายชื่อผู้ใช้งาน</th>
								<th className={styles.th}>เติม/ถอน</th>
								<th className={styles.th}>จำนวนเงิน</th>
							</tr>
						</thead>
						<tbody>
							{rows.map((r) => (
								<tr key={r.transaction_id}>
									<td className={styles.td}>
										<div className={styles.userCell}>
											<span className={styles.avatar}></span>
											{r.username}
										</div>
									</td>
									<td className={styles.td}>
										<div className={`${styles.status} ${r.typeLabel === 'เติม' ? styles.statusTopUp : r.typeLabel === 'ถอน' ? styles.statusWithdraw : styles.statusDeposit}`}>
											{r.typeLabel}
										</div>
									</td>
									<td className={styles.td} style={{textAlign:'right'}}>
										<span className={r.rawType === 'withdraw' ? styles.amountNegative : styles.amount}>
											{Number(r.amount).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
										</span>
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

