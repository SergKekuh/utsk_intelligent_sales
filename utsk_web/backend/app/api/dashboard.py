from fastapi import APIRouter, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token

router = APIRouter()

@router.get("/api/dashboard")
def dashboard(token: str = Query(None), db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(text("SELECT * FROM get_dashboard_stats()")).first()
    return {
        "status": "ok",
        "total_clients": result.total_clients,
        "active_30d": result.active_30d,
        "active_90d": result.active_90d,
        "total_revenue": round(float(result.total_revenue), 2),
        "revenue_30d": round(float(result.revenue_30d), 2)
    }

@router.get("/health")
def health(db: Session = Depends(get_db)):
    try:
        result = db.execute(text("SELECT COUNT(*) FROM clients")).scalar()
        return {"status": "ok", "database": "connected", "clients_count": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}
