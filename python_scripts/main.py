import sys
sys.path.append("..")

from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware

import llama_chat
import openai_chat
import h2o_chat
import asyncio
import httpx


app = FastAPI()

# origins = [
#     "http://localhost:8000",
#     "http://localhost",
#     "http://localhost:8080",
# ]

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=origins,
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

@app.get("/run_ggml_model")
async def run_ggml_model_endpoint(model_path: str, userInput: str, chat_uuid: str):
    result = llama_chat.run_ggml_model(model_path, userInput, chat_uuid)
    return {"result": result}

@app.get("/run_openai_model")
async def run_openai_model_endpoint(chat_uuid: str, userInput: str, modelName: str):
    result = openai_chat.run_openai_model(chat_uuid, userInput, modelName)
    return {"result": result}


@app.get("/run_h2o_model")
async def run_h2o_model_endpoint(chat_uuid: str, userInput: str, model_endpoint: str):
    result = await h2o_chat.run_h2o_model(chat_uuid, userInput, model_endpoint)
    return {"result": result}

@app.get("/kill_chat")
def kill_chat_endpoint(chat_uuid: str):
    llama_chat.kill_chat(chat_uuid)
    return {"message": "Chat terminated"}
