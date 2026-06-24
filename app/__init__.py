import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

load_dotenv()

db = SQLAlchemy()

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_SQLITE_PATH = BASE_DIR / "data" / "events.db"


def _sqlite_uri(db_path: Path) -> str:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    return f"sqlite:///{db_path.resolve()}"


def create_app(config=None):
    sqlite_path = Path(os.environ.get("SQLITE_DB_PATH", DEFAULT_SQLITE_PATH))

    app = Flask(__name__)
    app.config.from_mapping(
        {
            "SQLALCHEMY_DATABASE_URI": _sqlite_uri(sqlite_path),
            "SQLALCHEMY_TRACK_MODIFICATIONS": False,
            "SQLALCHEMY_ENGINE_OPTIONS": {
                "connect_args": {"check_same_thread": False},
            },
        }
    )
    if config:
        app.config.update(config)

    db.init_app(app)

    from app.routes import ask_bp, deep_analysis_bp, events_bp, tasks_bp

    app.register_blueprint(ask_bp, url_prefix="/api/ask")
    app.register_blueprint(deep_analysis_bp, url_prefix="/api/deep-analysis")
    app.register_blueprint(events_bp, url_prefix="/api/events")
    app.register_blueprint(tasks_bp, url_prefix="/api/tasks")

    @app.route("/health")
    def health():
        from flask import jsonify as _jsonify
        return _jsonify({"status": "ok"})

    with app.app_context():
        db.create_all()

    return app
