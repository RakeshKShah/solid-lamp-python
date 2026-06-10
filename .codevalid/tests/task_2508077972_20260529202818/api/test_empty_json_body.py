import pytest
from app import create_app, db


@pytest.fixture()
def app(tmp_path):
    database_path = tmp_path / "test_empty_json_body.db"
    app = create_app(
        {
            "TESTING": True,
            "SQLALCHEMY_DATABASE_URI": f"sqlite:///{database_path}",
            "SQLALCHEMY_ENGINE_OPTIONS": {"connect_args": {"check_same_thread": False}},
        }
    )
    with app.app_context():
        db.drop_all()
        db.create_all()
    yield app


@pytest.fixture()
def client(app):
    return app.test_client()


def test_empty_json_body(client, app):
    with app.app_context():
        event = Event(
            name="KART Original",
            description="Original desc",
            location="Original loc",
        )
        db.session.add(event)
        db.session.commit()
        event_id = event.id

    response = client.put(f"/api/events/{event_id}", json={})

    assert response.status_code == 200
    body = response.get_json()
    assert body["id"] == event_id
    assert body["name"] == "KART Original"
    assert body["description"] == "Original desc"
    assert body["location"] == "Original loc"
