"use client"

import React, { useEffect, useState } from "react"
import styles from "./page.module.css"

const reports = Array(9).fill({ title: "รายงานระบบ", user: "ชื่อผู้ใช้งาน" })

export default function ReportPage(){
  const [adminName, setAdminName] = useState<string | null>(null)
  useEffect(() => {
    try { const n = localStorage.getItem('admin_username'); if (n) setAdminName(n) } catch (_) {}
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
          <button className={styles.navItem} onClick={() => go('/admin/manage_posts')}>โพสรออนุมัติ</button>
          <button className={styles.navItem} onClick={() => go('/admin/account_user')}>บัญชีผู้ใช้</button>
          <button className={styles.navItem} onClick={() => go('/admin/finance')}>ระบบการเงิน</button>
          <button className={`${styles.navItem} ${styles.navItemActive}`} onClick={() => go('/admin/report')}>รายงานปัญหา</button>
        </nav>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          {adminName && <div style={{ color: '#173F4E' }}>{adminName}</div>}
          <button className={styles.logoutBtn} onClick={handleLogout}>ออกจากระบบ</button>
        </div>
      </header>

      <main className={styles.container}>
        <div className={styles.pageTitle}>รายงานทั้งหมด</div>

        <div className={styles.tableWrap}>
          <table className={styles.table}>
            <thead className={styles.thead}>
              <tr>
                <th className={styles.th}>รายชื่อผู้ใช้งาน</th>
                <th className={styles.th}>รายงานระบบ</th>
                <th className={styles.th}></th>
              </tr>
            </thead>
            <tbody>
              {reports.map((r, i) => (
                <tr key={i}>
                  <td className={styles.td}>
                    <div style={{display:'flex',alignItems:'center',gap:16}}>
                      <span className={styles.avatar}></span>
                      {r.user}
                    </div>
                  </td>
                  <td className={styles.td} style={{textAlign:'center'}}>{r.title}</td>
                  <td className={styles.td} style={{textAlign:'right'}}>
                    <button className={styles.btnCheck}>ตรวจสอบข้อมูล</button>
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
