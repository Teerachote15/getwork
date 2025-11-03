"use client"

import styles from "../page.module.css"
import React, { useEffect, useState } from "react"

type PostDetail = {
  post_id: number;
  user_id: number;
  image_post?: string | null;
  post_name: string;
  post_category?: number | null;
  wage?: number | null;
  description?: string | null;
  created_at?: string;
};

export default function CheckPostPage() {
  const [post, setPost] = useState<PostDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Get post id from query string
  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const id = params.get("id")
    if (!id) {
      setError("ไม่พบโพสต์")
      setLoading(false)
      return
    }
    const apiBase = (process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:4000').replace(/\/+$/, '')
    fetch(`${apiBase}/job/posts/${id}`)
      .then(async res => {
        if (!res.ok) throw new Error("ไม่พบโพสต์")
        const data = await res.json()
        setPost(data)
      })
      .catch(() => setError("ไม่พบโพสต์"))
      .finally(() => setLoading(false))
  }, [])

  const go = (path: string) => { window.location.href = path }

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
          <button className={styles.logoutBtn} onClick={() => {
            try {
              localStorage.removeItem('admin_token')
              localStorage.removeItem('admin_username')
            } catch (_) {}
            window.location.href = '/admin/login'
          }}>ออกจากระบบ</button>
        </div>
      </header>

      <main className={styles.container}>
        <button className={styles.backBtn} onClick={() => go('/admin/manage_posts')}>ย้อนกลับ</button>
        {loading ? (
          <div style={{ padding: 24 }}>Loading...</div>
        ) : error ? (
          <div style={{ color: "#b00020", margin: 24 }}>{error}</div>
        ) : post && (
          <form className={styles.formWrap} style={{ maxWidth: 500 }}>
            <div className={styles.label}>ตัวอย่างงาน</div>
            <div className={styles.imgBox}>
              {post.image_post
                ? <img src={
                    post.image_post.startsWith("/")
                      ? (process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:4000').replace(/\/+$/, '') + post.image_post
                      : post.image_post
                  } alt="" style={{ width: 200, height: 150, objectFit: 'cover', borderRadius: 8 }} />
                : <span style={{ width: 200, height: 150, background: '#eee', display: 'inline-block', borderRadius: 8 }} />}
            </div>

            <div className={styles.label}>
              ชื่องาน/ประเภทงาน
              {/* หมวดหมู่งาน: post_category (แสดงเป็น id หรือดึงชื่อหมวดหมู่เพิ่มได้) */}
              {post.post_category != null && (
                <span className={styles.chip}>หมวดหมู่: {post.post_category}</span>
              )}
            </div>
            <input className={styles.input} value={post.post_name ?? ""} readOnly />

            <div className={styles.label}>รายละเอียดงาน</div>
            <textarea className={styles.textarea} value={post.description ?? ""} readOnly />

            <div className={styles.label}>งบประมาณ/ค่าแรง (บาท)</div>
            <input className={styles.input} value={post.wage != null ? String(post.wage) : ""} readOnly />
          </form>
        )}
      </main>
    </div>
  )
}
