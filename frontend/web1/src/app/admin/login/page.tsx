"use client"

import React, { useState } from "react"
import styles from "./page.module.css"

export default function AdminLoginPage() {
	const [username, setUsername] = useState("")
	const [password, setPassword] = useState("")
	const [showPassword, setShowPassword] = useState(false)
	const [loading, setLoading] = useState(false)
	const [error, setError] = useState<string | null>(null)

	// backend base URL (set NEXT_PUBLIC_API_BASE in .env.local for dev/production)
	const apiBase = (process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:4000').replace(/\/+$/, '');

	const submit = async (e: React.FormEvent) => {
		e.preventDefault()
		setError(null)
		setLoading(true)
		try {
			const res = await fetch(`${apiBase}/auth/admin/login`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ username, password })
			})

			// Safely parse response: prefer JSON, but fallback to text if response isn't JSON
			let data: any = null
			const contentType = res.headers.get('content-type') || ''
			if (contentType.includes('application/json')) {
				try {
					data = await res.json()
				} catch (err) {
					// parsing failed despite header: fallback to text
					const txt = await res.text()
					if (!res.ok) {
						setError(txt || `Login failed (${res.status})`)
						return
					}
					setError('Unexpected response format from server')
					return
				}
			} else {
				// not JSON: read text to show a clearer error message
				const txt = await res.text()
				if (!res.ok) {
					// Show truncated text to avoid huge HTML dump in UI
					setError((txt && txt.length > 300) ? `${txt.slice(0,300)}...` : (txt || `Login failed (${res.status})`))
					return
				}
				// success but non-JSON body — treat as unexpected
				setError('Unexpected non-JSON response from server')
				return
			}

			if (!res.ok) {
				setError(data?.error || `Login failed (${res.status})`)
				return
			}

			// Ensure the authenticated user has an admin role according to API response
			let isAdmin = false
			try {
				// Try several common locations where role info might appear
				const roleCandidate = data?.role ?? data?.data?.role ?? data?.user?.role ?? data?.data?.user?.role ?? data?.data?.roles ?? data?.roles ?? null
				if (roleCandidate != null) {
					if (Array.isArray(roleCandidate)) {
						isAdmin = roleCandidate.map((r: any) => String(r).toLowerCase()).includes('admin')
					} else {
						const rv = String(roleCandidate).toLowerCase()
						isAdmin = rv === 'admin' || rv.includes('admin') || rv === 'administrator'
					}
				}
			} catch (_) {}

			if (!isAdmin) {
				setError('เฉพาะผู้ใช้งานที่มีสิทธิ์ผู้ดูแลระบบ (admin) เท่านั้นที่สามารถเข้าสู่ระบบได้')
				return
			}

			// store token and username for admin session (if provided)
			try {
				// try several common locations for token in response
				const tokenVal = data?.token ?? data?.data?.token ?? data?.data?.auth_token ?? data?.data?.accessToken ?? null;
				if (tokenVal) localStorage.setItem('admin_token', String(tokenVal));
				const uname = data?.data?.username ?? username;
				if (uname) localStorage.setItem('admin_username', String(uname));
			} catch (_) {}
			// success: redirect to admin manage posts
			window.location.href = '/admin/manage_posts'
		} catch (err: any) {
			setError(String(err?.message ?? err))
		} finally {
			setLoading(false)
		}
	}

	return (
		<div className={styles.pageWrap}>
			<header className={styles.topbar}>
				<div className={styles.logo}>Get Work!</div>
			</header>

			<main className={styles.container}>
				<form className={styles.card} onSubmit={submit}>
					<h1 className={styles.title}>เข้าสู่ระบบ</h1>

					{error && <div className={styles.error}>{error}</div>}

					<label className={styles.fieldLabel} htmlFor="username">ชื่อผู้ใช้งาน</label>
					<input
						id="username"
						className={styles.input}
						value={username}
						onChange={(e) => setUsername(e.target.value)}
						placeholder=""
					/>

					<label className={styles.fieldLabel} htmlFor="password">รหัสผ่าน</label>
					<div className={styles.inputRow}>
						<input
							id="password"
							className={styles.input}
							type={showPassword ? "text" : "password"}
							value={password}
							onChange={(e) => setPassword(e.target.value)}
							placeholder=""
						/>
						<button
							type="button"
							aria-label={showPassword ? "Hide password" : "Show password"}
							className={styles.eyeBtn}
							onClick={() => setShowPassword((s) => !s)}
						>
							{showPassword ? (
								<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M17.94 17.94C16.11 19.11 14.06 19.77 12 19.77C7 19.77 3 15.77 3 12C3 10.21 3.66 8.29 4.77 6.58" stroke="#173F4E" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round"/></svg>
							) : (
								<svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2 12s4-6 10-6 10 6 10 6-4 6-10 6S2 12 2 12z" stroke="#173F4E" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/><circle cx="12" cy="12" r="3" stroke="#173F4E" strokeWidth="1.2" strokeLinecap="round" strokeLinejoin="round"/></svg>
							)}
						</button>
					</div>

					<div className={styles.actions}>
						<button className={styles.submitBtn} type="submit" disabled={loading}>{loading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ'}</button>
					</div>
				</form>
			</main>
		</div>
	)
}

