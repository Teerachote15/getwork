"use client"

import React from "react"
import styles from "./page.module.css"

export default function CheckReportPage(){
  // example placeholder data
  const report = {
    title: 'หัวข้อ',
    user: 'ชื่อผู้ใช้งาน',
    detail: 'รายงานปัญหา ... ตัวอย่างข้อความรายละเอียดของรายงานปัญหาแสดงที่นี่'
  }

  return (
    <div className={styles.pageWrap}>
      <header className={styles.topbar}>
        <div className={styles.logo}>Get Work!</div>
        <nav className={styles.nav}>
          <button className={styles.navItem}>โพสรออนุมัติ</button>
          <button className={styles.navItem}>บัญชีผู้ใช้</button>
          <button className={`${styles.navItem} ${styles.navItemActive}`}>ระบบการเงิน</button>
          <button className={styles.navItem}>รายงานปัญหา</button>
        </nav>
        <div style={{width:120}} />
      </header>

      <main className={styles.container}>
        <button className={styles.backBtn}>ย้อนกลับ</button>

        <div className={styles.title}>รายงานปัญหา</div>

        <div className={styles.headBox}>
          <div className={styles.headLabel}>หัวข้อ</div>
          <div className={styles.headDots}> {report.title}</div>
        </div>

        <div className={styles.reportBox}>
          <div className={styles.reportHeader}>{report.user}</div>
          <div>{report.detail}</div>
        </div>

      </main>
    </div>
  )
}
