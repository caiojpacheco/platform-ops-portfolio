import time
import uuid
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    Counter,
    Histogram,
    generate_latest,
)
from pydantic import BaseModel

app = FastAPI(
    title="Platform Ops API",
    version="1.0.0",
    description="Demo API for platform-ops-portfolio",
)

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP request count",
    ["method", "endpoint", "status_code"],
)
REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

items_db: dict[str, dict] = {}


class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    in_stock: bool = True


class ItemResponse(Item):
    id: str


@app.middleware("http")
async def metrics_middleware(request, call_next):
    start = time.perf_counter()
    response = await call_next(request)
    duration = time.perf_counter() - start
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status_code=response.status_code,
    ).inc()
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path,
    ).observe(duration)
    return response


@app.get("/health", tags=["ops"])
async def health():
    return {"status": "healthy", "service": "platform-ops-api", "version": "1.0.0"}


@app.get("/metrics", tags=["ops"])
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/items", response_model=list[ItemResponse], tags=["items"])
async def list_items():
    return [ItemResponse(id=k, **v) for k, v in items_db.items()]


@app.post("/api/items", response_model=ItemResponse, status_code=201, tags=["items"])
async def create_item(item: Item):
    item_id = str(uuid.uuid4())
    items_db[item_id] = item.model_dump()
    return ItemResponse(id=item_id, **item.model_dump())


@app.get("/api/items/{item_id}", response_model=ItemResponse, tags=["items"])
async def get_item(item_id: str):
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    return ItemResponse(id=item_id, **items_db[item_id])


@app.put("/api/items/{item_id}", response_model=ItemResponse, tags=["items"])
async def update_item(item_id: str, item: Item):
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    items_db[item_id] = item.model_dump()
    return ItemResponse(id=item_id, **item.model_dump())


@app.delete("/api/items/{item_id}", status_code=204, tags=["items"])
async def delete_item(item_id: str):
    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")
    del items_db[item_id]
