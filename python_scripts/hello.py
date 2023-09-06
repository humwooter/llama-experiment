
from queue import Queue, Empty
import subprocess
import os
import threading

chat_interfaces = {}

def kill_chat(chat_uuid):
    if chat_uuid in chat_interfaces:
        chat_interfaces[chat_uuid].process.terminate()
        del chat_interfaces[chat_uuid]
    else:
        print(f"No chat with UUID {chat_uuid} found.")

        
class ChatInterface:
    def __init__(self):
        self.process = None
        self.q = Queue()
        self.t = None

    def set_model_path(self, model_path):
        # print("model path: ", model_path)
        model_dir = os.path.dirname(model_path)
        parent_dir = os.path.dirname(model_dir)
        target_dir = os.path.dirname(parent_dir)
        os.chdir(target_dir)

# ./main -m model_path -n 1024 --repeat_penalty 1.0 --color -i -r User: -f ./prompts/chat-with-bob.txt

        self.cmd = ['./main', '-m', model_path, '-n', '1024', '--repeat_penalty', '1.0', '--color', '-i', '-r', 'User:', '-f', './prompts/chat-with-bob.txt']
        
        # self.process = subprocess.Popen(self.cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=0, universal_newlines=True)
        self.process = subprocess.Popen(self.cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, bufsize=0, universal_newlines=True, encoding='utf-8')

        self.t = threading.Thread(target=self.read_output, args=(self.process.stdout, self.q))
        self.t.daemon = True
        self.t.start()

    # def read_output(self, pipe, q):
    #     while True:
    #         line = pipe.readline()
    #         if line:
    #             print("Received:", line)  # Debugging
    #             q.put(line)


    def read_output(self, pipe, q):
        
        buffer = ""
        while True:
            line = pipe.readline()
            if line:
                # print("Received:", line)  # Debugging
                buffer += line
                if "#END#" in buffer:
                    split_output = buffer.split("#END#")
                    for partial_output in split_output[:-1]:
                        q.put(partial_output.strip())
                    buffer = split_output[-1]
        # print("buffer ", buffer)


    
    def chat(self, userInput, timeout_seconds=120):
        if self.process is None:
            return "Model not initialized."
        
        if not userInput.strip():  # Check for empty or whitespace-only strings
            return "Please provide more information or clarify your question."

        # print("Sending:", userInput)  # Debugging
        # print("User:", userInput, file=self.process.stdin, flush=True)
        # print(f"User: {userInput}User", file=self.process.stdin, flush=True)
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
                    # print("Collected:", line)  # Debugging
                    output_lines.append(line)
                    break
            except Empty:
                print("Process timed out. Terminating.")
                self.process.kill()
                return "Timeout"
        
        return ''.join(output_lines)


# Initialize once and use it multiple times

# # def initialize_chat():
# chat_interface = ChatInterface()

# def run_ggml_model(model_path, userInput):
#     if chat_interface == None:
#         print("no chat available")
#         return   
#     if chat_interface.process is None:
#         chat_interface.set_model_path(model_path)
#     return chat_interface.chat(userInput)


def run_ggml_model(model_path, userInput, chat_uuid):
    if chat_uuid not in chat_interfaces:
        chat_interfaces[chat_uuid] = ChatInterface()
        chat_interfaces[chat_uuid].set_model_path(model_path)
    
    return chat_interfaces[chat_uuid].chat(userInput)