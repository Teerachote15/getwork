"use client"

import styles from "./page.module.css"
import React, { useEffect, useState } from "react"

type PostItem = {
  post_id: number;
  user_id: number;
  image_post?: string | null;
  post_name: string;
  post_category?: number | null;
  wage?: number | null;
  status?: string;
  created_at?: string;
};

export default function ManagePostsPage() {
  const [adminName, setAdminName] = useState<string | null>(null)
  const [posts, setPosts] = useState<PostItem[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const apiBase = (process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:4000').replace(/\/+$/, '')

  useEffect(() => {
    try {
      const n = localStorage.getItem('admin_username')
      if (n) setAdminName(n)
    } catch (_) {}
    loadPosts()
    // eslint-disable-next-line
  }, [])

  async function loadPosts() {
    setLoading(true)
    setError(null)
    try {
      const res = await fetch(`${apiBase}/admin/posts?status=pending`)
      if (!res.ok) {
        setError('โหลดข้อมูลโพสต์ไม่สำเร็จ')
        setPosts([])
        return
      }
      const data = await res.json()
      // แปลงข้อมูลให้ตรงกับ PostItem
      setPosts(Array.isArray(data) ? data.map((p: any) => ({
        post_id: p.post_id,
        user_id: p.user_id,
        image_post: p.image_post && typeof p.image_post === 'string' && p.image_post.startsWith('/')
          ? apiBase + p.image_post
          : p.image_post,
        post_name: p.post_name,
        post_category: p.post_category,
        wage: p.wage,
        status: p.status,
        created_at: p.created_at
      })) : [])
    } catch (err: any) {
      setError('เกิดข้อผิดพลาดในการโหลดโพสต์')
      setPosts([])
    } finally {
      setLoading(false)
    }
  }

  const go = (path: string) => { window.location.href = path }
  const handleLogout = () => {
    try {
      localStorage.removeItem('admin_token')
      localStorage.removeItem('admin_username')
    } catch (_) {}
    window.location.href = '/admin/login'
  }

  async function handleApprove(id: number) {
    try {
      const res = await fetch(`${apiBase}/admin/posts/${id}/approve`, { method: 'POST' })
      if (!res.ok) {
        const t = await res.text()
        alert('Approve failed: ' + t)
        return
      }
      setPosts(p => p.filter(x => x.post_id !== id))
    } catch (e) {
      alert('Approve error: ' + String(e))
    }
  }

  async function handleReject(id: number) {
    try {
      const res = await fetch(`${apiBase}/admin/posts/${id}/reject`, { method: 'POST' })
      if (!res.ok) {
        const t = await res.text()
        alert('Reject failed: ' + t)
        return
      }
      setPosts(p => p.filter(x => x.post_id !== id))
    } catch (e) {
      alert('Reject error: ' + String(e))
    }
  }

  return (
    <div className={styles.pageWrap}>
      <header className={styles.topbar}>
        <div className={styles.logo}>Get Work!</div>
        <nav className={styles.nav}>
          <button className={`${styles.navItem} ${styles.navItemActive}`} onClick={() => go('/admin/manage_posts')}>จัดการโพสต์</button>
          <button className={styles.navItem} onClick={() => go('/admin/account_user')}>บัญชีผู้ใช้</button>
          <button className={styles.navItem} onClick={() => go('/admin/finance')}>ระบบการเงิน</button>
        </nav>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {adminName && <div style={{ color: '#173F4E' }}>{adminName}</div>}
          <button className={styles.logoutBtn} onClick={handleLogout}>ออกจากระบบ</button>
        </div>
      </header>

      <main className={styles.container}>
        {error && <div style={{ color: "#b00020", marginBottom: 16 }}>{error}</div>}
        <div className={styles.headerRow}>
          <div className={styles.pageTitle}>โพสต์ทั้งหมด</div>
        </div>
        <div className={styles.tableWrap}>
          {loading ? <div style={{ padding: 24 }}>Loading...</div> : (
            <table className={styles.table}>
              <thead className={styles.thead}>
                <tr>
                  <th className={styles.th}>โพสโดย (user_id)</th>
                  <th className={styles.th}>หัวข้อ / รูป</th>
                  <th className={styles.th}>วันที่</th>
                  <th className={styles.th}></th>
                </tr>
              </thead>
              <tbody>
                {posts.length === 0 ? (
                  <tr><td className={styles.td} colSpan={4} style={{ textAlign: 'center', padding: 24 }}>ไม่มีโพสต์รอดำเนินการ</td></tr>
                ) : posts.map((p) => (
                  <tr key={p.post_id}>
                    <td className={styles.td}>
                      <div className={styles.userCell}>
                        <span className={styles.avatar}></span>
                        {String(p.user_id)}
                      </div>
                    </td>
                    <td className={styles.td}>
                      <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                        {p.image_post ? <img src={p.image_post} alt="" style={{ width: 72, height: 54, objectFit: 'cover', borderRadius: 6 }} /> : <span style={{ width: 72, height: 54, background: '#eee', borderRadius: 6 }} />}
                        <div>
                          <div style={{ fontWeight: 600 }}>{p.post_name}</div>
                          <div style={{ color: '#666' }}>งบ: {p.wage ?? '-'}</div>
                        </div>
                      </div>
                    </td>
                    <td className={styles.td}>{p.created_at ?? '-'}</td>
                    <td className={styles.td} style={{ textAlign: 'right' }}>
                      <button
                        className={styles.btnDetail}
                        style={{ marginRight: 8 }}
                        onClick={() => go(`/admin/manage_posts/check_post?id=${p.post_id}`)}
                      >
                        ดูรายละเอียดโพส
                      </button>
                      <button className={styles.btnReject} style={{ marginRight: 8 }} onClick={() => handleReject(p.post_id)}>ไม่อนุมัติ</button>
                      <button className={styles.btnApprove} onClick={() => handleApprove(p.post_id)}>อนุมัติ</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </main>
    </div>
  )
}
