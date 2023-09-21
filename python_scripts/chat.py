from queue import Queue, Empty
import subprocess
import os
import threading


#dictionary of chats, where the key is the uuid of the chat
chat_interfaces = {}

def create_summary(self, history_content):
    # This is a very simple example. You'll need to replace this with your own summarization logic.
    lines = history_content.split('\n')
    summary_lines = lines[-10:]  # Take the last 10 lines
    return '\n'.join(summary_lines)

#used for deleting the chat
def kill_chat(chat_uuid):
    if chat_uuid in chat_interfaces:
        chat_interfaces[chat_uuid].process.terminate()
        # Delete the history file
        if os.path.exists(chat_interfaces[chat_uuid].history_file):
            os.remove(chat_interfaces[chat_uuid].history_file)
        del chat_interfaces[chat_uuid]
    else:
        print(f"No chat with UUID {chat_uuid} found.")

def run_ggml_model(model_path, userInput, chat_uuid):
    if chat_uuid not in chat_interfaces: #create new chat
        print("creating new chat session")
        chat_interfaces[chat_uuid] = ChatInterface(chat_uuid=chat_uuid)
        chat_interfaces[chat_uuid].set_model_path(model_path)
    elif chat_interfaces[chat_uuid] == None:
        print("chat interface exists in dictionary but subprocess doesn't exist")

    return chat_interfaces[chat_uuid].chat(userInput)



class ChatInterface:
    def __init__(self, chat_uuid) -> None:
        self.process = None
        self.q = Queue()
        self.t = None #what's this
        self.chat_uuid = chat_uuid

        script_dir = os.path.dirname(os.path.realpath(__file__))
        history_dir = os.path.join(script_dir, 'Chat Histories')
        self.history_file = os.path.join(history_dir, f"{chat_uuid}_history.txt")
        os.makedirs(os.path.dirname(self.history_file), exist_ok=True) #create chat history file if it doesn't exist

        #load/initialize chat history
        if os.path.exists(self.history_file):
            with open(self.history_file, 'r') as f:
                self.history = f.read().splitlines()
        else:
            self.history = []

        
    def end_chat(self):
        self.process.terminate()
        if os.path.exists(self.history_file):
            open(self.history_file, 'w').close()
        with open(self.history_file, 'w') as f:
            for line in self.history:
                print(line, file=f)
    
    
    def set_model_path(self, model_path):
        #paths 
        model_dir = os.path.dirname(model_path)
        parent_dir = os.path.dirname(model_dir)
        target_dir = os.path.dirname(parent_dir)
        os.chdir(target_dir)

        intro_prompt = "This is the conversation history between a User and an AI Assistant named Bob. Bob is helpful, friendly, and tries to have natural conversations. The \"#END#\" delimiter marks the end of a response. Below you will find the conversation history. Use this as reference for when the user asks any question about the conversation."
        
        #create history_file if it doesn't exist already
        if not os.path.exists(self.history_file):
            open(self.history_file, 'w').close()
        with open(self.history_file, 'r') as f:
            history_content = f.read()

        full_prompt = f"{intro_prompt}\n{history_content}"

        with open('temp_prompt.txt', 'w') as f:
            f.write(full_prompt)
        
        self.cmd = ['./main', '-m', model_path, '-n', '1024', '--repeat_penalty', '1.0', '--color', '-i', '-r', 'User:', '-f', './temp_prompt.txt']
        self.process = subprocess.Popen(self.cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=0, universal_newlines=True, encoding='utf-8')
        self.t = threading.Thread(target=self.read_output, args=(self.process.stdout, self.q))
        
        # Sets the thread 'self.t' as a daemon thread, allowing the main program to exit even if this thread is still running.
        self.t.daemon = True
        self.t.start()

    def read_output(self, pipe, q):
        buffer = ""
        while True:
            line = pipe.readline()
            if line:
                buffer += line
                if "#END#" in buffer:
                    split_output = buffer.split("#END#")
                    #collect all output except for end delimeter
                    for partial_output in split_output[:-1]:
                        q.put(partial_output.strip())
                    buffer = split_output[-1] #set buffer to whatever came after end delimeter (should be empty)

    
    def chat(self, userInput, timeout_seconds=240):
        if self.process is None:
            return "Model not initialized. Please select model file"
        
        if not userInput.strip():
            return "Please provide more information or clarify your question."
        
        # Save userInput to history
        self.history.append(f"User: {userInput}#END#")
        if not os.path.exists(self.history_file):
            open(self.history_file, 'w').close()

        #append new chats to the chat history
        with open(self.history_file, 'a') as f:
            print(f"User: {userInput}", file=f)

        self.process.stdin.write(f"User: {userInput} #END#\n")
        self.process.stdin.flush()


        # Clear the queue before listening for new output
        while not self.q.empty():
            try:
                self.q.get_nowait()
            except Empty:
                break
    
        output_lines = []

        while True:
            try:
                line = self.q.get(timeout=timeout_seconds)
                if "Bob:" in line:
                    output_lines.append(line)
                    break
            except Empty:
                print("Process timed out.")
                self.end_chat()
                return "Timeout"
            
        output = ''.join(output_lines)
        output += '#END#'
        self.history.append(output)

        with open(self.history_file, 'a') as f:
            print(output, file=f)
        return output
    





