import pytest
from fastapi.testclient import TestClient

from main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_metrics_endpoint():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text


def test_create_and_get_item():
    payload = {"name": "Widget", "description": "A test widget", "price": 9.99, "in_stock": True}
    create_resp = client.post("/api/items", json=payload)
    assert create_resp.status_code == 201
    item_id = create_resp.json()["id"]

    get_resp = client.get(f"/api/items/{item_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["name"] == "Widget"


def test_update_item():
    payload = {"name": "Widget", "price": 9.99}
    item_id = client.post("/api/items", json=payload).json()["id"]
    updated = client.put(f"/api/items/{item_id}", json={"name": "Widget Pro", "price": 19.99})
    assert updated.status_code == 200
    assert updated.json()["name"] == "Widget Pro"


def test_delete_item():
    item_id = client.post("/api/items", json={"name": "Temp", "price": 1.0}).json()["id"]
    del_resp = client.delete(f"/api/items/{item_id}")
    assert del_resp.status_code == 204
    assert client.get(f"/api/items/{item_id}").status_code == 404


def test_item_not_found():
    response = client.get("/api/items/non-existent-id")
    assert response.status_code == 404
