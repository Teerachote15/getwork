# model/data_loader.py
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv
import pandas as pd

load_dotenv()

DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "getworks_app")

def load_freelancers_from_db():
    engine = create_engine(f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}")
    
    query = text("""
        SELECT
            u.user_id AS user_id,
            u.displayname AS name,
            u.about_me AS description,
            u.education_history,
            u.work_experience,
            AVG(r.rate) AS avg_rating,
            COUNT(DISTINCT r.rating_id) AS job_count,
            GROUP_CONCAT(DISTINCT jc.name SEPARATOR ', ') AS categories,
            GROUP_CONCAT(DISTINCT p.post_name SEPARATOR ', ') AS posts
        FROM users u
        LEFT JOIN posts p ON p.user_id = u.user_id
        LEFT JOIN job_categories jc ON jc.category_id = p.post_category
        LEFT JOIN ratings r ON r.to_user_id = u.user_id
        WHERE u.role = 'user'
        GROUP BY
            u.user_id, u.displayname, u.about_me, u.education_history,
            u.work_experience;
    """)
    
    df = pd.read_sql(query, engine)

    # แปลงค่าเพื่อให้ Pydantic รับได้ตรง ๆ
    df['avg_rating'] = df['avg_rating'].fillna(0).astype(float)
    df['job_count'] = df['job_count'].fillna(0).astype(int)
    df.fillna("", inplace=True)  # สำหรับ string fields

    return df.to_dict(orient="records")
