import json
import os
from datetime import datetime
from uuid import uuid4

import pandas as pd
# from dotenv import dotenv_values

import openai
import pprint
import random
from copy import deepcopy
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from itertools import combinations
from typing import Any, Dict, List, Union

import numpy as np
import pandas as pd

# import plotly.express as px
# import psycopg
# from pandas import option_context
# from psycopg.rows import dict_row
from collections import defaultdict
from openai_info import OPENAI_API_KEY, OPENAI_ORGANIZATION #
import httpx
import asyncio


chat_interfaces = {}
openai.organization = OPENAI_ORGANIZATION
openai.api_key = OPENAI_API_KEY


model_mapping = {
    # "GPT 4": "text-davinci-002",
    "GPT 3.5": "gpt-3.5-turbo-0613",
    "GPT 4": "gpt-4-0613",
    # "GPT 3.5": "text-davinci-003",
}




# def run_openai_model(chat_uuid, userInput):
#     print("entered run openai model")
#     if chat_uuid not in chat_interfaces: #create new chat
#         print("creating new chat session")
#         chat_interfaces[chat_uuid] = ChatInterface(chat_uuid=chat_uuid)
#     elif chat_interfaces[chat_uuid] == None:
#         print("chat interface exists in dictionary but subprocess doesn't exist")

#     loop = asyncio.get_event_loop()
#     return loop.run_until_complete(chat_interfaces[chat_uuid].chat(userInput))


# async def run_openai_model(chat_uuid, userInput):
#     print("entered run openai model")
#     if chat_uuid not in chat_interfaces: #create new chat
#         print("creating new chat session")
#         chat_interfaces[chat_uuid] = ChatInterface(chat_uuid=chat_uuid)
#     elif chat_interfaces[chat_uuid] == None:
#         print("chat interface exists in dictionary but subprocess doesn't exist")

#     return await chat_interfaces[chat_uuid].chat(userInput)



# This function sends a request to the language model endpoint with a given prompt text
# and returns the generated text from the language model.
# async def ask_llm(prompt_text: str, user_input: str, eval_model_name: str):
#     try:
#         chat_completion_resp = await openai.ChatCompletion.acreate(
#             model=eval_model_name,
#             messages=[
#                 {
#                     "role": "system",
#                     "content": prompt_text,
#                 },
#                 {
#                     "role": "user",
#                     "content": user_input,
#                 },
#             ],
#             temperature=0.1,
#             max_tokens=1024,
#         )
#         print("completion_resp.choices: ", chat_completion_resp)
#         response_text = chat_completion_resp.choices[0].message.content
#     except Exception as e:
#         print(e)
#     else:
#         return response_text


def ask_llm(prompt_text: str, user_input: str, eval_model_name: str):
    print("prompt text: ", prompt_text)
    print("user input: ", user_input)
    print("eval model name: ", eval_model_name)
    try:
        # completion_resp = openai.Completion.create(
        completion_resp = openai.ChatCompletion.create(
            model=eval_model_name,
            # prompt=f"System prompt + User History: {prompt_text}\n- User: {user_input}",
            messages=[
                {
                    "role": "system",
                    "content": prompt_text,
                },
                {
                    "role": "user",
                    "content": user_input,
                },
            ],
            temperature=0.1,
            max_tokens=1024,
        )
        print("completion_resp.choices: ", completion_resp)
        response_text = completion_resp['choices'][0]['message']['content'].strip()
        print("RESPONSE TEXT FROM ASK LLM: ", response_text)
    except Exception as e:
        print(e)
    else:
        return response_text




# async def ask_llm(
#     prompt_text: str, llm_endpoint: str, client: httpx.AsyncClient
# ):
#     headers = {"Content-Type": "application/json"}
#     data = {
#         "inputs": f"<|prompt|>{prompt_text}<|endoftext|><|answer|>",
#         "parameters": {
#             "max_new_tokens": 1024,
#             "min_new_tokens": 2,
#             "num_beams": 1,
#             "do_sample": False,
#             "temperature": 0.3,
#             "repetition_penalty": 1.2,
#             "renormalize_logits": True,
#         },
#     }

#     try:
#         response = await client.post(
#             llm_endpoint,
#             json=data,
#             headers=headers,
#         )
#         response.raise_for_status()
#     except httpx.RequestError as exc:
#         print(f"An error occurred while requesting {exc.request.url!r}.")
#     except httpx.HTTPStatusError as exc:
#         print(
#             f"Error response {exc.response.status_code} while requesting {exc.request.url!r}."
#         )
#     else:
#         try:
#             response_text = response.json()["generated_text"]
#         except Exception as e:
#             print(e)
#         else:
#             return response_text
        

async def answer_questions(json_file: str, llm_endpoint: str, client: httpx.AsyncClient):
    with open(json_file, 'r') as file:
        data = json.load(file)

    answer_data = []
    for entry in data:
        prompt_text = f""" {entry['source']} Given the information above and only the information from above, answer the following question {entry['question']} """
        answer_text = await ask_llm(prompt_text, llm_endpoint, client)

        if answer_text:
            answer_data.append({'id': entry['id'], 'answer': answer_text})

    with open('answers.json', 'w') as file:
        json.dump(answer_data, file)


def read_json(json_path):
    json_data = None
    try:
        with open(json_path, "r") as json_fp:
            json_data = json.load(json_fp)
    except Exception as e:
        print(e)
    return json_data


def write_json(data: Union[Dict, List], file_name: str) -> str:
    out_file_path = os.path.abspath(file_name)
    with open(out_file_path, "w") as json_fp:
        json.dump(data, json_fp)
    return out_file_path


class ChatInterface:
    def __init__(self, chat_uuid) -> None:
        self.chat_uuid = chat_uuid
        # self.history = []
        # self.history_file = os.path.join(directory, f"{chat_uuid}_history.txt")


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
        intro_prompt = "This is the conversation history between a User and an AI Assistant named Bob. Bob is helpful, friendly, and tries to have natural conversations. The #END# delimiter marks the end of a response"
        
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


    def chat(self, userInput, model_name, timeout_seconds=120):
        if not userInput.strip():
            return "Please provide more information or clarify your question."
        
         # Add end delimiter to userInput and save it to history
        userInput += "#END#"

        # Save userInput to history
        self.history.append(f"User: {userInput}")
        if not os.path.exists(self.history_file):
            open(self.history_file, 'w').close()

        #append new chats to the chat history
        with open(self.history_file, 'a', encoding='utf-8') as f:
            print(f"User: {userInput}", file=f)
        
        # Create the prompt text
        intro_prompt = "This is a chat with Bob, an AI assistant. Each response is marked by '#END#'. Use the conversation history to answer the user's question." 
        prompt_file_path = self.create_prompt_file()


        with open(prompt_file_path, 'r', encoding='utf-8') as f:
            full_prompt = f.read()

        # Use ask_llm to get the response
        response_text = ask_llm(full_prompt, userInput, model_mapping[model_name])

        if response_text:
            output = response_text + '#END#'
            self.history.append(output)
            with open(self.history_file, 'a', encoding='utf-8') as f:
                print(output, file=f)
            return output
        else:
            return "Timeout"
    


def run_openai_model(chat_uuid, userInput, modelName):
    print("entered run openai model")
    if chat_uuid not in chat_interfaces: #create new chat
        print("creating new chat session")
        chat_interfaces[chat_uuid] = ChatInterface(chat_uuid=chat_uuid)
    elif chat_interfaces[chat_uuid] == None:
        print("chat interface exists in dictionary but subprocess doesn't exist")

    return chat_interfaces[chat_uuid].chat(userInput, modelName)
    # return asyncio.run(chat_interfaces[chat_uuid].chat(userInput, modelName))

    # async def chat(self, userInput, timeout_seconds=120):
    #     if not userInput.strip():
    #         return "Please provide more information or clarify your question."
        
    #     # Save userInput to history
    #     self.history.append(f"User: {userInput}#END#")
    #     if not os.path.exists(self.history_file):
    #         open(self.history_file, 'w').close()

    #     #append new chats to the chat history
    #     with open(self.history_file, 'a', encoding='utf-8') as f:
    #         print(f"User: {userInput}", file=f)
        
    #     # Create the prompt text
    #     intro_prompt = "This is the conversation history between a User and an AI Assistant named Bob. Bob is helpful, friendly, and tries to have natural conversations. The \"#END#\" delimiter marks the end of a response. Below you will find the conversation history. Use this as reference for when the user asks any question about the conversation."
    #     with open(self.history_file, 'r') as f:
    #         history_content = f.read()
    #     full_prompt = f"{intro_prompt}\n{history_content}"

    #     # Use ask_llm to get the response
    #     response_text = await ask_llm(full_prompt, self.llm_endpoint, self.client)

    #     if response_text:
    #         output = response_text + '#END#'
    #         self.history.append(output)
    #         with open(self.history_file, 'a', encoding='utf-8') as f:
    #             print(output, file=f)
    #         return output
    #     else:
    #         return "Timeout"
        



