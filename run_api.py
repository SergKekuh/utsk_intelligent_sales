import sys, os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

sys.path.append(os.path.join(os.getcwd(), 'utsk_web', 'backend'))
from app.api.analytics import c2_segmentation_companies

engine = create_engine("postgresql://postgres:root@localhost:5432/bd_intelligent_sales")
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

res = c2_segmentation_companies(token="utsk2026", year=2026, db=db)
print("count:", res['count'])
print("cohort_counts:", res.get('cohort_counts', "NOT FOUND"))
