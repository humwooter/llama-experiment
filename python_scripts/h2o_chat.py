import json
import os
from datetime import datetime
from uuid import uuid4

import pandas as pd
# from dotenv import dotenv_values

import pprint
import random
from copy import deepcopy
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from itertools import combinations
from typing import Any, Dict, List, Union

import numpy as np
import pandas as pd

from collections import defaultdict
import httpx
import asyncio


import ast
from enum import Enum
from gradio_client import Client
from loguru import logger
import time
import markdown  # pip install markdown
from bs4 import BeautifulSoup  # pip install beautifulsoup4


import time


chat_interfaces = {}



model_mapping = {
    # "GPT 4": "text-davinci-002",
    "GPT 3.5": "gpt-3.5-turbo-0613",
    "GPT 4": "gpt-4-0613",
    # "GPT 3.5": "text-davinci-003",
}



def get_client(endpoint, serialize=True, debug=False):
    client = Client(endpoint, serialize=serialize)
    if debug:
        logger.debug(client.view_api(all_endpoints=True))
    return client

def no_chat(
    prompt_text,
    gpt_client,
    max_new_tokens,
    max_time,
    num_beams,
    do_sample,
    repetition_penalty,
    temperature,
    prompt_type,
):
    logger.debug(f"prompt: {prompt_text}")

    kwargs = dict(
        instruction="",
        iinput="",
        context="",
        stream_output=False,
        prompt_type=prompt_type,
        temperature=temperature,
        top_p=0.75,
        top_k=40,
        num_beams=num_beams,
        max_new_tokens=max_new_tokens,
        min_new_tokens=0,
        early_stopping=False,
        max_time=max_time,
        repetition_penalty=repetition_penalty,
        num_return_sequences=1,
        do_sample=do_sample,
        chat=False,
        instruction_nochat=prompt_text,
        iinput_nochat="",
        langchain_mode="Disabled",
        top_k_docs=4,
        document_choice=["All"],
        h2ogpt_key='62224bfb-c832-4452-81e7-8a4bdabbe164'
    )

    if prompt_type is None:
        del kwargs["prompt_type"]

    api_name = "/submit_nochat_api"  # NOTE: like submit_nochat but stable API for string dict passing
    client = gpt_client
    response_text = None
    try:
        res = client.predict(
            str(dict(kwargs)),
            api_name=api_name,
        )
        res_dict = ast.literal_eval(res)
        if isinstance(res_dict, dict):
            response_text = res_dict.get("response")
        else:
            logger.error(f"Unable to eval response to a dict: {res}")
    except Exception as e:
        logger.error(f"Error in client.predict: {e}")

    logger.debug(f"response: {response_text}")

    return response_text

async def ask_model(endpoint, prompt,  h2ogpt_key=None):
    client = get_client(endpoint, serialize=False)
    return no_chat(
    prompt_text=prompt,
    gpt_client=client,
    max_new_tokens=None,
    max_time=None,
    num_beams=None,
    do_sample=None,
    repetition_penalty=None,
    temperature=None,
    prompt_type=None,
)
    


class ChatInterface:
    def __init__(self, chat_uuid) -> None:
        self.chat_uuid = chat_uuid

        script_dir = os.path.dirname(os.path.realpath(__file__))
        history_dir = os.path.join(script_dir, 'Chat Histories')
        self.history_file = os.path.join(history_dir, f"{chat_uuid}_history.txt")
        os.makedirs(os.path.dirname(self.history_file), exist_ok=True) #create chat history file if it doesn't exist

        #load/initialize chat history
        if os.path.exists(self.history_file):
            with open(self.history_file, 'r', encoding='utf-8') as f:
                self.history = f.read().splitlines()
        else:
            self.history = []


    def end_chat(self):
        self.history = []
        if os.path.exists(self.history_file):
            os.remove(self.history_file)


    def create_prompt_file(self, num_words=100):
        # Create history_file if it doesn't exist already
        if not os.path.exists(self.history_file):
            open(self.history_file, 'w').close()
        
        with open(self.history_file, 'r', encoding='utf-8') as f:
            history_content = f.readlines()


        # Reverse the history_content to start counting words from the end
        reversed_content = history_content[::-1]
        word_count = 0
        selected_content = []

        # Iterate over reversed_content and stop when word_count is as close to num_words as possible
        for line in reversed_content:
            words_in_line = line.split()
            if word_count + len(words_in_line) > num_words:
                break
            word_count += len(words_in_line)
            selected_content.append(line)

        # Reverse selected_content to maintain original order and join to form a string
        history_content = ' '.join(selected_content[::-1])
                
        intro_prompt = "This is a chat with Bob, an AI assistant. Assume the role of Bob and continue the conversation." 
        full_prompt = f"{intro_prompt}\n{history_content}"

        # Create the Prompts directory if it doesn't exist
        prompts_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'Prompts')
        os.makedirs(prompts_dir, exist_ok=True)

        # Write the prompt to a file in the Prompts directory
        prompt_file_path = os.path.join(prompts_dir, f'prompt_{self.chat_uuid}.txt')
        with open(prompt_file_path, 'w', encoding='utf-8') as f:
            f.write(full_prompt)

        # Get the absolute path to the prompt file
        script_dir = os.path.dirname(os.path.realpath(__file__))
        prompts_dir = os.path.join(script_dir, 'Prompts')
        prompt_file_path = os.path.join(prompts_dir, f'prompt_{self.chat_uuid}.txt')
        return prompt_file_path


    async def chat(self, userInput, model_endpoint, timeout_seconds=120):
        print("ENTERED CHAT!!!")
        if not userInput.strip():
            return "Please provide more information or clarify your question."
        
        # Save userInput to history
        self.history.append(f"User: {userInput}")
        if not os.path.exists(self.history_file):
            open(self.history_file, 'w').close()

        #append new chats to the chat history
        with open(self.history_file, 'a', encoding='utf-8') as f:
            print(f"User: {userInput}", file=f)
    
        prompt_file_path = self.create_prompt_file()


        with open(prompt_file_path, 'r', encoding='utf-8') as f:
            full_prompt = f.read()


        response_text = await ask_model(model_endpoint, full_prompt)

        if response_text:
            # output = response_text 
            self.history.append(f"Bob: {response_text}")
            with open(self.history_file, 'a', encoding='utf-8') as f:
                print(f"Bob: {response_text}", file=f)
            return response_text
        else:
            return "Timeout"
    


async def run_h2o_model(chat_uuid, userInput, model_endpoint):
    print("entered run h2o model!")
    if chat_uuid not in chat_interfaces: #create new chat
        print("creating new chat session")
        chat_interfaces[chat_uuid] = ChatInterface(chat_uuid=chat_uuid)
    elif chat_interfaces[chat_uuid] == None:
        print("chat interface exists in dictionary but subprocess doesn't exist")

    return await chat_interfaces[chat_uuid].chat(userInput, model_endpoint)

